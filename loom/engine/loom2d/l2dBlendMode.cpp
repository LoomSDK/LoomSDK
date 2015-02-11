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

#include "loom/engine/loom2d/l2dBlendMode.h"

#include "OpenGL/OpenGL.h"
#include "OpenGL/gl.h"


namespace Loom2D
{
unsigned int BlendMode::_blendFunctions[BlendMode::NUM_BLEND_FUNCTIONS][2] =
{
    { GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA},        //AUTO (same as NORMAL)
    { GL_ONE, GL_ZERO},                             //NONE
    { GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA},        //NORMAL
    { GL_SRC_ALPHA, GL_DST_ALPHA},                  //ADD
    { GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA},        //MULTIPLY
    { GL_SRC_ALPHA, GL_ONE},                        //SCREEN
    { GL_ZERO, GL_ONE_MINUS_SRC_ALPHA},             //ERASE
    { GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA}         //BELOW
};
}
