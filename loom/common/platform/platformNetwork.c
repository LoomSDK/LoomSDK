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
#include "loom/common/platform/platformTime.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"

#include "loom/common/utils/bipbuffer.h"
#include "loom/common/utils/uthash.h"

#include <stdio.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#define _WINSOCK_DEPRECATED_NO_WARNINGS
#include <WinSock2.h>
#include <WS2tcpip.h>
#include <WS2def.h>
#include <errno.h>
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#include <fcntl.h>
#include <sys/socket.h>
#include <netdb.h>
#include <errno.h>
#include <sys/select.h>
#include <unistd.h>
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


lmDefineLogGroup(netLogGroup, "net", 1, LoomLogWarn);

// Defines how many milliseconds to sleep for if the non-blocking read failed.
static const int readSpinSleepMs = 5;

// Defines how many approx. milliseconds to wait for on a
// stalled (no reads made) socket before timing out.
static const int readSpinTimeoutMs = 6000;

// The maximum number of bytes to send with one syscall at a time.
static const int writeChunkMaxSize = 16384;

// Power of two to round up to when growing the write buffer, e.g. 12 = 4KiB
static const int writeResizePagePower = 12;

// How many times does the total size of the buffer have to exceed the 
// used size for the write to be considered a "small write".
static const int writeShrinkThreshold = 3;

// Defines the number of consecutive small writes triggering buffer shrinkage.
static const int writeSmallCountThreshold = 200;

// How many times the used size the buffer resizes to while shrinking.
static const int writeShrinkTarget = 2;

// Structure keeping socket buffers and metadata
struct SocketData {
    // Handle to the socket itself
    loom_socketId_t id;

    // Write bip-buffer (modified circular buffer)
    bipbuf_t* writeBuffer;

    // The number of small writes made in a row.
    // Used for identifying buffer shrink points.
    int smallWrites;

    // The number of failed writes made in a row.
    // Used to detect stalled writing / unresponsive remote endpoint.
    int stallWrites;

    // 1 if write stall is detected, 0 otherwise
    int stalled;

    // Activity timer used in stall detection
    loom_precision_timer_t activityTimer;

    // The number of bytes sent, used for debug log reporting
    unsigned int bytesSent;

    // Required structure for the hash to work
    UT_hash_handle hh;
};

// Head of the socket id -> SocketData hash table
static struct SocketData* socketHashTable = NULL;

static MutexHandle writeMutex;

// Timer used for debug log reporting
static loom_precision_timer_t pumpTimer = NULL;

int loom_net_initialize()
{
    // Platform-specific declarations
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    WSADATA wsaData;
    WORD    wVersionRequested;
    int     err;
#endif
    
    // Cross-platform init
    writeMutex = loom_mutex_create();
    if (!pumpTimer) pumpTimer = loom_startTimer();

    // Platform-specific init
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    wVersionRequested = MAKEWORD(2, 0);
    err = WSAStartup(wVersionRequested, &wsaData);
    if (err != 0)
    {
        lmLogError(netLogGroup, "Failed WinSock initalization with error %d", err);
        return 0;
    }

    if (((LOBYTE(wsaData.wVersion) != 2) || (HIBYTE(wsaData.wVersion) != 0)) &&
        ((LOBYTE(wsaData.wVersion) != 1) || (HIBYTE(wsaData.wVersion) != 1)))
    {
        lmLogError(netLogGroup, "Failed WinSock initalization due to version mismatch");
        WSACleanup();
        return 0;
    }

    // Sanity checks.
    lmAssert(sizeof(SOCKET) <= sizeof(loom_socketId_t), "Can't pack a SOCKET into loom_socketId_t");

    lmLogDebug(netLogGroup, "Initialized WinSock");
#else
    // Ignore sigpipe.
    lmLogDebug(netLogGroup, "Disabling signal SIGPIPE");
    signal(SIGPIPE, SIG_IGN);
#endif

    return 1;
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
    int flags = fcntl((int)(size_t)s, F_GETFL);

    if (blocking == 1)
    {
        flags &= ~O_NONBLOCK;
    }
    else
    {
        flags |= O_NONBLOCK;
    }

    fcntl((int)(size_t)s, F_SETFL, flags);
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
    lmLogDebug(netLogGroup, "Note: this platform doesn't support reusing port, but it probably doesn't matter.");
#endif
}


loom_socketId_t loom_net_openTCPSocket(const char *host, unsigned short port, int blocking)
{
    SOCKET s;
    int     status, res;
    struct addrinfo hints;
    struct addrinfo *hostInfo;
    char portString[16];

    //set up he hints
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    //copy the port over to a string
    sprintf(portString, "%d", port);

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
    loom_net_setSocketBlocking((loom_socketId_t)(size_t)s, blocking);

    // Disable SIGPIPE, we handle that in another way.
#ifdef SO_NOSIGPIPE
    int set = 1;
    setsockopt(s, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
#endif

    // Do the connect.
    status = connect(s, hostInfo->ai_addr, (int)hostInfo->ai_addrlen);
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
    return (loom_socketId_t)(size_t)s;
}


void loom_net_getSocketPeerName(loom_socketId_t s, int *hostIp, int *hostPort)
{
    struct sockaddr_in name;
    socklen_t          nameLen = sizeof(name);

    getpeername((int)(size_t)s, (struct sockaddr *)&name, &nameLen);

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
    FD_SET((int)(size_t)s, &waitSockets);

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
    struct SocketData* sd;

    retval = getsockopt((int)(size_t)s, SOL_SOCKET, SO_ERROR, (char *)&error, &len);
    if (retval == -1)
    {
        lmLogError(netLogGroup, "Could not read error on socket %x due to %d, must be dead.", s, errno);
        return 1;
    }
    
    // Report as dead if writing is stalled
    HASH_FIND(hh, socketHashTable, &s, sizeof(s), sd);
    if (sd)
    {
        if (sd->stalled) return 1;
    }

    return error != 0;
}


void loom_net_enableSocketKeepalive(loom_socketId_t s)
{
    int       optVal = 1;
    socklen_t optLen = sizeof(optVal);

    if (loom_net_isSocketDead(s))
    {
        lmLogError(netLogGroup, "Tried to set keepalive on dead socket.");
        return;
    }

    //lmLog(netLogGroup, "Setting keepalive with %d %d", optVal, optLen);

    if (setsockopt((int)(size_t)s, SOL_SOCKET, SO_KEEPALIVE, (char *)&optVal, optLen) < 0)
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
    SOCKET listenSocket = socket(AF_INET, SOCK_STREAM, 0);

    lmAssert(listenSocket != -1, "Failed to allocate TCP socket to listen on!");

    // Bind to a port.
    listenName.sin_family      = AF_INET;
    listenName.sin_addr.s_addr = INADDR_ANY;
    listenName.sin_port        = htons(port);

    // Reuse addy. This avoids issues where socket lingers in TIME_WAIT and we cannot
    // reacquire it.
    loom_net_setSocketReuseAddress((loom_socketId_t)(size_t)listenSocket, 1);

    status = bind(listenSocket, (struct sockaddr *)&listenName, sizeof(listenName));
    if (status == -1)
    {
        lmLogError(netLogGroup, "Could not bind TCP socket");
        return (loom_socketId_t)-1;
    }

    // Start listening.
    status = listen(listenSocket, 5);
    if (status == -1)
    {
        lmLogError(netLogGroup, "Could not listen on TCP socket");
        return (loom_socketId_t)(size_t)-1;
    }

    // And set it nonblocking so we can poll accept.
    loom_net_setSocketBlocking((loom_socketId_t)(size_t)listenSocket, 0);


    return (loom_socketId_t)(size_t)listenSocket;
}


loom_socketId_t loom_net_acceptTCPSocket(loom_socketId_t listenSocket)
{
    struct sockaddr_in peer_name; // TODO: Expose this to caller.
    int                addrLen        = sizeof(peer_name);
    SOCKET             acceptedSocket = accept((SOCKET)(size_t)listenSocket, (struct sockaddr *)&peer_name, &addrLen);

    return (loom_socketId_t)(size_t)acceptedSocket;
}


void loom_net_readTCPSocket(loom_socketId_t s, void *buffer, int *bytesToRead, int peek /*= 0*/)
{
    int errorCode;

    // Used to track reading timeouts
    int waitingNum = 0;

    int tmp = *bytesToRead;

    int bytesLeft;

    if (loom_net_isSocketDead(s))
    {
        *bytesToRead = 0;
        return;
    }

    if (peek) {
        *bytesToRead = recv((SOCKET)(size_t)s, buffer, tmp, MSG_PEEK);
        return;
    }

    bytesLeft = *bytesToRead;

    while (bytesLeft > 0)
    {
        int received = recv((SOCKET)(size_t)s, buffer, bytesLeft, 0);
        int waiting = 0;

        if (received > 0)
        {
            waitingNum = 0;
        }
        else if (received == 0)
        {
            waiting = 1;
        }
        else
        {
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
            errorCode = WSAGetLastError();
            if (errorCode == WSAEWOULDBLOCK)
            {
                waiting = 1;
            }
#else
            errorCode = errno;
            if (errorCode == EAGAIN)
            {
                waiting = 1;
            }
#endif
            if (!waiting)
            {
                platform_error("Read socket error (%d)", errorCode);
                *bytesToRead = -1;
                return;
            }
        }

        if (waiting)
        {
            // Uncomment for receive wait logs
            //platform_debugOut("Waiting for receive buffer %d / %d", *bytesToRead - bytesLeft, *bytesToRead);
            waitingNum++;
            if (waitingNum >= readSpinTimeoutMs / readSpinSleepMs)
            {
                platform_error("Read socket timeout, tried every %d ms %d times", readSpinSleepMs, waitingNum);
                *bytesToRead = -1;
                return;
            }
            loom_thread_sleep(readSpinSleepMs);
            continue;
        }

        bytesLeft -= received;
        buffer = (char*)buffer + received;
    }

    lmAssert(bytesLeft == 0, "Internal recv error, read too much data? %d", bytesLeft);
}

// Align the provided size to the next page (page size provided with the page power, e.g. 12 is 4096)
static int alignToNextPage(int n, int pageShift)
{
    return ((n >> pageShift) + 1) << pageShift;
}

// Pump all the buffered messages as much as possible without blocking entirely.
// Call this often to flush out buffers for all the sockets. 
void loom_net_pump()
{
    struct SocketData* sd;
    int print = 0;

    // Uncomment this to show buffer reports
    // if (loom_readTimer(pumpTimer) > 1000) {
    // 	print = 1;
    // 	loom_resetTimer(pumpTimer);
    // }

    loom_mutex_lock(writeMutex);

    // Loop over all the sockets
    for (sd = socketHashTable; sd != NULL; sd = sd->hh.next) {
        int sent;
        bipbuf_t* bipbuf;
        loom_socketId_t *socket;
        if (!sd->writeBuffer) continue;
        
        sent = 0;
        bipbuf = sd->writeBuffer;
        socket = sd->id;

        for (;;)
        {
            int bytesPending, bytesSending, bytesAvailable, result;
            unsigned char* buf;

            // How many bytes we still have to send
            bytesPending = bipbuf_used(bipbuf);
            if (bytesPending <= 0) break;

            // How many bytes we are going to send this time
            bytesSending = bytesPending < writeChunkMaxSize ? bytesPending : writeChunkMaxSize;

            // How many bytes we can actually read at once from the buffer
            // at this time.
            bytesAvailable = bipbuf_available(bipbuf);
            if (bytesAvailable < bytesSending) bytesSending = bytesAvailable;

            // Pointer into the buffer
            buf = bipbuf_peek(bipbuf, bytesSending);
            lmAssert(buf, "Unable to peek into bipbuffer, %d pending, %d sending, %d available", bytesPending, bytesSending, bytesAvailable);

            result = send((SOCKET)(size_t)socket, buf, bytesSending, MSG_NOSIGNAL);

            if (result >= 0)
            {
                lmAssert(bipbuf_poll(bipbuf, result), "Internal error, unable to poll the bipbuffer");
                sent += result;
                // Uncomment to print out every successful write
                //platform_debugOut("Pumped %d bytes", result);
                if (bipbuf_used(bipbuf) > 0)
                {
                    // Uncomment to print out partial writes
                    //platform_debugOut("Partial write %d sent, %d left,   %d sent this call", result, bipbuf_used(bipbuf), sent);
                    continue;
                }
                break;
            }

            // Try another time on failed write
            break;
        }

        sd->bytesSent += sent;

        // Stall check
        if (sent == 0)
        {
            sd->stallWrites++;
            if (sd->stallWrites >= 200)
            {
                if (sd->stallWrites == 200)
                {
                    loom_resetTimer(sd->activityTimer);
                }
                else
                {
                    if (loom_readTimer(sd->activityTimer) > 30000)
                    {
                        sd->stalled = 1;
                    }
                }
            }
            // Uncomment to print out stalled write status
            //platform_debugOut("Stall check: %d writes, %d stalled, %d ms", sd->stallWrites, sd->stalled, loom_readTimer(sd->activityTimer));
        }
        else
        {
            sd->stallWrites = 0;
            sd->stalled = 0;
        }

        // Debug print log output
        if (print) {
            // We don't want to lmLog here as that will usually cause
            // additional network traffic triggering this line again in an
            // endless logging loop of logs.
            platform_debugOut("Socket %x%s write buffer status: %d %s/s, %lld%% full, %d left, %d free, %d total",
                socket, loom_net_isSocketDead(socket) ? " (dead)" : "", sd->bytesSent < 1000 ? sd->bytesSent : sd->bytesSent / 1000,
                sd->bytesSent < 1000 ? "B" : "KB",
                ((unsigned long long)bipbuf_used(bipbuf) * 100L) / (unsigned long long)bipbuf_size(bipbuf),
                bipbuf_used(bipbuf),
                bipbuf_unused(bipbuf),
                bipbuf_size(bipbuf)
            );
            sd->bytesSent = 0;
        }
    }

    loom_mutex_unlock(writeMutex);

}

int loom_net_writeTCPSocket(loom_socketId_t s, void *buffer, int bytesToWrite)
{
    int offered, unused, used, shrinkThreshold;
    struct SocketData* sd;
    bipbuf_t* bipbuf;

    if (bytesToWrite <= 0) return 0;

    loom_mutex_lock(writeMutex);

    HASH_FIND(hh, socketHashTable, &s, sizeof(s), sd);

    // If SocketData doesn't exist yet, create it
    if (sd == NULL) {
        sd = lmAlloc(NULL, sizeof(struct SocketData));
        lmAssert(sd, "Unable to allocate socket data");
        sd->id = (loom_socketId_t)s;
        sd->writeBuffer = NULL;
        sd->smallWrites = 0;
        sd->stallWrites = 0;
        sd->stalled = 0;
        sd->bytesSent = 0;
        sd->activityTimer = loom_startTimer();
        HASH_ADD(hh, socketHashTable, id, sizeof(loom_socketId_t), sd);
    }

    bipbuf = sd->writeBuffer;

    unused = bipbuf ? bipbuf_unused(bipbuf) : 0;
    // Create/resize buffer if it's too small
    if (unused < bytesToWrite)
    {
        const int oldSize = bipbuf ? bipbuf_size(bipbuf) : 0;
        
        // Two growth stategies, pick the biggest one
        int growDouble = oldSize;
        int growByNeeded = bytesToWrite - unused;
        const int totalSize = alignToNextPage(sizeof(bipbuf_t) + oldSize + (growDouble > growByNeeded ? growDouble : growByNeeded), writeResizePagePower);
        const int contentSize = totalSize - sizeof(bipbuf_t);
        if (bipbuf) {
            bipbuf = lmRealloc(NULL, bipbuf, totalSize);
            bipbuf_resize(bipbuf, contentSize);
        }
        else
        {
            bipbuf = lmAlloc(NULL, totalSize);
            bipbuf_init(bipbuf, contentSize);
        }
        // Uncomment to log write buffer growth
        // platform_debugOut("Socket %x write buffer growth, %d unused, %d to write, %d old size, %d new size, %d new unused", socket, unused, bytesToWrite, oldSize, contentSize, bipbuf_unused(bipbuf));

        unused = bipbuf_unused(bipbuf);
        lmAssert(bytesToWrite <= unused, "Internal bipbuffer resize error, %d is still too many bytes, only %d bytes are unused", bytesToWrite, unused);
    }

    offered = bipbuf_offer(bipbuf, buffer, bytesToWrite);
    lmAssert(offered == bytesToWrite, "Internal bipbuffer write error");

    used = bipbuf_used(bipbuf);

    // Shrink when usage is < 33%
    shrinkThreshold = alignToNextPage(sizeof(bipbuf_t) + used * writeShrinkThreshold, writeResizePagePower);

    sd->smallWrites = shrinkThreshold < (int)sizeof(bipbuf_t)+bipbuf_size(bipbuf) ? sd->smallWrites + 1 : 0;
    if (sd->smallWrites > writeSmallCountThreshold)
    {
        const int oldSize = bipbuf_size(bipbuf);
        const int shrinkTarget = alignToNextPage(sizeof(bipbuf_t) + used * writeShrinkTarget, writeResizePagePower);
        bipbuf_resize(bipbuf, shrinkTarget - sizeof(bipbuf_t));
        bipbuf = lmRealloc(NULL, bipbuf, shrinkTarget);
        // Uncomment to log buffer shrinking
        // platform_debugOut("Socket %x write buffer shrink, %d old, %d used, %d required, %d new", socket, oldSize, bipbuf_used(bipbuf), required, bipbuf_size(bipbuf));
        sd->smallWrites = 0;
    }

    sd->writeBuffer = bipbuf;

    loom_net_pump(s);

    loom_mutex_unlock(writeMutex);

    return bytesToWrite;
}


void loom_net_closeTCPSocket(loom_socketId_t s)
{
    struct SocketData* sd;
    loom_mutex_lock(writeMutex);
    // FInd SocketData if it exists and remove it
    HASH_FIND(hh, socketHashTable, &s, sizeof(s), sd);
    if (sd)
    {
        HASH_DEL(socketHashTable, sd);
        loom_destroyTimer(sd->activityTimer);
        lmSafeFree(NULL, sd->writeBuffer);
        lmFree(NULL, sd);
    }
    loom_mutex_unlock(writeMutex);

    closesocket((SOCKET)(size_t)s);
}
