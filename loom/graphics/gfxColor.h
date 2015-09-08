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

#include <inttypes.h>

namespace GFX
{
    // Typedefs for raw color data
    typedef uint32_t rgba_t;
    typedef uint8_t channel_t;

    /*
     * A utility struct for storing color values and converting between
     * float RGBA values and hex values
     */
    struct Color
    {
        float r;
        float g;
        float b;
        float a;

        Color(float R, float G, float B, float A);
        Color(rgba_t color);

        rgba_t getHex() const;
    };
}
