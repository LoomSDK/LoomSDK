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

#include "bx/bx.h"
#include "loom/common/platform/platform.h"
#include "loom/graphics/gfxShaders.h"

namespace GFX
{

const uint8_t *GetFragmentShaderPosTex(int& size)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include "../../sdk/shaders/fs_postex_hlsl.cpp"
#else
#include "../../sdk/shaders/fs_postex_glsl.cpp"
#endif

    size = sizeof(gfShaderPosTex);
    return gfShaderPosTex;
}

const uint8_t *GetFragmentShaderPosColorTex(int& size)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include "../../sdk/shaders/fs_poscolortex_hlsl.cpp"
#else
#include "../../sdk/shaders/fs_poscolortex_glsl.cpp"
#endif
    size = sizeof(gfShaderPosColorTex);
    return gfShaderPosColorTex;
}

const uint8_t *GetVertexShaderPosColorTex(int& size)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include "../../sdk/shaders/vs_poscolortex_hlsl.cpp"
#else
#include "../../sdk/shaders/vs_poscolortex_glsl.cpp"
#endif
    size = sizeof(gvShaderPosColorTex);
    return gvShaderPosColorTex;
}

const uint8_t *GetVertexShaderPosTex(int& size)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include "../../sdk/shaders/vs_postex_hlsl.cpp"
#else
#include "../../sdk/shaders/vs_postex_glsl.cpp"
#endif
    size = sizeof(gvShaderPosTex);
    return gvShaderPosTex;
}

}
