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


#ifndef _ASSETS_ASSETSIMAGE_H_
#define _ASSETS_ASSETSIMAGE_H_

#ifdef __cplusplus
extern "C" {
#endif

#define LATImage    LOOM_FOURCC('I', 'M', 'G', 1)

// correspond to the easyexif Orientation field values
#define IMAGE_ORIENTATION_UNSPECIFIED 0
#define IMAGE_ORIENTATION_UPPER_LEFT 1
#define IMAGE_ORIENTATION_LOWER_RIGHT 3
#define IMAGE_ORIENTATION_UPPER_RIGHT 6
#define IMAGE_ORIENTATION_LOWER_LEFT 8

typedef struct loom_asset_image
{
    int  width, height, bpp;

    // see IMAGE_ORIENTATION values above
    int orientation;

    void *bits;

} loom_asset_image_t;

void loom_asset_registerImageAsset();
int loom_asset_identifyImage(const char *path);
void *loom_asset_imageDeserializer(void *buffer, size_t bufferLen, LoomAssetCleanupCallback *dtor);

#ifdef __cplusplus
};
#endif
#endif
