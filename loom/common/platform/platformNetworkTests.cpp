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

#include "seatest.h"
#include "loom/common/platform/platformNetwork.h"
#include "loom/common/platform/platformThread.h"

SEATEST_FIXTURE(platformNetwork)
{
    SEATEST_FIXTURE_ENTRY(platformNetwork_googlePing);
    SEATEST_FIXTURE_ENTRY(platformNetwork_socketListen);
}

SEATEST_TEST(platformNetwork_googlePing)
{
    loom_net_initialize();

    loom_socketId_t s = loom_net_openTCPSocket("google.si", 80, 1);

    char request[] = "GET / HTTP/1.0\r\n\r\n";

    loom_net_writeTCPSocket(s, request, sizeof(request));

    // Give it a chance to reply, a little weak, but there you go.
    loom_thread_sleep(100);

    char response[4096];
    int  responseRead = 100; // Just read the first 100 bytes, enough to make sure we're getting something

    loom_net_readTCPSocket(s, response, &responseRead, 0);

    loom_net_closeTCPSocket(s);

    // Expect some bytes back from GOOG.
    assert_true(responseRead >= 100);

    loom_net_shutdown();
}

SEATEST_TEST(platformNetwork_socketListen)
{
    loom_net_initialize();

    // No one better be using this port.
    loom_socketId_t serverSocket = loom_net_listenTCPSocket(12340);

    // Start connecting.
    loom_socketId_t connectSocket = loom_net_openTCPSocket("localhost", 12340, 1);

    // Accept the connection.
    loom_socketId_t acceptedSocket = NULL;
    int             maxWait        = 100;
    while (!acceptedSocket && maxWait-- > 0)
    {
        acceptedSocket = loom_net_acceptTCPSocket(serverSocket);
        loom_thread_sleep(5);
    }


    // Make sure we successfully got a socket.
    assert_true(maxWait > 0);
    assert_true(acceptedSocket != NULL);

    // Guess we got a connection? Close some sockets.
    loom_net_closeTCPSocket(serverSocket);
    loom_net_closeTCPSocket(connectSocket);
    loom_net_closeTCPSocket(acceptedSocket);

    loom_net_shutdown();
}
