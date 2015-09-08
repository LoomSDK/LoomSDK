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

#include "loom/graphics/gfxBitmapData.h"

#include "loom/graphics/gfxGraphics.h"
#include "loom/common/core/allocator.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"
#include "loom/common/core/log.h"
#include "loom/common/core/string.h"

#include "stb_image_write.h"
#include <math.h>
#include <string.h>


const int DATA_BPP = 4;

namespace GFX
{
    BitmapData::BitmapData(size_t width, size_t height)
    : w(width)
    , h(height)
    , data((unsigned char*)lmAlloc(NULL, DATA_BPP * w * h))
    {
    }

    BitmapData::~BitmapData()
    {
        if (data != NULL)
        {
            lmFree(NULL, data);
        }
    }

    void BitmapData::save(const char* path) const
    {
        const char* ext = strrchr(path, '.');
        if (ext == NULL)
        {
            lmLog(gGFXLogGroup, "No extension in path %s. Unable to detect file format.", path);
            return;
        }

        if (stricmp(ext, ".bmp") == 0)
        {
            if (stbi_write_bmp(path, w, h, DATA_BPP, data) != 1)
            {
                lmLog(gGFXLogGroup, "Unable to write image %s", path);
            }
            return;
        }

        if (stricmp(ext, ".png") == 0)
        {
            if (stbi_write_png(path, w, h, DATA_BPP, data, w * DATA_BPP) != 1)
            {
                lmLog(gGFXLogGroup, "Unable to write image %s", path);
            }
            return;
        }

        if (stricmp(ext, ".tga") == 0)
        {
            if (stbi_write_tga(path, w, h, DATA_BPP, data) != 1)
            {
                lmLog(gGFXLogGroup, "Unable to write image %s", path);
            }
            return;
        }

        lmLog(gGFXLogGroup, "Unsupported image extension in path %s.", path);
    }

    void BitmapData::setPixel(size_t x, size_t y, rgba_t color)
    {
        if (x < 0 || x >= w ||
            y < 0 || y >= h)
            return;

        rgba_t* pixelptr = reinterpret_cast<rgba_t*>(data);
        pixelptr[x + y * w] = convertHostToBEndian(color);
    }

    rgba_t BitmapData::getPixel(size_t x, size_t y)
    {
        if (x < 0 || x >= w ||
            y < 0 || y >= h)
            return 0;

        rgba_t* pixelptr = reinterpret_cast<rgba_t*>(data);
        return convertHostToBEndian(pixelptr[x + y * w]);
    }

    const channel_t* BitmapData::getData() const
    {
        return data;
    }

    int BitmapData::getBpp() const
    {
        return DATA_BPP;
    }

    TextureInfo* BitmapData::createTextureInfo() const
    {
        TextureInfo* info = Texture::getAvailableTextureInfo(NULL);
        return Texture::load(data, w, h, info->id);
    }

    const BitmapData* BitmapData::fromFramebuffer()
    {
        int w = GFX::Graphics::getWidth();
        int h = GFX::Graphics::getHeight();

        // Sanity check
        if (w == 0 || h == 0) {
            lmLog(gGFXLogGroup, "Graphics dimensions invalid %d x %d: %s", w, h, SDL_GetError());
            return NULL;
        }

        BitmapData* result = lmNew(NULL) BitmapData(w, h);

        if (result == NULL) {
            lmLog(gGFXLogGroup, "Unable to allocate memory for screenshot pixel data buffer");
            return NULL;
        }

        GFX::GL_Context* ctx = GFX::Graphics::context();

        utByteArray tmp;
        tmp.resize(result->w * result->h * DATA_BPP);

        ctx->glPixelStorei(GL_PACK_ALIGNMENT, 1);
        ctx->glReadPixels(0, 0, result->w, result->h, GL_RGBA, GL_UNSIGNED_BYTE, tmp.getDataPtr());

        for (int i = result->h - 1; i >= 0; i--)
        {
            memcpy(result->data + (result->h - 1 - i) * result->w * DATA_BPP, (channel_t*)tmp.getDataPtr() + i * result->w * DATA_BPP, result->w * DATA_BPP);
        }

        return result;
    }

    const BitmapData* BitmapData::fromAsset(const char* name)
    {
        loom_asset_image_t* img = static_cast<loom_asset_image_t*>(loom_asset_lock(name, LATImage, 1));
        loom_asset_unlock(name);

        if (img == NULL)
            return NULL;

        BitmapData* result = lmNew(NULL) BitmapData(
            (size_t)img->width,
            (size_t)img->height
        );

        if (result == NULL) {
            lmLog(gGFXLogGroup, "Unable to allocate memory for BitmapData asset data");
            return NULL;
        }

        memcpy(result->data, img->bits, img->width * img->height * DATA_BPP);

        return result;
    }

    lmscalar BitmapData::compare(const BitmapData* a, const BitmapData* b)
    {
        lmscalar result = 0;
        if (a->w != b->w || a->h != b->h)
            return (lmscalar)1.0;

        rgba_t* pixelptr_a = reinterpret_cast<rgba_t*>(a->data);
        rgba_t* pixelptr_b = reinterpret_cast<rgba_t*>(b->data);

        for (size_t i = 0; i < a->w * a->h; i++)
        {
            if (pixelptr_a[i] != pixelptr_b[i])
                result += 1;
        }

        return result / (a->w * a->h);
    }

    BitmapData* BitmapData::diff(const BitmapData* a, const BitmapData* b)
    {
        if (a->w != b->w || a->h != b->h)
            return NULL;

        BitmapData* result = lmNew(NULL) BitmapData(
            (size_t)a->w,
            (size_t)a->h
        );

        if (result == NULL) {
            lmLog(gGFXLogGroup, "Unable to allocate memory for BitmapData diff result");
            return NULL;
        }

        rgba_t* pixelptr_a = reinterpret_cast<rgba_t*>(a->data);
        rgba_t* pixelptr_b = reinterpret_cast<rgba_t*>(b->data);
        rgba_t* resultptr = reinterpret_cast<rgba_t*>(result->data);

        for (size_t i = 0; i < a->w * a->h; i++)
        {
            Color ap(convertHostToBEndian(pixelptr_a[i]));
            Color bp(convertHostToBEndian(pixelptr_b[i]));
            Color rp(fabsf(ap.r - bp.r), fabsf(ap.g - bp.g), fabsf(ap.b - bp.b), 1.0f);
            rgba_t a = rp.getHex();
            resultptr[i] = convertBEndianToHost(a);
        }

        return result;
    }
}
