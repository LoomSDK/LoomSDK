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


#include <string.h>
#include "loom/common/assets/assetProtocol.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/utils/fourcc.h"

lmDefineLogGroup(assetProtocolLogGroup, "asset.protocol", 1, LoomLogInfo);

int AssetProtocolHandler::uniqueId = 1000;

void NetworkBuffer::setBuffer(void *_buffer, int _length)
{
    length  = _length;
    buffer  = _buffer;
    curByte = 0;
}


void NetworkBuffer::reset()
{
    curByte = 0;
}


int NetworkBuffer::readInt()
{
    int r = *(int *)((char *)buffer + curByte);

    r = convertLEndianToHost(r);

    curByte += 4;
    return(r);
}


void NetworkBuffer::writeInt(int _value)
{
    _value = convertHostToLEndian(_value);

    *(int *)((char *)buffer + curByte) = (_value);
    curByte += 4;
}


bool NetworkBuffer::readString(char **outString, int *outLength)
{
    int stringLength = readInt();

    char *strBuffer = (char *)lmAlloc(NULL, stringLength + 1);

    memcpy(strBuffer, (char *)((char *)buffer + curByte), stringLength);
    strBuffer[stringLength] = 0;
    curByte += stringLength;

    *outLength = stringLength;
    *outString = strBuffer;
    return true;
}


void NetworkBuffer::writeString(const char *bits, int stringLength)
{
    writeInt(stringLength);
    memcpy((char *)buffer + curByte, bits, stringLength);
    curByte += stringLength;
}


void NetworkBuffer::writeCheckpoint(int _value)
{
    writeInt(_value);
}


void NetworkBuffer::readCheckpoint(int _value)
{
    int readValue = readInt();

    lmAssert(readValue == _value, "Failed net protocol checkpoint, saw %x but expected %x.", readValue, _value);
}


class AssetProtocolPingAndLogMessageListener : public AssetProtocolMessageListener
{
public:
    virtual bool handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& buffer)
    {
        switch (fourcc)
        {
        case LOOM_FOURCC('P', 'O', 'N', 'G'):
            lmLogDebug(assetProtocolLogGroup, "Pong on %x", this);
            return true;

        case LOOM_FOURCC('P', 'I', 'N', 'G'):
            // Send back pong!
            lmLogDebug(assetProtocolLogGroup, "Ping on %x", this);
            handler->sendPong();
            return true;

        case LOOM_FOURCC('L', 'O', 'G', '1'):
            // Read the log string.
            char *logString;
            int  logStringLength;
            buffer.readString(&logString, &logStringLength);

            // Nuke newline off the end.
            if (logString[logStringLength - 1] == '\n')
            {
                logString[logStringLength - 1] = 0;
            }

            // Display it.
            lmLogRun(assetProtocolLogGroup, "%s", logString);
            lmFree(NULL, logString);

            return true;
        }

        return false;
    }
};

AssetProtocolHandler::AssetProtocolHandler(loom_socketId_t _socket)
{
    socket       = _socket;
    bytesLength  = 0;
    bytes        = NULL;
    listenerHead = NULL;

    // Note a unique ID for connection tracking purposes.
    _id = uniqueId++;

    // Default message listener.
    registerListener(lmNew(NULL) AssetProtocolPingAndLogMessageListener());
}


AssetProtocolHandler::~AssetProtocolHandler()
{
    lmSafeFree(NULL, bytes);

    // TODO: Free listeners.
}


utString AssetProtocolHandler::description()
{
    int host[4], port;

    loom_net_getSocketPeerName(socket, host, &port);
    return utStringFormat("[ip=%d.%d.%d.%d:%d]", host[0], host[1], host[2], host[3], port);
}


bool AssetProtocolHandler::readFrame()
{
    // Service the asset server connection.
    unsigned char header[128];
    int           bytesRead = 12;

    loom_net_readTCPSocket(socket, header, &bytesRead, 1);

    buffer.setBuffer(header, bytesRead);

    // See if we have enough of a frame to read the frame length.
    int frameLength = 0;
    if (bytesRead < 4)
    {
        return false;
    }

    frameLength = buffer.readInt();

    buffer.readCheckpoint(0xDEADBEEF);

    // Allocate a buffer to store data.
    bytes = (unsigned char *)lmAlloc(NULL, frameLength);

    // Make sure we can peek that much data.
    bytesLength = frameLength;
    loom_net_readTCPSocket(socket, bytes, &bytesLength, 1);

    if (bytesLength != frameLength)
    {
        lmSafeFree(NULL, bytes);
        return false;
    }

    // Read for real to clear out the socket.
    loom_net_readTCPSocket(socket, bytes, &bytesLength, 0);

    // Great, we have a frame!
    buffer.setBuffer(bytes, bytesLength);
    buffer.readInt(); // Skip past the length and checkpoint.
    buffer.readCheckpoint(0xDEADBEEF);
    return true;
}


void AssetProtocolHandler::process()
{
    // See if we got a frame.
    if (!readFrame())
    {
        return;
    }

    // Awesome, so parse it.
    int fourcc = buffer.readInt();

    // Let everybody have a shot at it.
    AssetProtocolMessageListener *apml = listenerHead;
    bool handled = false;
    while (apml)
    {
        if (!apml->handleMessage(fourcc, this, buffer))
        {
            // Go to next.
            apml = apml->next;
            continue;
        }

        handled = true;
        break;
    }

    if (!handled)
    {
        lmLogError(assetProtocolLogGroup, "Unknown fourcc %x! Skipping ahead %d bytes to next frame.", fourcc, bytesLength);
    }
}


void AssetProtocolHandler::sendPing()
{
    char          tmpBuff[1024];
    NetworkBuffer sendBuffer;

    sendBuffer.setBuffer(tmpBuff, 1024);

    // Construct it - frame + type.
    sendBuffer.writeInt(4 * 3);
    sendBuffer.writeCheckpoint(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('P', 'I', 'N', 'G'));

    // Send it.
    loom_net_writeTCPSocket(socket, tmpBuff, sendBuffer.getCurrentPosition());
}


void AssetProtocolHandler::sendPong()
{
    char          tmpBuff[1024];
    NetworkBuffer sendBuffer;

    sendBuffer.setBuffer(tmpBuff, 1024);

    // Construct it - frame + type.
    sendBuffer.writeInt(4 * 3);
    sendBuffer.writeCheckpoint(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('P', 'O', 'N', 'G'));

    // Send it.
    loom_net_writeTCPSocket(socket, tmpBuff, sendBuffer.getCurrentPosition());
}


void AssetProtocolHandler::sendFile(const char *path, void *fileBits, int fileBitsLength, int pendingFiles)
{
    // Allocate message buffer.
    // Size is:
    //    4 - frame length
    //    4 - message type
    //    4 - pending files
    //    4 - path length
    //    P - path + NULL
    //    4 - content length
    //    C - content of file
    // Size is 20 + P + C


    // Send files in chunks; TCP has maximum send/receive buffer sizes so we
    // need to break it up.

    // First we send a header message.
    //    4 - frame length
    //    4 - message type
    //    4 - pending file count
    //    4 - path length
    //    P - path + NULL
    //    4 - content length
    {
        int pathLength = (int)strlen(path) + 1;

        NetworkBuffer fileBeginBuffer;
        char          headerBuffer[128];
        fileBeginBuffer.setBuffer(headerBuffer, 128);

        int frameLength = 7 * 4 + pathLength;
        fileBeginBuffer.writeInt(frameLength);
        fileBeginBuffer.writeCheckpoint(0xDEADBEEF);
        fileBeginBuffer.writeInt(LOOM_FOURCC('F', 'I', 'L', 'E'));
        fileBeginBuffer.writeInt(pendingFiles);
        fileBeginBuffer.writeString(path, pathLength);
        fileBeginBuffer.writeInt(fileBitsLength);
        fileBeginBuffer.writeCheckpoint(0xDEADBEE3);

        // Send it.
        loom_net_writeTCPSocket(socket, headerBuffer, fileBeginBuffer.getCurrentPosition());
    }

    // Followed by the file content in chunks.
    //    4 - frame length
    //    4 - message type
    //    4 - pending file count
    //    4 - offset
    //    4 - length
    //    N - file bits
    {
        int       bytesToSend  = fileBitsLength;
        int       offset       = 0;
        const int maxChunkSize = 8 * 1024;
        while (bytesToSend)
        {
            int           chunkSize   = bytesToSend > maxChunkSize ? maxChunkSize : bytesToSend;
            int           frameLength = 7 * 4 + chunkSize;
            unsigned char *msgBuffer  = (unsigned char *)lmAlloc(NULL, frameLength);

            NetworkBuffer sendBuffer;
            sendBuffer.setBuffer(msgBuffer, frameLength);

            sendBuffer.writeInt(frameLength);
            sendBuffer.writeCheckpoint(0xDEADBEEF);
            sendBuffer.writeInt(LOOM_FOURCC('F', 'C', 'H', 'K'));
            sendBuffer.writeInt(pendingFiles);
            sendBuffer.writeInt(offset);
            sendBuffer.writeString(((char *)fileBits) + offset, chunkSize);
            sendBuffer.writeCheckpoint(0xDEADBEE2);

            // Send it.
            loom_net_writeTCPSocket(socket, msgBuffer, sendBuffer.getCurrentPosition());

            lmFree(NULL, msgBuffer);

            // Update for next chunk.
            offset      += chunkSize;
            bytesToSend -= chunkSize;
        }
    }
}


void AssetProtocolHandler::sendLog(const char *log)
{
    int len = strlen(log);

    char          msgBuffer[4096];
    NetworkBuffer sendBuffer;

    sendBuffer.setBuffer(msgBuffer, 4096);

    sendBuffer.writeInt(4 * 4 + len);
    sendBuffer.writeCheckpoint(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('L', 'O', 'G', '1'));
    sendBuffer.writeString(log, len);

    // Send it.
    loom_net_writeTCPSocket(socket, msgBuffer, sendBuffer.getCurrentPosition());
}


void AssetProtocolHandler::sendCommand(const char *cmd)
{
    int len = strlen(cmd);

    char          msgBuffer[4096];
    NetworkBuffer sendBuffer;

    sendBuffer.setBuffer(msgBuffer, 4096);

    sendBuffer.writeInt(4 * 4 + len);
    sendBuffer.writeCheckpoint(0xDEADBEEF);
    sendBuffer.writeInt(LOOM_FOURCC('C', 'M', 'D', '1'));
    sendBuffer.writeString(cmd, len);

    // Send it.
    loom_net_writeTCPSocket(socket, msgBuffer, sendBuffer.getCurrentPosition());
}


void AssetProtocolHandler::registerListener(AssetProtocolMessageListener *listener)
{
    listener->next = listenerHead;
    listenerHead   = listener;
}
