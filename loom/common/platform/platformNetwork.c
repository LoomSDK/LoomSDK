/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platformNetwork.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#define _WINSOCK_DEPRECATED_NO_WARNINGS
#include <WinSock2.h>
#include <WS2tcpip.h>
#include <WS2def.h>
#include <errno.h>
#include <stdio.h>
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <fcntl.h>
#include <sys/socket.h>
#include <netdb.h>
#include <errno.h>
#include <sys/select.h>
#define closesocket    close
typedef int   SOCKET;
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include "netinet/in.h"
#include <sys/ioctl.h>
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <signal.h>
#endif

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL    0 // no support for this flag
#endif // MSG_NOSIGNAL


lmDefineLogGroup(netLogGroup, "platform.network", 1, LoomLogWarn);

int loom_net_initialize()
{
    // Platform-specific init.
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    WSADATA wsaData;
    WORD    wVersionRequested = MAKEWORD(2, 0);
    int     err = WSAStartup(wVersionRequested, &wsaData);
    if (err != 0)
    {
        lmLogError(netLogGroup, "Failed WinSock initalization with error %d", err);
        return 0;
    }

    if (((LOBYTE(wsaData.wVersion) != 2) || (HIBYTE(wsaData.wVersion) != 0)) &&
        ((LOBYTE(wsaData.wVersion) != 1) || (HIBYTE(wsaData.wVersion) != 1)))
    {
        lmLogError(netLogGroup, "Failed WinSock initalization due to version mismatch.");
        WSACleanup();
        return 0;
    }

    // Sanity checks.
    lmAssert(sizeof(SOCKET) <= sizeof(loom_socketId_t), "Can't pack a SOCKET into loom_socketId_t");

    lmLogError(netLogGroup, "WinSock initialized.");
    return 1;

#else
    // Ignore sigpipe.
    lmLogInfo(netLogGroup, "Disabling signal SIGPIPE");
    signal(SIGPIPE, SIG_IGN);
    return 1;
#endif
}


void loom_net_shutdown()
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    WSACleanup();
#endif
}


static void loom_net_setSocketBlocking(loom_socketId_t s, int blocking)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    int blockTmp = blocking ? 0 : 1;
    int status   = ioctlsocket((SOCKET)s, FIONBIO, &blockTmp);
    lmAssert(status == NO_ERROR, "Failed trying to set socket blocking status due to %d", status);
#elif LOOM_PLATFORM_IS_APPLE == 1 || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    // This should work for POSIX compliant environments.
    // See http://stackoverflow.com/questions/1150635/unix-nonblocking-i-o-o-nonblock-vs-fionbio
    int flags = fcntl((int)s, F_GETFL);

    if (blocking == 1)
    {
        flags &= ~O_NONBLOCK;
    }
    else
    {
        flags |= O_NONBLOCK;
    }

    fcntl((int)s, F_SETFL, flags);
#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
    int val = 1;
    ioctl((int)s, FIONBIO, &val);
#endif
}


static void loom_net_setSocketReuseAddress(loom_socketId_t s, int reuse)
{
#if LOOM_PLATFORM_IS_APPLE == 1
    int reuseTmp = reuse;
    int status   = setsockopt((SOCKET)s, SOL_SOCKET, SO_REUSEPORT, &reuseTmp, sizeof(reuseTmp));
    lmAssert(status == 0, "Failed trying to set socket reuse address status due to %d", status);
#else
    // If you get issues where the socket stays bound after a listening process (like the assetAgent)
    // terminates you may need to set SO_REUSEADDR or SO_REUSEPORT or equivalent on your platform.
    lmLogInfo(netLogGroup, "Note: this platform doesn't support reusing port, but it probably doesn't matter.");
#endif
}


loom_socketId_t loom_net_openTCPSocket(const char *host, unsigned short port, int blocking)
{
    int     status, s, res;
    struct addrinfo hints;
    struct addrinfo *hostInfo;
    char portString[16];

    //set up he hints
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    //copy the port over to a string
    sprintf(portString, "%ld", port);

    // Resolve the host.
    res = getaddrinfo(host, portString, &hints, &hostInfo);
    if (res != 0)
    {
        lmLogError(netLogGroup, "Failed to resolve host '%s' via getaddrinfo: %s", host, gai_strerror(res));
        return NULL;
    }

    // Create the socket.
    s = socket(AF_INET, SOCK_STREAM, 0);
    if (s == -1)
    {
        lmLogError(netLogGroup, "Failed to open TCP socket - socket() failed.");
        freeaddrinfo(hostInfo);
        return NULL;
    }

    // Block if user wants it.
    loom_net_setSocketBlocking((loom_socketId_t)s, blocking);

    // Disable SIGPIPE, we handle that in another way.
#ifdef SO_NOSIGPIPE
    int set = 1;
    setsockopt(s, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
#endif

    // Do the connect.
    status = connect(s, hostInfo->ai_addr, hostInfo->ai_addrlen);
    if (status != 0)
    {
        // Get the real error code, might be WOULDBLOCK.
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
        int res = WSAGetLastError();
#else
        int res = errno;
#endif

        if (res != EINPROGRESS

            // Assorted platform specific checks/exceptions.
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
            && res != 0 &&
            res != WSAEWOULDBLOCK
#endif
            )
        {
            // Failure due to some grody reason.
            lmLogError(netLogGroup, "Failed to connect() TCP socket due to error code %d.", res);
            closesocket(s);
            freeaddrinfo(hostInfo);
            return NULL;
        }
    }

    freeaddrinfo(hostInfo);
    return (loom_socketId_t)s;
}


void loom_net_getSocketPeerName(loom_socketId_t s, int *hostIp, int *hostPort)
{
    struct sockaddr_in name;
    socklen_t          nameLen = sizeof(name);

    getpeername((int)s, (struct sockaddr *)&name, &nameLen);

    hostIp[0]   = ((unsigned char *)&name.sin_addr.s_addr)[0];
    hostIp[1]   = ((unsigned char *)&name.sin_addr.s_addr)[1];
    hostIp[2]   = ((unsigned char *)&name.sin_addr.s_addr)[2];
    hostIp[3]   = ((unsigned char *)&name.sin_addr.s_addr)[3];
    hostPort[0] = name.sin_port;
}


int loom_net_isSocketWritable(loom_socketId_t s)
{
    int    readsocks;
    fd_set waitSockets;

    struct timeval timeout;

    timeout.tv_sec  = 0;
    timeout.tv_usec = 1;

    // Set up sets for select().
    FD_ZERO(&waitSockets);
    FD_SET((int)s, &waitSockets);

    // Run the select with a very short wait period.
    readsocks = select(FD_SETSIZE, NULL, &waitSockets, NULL, &timeout);
    if (readsocks > 0)
    {
        // Cool, something happened, so we are by process of elimination writable.
        return 1;
    }

    // Nothing happened, so return 0.
    return 0;
}


int loom_net_isSocketDead(loom_socketId_t s)
{
    // According to http://stackoverflow.com/questions/4142012/how-to-find-the-socket-connection-state-in-c
    // If there is a non-zero error code it is dead.
    int       error = 0, retval = 0;
    socklen_t len   = sizeof(error);

    retval = getsockopt((int)s, SOL_SOCKET, SO_ERROR, (char *)&error, &len);
    if (retval == -1)
    {
        lmLogError(netLogGroup, "Could not read error on socket %x due to %d, must be dead.", s, errno);
        return 1;
    }

    return error != 0;
}


void loom_net_enableSocketKeepalive(loom_socketId_t s)
{
    int       optVal = 1;
    socklen_t optLen = sizeof(optVal);

    if (loom_net_isSocketDead(s))
    {
        lmLogError(netLogGroup, "Trying to set keepalive on dead socket.");
        return;
    }

    //lmLog(netLogGroup, "Setting keepalive with %d %d", optVal, optLen);

    if (setsockopt((int)s, SOL_SOCKET, SO_KEEPALIVE, (char *)&optVal, optLen) < 0)
    {
        // This failure when due to EINVAL (22 on darwin) on a freshly created
        // socket is often because the sockethas been shutdown asynchronously by the OS.
        lmLogError(netLogGroup, "Could not set SO_KEEPALIVE on socket %x due to %d", s, errno);
        return;
    }
}


loom_socketId_t loom_net_listenTCPSocket(unsigned short port)
{
    struct sockaddr_in listenName;
    int                status;

    // Create the socket.
    int listenSocket = socket(AF_INET, SOCK_STREAM, 0);

    lmAssert(listenSocket != -1, "Failed to allocate TCP socket to listen on!");

    // Bind to a port.
    listenName.sin_family      = AF_INET;
    listenName.sin_addr.s_addr = INADDR_ANY;
    listenName.sin_port        = htons(port);

    // Reuse addy. This avoids issues where socket lingers in TIME_WAIT and we cannot
    // reacquire it.
    loom_net_setSocketReuseAddress((loom_socketId_t)listenSocket, 1);

    status = bind(listenSocket, (struct sockaddr *)&listenName, sizeof(listenName));
    if (status == -1)
    {
        lmLogError(netLogGroup, "Could not bind TCP socket due to %d", status);
        return (loom_socketId_t)-1;
    }

    // Start listening.
    status = listen(listenSocket, 5);
    if (status == -1)
    {
        lmLogError(netLogGroup, "Could not listen on TCP socket due to %d", status);
        return (loom_socketId_t)-1;
    }

    // And set it nonblocking so we can poll accept.
    loom_net_setSocketBlocking((loom_socketId_t)listenSocket, 0);


    return (loom_socketId_t)listenSocket;
}


loom_socketId_t loom_net_acceptTCPSocket(loom_socketId_t listenSocket)
{
    struct sockaddr_in peer_name; // TODO: Expose this to caller.
    int                addrLen        = sizeof(peer_name);
    SOCKET             acceptedSocket = accept((SOCKET)listenSocket, (struct sockaddr *)&peer_name, &addrLen);

    return (loom_socketId_t)acceptedSocket;
}


void loom_net_readTCPSocket(loom_socketId_t s, void *buffer, int *bytesToRead, int peek /*= 0*/)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    int winsockErrorCode;
#endif
    int waiting;

    int tmp = *bytesToRead;

    if (loom_net_isSocketDead(s))
    {
        *bytesToRead = 0;
        return;
    }

    if (peek) {
        *bytesToRead = recv((SOCKET)s, buffer, tmp, MSG_PEEK);
        return;
    }

    int bytesLeft = *bytesToRead;

    while (bytesLeft > 0)
    {
        int received = recv((SOCKET)s, buffer, bytesLeft, 0);
        if (received == -1) {
            waiting = 0;
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
            winsockErrorCode = WSAGetLastError();
            if (winsockErrorCode == WSAEWOULDBLOCK)
            {
                waiting = 1;
            }
#else
            if (errno == EAGAIN)
            {
                waiting = 1;
            }
#endif
            if (waiting)
            {
                lmLogWarn(netLogGroup, "Waiting for receive buffer %d / %d", *bytesToRead - bytesLeft, *bytesToRead);
                loom_thread_sleep(5);
                continue;
            }
            else
            {
                lmLogError(netLogGroup, "Read socket error");
                *bytesToRead = -1;
                return;
            }
        }
        bytesLeft -= received;
    }

    lmAssert(bytesLeft == 0, "Internal recv error, read too much data? %d", bytesLeft);
}


int loom_net_writeTCPSocket(loom_socketId_t s, void *buffer, int bytesToWrite)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    int winsockErrorCode;
#endif

    int bytesLeft = bytesToWrite;
    for ( ; ; )
    {
        int result = send((SOCKET)s, buffer, bytesLeft, MSG_NOSIGNAL);

        if (result >= 0)
        {
            bytesLeft -= result;
            if (bytesLeft != 0)
            {
                lmLogInfo(netLogGroup, "Partial write on socket %d, expected %d but wrote %d! Retrying...", s, bytesToWrite, result);

                // Set up to try again by advancing into the buffer.
                buffer = (void *)((char *)buffer + result);
                continue;
            }

            return bytesToWrite - bytesLeft;
        }

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
        winsockErrorCode = WSAGetLastError();
        if (winsockErrorCode != WSAEWOULDBLOCK)
        {
            break;
        }
#else
        if (errno != EAGAIN)
        {
            break;
        }
#endif

        if (loom_net_isSocketDead(s))
        {
            break;
        }

        //lmLogInfo(netLogGroup, "Write failed, trying again with socket %d buffer %x", s, buffer);
        //fprintf(stderr, "Write failed, trying again with socket %d buffer %x", s, buffer);
        loom_thread_sleep(5);
    }

    return -1;
}


void loom_net_closeTCPSocket(loom_socketId_t s)
{
    closesocket((SOCKET)s);
}
