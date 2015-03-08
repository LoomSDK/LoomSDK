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

#include "loom/graphics/internal/bgfx/include/bgfx.h"
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
    bool                     asyncDispose;

    bgfx::TextureHandle      handle;

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

    int getHandleID() const { return (int)handle.idx; }
    const char* getTexturePath() const { return texturePath.c_str(); }

    void                     reset()
    {
        width        = height = 0;
        smoothing    = TEXTUREINFO_SMOOTHING_NONE;
        wrapU        = TEXTUREINFO_WRAP_CLAMP;
        wrapV        = TEXTUREINFO_WRAP_CLAMP;
        reload       = false;
        asyncDispose = false;
        handle.idx   = bgfx::invalidHandle;
        texturePath  = "";
    }
};


struct AsyncLoadNote
{
    int             id;
    utString        path;
    TextureInfo     *tinfo;
};


class Texture
{
    friend class Graphics;
    friend class QuadRenderer;

private:

    static utHashTable<utFastStringHash, TextureID> sTexturePathLookup;
    static bool sTextureAssetNofificationsEnabled;
    static MutexHandle sTexInfoLock;
    static MutexHandle sAsyncQueueMutex;
    static bool sAsyncThreadRunning;
    static int sAsyncTextureCreateDelay;
    static utList<AsyncLoadNote> sAsyncLoadQueue;
    static utList<AsyncLoadNote> sAsyncCreateQueue;


    // simple linear TextureID -> TextureHandle
    static TextureInfo sTextureInfos[MAXTEXTURES];

    static TextureID getAvailableTextureID()
    {
        TextureID id;

        loom_mutex_lock(sTexInfoLock);
        for (id = 0; id < MAXTEXTURES; id++)
        {
            if (sTextureInfos[id].handle.idx == bgfx::invalidHandle)
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


    static TextureInfo *getAvailableTextureInfo(const char *path)
    {
        TextureID id;
        TextureInfo *tinfo = NULL;

        loom_mutex_lock(sTexInfoLock);
        for (id = 0; id < MAXTEXTURES; id++)
        {
            if (sTextureInfos[id].handle.idx == bgfx::invalidHandle)
            {
                // Initialize it.
                tinfo = &sTextureInfos[id];
                tinfo->handle.idx = MARKEDTEXTURE;    // mark in use, but not yet loaded
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
        if (tinfo->handle.idx == bgfx::invalidHandle)
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

    static TextureInfo *initFromBytes(utByteArray *bytes);
    static TextureInfo *initFromAssetManager(const char *path);
    static TextureInfo *initFromAssetManagerAsync(const char *path);
    static int __stdcall loadTextureAsync_body(void *param);

    static void dispose(TextureID id);

    static void scaleImageOnDisk(const char *outPath, const char *inPath, int maxWidth, int maxHeight, bool preserveAspect);
};
}
