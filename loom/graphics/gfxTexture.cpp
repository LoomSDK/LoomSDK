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

#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/utTypes.h"

#include "loom/graphics/gfxTexture.h"

#include "loom/common/platform/platformTime.h"

lmDefineLogGroup(gGFXTextureLogGroup, "GFXTexture", 1, LoomLogInfo);
loom_allocator_t *gGFXTextureAllocator = NULL;

namespace GFX
{


utList<AsyncLoadNote> Texture::sAsyncLoadQueue;
utList<AsyncLoadNote> Texture::sAsyncCreateQueue;
int Texture::sAsyncTextureCreateDelay = 0;
bool Texture::sAsyncThreadRunning = false;
MutexHandle Texture::sAsyncQueueMutex = NULL;
MutexHandle Texture::sTexInfoLock = NULL;
TextureInfo Texture::sTextureInfos[MAXTEXTURES];
utHashTable<utFastStringHash, TextureID> Texture::sTexturePathLookup;
bool Texture::sTextureAssetNofificationsEnabled = true;

void Texture::initialize()
{
    for (int i = 0; i < MAXTEXTURES; i++)
    {
        sTextureInfos[i].id           = i;
        sTextureInfos[i].reload       = false;
        sTextureInfos[i].asyncDispose = false;
        sTextureInfos[i].handle.idx   = bgfx::invalidHandle;
    }
    Texture::sTexInfoLock = loom_mutex_create();
    Texture::sAsyncQueueMutex = loom_mutex_create();
}

void Texture::tick()
{
    int startTime;

    //process any textures queued up for creation inside of the async load thread
    //only process a new texture after so much time has elapsed so that we don't bog the main thread down
    if(--Texture::sAsyncTextureCreateDelay <= 0)
    {
        Texture::sAsyncTextureCreateDelay = 20;
        loom_mutex_lock(Texture::sAsyncQueueMutex);
        if(!Texture::sAsyncCreateQueue.empty())
        {
            //get the note containing the information for this texture
            AsyncLoadNote threadNote = Texture::sAsyncCreateQueue.front();
            Texture::sAsyncCreateQueue.pop_front();
            loom_mutex_unlock(Texture::sAsyncQueueMutex);

            //handleAssetNotification does the actual creation of the texture data immediately below when '1' is specified
            startTime = platform_getMilliseconds();
            if(!threadNote.path.empty())
            {
                //Texture is an Asset, so Create via handleAssetNotification
                loom_asset_subscribe(threadNote.path.c_str(), Texture::handleAssetNotification, (void *)threadNote.id, 1);
                lmLog(gGFXTextureLogGroup, "Async loaded texture '%s' took %i ms to create", threadNote.path.c_str(), platform_getMilliseconds() - startTime);
            }
            else
            {
                //Texture is just a byte stream, so load the deserialized image data now
                loadImageAsset(threadNote.imageAsset, threadNote.id);
                threadNote.iaCleanup(threadNote.imageAsset);
                lmLog(gGFXTextureLogGroup, "Async loaded byte texture took %i ms to create", platform_getMilliseconds() - startTime);
            }

            //were we disposed while we were busy loading?
            loom_mutex_lock(Texture::sTexInfoLock);
            int disposeID = (!threadNote.tinfo->asyncDispose) ? -1 : threadNote.id;
            loom_mutex_unlock(Texture::sTexInfoLock);
            if(disposeID != -1)
            {
                //dispose!
                Texture::dispose(disposeID);
            }
            else
            {
                //Fire the async load complete delegate... not if we were destroyed while loading though
                threadNote.tinfo->asyncLoadCompleteDelegate.invoke();
            }    
        }
        else
        {
            loom_mutex_unlock(Texture::sAsyncQueueMutex);
        }
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

    // Make a copy of the texture so we can swizzle it safely. No need to
    // free memory, this will be freed at end of frame by bgfx.
    const bgfx::Memory *mem = bgfx::alloc(width * height * 4);
    memcpy(mem->data, data, width * height * 4);

    // Do the swizzle for D3D9 - see LOOM-1713 for details on this.
    rgbaToBgra(mem->data, width, height);

    loom_mutex_lock(Texture::sTexInfoLock);
    TextureInfo *tinfo = &sTextureInfos[id];
    if (!tinfo->reload || (tinfo->width != width) || (tinfo->height != height))
    {
        if (tinfo->texturePath.empty()) {
            lmLog(gGFXTextureLogGroup, "Create texture for bytes");
        } else {
            lmLog(gGFXTextureLogGroup, "Create texture for %s", tinfo->texturePath.c_str());
        }
        
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
        if (tinfo->texturePath.empty()) {
            lmLog(gGFXTextureLogGroup, "Updating texture from bytes");
        }
        else {
            lmLog(gGFXTextureLogGroup, "Updating texture %s", tinfo->texturePath.c_str());
        }

        bgfx::updateTexture2D(tinfo->handle, 0, 0, 0, width, height, mem);

        tinfo->width  = width;
        tinfo->height = height;

        // Fire the delegate.
        tinfo->updateDelegate.pushArgument(width);
        tinfo->updateDelegate.pushArgument(height);
        tinfo->updateDelegate.invoke();
    }

    loom_mutex_unlock(Texture::sTexInfoLock);

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

    //check if this texture already has a TextureInfo reserved for it
    loom_mutex_lock(Texture::sTexInfoLock);
    TextureID   *pid   = sTexturePathLookup.get(path);
    TextureInfo *tinfo = (pid && ((*pid >= 0) && (*pid < MAXTEXTURES))) ? &sTextureInfos[*pid] : NULL;
    if(tinfo && (tinfo->handle.idx == bgfx::invalidHandle))
    {
        tinfo = NULL;
    }
    loom_mutex_unlock(Texture::sTexInfoLock);
    if(pid)
    {
        return tinfo;
    }

    // Force it to load.
    if(loom_asset_lock(path, LATImage, 1) == NULL)
    {
        lmLogWarn(gGFXTextureLogGroup, "Unable to lock the asset for texture %s", path);
        return NULL;
    }
    loom_asset_unlock(path);

    // Get a new texture info
    tinfo = getAvailableTextureInfo(path);
    if(tinfo != NULL)
    {
        // allocate the texture handle/id
        lmLog(gGFXTextureLogGroup, "loading %s", path);

        // Now subscribe and let us load for reals.
        loom_asset_subscribe(path, Texture::handleAssetNotification, (void *)tinfo->id, 1);        
    }
    else
    {
        lmLog(gGFXTextureLogGroup, "No available texture id for %s", path);
    }
    return tinfo;
}


TextureInfo *Texture::initFromBytes(utByteArray *bytes, const char *name)
{
    TextureInfo *tinfo = NULL;
    name = (name && !name[0]) ? NULL : name;
    if(name)
    {
        //check if this texture already has a TextureInfo reserved for it
        loom_mutex_lock(Texture::sTexInfoLock);
        TextureID   *pid   = sTexturePathLookup.get(name);
        tinfo = (pid && ((*pid >= 0) && (*pid < MAXTEXTURES))) ? &sTextureInfos[*pid] : NULL;
        if(tinfo && (tinfo->handle.idx == bgfx::invalidHandle))
        {
            tinfo = NULL;
        }
        loom_mutex_unlock(Texture::sTexInfoLock);
        if(pid)
        {
            return tinfo;
        }
    }

    // Get a new texture info
    tinfo = getAvailableTextureInfo(name);
    if(tinfo == NULL)
    {
        lmLog(gGFXTextureLogGroup, "No available texture id for image bytes");
        return NULL;
    }

    //load the byte stream
    LoomAssetCleanupCallback dtor = NULL;
    loom_asset_image_t *lat = static_cast<loom_asset_image_t*>(loom_asset_imageDeserializer(bytes->getDataPtr(), bytes->getSize(), &dtor));

    if (lat == NULL) {
        lmLog(gGFXTextureLogGroup, "Unable to load image bytes");
        return NULL;
    }

    // Great, stuff real bits!
    lmLog(gGFXTextureLogGroup, "loaded image bytes - %i x %i at id %i", lat->width, lat->height, tinfo->id);

    loadImageAsset(lat, tinfo->id);

    dtor(lat);

    return tinfo;
}


int __stdcall Texture::loadTextureAsync_body(void *param)
{
    bool addToQueue;
    const char *path = NULL;

    //remain in a loop here so long as we have notes to process
    while(true)
    {
        addToQueue = true;

        //get the front of the async texture queue to process
        loom_mutex_lock(Texture::sAsyncQueueMutex);
        AsyncLoadNote threadNote = Texture::sAsyncLoadQueue.front();
        Texture::sAsyncLoadQueue.pop_front();
        loom_mutex_unlock(Texture::sAsyncQueueMutex);
        path = (!threadNote.path.empty()) ? threadNote.path.c_str() : NULL;

        //make sure we weren't disposed in the meantime... if so, just skip!
        loom_mutex_lock(Texture::sTexInfoLock);
        bool alreadyDisposed = threadNote.tinfo->asyncDispose;
        if(alreadyDisposed)
        {
            //invalidate the TextureInfo and make it available for use again
            if (!threadNote.tinfo->texturePath.empty()) 
            {
                sTexturePathLookup.erase(threadNote.tinfo->texturePath);
            }
            threadNote.tinfo->reset();
            loom_mutex_unlock(Texture::sTexInfoLock);

            //prep for below
            loom_mutex_lock(Texture::sAsyncQueueMutex);
        }
        else
        {
            loom_mutex_unlock(Texture::sTexInfoLock);
            
            //handle Asset vs ByteArray texture load
            if(path)
            {
                // Load async since we're in a background thread.
                lmLog(gGFXTextureLogGroup, "loading %s async...", path);
                loom_asset_preload(path);
                loom_thread_yield();
                loom_asset_image *lai = NULL;
                while((lai = (loom_asset_image *)loom_asset_lock(path, LATImage, 0)) == NULL)
                {
                    loom_thread_yield();
                }
                loom_asset_unlock(path);
            }
            else
            {
                //deserialize the image data from bytes
                threadNote.imageAsset = static_cast<loom_asset_image_t*>(loom_asset_imageDeserializer(threadNote.bytes->getDataPtr(), 
                                                                                                        threadNote.bytes->getSize(), 
                                                                                                        &threadNote.iaCleanup));
                if (threadNote.imageAsset == NULL) 
                {
                    lmLog(gGFXTextureLogGroup, "ERROR: Unable to deserialize image bytes!");
                    addToQueue = false;
                }
            }

            //add to the CreateQueue that happens in the main thread because bgfx cannot create textures from side threads
            loom_mutex_lock(Texture::sAsyncQueueMutex);
            if(addToQueue)
            {
                lmLog(gGFXTextureLogGroup, "Adding async loaded texture to CreateQueue: %s", ((path) ? path : "Byte Texture"));
                sAsyncCreateQueue.push_back(threadNote);            
            }
        }

        //do we have any more items to process?
        if(Texture::sAsyncLoadQueue.empty())
        {
            //flag that the async texture thread is no longer running
            Texture::sAsyncThreadRunning = false;
            loom_mutex_unlock(Texture::sAsyncQueueMutex);
            break;
        }
        loom_mutex_unlock(Texture::sAsyncQueueMutex);

        //yield to the main thread, baby!
        loom_thread_yield();
    }

    return 0;
}


TextureInfo * Texture::initFromAssetManagerAsync(const char *path)
{
    if (!path || !path[0])
    {
        lmLogError(gGFXTextureLogGroup, "Empty Path specified for initFromAssetManagerAsync()");
        return NULL;
    }

    //check if this texture already has a TextureInfo reserved for it
    //NOTE: shouldn't really happen... there is a check for this in LS that returns early there!    
    loom_mutex_lock(Texture::sTexInfoLock);
    TextureID   *pid   = sTexturePathLookup.get(path);
    TextureInfo *tinfo = (pid && ((*pid >= 0) && (*pid < MAXTEXTURES))) ? &sTextureInfos[*pid] : NULL;
    if(pid && (!tinfo || (tinfo->handle.idx == bgfx::invalidHandle)))
    {
        lmLogError(gGFXTextureLogGroup, "Invalid Texture ID or Handle returned in initFromAssetManagerAsync() for texture: %s", path);
        tinfo = NULL;
    }
    if(pid)
    {
        if(tinfo && tinfo->asyncDispose)
        {
            lmLog(gGFXTextureLogGroup, "Returning a TextureInfo that was flagged for disposal during initFromAssetManagerAsync() for texture: %s", path);
            tinfo->asyncDispose = false;
        }
        loom_mutex_unlock(Texture::sTexInfoLock);
        return tinfo;
    }
    loom_mutex_unlock(Texture::sTexInfoLock);

    // Get a new texture info
    tinfo = getAvailableTextureInfo(path);
    if(tinfo != NULL)
    {
         //build up temp struct to pass over to the aysnc load thread
        AsyncLoadNote threadNote;
        memset(&threadNote, 0, sizeof(AsyncLoadNote));
        threadNote.id = tinfo->id;
        threadNote.path = path;
        threadNote.tinfo = tinfo;

        //add this texture to async queue
        loom_mutex_lock(Texture::sAsyncQueueMutex);
        sAsyncLoadQueue.push_back(threadNote);
        if(!Texture::sAsyncThreadRunning)
        {
            //only kick the async thread if it isn't already running
            Texture::sAsyncThreadRunning = true;
            loom_thread_start(Texture::loadTextureAsync_body, NULL);
        }
        loom_mutex_unlock(Texture::sAsyncQueueMutex); 
    }
    else
    {
        lmLog(gGFXTextureLogGroup, "No available texture id for %s", path);
    }
    return tinfo;
}


TextureInfo *Texture::initFromBytesAsync(utByteArray *bytes, const char *name)
{
    TextureInfo *tinfo = NULL;
    name = (name && !name[0]) ? NULL : name;
    if(name)
    {
        //check if this texture already has a TextureInfo reserved for it
        //NOTE: shouldn't really happen... there is a check for this in LS that returns early there!    
        loom_mutex_lock(Texture::sTexInfoLock);
        TextureID   *pid   = sTexturePathLookup.get(name);
        TextureInfo *tinfo = (pid && ((*pid >= 0) && (*pid < MAXTEXTURES))) ? &sTextureInfos[*pid] : NULL;
        if(pid && (!tinfo || (tinfo->handle.idx == bgfx::invalidHandle)))
        {
            lmLogError(gGFXTextureLogGroup, "Invalid Texture ID or Handle returned in initFromBytesAsync() for texture: %s", name);
            tinfo = NULL;
        }
        if(pid)
        {
            if(tinfo && tinfo->asyncDispose)
            {
                lmLog(gGFXTextureLogGroup, "Returning a TextureInfo that was flagged for disposal during initFromBytesAsync() for texture: %s", name);
                tinfo->asyncDispose = false;
            }
            loom_mutex_unlock(Texture::sTexInfoLock);
            return tinfo;
        }
        loom_mutex_unlock(Texture::sTexInfoLock);
    }

    // Get a new texture info
    tinfo = getAvailableTextureInfo(name);
    if(tinfo != NULL)
    {
         //build up temp struct to pass over to the aysnc load thread
        AsyncLoadNote threadNote;
        memset(&threadNote, 0, sizeof(AsyncLoadNote));
        threadNote.id = tinfo->id;
        threadNote.path = "";
        threadNote.tinfo = tinfo;
        threadNote.bytes = bytes;

        //add this texture to async queue
        loom_mutex_lock(Texture::sAsyncQueueMutex);
        sAsyncLoadQueue.push_back(threadNote);
        if(!Texture::sAsyncThreadRunning)
        {
            //only kick the async thread if it isn't already running
            Texture::sAsyncThreadRunning = true;
            loom_thread_start(Texture::loadTextureAsync_body, NULL);
        }
        loom_mutex_unlock(Texture::sAsyncQueueMutex); 
    }
    else
    {
        lmLog(gGFXTextureLogGroup, "No available texture id for image bytes");
    }
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
        loom_mutex_lock(Texture::sTexInfoLock);
        bool reload = sTextureInfos[id].reload;
        loom_mutex_unlock(Texture::sTexInfoLock);
        if(reload)
            return;

        lmLogError(gGFXTextureLogGroup, "Missing image asset '%s', using %dx%d px debug checkerboard.", name, 128, 128);

        loadCheckerBoard(id);

        return;
    }

    // Great, stuff real bits!
    lmLog(gGFXTextureLogGroup, "loaded %s - %i x %i at id %i", name, lat->width, lat->height, id);

    loadImageAsset(lat, id);

    // Release lock on the asset.
    loom_asset_unlock(name);
    
    // Once we load it we don't need it any more.
    loom_asset_flush(name);
}

void Texture::loadImageAsset(loom_asset_image_t *lat, TextureID id)
{
    // See if it's over 2048 - if so, downsize to fit.
    const int          maxSize = 2048;
    void               *localBits = lat->bits;
    const bgfx::Memory *localMem = NULL;
    int                localWidth = lat->width;
    int                localHeight = lat->height;
    while (localWidth > maxSize || localHeight > maxSize)
    {
        // Allocate new bits.
        int oldWidth = localWidth, oldHeight = localHeight;
        localWidth = localWidth >> 1;
        localHeight = localHeight >> 1;
        void *oldBits = localBits;

        // This will be freed automatically. This will be inefficient for huge bitmaps but it's
        // only around for one frame.
        localMem = bgfx::alloc(localWidth * localHeight * 4);
        localBits = localMem->data;

        lmLog(gGFXTextureLogGroup, "   - Too big! Downsampling to %dx%d", localWidth, localHeight);

        bitmapExtrudeRGBA_c(oldBits, localBits, oldHeight, oldWidth);
    }

    // Perform the actual load.
    load((uint8_t *)localBits, (uint16_t)localWidth, (uint16_t)localHeight, id);
}

void Texture::reset()
{
    for (int i = 0; i < MAXTEXTURES; i++)
    {
        loom_mutex_lock(Texture::sTexInfoLock);
        TextureInfo *tinfo = &sTextureInfos[i];

        // Ignore invalid entries.
        if (tinfo->handle.idx != bgfx::invalidHandle)
        {
            const char *path = tinfo->texturePath.c_str();
            lmLog(gGFXTextureLogGroup, "Reloading texture for path %s", path);

            //bgfx::destroyTexture(tinfo->handle);
            tinfo->handle.idx = bgfx::invalidHandle;
            tinfo->reload = false;
            tinfo->asyncDispose = false;
            loom_mutex_unlock(Texture::sTexInfoLock);

            //force it to be loaded from disk
            loom_asset_lock(path, LATImage, 1);
            loom_asset_unlock(path);

            //do actual texture creation/update
            handleAssetNotification((void *)tinfo->id, path);
        }
        else
        {
            loom_mutex_unlock(Texture::sTexInfoLock);            
        }
    }
}


void Texture::dispose(TextureID id)
{
    if ((id < 0) || (id >= MAXTEXTURES))
    {
        return;
    }

    loom_mutex_lock(Texture::sTexInfoLock);
    TextureInfo *tinfo = &sTextureInfos[id];

    // If the texture isn't valid ignore it.
    if (tinfo->handle.idx != bgfx::invalidHandle)
    {
        //if texture is still loading or is inside of the loading queue, we can't dispose of it now, 
        //but need to flag it for disposal in the thread
        if(tinfo->handle.idx == MARKEDTEXTURE)
        {
            sTextureInfos[id].asyncDispose = true;
            loom_mutex_unlock(Texture::sTexInfoLock);
            return;
        }

        //TODO: LOOM-1653, we really shouldn't be holding a copy of the texture data in the
        // asset system until we dispose
        if (!tinfo->texturePath.empty()) {
            loom_asset_unsubscribe(tinfo->texturePath.c_str(), handleAssetNotification, (void *)id);
            loom_asset_flush(tinfo->texturePath.c_str());

            // Reset the hash, too
            sTexturePathLookup.erase(tinfo->texturePath);
        }

        // And erase backing state.
        bgfx::destroyTexture(tinfo->handle);
        tinfo->reset();
    }
    loom_mutex_unlock(Texture::sTexInfoLock);
}
}
