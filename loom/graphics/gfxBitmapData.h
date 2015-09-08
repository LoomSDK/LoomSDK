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

#include "loom/common/utils/utCommon.h"
#include "loom/graphics/gfxColor.h"
#include "loom/graphics/gfxTexture.h"

namespace GFX
{
/*
 * This class is a utility to load and compare data of images. This is not meant
 * for general use, but rather as a testing utility.
 *
 * BitmapData can be loaded from the current framebuffer or from an asset.
 * Then this data can be compared and get a numeric result or a diff image can
 * be generated.
 */
class BitmapData
{
private:
    size_t w;
    size_t h;

    channel_t* data;

    // Private constructor. Use only static methods for construction.
    BitmapData(size_t width, size_t height);

public:

    ~BitmapData();

    // Saves the loaded data to a file. Supported file formats are BMP, PNG and TGA.
    void save(const char* path) const;

    void setPixel(size_t x, size_t y, rgba_t color);
    rgba_t getPixel(size_t x, size_t y);

    const channel_t* getData() const;
    int getBpp() const;

    TextureInfo* createTextureInfo() const;

    // Loads data from the current framebuffer
    static const BitmapData* fromFramebuffer();
    // Loads data from an asset
    static const BitmapData* fromAsset(const char* name);

    // Returns a value on interval (0,1) that reperesents the ratio of pixels that are the same
    // within a given tolerance.
    static lmscalar compare(const BitmapData* a, const BitmapData* b);

    // Generates a new BitmapData where each pixel has been substracted between a and b
    static BitmapData* diff(const BitmapData* a, const BitmapData* b);
};
}
