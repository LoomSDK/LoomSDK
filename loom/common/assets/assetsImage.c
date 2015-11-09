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
#include "loom/common/core/assert.h"
#include "loom/common/core/string.h"
#include "loom/common/assets/assets.h"
#include "loom/common/assets/assetsImage.h"

#include "loom/common/core/allocator.h"
#define STBI_MALLOC(sz)    lmAlloc(NULL, sz)
#define STBI_REALLOC(p,sz) lmRealloc(NULL, p, sz)
#define STBI_FREE(p)       lmFree(NULL, p)
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

extern loom_allocator_t *gAssetAllocator;
static loom_logGroup_t gImageAssetGroup = { "imageAsset", 1 };

int exifinfo_parse_orientation(const unsigned char *buf, unsigned len);

void loom_asset_registerImageAsset()
{
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

void loom_asset_imageDtor(void *bits)
{
    loom_asset_image_t *img = (loom_asset_image_t*)bits;
    stbi_image_free(img->bits);
    lmFree(gAssetAllocator, bits);
}

void *loom_asset_imageDeserializer( void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor )
{
   loom_asset_image_t *img;

   lmAssert(buffer != NULL, "buffer should not be null");

   img = (loom_asset_image_t*)lmAlloc(gAssetAllocator, sizeof(loom_asset_image_t));

    // parse any orientation info from exif format
   img->orientation = exifinfo_parse_orientation(buffer, bufferLen);

   img->bits = stbi_load_from_memory((const stbi_uc *)buffer, (int)bufferLen, &img->width, &img->height, &img->bpp, 4);
   
   *dtor = loom_asset_imageDtor;
   
   if(!img->bits)
   {
      lmLogError(gImageAssetGroup, "Image load failed due to this cryptic reason: %s", stbi_failure_reason());
      lmFree(gAssetAllocator, img);
      return 0;
   }
   
   lmLogDebug(gImageAssetGroup, "Allocated %d bytes for an image!", img->width * img->height * 4);
   
   return img;
}
