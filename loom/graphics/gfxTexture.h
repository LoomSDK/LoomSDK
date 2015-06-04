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
#define TEXTURE_ID_BITS   12
#define TEXTURE_ID_MASK   (1 << TEXTURE_ID_BITS) - 1
#define MAXTEXTURES       1 << TEXTURE_ID_BITS

#define TEXTURE_GEN_BATCH 16

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
    // This number uniquely identifies the texture.
    // The last TEXTURE_ID_BITS represent the index into the `sTextureInfos` array.
    // The remaining bits represent the version or check bits used to determine
    // if some part of the program is trying to operate on a texture that has
    // been recycled, since the version increments every time the texture is recycled.
    TextureID                id;

    // todo: format

    int                      width;
    int                      height;
    int                      smoothing;
    int                      wrapU;
    int                      wrapV;

    bool                     clampOnly;
    bool                     mipmaps;

    bool                     reload;

    //this flag will be set if a TextureInfo was requested to be disposed but it is still 
    //busy in the async loading thread as it can only be disposed from the main thread once \
    //its async processing is complete
    bool                     asyncDispose;
    GLuint                   handle;
    bool                     renderTarget;
    GLuint                   framebuffer;
    GLuint                   renderbuffer;

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

    inline bool isPowerOfTwo() const
    {
        return intIsPOT(width) && intIsPOT(height);
    }

    inline bool intIsPOT(unsigned int x) const
    {
        return (!(x & (x - 1)) && x);
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
        width        = height = 0;
        smoothing    = TEXTUREINFO_SMOOTHING_NONE;
        wrapU        = TEXTUREINFO_WRAP_CLAMP;
        wrapV        = TEXTUREINFO_WRAP_CLAMP;
        reload       = false;
        asyncDispose = false;
        handle       = -1;
		// This increments the check bits / version by 1
		id          += MAXTEXTURES;
        texturePath  = "";
        renderTarget = false;
        framebuffer  = -1;
        renderbuffer = -1;
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
	static bool supportsFullNPOT;
	static TextureID currentRenderTexture;
	static uint32_t previousRenderFlags;
    
    // simple linear TextureID -> TextureHandle
    static TextureInfo sTextureInfos[MAXTEXTURES];

    //queue of textures to load in the async loading thread
    static utList<AsyncLoadNote> sAsyncLoadQueue;

    //queue of loaded texture data to be created back in the main thread
    static utList<AsyncLoadNote> sAsyncCreateQueue;

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
        TextureID   *texID = sTexturePathLookup.get(path);
        loom_mutex_lock(Texture::sTexInfoLock);
        TextureInfo *tinfo = Texture::getTextureInfo(texID);
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

    static void shutdown();

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

    inline static TextureInfo *getTextureInfo(TextureID* id)
    {
        return id ? getTextureInfo(*id) : NULL;
    }

    static TextureInfo *getTextureInfo(TextureID id);
	
    inline static int getIndex(TextureID id)
    {
        return id & TEXTURE_ID_MASK;
    }

    inline static int getVersion(TextureID id)
    {
        return id >> TEXTURE_ID_BITS;
    }

    inline static void enableAssetNotifications(bool value)
    {
        sTextureAssetNofificationsEnabled = value;
    }

    static void reset();
    static void tick();
    static void validate();
    static void validate(TextureID id);

    // This method accepts rgba data.
    static TextureInfo *load(uint8_t *data, uint16_t width, uint16_t height, TextureID id = -1);

    static TextureInfo *initFromAssetManager(const char *path);
    static TextureInfo *initFromBytes(utByteArray *bytes, const char *name);
    static TextureInfo *initFromBytesAsync(utByteArray *bytes, const char *name, bool highPriorty);
    static TextureInfo *initFromAssetManagerAsync(const char *path, bool highPriorty);
	static TextureInfo *initEmptyTexture(int width, int height);
    static int __stdcall loadTextureAsync_body(void *param);

	static void clear(TextureID id, int color, float alpha);

	static void setRenderTarget(TextureID id = -1);
	static int render(lua_State *L);

    static void dispose(TextureID id);

    static void scaleImageOnDisk(const char *outPath, const char *inPath, int maxWidth, int maxHeight, bool preserveAspect);
};
}