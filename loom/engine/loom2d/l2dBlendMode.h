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

#include <SDL_opengl.h>
#include "loom/common/core/assert.h"

namespace Loom2D
{
class BlendMode
{
public:
    /** 
     *  An enumeration that defines the supported visual blend mode effects
     */
    enum
    {
        /** Inherits the blend mode from this display object's parent. */
        AUTO        = 0,
        
        /** Deactivates blending, i.e. disabling any transparency. */
        NONE        = 1,
        
        /** The display object appears in front of the background. */
        NORMAL      = 2,
        
        /** Adds the values of the colors of the display object to the colors of its background. */
        ADD         = 3,
        
        /** Multiplies the values of the display object colors with the the background color. */
        MULTIPLY    = 4,

        /** Multiplies the complement (inverse) of the display object color with the complement of 
          * the background color, resulting in a bleaching effect. */
        SCREEN      = 5,
        
        /** Erases the background when drawn on a RenderTexture. */
        ERASE       = 6,

        /** Draws under/below existing objects; useful especially on RenderTextures. */
        BELOW       = 7,

        /** Constant for Number of Blend Functions */
        NUM_BLEND_FUNCTIONS
    };


    //Returns the numerical blend function value based on the blend mode string
    static void BlendFunction(int mode, unsigned int &srcBlend, unsigned int &dstBlend)
    {
        // TODO: Log out of bounds.
        if(mode < 0)
            mode = 0;
        if(mode >= NUM_BLEND_FUNCTIONS)
            mode = NUM_BLEND_FUNCTIONS - 1;

        srcBlend = _blendFunctions[mode][0];
        dstBlend = _blendFunctions[mode][1];
    }

private:
    //Array associating the full Blend Functions to the Blend Mode enumeration
    static unsigned int _blendFunctions[NUM_BLEND_FUNCTIONS][2];
};
}

