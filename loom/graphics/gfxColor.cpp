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

#include "loom/graphics/gfxColor.h"

namespace GFX
{
    Color::Color(float R, float G, float B, float A)
        : r(R)
        , g(G)
        , b(B)
        , a(A)
    {
    }

    Color::Color(unsigned int color)
    {
        r = ((color & 0xFF000000) >> 24) / 255.0f;
        g = ((color & 0x00FF0000) >> 16) / 255.0f;
        b = ((color & 0x0000FF00) >> 8) / 255.0f;
        a = (color & 0x000000FF) / 255.0f;
    }

    unsigned int Color::getHex() const
    {
        unsigned char R = (unsigned char)(r * 255);
        unsigned char G = (unsigned char)(g * 255);
        unsigned char B = (unsigned char)(b * 255);
        unsigned char A = (unsigned char)(a * 255);
        return (R << 24) + (G << 16) + (B << 8) + A;
    }
}
