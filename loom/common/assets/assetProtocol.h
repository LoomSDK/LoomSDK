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


#ifndef _ASSETS_ASSETPROTOCOL_H_
#define _ASSETS_ASSETPROTOCOL_H_

#include "loom/common/platform/platformNetwork.h"
#include "loom/common/utils/utString.h"

// Helper class to handle reading/writing asset protocol data.
class NetworkBuffer
{
protected:

    int curByte;

public:

    void *buffer;
    int  length;

    void setBuffer(void *_buffer, int _length);

    void reset();

    int readInt();
    void writeInt(int _value);

    double readDouble();
    void writeDouble(double _value);

    // This is binary safe, and we use it to read write blobs.
    bool readString(char **outString, int *outLength);
    void writeString(const char *bits, int stringLength);

    // Checkpoints are known values that we put in the data stream to confirm
    // we are reading/writing stuff in the right order and matching on both
    // ends.
    void writeCheckpoint(int _value);
    void readCheckpoint(int _value);

    int getCurrentPosition()
    {
        return curByte;
    }
};

class AssetProtocolHandler;

// Subclass this to register to handle new message types in the asset protocol.
class AssetProtocolMessageListener
{
public:

    AssetProtocolMessageListener()
    {
        next = NULL;
    }

    virtual bool handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& buffer) = 0;

    // Cheesy linked list for keeping track of listeners.
    AssetProtocolMessageListener *next;
};

// This class wraps a connection to or from the asset agent.
class AssetProtocolHandler
{
public:

    NetworkBuffer buffer;
    int           bytesLength;
    unsigned char *bytes;

    loom_socketId_t socket;

    bool readFrame();

    AssetProtocolMessageListener *listenerHead;

    static int uniqueId;
    int        _id;

public:

    AssetProtocolHandler(loom_socketId_t _socket);
    ~AssetProtocolHandler();

    const int getId() const
    {
        return _id;
    }

    // Look for network frames to process.
    void process();

    // Get a string describing this connection.
    utString description();

    // Register a listener.
    void registerListener(AssetProtocolMessageListener *listener);

    // Elemental messages which we can send.
    void sendPing();
    void sendPong();
    void sendFile(const char *filename, void *fileBits, int fileBitsLength, int pendingFiles);
    void sendLog(const char *log);
    void sendCommand(const char *cmd);
    void sendCustom(void* buffer, int length);
};
#endif
