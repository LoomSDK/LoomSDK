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

#ifndef _PLATFORM_PLATFORMNETWORK_H_
#define _PLATFORM_PLATFORMNETWORK_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void * loom_socketId_t;

int loom_net_initialize();
void loom_net_shutdown();

loom_socketId_t loom_net_openTCPSocket(const char *host, unsigned short port, int blocking);

loom_socketId_t loom_net_listenTCPSocket(unsigned short port);
loom_socketId_t loom_net_acceptTCPSocket(loom_socketId_t listenSocket);

void loom_net_enableSocketKeepalive(loom_socketId_t s);

void loom_net_readTCPSocket(loom_socketId_t s, void *buffer, int *bytesToRead, int peek);
int loom_net_writeTCPSocket(loom_socketId_t s, void *buffer, int bytesToWrite);
void loom_net_pump();

void loom_net_getSocketPeerName(loom_socketId_t s, int *hostIp, int *hostPort);
int loom_net_isSocketWritable(loom_socketId_t s);
int loom_net_isSocketDead(loom_socketId_t s);

void loom_net_closeTCPSocket(loom_socketId_t s);

#ifdef __cplusplus
};
#endif
#endif
