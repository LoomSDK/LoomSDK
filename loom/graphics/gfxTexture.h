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

#pragma once

#include "loom/graphics/gfxGraphics.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"
#include "loom/common/utils/utString.h"
#include "loom/common/utils/utByteArray.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/platform/platformThread.h"

namespace GFX
{
typedef int   TextureID;

#define TEXTUREINVALID    -1
#define MAXTEXTURES       4096

// loading textures are marked
#define MARKEDTEXTURE     65534

// texture smoothing modes
#define TEXTUREINFO_SMOOTHING_NONE 0
#define TEXTUREINFO_SMOOTHING_BILINEAR 1

// texture wrapping modes
#define TEXTUREINFO_WRAP_REPEAT     0
#define TEXTUREINFO_WRAP_MIRROR     1
#define TEXTUREINFO_WRAP_CLAMP      2


struct TextureInfo
{
    TextureID                id;

    // todo: format

    int                      width;
    int                      height;
    int                      smoothing;
    int                      wrapU;
    int                      wrapV;

    bool                     reload;

    //this flag will be set if a TextureInfo was requested to be disposed but it is still 
    //busy in the async loading thread as it can only be disposed from the main thread once \
    //its async processing is complete
    bool                     asyncDispose;
    GLuint                   handle;

    utString                 texturePath;

    LS::NativeDelegate       updateDelegate;
    LS::NativeDelegate       asyncLoadCompleteDelegate;

    const LS::NativeDelegate *getUpdateDelegate() const
    {
        return &updateDelegate;
    }

    const LS::NativeDelegate *getAsyncLoadCompleteDelegate() const
    {
        return &asyncLoadCompleteDelegate;
    }

    int getHandleID() const 
    {
        return (int)handle; 
    }

    const char* getTexturePath() const 
    { 
        return texturePath.c_str(); 
    }

    TextureInfo()
    {
        reset();
    }
    void reset()
    {
        width       = height = 0;
        smoothing   = TEXTUREINFO_SMOOTHING_NONE;
        wrapU       = TEXTUREINFO_WRAP_CLAMP;
        wrapV       = TEXTUREINFO_WRAP_CLAMP;
        reload      = false;
        asyncDispose = false;
        handle      = -1;
        texturePath = "";
    }
};


//struct to hold the data that needs to be transferred between threads for async texture loading and creation
struct AsyncLoadNote
{
    int                         id;
    bool                        priority;
    utString                    path;
    TextureInfo                 *tinfo;

    //the following are only used for async loading of pure byte data
    utByteArray                 *bytes;
    loom_asset_image_t          *imageAsset;
    LoomAssetCleanupCallback    iaCleanup;
};


class Texture
{
    friend class Graphics;
    friend class QuadRenderer;

private:

    static utHashTable<utFastStringHash, TextureID> sTexturePathLookup;
    static bool sTextureAssetNofificationsEnabled;

    // simple linear TextureID -> TextureHandle
    static TextureInfo sTextureInfos[MAXTEXTURES];

    //queue of textures to load in the async loading thread
    static utList<AsyncLoadNote> sAsyncLoadQueue;

    //queue of loaded texture data to be created back in the main thread
    static utList<AsyncLoadNote> sAsyncCreateQueue;

    //current frame delay counter used to space out texture creation between frames
    static int sAsyncTextureCreateDelay;

    //flag indicating if the async loading thread is currently running
    static bool sAsyncThreadRunning;

    //mutex used for locking sAsyncLoadQueue and sAsyncCreateQueue between threads
    static MutexHandle sAsyncQueueMutex;

    //mutex used for locking sTextureInfos and sTexturePathLookup between threads
    static MutexHandle sTexInfoLock;

    static TextureID getAvailableTextureID()
    {
        TextureID id;

        loom_mutex_lock(sTexInfoLock);
        for (id = 0; id < MAXTEXTURES; id++)
        {
            if (sTextureInfos[id].handle == -1)
            {
                break;
            }
        }
        loom_mutex_unlock(sTexInfoLock);

        if (id == MAXTEXTURES)
        {
            return TEXTUREINVALID;
        }

        return id;
    }

    static TextureInfo *getTextureInfoFromPath(const char *path, 
                                                TextureID **pid, 
                                                bool checkHandle = true, 
                                                bool clearDispose = true)
    {
        loom_mutex_lock(Texture::sTexInfoLock);
        TextureID   *texID = sTexturePathLookup.get(path);
        TextureInfo *tinfo = (texID && ((*texID >= 0) && (*texID < MAXTEXTURES))) ? &sTextureInfos[*texID] : NULL;
        if(checkHandle && (tinfo && (tinfo->handle == -1)))
        {
            tinfo = NULL;
        }
        if(clearDispose && (tinfo != NULL))
        {
            //need to disable the async dispose flag if we're going to continue using it
            tinfo->asyncDispose = false;
        }
        loom_mutex_unlock(Texture::sTexInfoLock);
        
        *pid = texID;
        return tinfo;
    }

    static TextureInfo *getAvailableTextureInfo(const char *path)
    {
        TextureID id;
        TextureInfo *tinfo = NULL;

        loom_mutex_lock(sTexInfoLock);
        for (id = 0; id < MAXTEXTURES; id++)
        {
            if (sTextureInfos[id].handle == -1)
            {
                // Initialize it.
                tinfo = &sTextureInfos[id];
                tinfo->handle = MARKEDTEXTURE;    // mark in use, but not yet loaded
                if(path != NULL)
                {
                    tinfo->texturePath = path;
                    sTexturePathLookup.insert(path, id);
                }
                break;
            }
        }
        loom_mutex_unlock(sTexInfoLock);
        return tinfo;
    }


    static void loadCheckerBoard(TextureID id);

    static void initialize();

    static void handleAssetNotification(void *payload, const char *name);

    static void loadImageAsset(loom_asset_image_t *lat, TextureID id);

public:

    inline static TextureInfo *getTextureInfo(const char *path)
    {
        TextureID *pid = sTexturePathLookup.get(path);

        if (!pid)
        {
            return NULL;
        }

        if (pid)
        {
            return getTextureInfo(*pid);
        }

        return NULL;
    }

    inline static TextureInfo *getTextureInfo(TextureID id)
    {
        if ((id < 0) || (id >= MAXTEXTURES))
        {
            return NULL;
        }

        loom_mutex_lock(sTexInfoLock);
        TextureInfo *tinfo = &sTextureInfos[id];

        if (tinfo->handle == -1)
        {
            tinfo = NULL;
        }
        loom_mutex_unlock(sTexInfoLock);

        return tinfo;
    }

    inline static void enableAssetNotifications(bool value)
    {
        sTextureAssetNofificationsEnabled = value;
    }

    static void reset();
    static void tick();

    // This method accepts rgba data.
    static TextureInfo *load(uint8_t *data, uint16_t width, uint16_t height, TextureID id = -1);

    static TextureInfo *initFromAssetManager(const char *path);
    static TextureInfo *initFromBytes(utByteArray *bytes, const char *name);
    static TextureInfo *initFromBytesAsync(utByteArray *bytes, const char *name, bool highPriorty);
    static TextureInfo *initFromAssetManagerAsync(const char *path, bool highPriorty);
    static int __stdcall loadTextureAsync_body(void *param);

    static void dispose(TextureID id);

    static void scaleImageOnDisk(const char *outPath, const char *inPath, int maxWidth, int maxHeight, bool preserveAspect);
};
}