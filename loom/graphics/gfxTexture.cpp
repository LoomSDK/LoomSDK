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

#include "bgfx.h"

#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"

#include "loom/graphics/gfxTexture.h"

#include "loom/common/platform/platformTime.h"

lmDefineLogGroup(gGFXTextureLogGroup, "GFXTexture", 1, LoomLogInfo);
loom_allocator_t *gGFXTextureAllocator = NULL;

namespace GFX
{

TextureInfo Texture::sTextureInfos[MAXTEXTURES];
utHashTable<utFastStringHash, TextureID> Texture::sTexturePathLookup;
bool Texture::sTextureAssetNofificationsEnabled = true;

void Texture::initialize()
{
    for (int i = 0; i < MAXTEXTURES; i++)
    {
        sTextureInfos[i].id         = i;
        sTextureInfos[i].reload     = false;
        sTextureInfos[i].handle.idx = bgfx::invalidHandle;
    }
}


static void rgbaToBgra(uint8_t *_data, uint32_t _width, uint32_t _height)
{
    uint32_t dstpitch = _width * 4;

    for (uint32_t yy = 0; yy < _height; ++yy)
    {
        uint8_t *dst = &_data[yy * dstpitch];

        for (uint32_t xx = 0; xx < _width; ++xx)
        {
            uint8_t tmp = dst[0];
            dst[0] = dst[2];
            dst[2] = tmp;
            dst   += 4;
        }
    }
}


TextureInfo *Texture::load(uint8_t *data, uint16_t width, uint16_t height, TextureID id)
{
    if (id == -1)
    {
        id = getAvailableTextureID();

        if (id == TEXTUREINVALID)
        {
            return NULL;
        }
    }

    if ((id < 0) || (id >= MAXTEXTURES))
    {
        return NULL;
    }

    TextureInfo *tinfo = &sTextureInfos[id];

    // Make a copy of the texture so we can swizzle it safely. No need to
    // free memory, this will be freed at end of frame by bgfx.
    const bgfx::Memory *mem = bgfx::alloc(width * height * 4);
    memcpy(mem->data, data, width * height * 4);

    // Do the swizzle for D3D9 - see LOOM-1713 for details on this.
    rgbaToBgra(mem->data, width, height);

    if (!tinfo->reload || (tinfo->width != width) || (tinfo->height != height))
    {
        lmLog(gGFXTextureLogGroup, "Create texture for %s", tinfo->texturePath.c_str());

        if (tinfo->reload)
        {
            bgfx::destroyTexture(tinfo->handle);
        }

        tinfo->handle = bgfx::createTexture2D(width, height, 1, bgfx::TextureFormat::BGRA8, BGFX_TEXTURE_NONE, mem);
        tinfo->width  = width;
        tinfo->height = height;

        if (tinfo->reload)
        {
            // Fire the delegate.
            tinfo->updateDelegate.pushArgument(width);
            tinfo->updateDelegate.pushArgument(height);
            tinfo->updateDelegate.invoke();
        }

        // mark that next time we will be reloading
        tinfo->reload = true;
    }
    else
    {
        lmLog(gGFXTextureLogGroup, "Updating texture %s", tinfo->texturePath.c_str());
        bgfx::updateTexture2D(tinfo->handle, 0, 0, 0, width, height, mem);

        tinfo->width  = width;
        tinfo->height = height;

        // Fire the delegate.
        tinfo->updateDelegate.pushArgument(width);
        tinfo->updateDelegate.pushArgument(height);
        tinfo->updateDelegate.invoke();
    }

    return tinfo;
}


// Courtesy of Torque via MIT license.
void bitmapExtrudeRGBA_c(const void *srcMip, void *mip, int srcHeight, int srcWidth)
{
    const unsigned char *src   = (const unsigned char *)srcMip;
    unsigned char       *dst   = (unsigned char *)mip;
    int                 stride = srcHeight != 1 ? (srcWidth) * 4 : 0;

    int width  = srcWidth >> 1;
    int height = srcHeight >> 1;

    if (width == 0)
    {
        width = 1;
    }
    if (height == 0)
    {
        height = 1;
    }

    if (srcWidth != 1)
    {
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                *dst++ = (int(*src) + int(src[4]) + int(src[stride]) + int(src[stride + 4]) + 2) >> 2;
                src++;
                *dst++ = (int(*src) + int(src[4]) + int(src[stride]) + int(src[stride + 4]) + 2) >> 2;
                src++;
                *dst++ = (int(*src) + int(src[4]) + int(src[stride]) + int(src[stride + 4]) + 2) >> 2;
                src++;
                *dst++ = (int(*src) + int(src[4]) + int(src[stride]) + int(src[stride + 4]) + 2) >> 2;
                src   += 5;
            }
            src += stride;    // skip
        }
    }
    else
    {
        for (int y = 0; y < height; y++)
        {
            *dst++ = (int(*src) + int(src[stride]) + 1) >> 1;
            src++;
            *dst++ = (int(*src) + int(src[stride]) + 1) >> 1;
            src++;
            *dst++ = (int(*src) + int(src[stride]) + 1) >> 1;
            src++;
            *dst++ = (int(*src) + int(src[stride]) + 1) >> 1;
            src   += 5;

            src += stride;    // skip
        }
    }
}


TextureInfo *Texture::initFromAssetManager(const char *path)
{
    if (!path || !path[0])
    {
        return NULL;
    }

    TextureID   *pid   = sTexturePathLookup.get(path);
    TextureInfo *tinfo = NULL;

    if (pid)
    {
        if ((*pid < 0) || (*pid >= MAXTEXTURES))
        {
            return NULL;
        }

        tinfo = &sTextureInfos[*pid];

        if (tinfo->handle.idx == bgfx::invalidHandle)
        {
            return NULL;
        }

        return tinfo;
    }

    // Force it to load.
    if(loom_asset_lock(path, LATImage, 1) == NULL)
    {
        lmLogWarn(gGFXTextureLogGroup, "Unable to lock the asset for texture %s", path);
        return NULL;
    }
    loom_asset_unlock(path);

    // Get a new texture ID.
    TextureID id = getAvailableTextureID();
    if (id == TEXTUREINVALID)
    {
        lmLog(gGFXTextureLogGroup, "No available texture id for %s", path);
        return NULL;
    }

    // Initialize it.
    tinfo              = &sTextureInfos[id];
    tinfo->handle.idx  = MARKEDTEXTURE;    // mark in use, but not yet loaded
    tinfo->texturePath = path;
    sTexturePathLookup.insert(path, id);

    // allocate the texture handle/id
    lmLog(gGFXTextureLogGroup, "loading %s", path);

    // Now subscribe and let us load for reals.
    loom_asset_subscribe(path, Texture::handleAssetNotification, (void *)id, 1);

    return tinfo;
}


void Texture::loadCheckerBoard(TextureID id)
{
        const int checkerboardSize = 128, checkSize = 8;        

        int *checkerboard = (int*)lmAlloc(gGFXTextureAllocator, checkerboardSize*checkerboardSize*4);

        for (int i = 0; i < checkerboardSize; i++)
        {
            for (int j = 0; j < checkerboardSize; j++)
            {
                checkerboard[(i * checkerboardSize) + j] = (((i / checkSize) ^ (j / checkSize)) & 1) == 0 ? 0xFF00FFFF : 0x00FF0077;
            }
        }

        load((uint8_t *)checkerboard, checkerboardSize, checkerboardSize, id);

        lmFree(gGFXTextureAllocator, checkerboard);

}

void Texture::handleAssetNotification(void *payload, const char *name)
{
    TextureID id = (TextureID)payload;

    if (!sTextureAssetNofificationsEnabled)
    {

        lmLogError(gGFXTextureLogGroup, "Attempting to load texture while notifications are disabled '%s', using debug checkerboard.", name);        
        loadCheckerBoard(id);
        return;
    }    

    // Get the image via the asset manager.    
    loom_asset_image_t *lat = (loom_asset_image_t *)loom_asset_lock(name, LATImage, 0);

    // If we couldn't load it, and we have never loaded it, generate a checkerboard placeholder texture.
    if (!lat)
    {
        if(sTextureInfos[id].reload == true)
            return;
        

        lmLogError(gGFXTextureLogGroup, "Missing image asset '%s', using %dx%d px debug checkerboard.", name, 128, 128);

        loadCheckerBoard(id);

        return;
    }

    // Great, stuff real bits!
    lmLog(gGFXTextureLogGroup, "loaded %s - %i x %i at id %i", name, lat->width, lat->height, id);

    // See if it's over 2048 - if so, downsize to fit.
    const int          maxSize     = 2048;
    void               *localBits  = lat->bits;
    const bgfx::Memory *localMem   = NULL;
    int                localWidth  = lat->width;
    int                localHeight = lat->height;
    while (localWidth > maxSize || localHeight > maxSize)
    {
        // Allocate new bits.
        int oldWidth = localWidth, oldHeight = localHeight;
        localWidth  = localWidth >> 1;
        localHeight = localHeight >> 1;
        void *oldBits = localBits;

        // This will be freed automatically. This will be inefficient for huge bitmaps but it's
        // only around for one frame.
        localMem  = bgfx::alloc(localWidth * localHeight * 4);
        localBits = localMem->data;

        lmLog(gGFXTextureLogGroup, "   - Too big! Downsampling to %dx%d", localWidth, localHeight);

        bitmapExtrudeRGBA_c(oldBits, localBits, oldHeight, oldWidth);
    }

    // Perform the actual load.
    load((uint8_t *)localBits, (uint16_t)localWidth, (uint16_t)localHeight, id);

    // Release lock on the asset.
    loom_asset_unlock(name);
    
    // Once we load it we don't need it any more.
    loom_asset_flush(name);
}


void Texture::reset()
{
    for (int i = 0; i < MAXTEXTURES; i++)
    {
        // Ignore invalid entries.
        if (sTextureInfos[i].handle.idx == bgfx::invalidHandle)
        {
            continue;
        }

        TextureInfo *tinfo = &sTextureInfos[i];

        lmLog(gGFXTextureLogGroup, "Reloading texture for path %s", tinfo->texturePath.c_str());

        //bgfx::destroyTexture(sTextureInfos[i].handle);
        tinfo->handle.idx = bgfx::invalidHandle;
        tinfo->reload     = false;

        loom_asset_lock(tinfo->texturePath.c_str(), LATImage, 1);
        handleAssetNotification((void *)tinfo->id, tinfo->texturePath.c_str());
        loom_asset_unlock(tinfo->texturePath.c_str());
    }
}


void Texture::dispose(TextureID id)
{
    if ((id < 0) || (id >= MAXTEXTURES))
    {
        return;
    }

    TextureInfo *tinfo = &sTextureInfos[id];

    // If the texture isn't valid ignore it.
    if (tinfo->handle.idx == bgfx::invalidHandle)
    {
        return;
    }

    //TODO: LOOM-1653, we really shouldn't be holding a copy of the texture data in the
    // asset system until we dispose
    loom_asset_unsubscribe(tinfo->texturePath.c_str(), handleAssetNotification, (void *)id);
    loom_asset_flush(tinfo->texturePath.c_str());

    // Reset the hash, too
    sTexturePathLookup.erase(tinfo->texturePath);

    // And erase backing state.
    bgfx::destroyTexture(tinfo->handle);
    tinfo->reset();
}
}
