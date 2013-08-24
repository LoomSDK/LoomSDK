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
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"

#include "stb_image.h"

#ifdef _MSC_VER
#define stricmp    _stricmp
#endif

#if LOOM_PLATFORM_IS_APPLE == 1 || ANDROID_NDK || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
#define stricmp    strcasecmp //I feel dirty.
#endif

static loom_allocator_t *gImageAssetAllocator = NULL;
static loom_logGroup_t  gImageAssetGroup      = { "imageAsset", 1 };

void loom_asset_registerImageAsset()
{
    gImageAssetAllocator = loom_allocator_getGlobalHeap();
    loom_asset_registerType(LATImage, loom_asset_imageDeserializer, loom_asset_identifyImage);
}


int loom_asset_identifyImage(const char *extension)
{
    if (!stricmp(extension, "jpg"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "jpeg"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "bmp"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "png"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "psd"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "pic"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "tga"))
    {
        return LATImage;
    }
    if (!stricmp(extension, "gif"))
    {
        return LATImage;
    }
    return 0;
}


void *loom_asset_imageDeserializer(void *buffer, size_t bufferLen)
{
    loom_asset_image_t *img = lmAlloc(gImageAssetAllocator, sizeof(loom_asset_image_t));

    img->bits = stbi_load_from_memory((const stbi_uc *)buffer, (int)bufferLen, &img->width, &img->height, &img->bpp, 4);
    if (!img->bits)
    {
        lmLogError(gImageAssetGroup, "Image load failed due to this cryptic reason: %s", stbi_failure_reason());
        lmFree(gImageAssetAllocator, img);
        return 0;
    }
    return img;
}
