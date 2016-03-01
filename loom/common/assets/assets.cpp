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


#include <assert.h>
#include <string.h>

#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/string.h"
#include "loom/common/core/stringTable.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/platform/platformFile.h"
#include "loom/common/platform/platformNetwork.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"
#include "loom/common/utils/utByteArray.h"
#include "loom/common/utils/fourcc.h"
#include "loom/common/utils/humanFormat.h"

#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"
#include "loom/common/assets/assetsSound.h"
#include "loom/common/assets/assetsScript.h"
#include "loom/common/assets/assetProtocol.h"

#include <jansson.h>

#include "loom/common/config/applicationConfig.h"

#include "loom/script/native/lsNativeDelegate.h"

#define ASSET_STREAM_HOST    LoomApplicationConfig::assetAgentHost().c_str()
#define ASSET_STREAM_PORT    LoomApplicationConfig::assetAgentPort()

// This actually lives in lsAsset.cpp, but is useful to call from in the asset manager implementation.
void loom_asset_notifyPendingCountChange();

static const int PROGRESS_INIT_TIME = 200;
static const int PROGRESS_UPDATE_TIME = 500;

extern "C" 
{
  loom_allocator_t *gAssetAllocator = NULL;
}

// Small helper class to track a change callback for an asset.
struct loom_asset_subscription_t
{
    LoomAssetChangeCallback callback;
    void                    *payload;
};

// The actual binary data behind an asset; refcounted to let old copies linger
// until they are unlocked.
struct loom_assetBlob_t
{
   loom_assetBlob_t()
   {
      refCount = 0;
      hash[0] = 0;
      length = 0;
      bits = NULL;
      dtor = NULL;
   }

   ~loom_assetBlob_t()
   {
      if(bits)
      {
         lmFree(gAssetAllocator, bits);
         bits = NULL;
      }
   }

   void incRef()
   {
      refCount++;
   }

   bool decRef()
   {
      refCount--;
      
      if(refCount == 0)
      {
         if(dtor)
            dtor(bits);
         else
            lmFree(gAssetAllocator, bits);

         refCount = 0xBAADF00D;
         length = -1;
         bits = NULL;
         
         lmDelete(gAssetAllocator, this);
         return true;
      }
      return false;
   }

   int refCount;
   char hash[40]; // sha1 of the specific data we loaded.
   size_t length;
   void *bits;
   LoomAssetCleanupCallback dtor;
};

// An individual asset; tracks all the state related to an asset, if it's loaded
// or not, the actual bits behind it, type, and so on.
struct loom_asset_t
{
   loom_asset_t()
   {
      state = Unloaded;
      type = 0;
      blob = NULL;
      isSupplied = 0;
   }

   enum {
      Unloaded,
      QueuedForDownload,
      Downloading,
      WaitingForDependencies,
      QueuedForDeserialize,
      Deserializing,
      Loaded,
      QueuedForUnload,
      Failed,
   } state;

   // Not currently used; but allows an asset to wait until all its dependencies
   // are deserialized.
   utArray<loom_asset_t*> dependencies;

   // All the callbacks to call when an asset changes state (is loaded, unloaded, 
   // etc.)
   utArray<loom_asset_subscription_t> subscribers;

   // Actual bits for the asset. Note this is refcounted so be careful how you
   // mess with it.
   loom_assetBlob_t *blob;

   // The path/name of the asset.
   utString name;

   // The type of the asset as inferred.
   unsigned int type;

   // Set if this asset was supplied; we assume it means that it can't be
   // flushed as there is no backing copy on disk/elsewhere.
   unsigned int isSupplied;

   // Instate new bits/type to the asset.
   void instate(int _type, void *bits, LoomAssetCleanupCallback dtor)
   {
      // Swap in a new blob.
      if(blob)
         blob->decRef();
      blob = lmNew(gAssetAllocator) loom_assetBlob_t();
      blob->incRef();

      blob->bits = bits;
      blob->dtor = dtor;

      // Update the type.
      type = _type;

      // We're by definition loaded at this point.
      state = loom_asset_t::Loaded;

      // Fire subscribers.
      loom_asset_notifySubscribers(name.c_str());
   }
};

lmDefineLogGroup(gAssetLogGroup, "asset", 1, LoomLogInfo);

// General asset manager state.
static MutexHandle gAssetLock = NULL;
static utHashTable<utHashedString, loom_asset_t *> gAssetHash;
static utArray<loom_asset_t *> gAssetLoadQueue;
static utHashTable<utIntHashKey, LoomAssetDeserializeCallback> gAssetDeserializerMap;
static utArray<LoomAssetRecognizerCallback> gRecognizerList;
static LoomAssetCommandCallback             gCommandCallback = NULL;
static int gShuttingDown = 0;

// Asset server connection state.
static MutexHandle          gAssetServerSocketLock    = NULL;
static AssetProtocolHandler *gAssetProtocolHandler    = NULL;
static int             gAssetServerConnectTryInterval = 3000;
static int             gAssetServerPingInterval       = 1000;
static int             gAssetServerLastPingTime       = 0;
static loom_socketId_t gAssetServerSocket             = NULL;
static int             gAssetConnectionOpen           = 0;
static int             gPendingFiles = 0;

// App time starts at zero, so we need to start this negative to try right away.
static int gAssetServerLastConnectTryTime = -gAssetServerConnectTryInterval;

static int loom_asset_isOnTrackToLoad(loom_asset_t *asset)
{
    return (asset->state > loom_asset_t::Unloaded && asset->state < loom_asset_t::QueuedForUnload) ? 1 : 0;
}


static loom_asset_t *loom_asset_getAssetByName(const char *name, int create)
{
    loom_mutex_lock(gAssetLock);
    static char normalized[4096];
    strncpy(normalized, name, sizeof(normalized));
    platform_normalizePath(normalized);
    utHashedString key        = normalized;
    loom_mutex_unlock(gAssetLock);
    loom_asset_t   **assetPtr = gAssetHash.get(key);
    loom_asset_t   *asset     = assetPtr ? *assetPtr : NULL;

    if ((asset == NULL) && create)
    {
        // Create one.
        asset       = lmNew(gAssetAllocator) loom_asset_t;
        asset->name = name;
        gAssetHash.insert(key, asset);
    }

    return asset;
}


// Recognize text file types by their extension.
static int loom_asset_textRecognizer(const char *extension)
{
    if (!stricmp(extension, "txt"))
    {
        return LATText;
    }
    if (!stricmp(extension, "lml"))
    {
        return LATText;
    }
    if (!stricmp(extension, "css"))
    {
        return LATText;
    }
    if (!stricmp(extension, "xml"))
    {
        return LATText;
    }
    if (!stricmp(extension, "plist"))
    {
        return LATText;
    }
    if (!stricmp(extension, "fnt"))
    {
        return LATText;
    }
    if (!stricmp(extension, "tmx"))
    {
        return LATText;
    }
    if (!stricmp(extension, "vert"))
    {
        return LATText;
    }
    if (!stricmp(extension, "vsh"))
    {
        return LATText;
    }
    if (!stricmp(extension, "frag"))
    {
        return LATText;
    }
    if (!stricmp(extension, "fsh"))
    {
        return LATText;
    }
    if (!stricmp(extension, "ls"))
    {
        return LATText;
    }
    return 0;
}


// "Text" file types are just loaded directly as binary safe strings.
void *loom_asset_textDeserializer(void *ptr, size_t size, LoomAssetCleanupCallback *dtor)
{
    // Blast the bits into the asset.
    void *data = lmAlloc(gAssetAllocator, size + 1);

    memcpy(data, ptr, size);

    // Null terminate so we don't overrun strings.
    *(((unsigned char *)data) + size) = 0;

    return data;
}


// Recognize binary file types by their extension.
static int loom_asset_binaryRecognizer(const char *extension)
{
    if (!stricmp(extension, "zip"))
    {
        return LATBinary;
    }
    return 0;
}

static void loom_asset_binaryDtor(void *bytes)
{
    lmDelete(NULL, (utByteArray*)bytes);
}

static void *loom_asset_binaryDeserializer(void *ptr, size_t size, LoomAssetCleanupCallback *dtor)
{
    utByteArray *bytes = lmNew(NULL) utByteArray();
    bytes->allocateAndCopy(ptr, (int)size);
    *dtor = loom_asset_binaryDtor;
    return bytes;
}


int loom_asset_isConnected()
{
    return gAssetConnectionOpen;
}


// Helper function to route Loom log output over the network.
void loom_asset_logListener(void *payload, loom_logGroup_t *group, loom_logLevel_t level, const char *msg)
{
    loom_mutex_lock(gAssetServerSocketLock);

    if (gAssetProtocolHandler)
    {
        gAssetProtocolHandler->sendLog(msg);
    }

    loom_mutex_unlock(gAssetServerSocketLock);
}

// Helper function to route Loom custom output over the network.
void loom_asset_custom(void* buffer, int length)
{
    loom_mutex_lock(gAssetServerSocketLock);

    if (gAssetProtocolHandler)
    {
        gAssetProtocolHandler->sendCustom(buffer, length);
    }

    loom_mutex_unlock(gAssetServerSocketLock);
}

int loom_asset_queryPendingTransfers()
{
    return gPendingFiles;
}


void loom_asset_initialize(const char *rootUri)
{
    // Set up the lock for the mutex.
    lmAssert(gAssetLock == NULL, "Double initialization!");
    gAssetLock = loom_mutex_create();

    // Note the CWD.
    char tmpBuff[1024];
    platform_getCurrentWorkingDir(tmpBuff, 1024);
    lmLogDebug(gAssetLogGroup, "Current working directory ='%s'", tmpBuff);

    // And the allocator.
    //gAssetAllocator = loom_allocator_initializeTrackerProxyAllocator(loom_allocator_getGlobalHeap());
    gAssetAllocator = (loom_allocator_getGlobalHeap());

    // Clear, it might have been filled up before (for unit tests)
    gAssetLoadQueue.clear();
    gAssetHash.clear();

    // Asset server connection state.
    gAssetServerSocketLock = loom_mutex_create();

    // And set up some default asset types.
    loom_asset_registerType(LATText, loom_asset_textDeserializer, loom_asset_textRecognizer);
    loom_asset_registerType(LATBinary, loom_asset_binaryDeserializer, loom_asset_binaryRecognizer);

    loom_asset_registerImageAsset();
    loom_asset_registerSoundAsset();
    loom_asset_registerScriptAsset();

    // Listen to log and send it if we have a connection.
    loom_log_addListener(loom_asset_logListener, NULL);
}


void loom_asset_waitForConnection(int msToWait)
{
    // be extra agressive before starting up
    gAssetServerConnectTryInterval = 10;

    int startTime = platform_getMilliseconds();
    while (!gAssetConnectionOpen && (platform_getMilliseconds() - startTime) < msToWait)
    {
        loom_asset_pump();
        loom_thread_sleep(10);
    }

    // Go back to pinging every 3 seconds
    gAssetServerConnectTryInterval = 3000;
}

// Clears the asset name cache that is built up
// through loom_asset_lock and others
static void loom_asset_clear()
{
    utHashTableIterator<utHashTable<utHashedString, loom_asset_t *> > assetIterator(gAssetHash);
    while (assetIterator.hasMoreElements())
    {
        utHashedString key = assetIterator.peekNextKey();
        lmDelete(NULL, assetIterator.peekNextValue());
        assetIterator.next();
    }
    gAssetHash.clear();
}

void loom_asset_shutdown()
{
    gShuttingDown = 1;

    loom_asset_flushAll();
    loom_asset_clear();

    // Clear out our queues and maps.
    gAssetDeserializerMap.clear();
    gRecognizerList.clear();

    lmAssert(gAssetLock != NULL, "Shutdown without being initialized!");
    loom_mutex_destroy(gAssetLock);
    gAssetLock = NULL;
}


// Helper to recognize an asset's type from its path/name.
static int loom_asset_recognizeAssetTypeFromPath(utString& path)
{
    // Easy out - empty strings are no good!
    if (path.length() == 0)
    {
        return 0;
    }

    // Walk backwards to first dot.
    size_t firstDotPos = path.size() - 1;
    for (size_t pos = path.size() - 1; pos > 0; pos--)
    {
        if (path.at(pos) != '.')
        {
            continue;
        }

        firstDotPos = pos;
        break;
    }

    // Split out the extension.
    utString pathExt = path.substr(firstDotPos + 1);

    // See if we can get a type out of any of the recognizers.
    int type = 0;
    for (UTsize i = 0; i < gRecognizerList.size(); i++)
    {
        type = gRecognizerList[i](pathExt.c_str());
        if (type)
        {
            break;
        }
    }

    // No match, so let's use text.
    if (type == 0)
    {
        lmLogInfo(gAssetLogGroup, "Couldn't recognize '%s', defaulting to LATText...", path.c_str());
        type = LATText;
    }

    return type;
}


// Helper to deserialize an asset, routing to the right function by type.
static void *loom_asset_deserializeAsset(const utString &path, int type, int size, void *ptr, LoomAssetCleanupCallback *dtor)
{
    lmAssert(gAssetDeserializerMap.find(type) != UT_NPOS, "Can't deserialize asset, no deserializer was set for type %x!", type);
    LoomAssetDeserializeCallback ladc = *gAssetDeserializerMap.get(type);

    if (ladc == NULL)
    {
        lmLogError(gAssetLogGroup, "Failed deserialize asset '%s', deserializer was not found for type '%x'!", path.c_str(), type);
        return NULL;
    }

   void *assetBits = ladc(ptr, size, dtor);

    if (assetBits == NULL)
    {
        lmLogError(gAssetLogGroup, "Failed to deserialize asset '%s', deserializer returned NULL for type '%x'!", path.c_str(), type);
        return NULL;
    }

    return assetBits;
}


// Listener to allow the message protocol to receive and dispatch comands to
// script (or whatever callback you want).
class AssetProtocolCommandListener : public AssetProtocolMessageListener
{
public:
    virtual bool handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& buffer)
    {
        switch (fourcc)
        {
        case LOOM_FOURCC('C', 'M', 'D', '1'):

            // Read the command.
            char *cmdString;
            int  cmdStringLength;
            buffer.readString(&cmdString, &cmdStringLength);

            // Dispatch to script.
            if (gCommandCallback)
            {
                gCommandCallback(cmdString);
            }

            return true;

            break;
        }

        return false;
    }
};

void loom_asset_setCommandCallback(LoomAssetCommandCallback callback)
{
    gCommandCallback = callback;
}


// Helper to allow us to receive files from the asset agent.
class AssetProtocolFileMessageListener : public AssetProtocolMessageListener
{
protected:

    utString   pendingFilePath;
    loom_precision_timer_t pendingFileTimer;
    bool       pendingFileInit;
    int        pendingFileLength;
    const char *pendingFile;

public:

    AssetProtocolFileMessageListener()
        : pendingFile(NULL)
    {
        pendingFileTimer = loom_startTimer();
        wipePendingData();
    }

    ~AssetProtocolFileMessageListener()
    {
        loom_destroyTimer(pendingFileTimer);
    }

    void wipePendingData()
    {
        if (pendingFile)
        {
            lmFree(gAssetAllocator, (void *)pendingFile);
            pendingFile = NULL;
        }

        pendingFileLength = -1;
        pendingFilePath   = "";
    }

    virtual bool handleMessage(int fourcc, AssetProtocolHandler *handler, NetworkBuffer& buffer)
    {
        switch (fourcc)
        {
        case LOOM_FOURCC('F', 'I', 'L', 'E'):
           {
               // How many pending files?
               gPendingFiles = buffer.readInt();
               loom_asset_notifyPendingCountChange();

               // Read the filename.
               char *path;
               int  fileStringLength;
               buffer.readString(&path, &fileStringLength);

               // And the file length.
               int bitsLength = buffer.readInt();

               // Checkpoint at end!
               buffer.readCheckpoint(0xDEADBEE3);

               // Prepare the buffer!
               if (pendingFile != NULL)
               {
                   lmLogError(gAssetLogGroup, "Got a new file '%s' while still processing existing file '%s'!", path, pendingFilePath.c_str());
                   wipePendingData();
               }

               // Update the pending file state.
               pendingFilePath = path;
               lmFree(NULL, path);
               path = NULL;

               loom_resetTimer(pendingFileTimer);
               pendingFileInit = true;
               pendingFileLength = bitsLength;
               pendingFile       = (const char *)lmAlloc(gAssetAllocator, pendingFileLength);

               // Log it.
               
               // Awesome, sit back and wait for chunks to come in.
               return true;
           }

        case LOOM_FOURCC('F', 'C', 'H', 'K'):
           {
               // How many pending files?
               gPendingFiles = buffer.readInt();
               loom_asset_notifyPendingCountChange();

               // Get the offset.
               int chunkOffset = buffer.readInt();

               // Read bits into the buffer.
               char *fileBits;
               int  fileBitsLength;
               buffer.readString(&fileBits, &fileBitsLength);
               memcpy((void *)(pendingFile + chunkOffset), (void *)fileBits, fileBitsLength);
               lmFree(NULL, fileBits);

               // Checkpoint at end!
               buffer.readCheckpoint(0xDEADBEE2);

               int lastByteOffset = chunkOffset + fileBitsLength;

               // Log it.
               int elapsed = loom_readTimer(pendingFileTimer);
               if (pendingFileInit && elapsed > PROGRESS_INIT_TIME ||
                   !pendingFileInit && elapsed > PROGRESS_UPDATE_TIME)
               {
                   loom_resetTimer(pendingFileTimer);
                   int progress = lastByteOffset * 100 / pendingFileLength;
                   if (pendingFileInit) lmLogInfo(gAssetLogGroup, "Updating '%s', %s", pendingFilePath.c_str(), humanFileSize(pendingFileLength).c_str());
                   lmLogInfo(gAssetLogGroup, "  %d%%", progress);
                   pendingFileInit = false;
               }

               // If it's the last one, instate it and wipe our buffer.
               if (lastByteOffset == pendingFileLength)
               {
                   // And this resolves a file so decrement the pending count. This way
                   // we will get to zero.
                   gPendingFiles--;
                   loom_asset_notifyPendingCountChange();

                   // Instate the new asset data.
                   loom_asset_t *asset    = loom_asset_getAssetByName(pendingFilePath.c_str(), 1);
                   int          assetType = loom_asset_recognizeAssetTypeFromPath(pendingFilePath);
                   if (assetType == 0)
                   {
                       lmLogDebug(gAssetLogGroup, "Couldn't infer file type for '%s', ignoring.", pendingFilePath.c_str());
                       wipePendingData();
                       return true;
                   }

                   lmLogInfo(gAssetLogGroup, "Updated '%s', %s", pendingFilePath.c_str(), humanFileSize(pendingFileLength).c_str());
                   LoomAssetCleanupCallback dtor = NULL;
                   void *assetBits = loom_asset_deserializeAsset(pendingFilePath.c_str(), assetType, pendingFileLength, (void *)pendingFile, &dtor);
                   asset->instate(assetType, assetBits, dtor);

                   // And wipe the pending date.
                   wipePendingData();
               }
         }

         return true;
      }

    return false;
    }
};

// Service our connection to the asset agent.
static void loom_asset_serviceServer()
{
    loom_mutex_lock(gAssetServerSocketLock);

    // Try to connect to the asset server if we aren't already, and it is set.
    if ((gAssetServerSocket == NULL) &&
        ((ASSET_STREAM_HOST != NULL) && (strlen(ASSET_STREAM_HOST) > 0)) &&
        ((platform_getMilliseconds() - gAssetServerLastConnectTryTime) > gAssetServerConnectTryInterval))
    {
        lmLogDebug(gAssetLogGroup, "Attempting to stream assets from %s:%d", ASSET_STREAM_HOST, ASSET_STREAM_PORT);
        gAssetServerLastConnectTryTime = platform_getMilliseconds();
        gAssetServerSocket             = loom_net_openTCPSocket(ASSET_STREAM_HOST, ASSET_STREAM_PORT, 0);
        gAssetConnectionOpen           = false;
        loom_asset_notifyPendingCountChange();

        loom_mutex_unlock(gAssetServerSocketLock);
        return;
    }

    if ((gAssetServerSocket != NULL) && (gAssetConnectionOpen == false))
    {
        // We are waiting on the connection, see if it's writable... If not, return.
        if (loom_net_isSocketWritable(gAssetServerSocket) == 0)
        {
            loom_mutex_unlock(gAssetServerSocketLock);
            return;
        }

        if (loom_net_isSocketDead(gAssetServerSocket) == 1)
        {
            // Might be DOA, ie, connect failed.
            lmLogWarn(gAssetLogGroup, "Failed to connect to asset server %s:%d", ASSET_STREAM_HOST, ASSET_STREAM_PORT);

            loom_net_closeTCPSocket(gAssetServerSocket);

            gAssetServerSocket = NULL;
            lmSafeDelete(NULL, gAssetProtocolHandler);
            gAssetConnectionOpen = false;
            loom_asset_notifyPendingCountChange();
            loom_mutex_unlock(gAssetServerSocketLock);
            return;
        }

        lmLogDebug(gAssetLogGroup, "Successfully connected to asset server %s:%d!", ASSET_STREAM_HOST, ASSET_STREAM_PORT);

        // Do this now to avoid clobbering error state and seeing the socket as
        // "open" when it is really dead.
        loom_net_enableSocketKeepalive(gAssetServerSocket);
        gAssetConnectionOpen = true;
        loom_asset_notifyPendingCountChange();

        // Make sure we have a protocol handler.
        if (!gAssetProtocolHandler)
        {
            gAssetProtocolHandler = lmNew(NULL) AssetProtocolHandler(gAssetServerSocket);
            gAssetProtocolHandler->registerListener(lmNew(NULL) AssetProtocolFileMessageListener());
            gAssetProtocolHandler->registerListener(lmNew(NULL) AssetProtocolCommandListener());
        }

        loom_mutex_unlock(gAssetServerSocketLock);
        return;
    }

    // See if the socket is dead, and if so, clean up.
    if ((gAssetServerSocket != NULL) && (loom_net_isSocketDead(gAssetServerSocket) == 1))
    {
        lmLog(gAssetLogGroup, "Lost connection to asset server.");
        loom_net_closeTCPSocket(gAssetServerSocket);
        gAssetServerSocket = NULL;
        lmSafeDelete(NULL, gAssetProtocolHandler);
        gAssetConnectionOpen = false;
        loom_asset_notifyPendingCountChange();
        loom_mutex_unlock(gAssetServerSocketLock);
        return;
    }

    // Bail if we don't have a connection.
    if (!gAssetServerSocket || !gAssetConnectionOpen)
    {
        loom_mutex_unlock(gAssetServerSocketLock);
        return;
    }

    // Ping if we need to.
    if (platform_getMilliseconds() - gAssetServerLastPingTime > gAssetServerPingInterval)
    {
        gAssetProtocolHandler->sendPing();
        gAssetServerLastPingTime = platform_getMilliseconds();
    }

    // Service the asset server connection.
    gAssetProtocolHandler->process();

    loom_mutex_unlock(gAssetServerSocketLock);
}


void loom_asset_pump()
{
   // Currently we only want to do this on the main thread so piggy back on the
   // native delegate sanity check to bail if on secondary thread.
   if(platform_getCurrentThreadId() != LS::NativeDelegate::smMainThreadID && LS::NativeDelegate::smMainThreadID != 0xBAADF00D)
      return;

   loom_mutex_lock(gAssetLock);

   // Talk to the asset server.
   loom_asset_serviceServer();

   // For now just blast all the data from each file into the asset.
   while(gAssetLoadQueue.size())
   {
      loom_asset_t *asset = gAssetLoadQueue.front();

      // Figure out the type from the path.
      utString path = asset->name;
      int type = loom_asset_recognizeAssetTypeFromPath(path);
      
      if(type == 0)
      {
         lmLog(gAssetLogGroup, "Could not infer type of resource '%s', skipping it...", path.c_str());
         asset->state = loom_asset_t::Unloaded;
         gAssetLoadQueue.erase((UTsize)0, true);
         continue;
      }

      // Open the file.
      void *ptr;
      long size;
      if(!platform_mapFile(asset->name.c_str(), &ptr, &size))
      {
         lmAssert(false, "Could not open file '%s'.", asset->name.c_str());
      }

      // Deserialize it.
      LoomAssetCleanupCallback dtor = NULL;
      void *assetBits = loom_asset_deserializeAsset(path, type, size, ptr, &dtor);

      // Close the file.
      platform_unmapFile(ptr);

      if(!assetBits)
      {
        // Note it as failed.
        asset->state = loom_asset_t::Failed;
      }
      else
      {
        // Instate the asset.
        asset->instate(type, assetBits, dtor);        
      }

      // Done! Update queue.
      gAssetLoadQueue.erase((UTsize)0, true);
   }

   loom_mutex_unlock(gAssetLock);
}


void loom_asset_preload(const char *name)
{
    loom_mutex_lock(gAssetLock);

    // Look 'er up.
    loom_asset_t *asset = loom_asset_getAssetByName(name, 1);

    // If it's not pending load, then stick it in the queue.
    if (loom_asset_isOnTrackToLoad(asset))
    {
        loom_mutex_unlock(gAssetLock);
        return;
    }

    asset->state = loom_asset_t::QueuedForDownload;
    gAssetLoadQueue.push_back(asset);

    loom_mutex_unlock(gAssetLock);
}

int loom_asset_pending(const char *name)
{
    loom_mutex_lock(gAssetLock);
    
    // Look 'er up.
    loom_asset_t *asset = loom_asset_getAssetByName(name, 0);
    
    // If it's not pending load, then stick it in the queue.
    int result;
    if(asset && loom_asset_isOnTrackToLoad(asset))
        result = 1;
    else
        result = 0;
    
    loom_mutex_unlock(gAssetLock);
    
    return result;
}

void loom_asset_flush(const char *name)
{
   // Currently we only want to do this on the main thread so piggy back on the
   // native delegate sanity check to bail if on secondary thread.
   if(platform_getCurrentThreadId() != LS::NativeDelegate::smMainThreadID
      && LS::NativeDelegate::smMainThreadID != 0xBAADF00D)
      return;

   loom_mutex_lock(gAssetLock);

    // Delete it + unload it.
    loom_asset_t *asset = loom_asset_getAssetByName(name, 0);

   if(!asset || asset->isSupplied)
   {
      loom_mutex_unlock(gAssetLock);
      return;
   }
    
   lmLogDebug(gAssetLogGroup, "Flushing '%s'", name);

    if (asset->blob)
    {
        asset->blob->decRef();
        asset->blob = NULL;
    }

    asset->state = loom_asset_t::Unloaded;

    // Fire subscribers.
    if(!gShuttingDown)
        loom_asset_notifySubscribers(asset->name.c_str());

    loom_mutex_unlock(gAssetLock);
}


void loom_asset_flushAll()
{
    // Call flush on everything in the hash.
    utHashTableIterator<utHashTable<utHashedString, loom_asset_t *> > assetIterator(gAssetHash);
    while (assetIterator.hasMoreElements())
    {
        utHashedString key = assetIterator.peekNextKey();
        loom_asset_flush(key.str().c_str());
        assetIterator.next();
    }
}


int loom_asset_queryPendingLoads()
{
    return gAssetLoadQueue.size() > 0 ? 1 : 0;
}


float loom_asset_checkLoadedPercentage(const char *name)
{
    loom_mutex_lock(gAssetLock);

    // Look it up.
    loom_asset_t *asset = loom_asset_getAssetByName(name, 0);

    loom_mutex_unlock(gAssetLock);

    if (!asset)
    {
        return 0.f;
    }

    // If loaded, return 1, else 0. (For now.)
    return asset->state == loom_asset_t::Loaded ? 1.f : 0.2f;
}

void loom_asset_unlock( const char *name )
{
   // Hack to report usage.
   //size_t allocBytes, allocCount;
   //loom_allocator_getTrackerProxyStats(gAssetAllocator, &allocBytes, &allocCount);
   //lmLogError(gAssetLogGroup, "Seeing %d bytes of allocator and %d allocations", allocBytes, allocCount);

   loom_mutex_lock(gAssetLock);

   // TODO: This needs to be against the blob we locked NOT the asset's
   //       current state.

   // Look it up.
   loom_asset_t *asset = loom_asset_getAssetByName(name, 0);

   // Assert if not loaded.
   lmAssert(asset, "Could not find asset '%s' to unlock!", name);
   //lmAssert(asset->blob, "Asset was not locked!");

   if(asset->state == loom_asset_t::Loaded)
   {
      // Dec count.
      if(asset->blob->decRef())
      {
         asset->state = loom_asset_t::Unloaded;
         asset->blob = NULL;
      }
   }
   else
   {
      // Nothing - it's not loaded.
      lmLogWarn(gAssetLogGroup, "Couldn't unlock '%s' as it was not loaded.", name);
   }

   loom_mutex_unlock(gAssetLock);
}

void *loom_asset_lock(const char *name, unsigned int type, int block)
{
    const char *namePtr = stringtable_insert(name);

    loom_mutex_lock(gAssetLock);

    // Look it up.
    loom_asset_t *asset = loom_asset_getAssetByName(namePtr, 1);
    lmAssert(asset != NULL, "Didn't get asset even though we should have!");

    // If not loaded, and we aren't ready to block, return NULL.
    if ((block == 0) && (asset->state != loom_asset_t::Loaded))
    {
        lmLogDebug(gAssetLogGroup, "Unable to lock without blocking, not loaded yet: '%s'", namePtr);
        loom_mutex_unlock(gAssetLock);
        return NULL;
    }

    bool preloaded = asset->state == loom_asset_t::Loaded;

    // Otherwise, let's force it to load now.
    if (!preloaded)
    {
        lmLogDebug(gAssetLogGroup, "Loading '%s'", namePtr);

        loom_asset_preload(namePtr);

        lmAssert(loom_asset_isOnTrackToLoad(asset), "Preloaded but wasn't on track to load!");

        while (loom_asset_checkLoadedPercentage(namePtr) != 1.f && loom_asset_isOnTrackToLoad(asset))
        {
            lmLogDebug(gAssetLogGroup, "Pumping load of '%s'", namePtr);
            loom_asset_pump();
        }

        if (asset->state != loom_asset_t::Loaded)
        {
            lmLogError(gAssetLogGroup, "Load failed for '%s'!", name);
            loom_mutex_unlock(gAssetLock);
            return NULL;
        }
    }

    // Check type.
    if (asset->type != type)
    {
        lmLogError(gAssetLogGroup, "Tried to lock asset '%s' with wrong type, assetType=%x, requestedType=%x", name, asset->type, type);
        loom_mutex_unlock(gAssetLock);
        return NULL;
    }

    // Inc count.
    asset->blob->incRef();

    loom_mutex_unlock(gAssetLock);

    if (preloaded)
    {
        lmLogDebug(gAssetLogGroup, "Acquired '%s'", namePtr);
    }
    else
    {
        lmLogInfo(gAssetLogGroup, "Loaded '%s'", namePtr);
    }

    // Return ptr.
    return asset->blob->bits;
}

int loom_asset_subscribe(const char *name, LoomAssetChangeCallback cb, void *payload, int doFirstCall)
{
    loom_mutex_lock(gAssetLock);

    loom_asset_t *asset = loom_asset_getAssetByName(name, 1);

    if (!asset)
    {
        loom_mutex_unlock(gAssetLock);
        return 0;
    }

    // Add to list of subscribers.
    loom_asset_subscription_t subscription;
    subscription.callback = cb;
    subscription.payload  = payload;
    asset->subscribers.push_back(subscription);

    // If it is loaded and we want it, do the first call.
    if (doFirstCall && (asset->state == loom_asset_t::Loaded))
    {
        cb(payload, name);
    }

    loom_mutex_unlock(gAssetLock);
    return 1;
}


void loom_asset_notifySubscribers(const char *name)
{
    loom_mutex_lock(gAssetLock);

    loom_asset_t *asset = loom_asset_getAssetByName(name, 0);

    if (!asset)
    {
        loom_mutex_unlock(gAssetLock);
        return;
    }

    for (UTsize i = 0; i < asset->subscribers.size(); i++)
    {
        loom_asset_subscription_t& s = asset->subscribers[i];
        s.callback(s.payload, name);
    }

    loom_mutex_unlock(gAssetLock);
}


int loom_asset_unsubscribe(const char *name, LoomAssetChangeCallback cb, void *payload)
{
    loom_mutex_lock(gAssetLock);

    loom_asset_t *asset = loom_asset_getAssetByName(name, 0);

    if (!asset)
    {
        loom_mutex_unlock(gAssetLock);
        return 0;
    }

    // Remove from list of subscribers.
    for (UTsize i = 0; i < asset->subscribers.size(); i++)
    {
        const loom_asset_subscription_t& subscription = asset->subscribers[i];

        if (subscription.callback != cb)
        {
            continue;
        }
        if (subscription.payload != payload)
        {
            continue;
        }

        asset->subscribers.erase(i, true);
        loom_mutex_unlock(gAssetLock);
        return 1;
    }

    loom_mutex_unlock(gAssetLock);
    return 0;
}


void loom_asset_registerType(unsigned int type, LoomAssetDeserializeCallback deserializer, LoomAssetRecognizerCallback recognizer)
{
    lmAssert(gAssetDeserializerMap.find(type) == UT_NPOS, "Asset type already registered!");

    gAssetDeserializerMap.insert(type, deserializer);
    gRecognizerList.push_back(recognizer);
}


void loom_asset_reload(const char *name)
{
    loom_mutex_lock(gAssetLock);

    loom_asset_t *asset = loom_asset_getAssetByName(name, 1);

    // Put it in the queue, this will trigger a new blob to be loaded.
    gAssetLoadQueue.push_back(asset);

    loom_mutex_unlock(gAssetLock);
}


void loom_asset_reloadAll()
{
    // Call reload on everything in the hash.
    utHashTableIterator<utHashTable<utHashedString, loom_asset_t *> > assetIterator(gAssetHash);
    while (assetIterator.hasMoreElements())
    {
        utHashedString key = assetIterator.peekNextKey();
        loom_asset_reload(key.str().c_str());
        assetIterator.next();
    }
}

void loom_asset_supply(const char *name, void *bits, int length)
{
    loom_mutex_lock(gAssetLock);

    // Prep the asset.
    loom_asset_t *asset = loom_asset_getAssetByName(name, 1);

    // Make sure it's pristine.
    lmAssert(asset->state == loom_asset_t::Unloaded, "Can't supply an asset that's already queued or in process of loading. Supply assets before you make any asset requests!");

    // Figure out the type from the path.
    utString nameAsUt = name;
    int      type     = loom_asset_recognizeAssetTypeFromPath(nameAsUt);

    if (type == 0)
    {
        lmLog(gAssetLogGroup, "Could not infer type of supplied resource '%s', skipping it...", name);
        asset->state = loom_asset_t::Unloaded;
        return;
    }

    // Deserialize it.
    LoomAssetCleanupCallback dtor = NULL;
    void *assetBits = loom_asset_deserializeAsset(name, type, length, bits, &dtor);

    // Instate the asset.
    // TODO: We can save some memory by pointing directly and not making a copy.
    asset->instate(type, assetBits, dtor);

    // Note it's supplied so we don't flush it.
    asset->isSupplied = 1;

    loom_mutex_unlock(gAssetLock);
}
