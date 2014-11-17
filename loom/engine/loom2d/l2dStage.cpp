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


#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/internal/bgfx/include/bgfx.h"
#include "loom/engine/loom2d/l2dStage.h"

namespace Loom2D
{
NativeDelegate Stage::_RenderStageDelegate;

float Stage::mtxProjection[16];
float Stage::mtxModelView[16];

void Stage::render(lua_State *L)
{
    // set the stages view, will be used when clearing, etc
    GFX::Graphics::setView(_view);

    GFX::Graphics::setViewTransform(mtxModelView, mtxProjection);

    GFX::Graphics::beginFrame();

    // only clear the stage if it is at view 0
    if (_view == 0)
    {
        bgfx::setViewClear(_view
                           , BGFX_CLEAR_COLOR_BIT | BGFX_CLEAR_DEPTH_BIT
                           , GFX::Graphics::getFillColor()
                           , 1.0f
                           , 0
                           );
    }

    updateLocalTransform();

    lualoom_pushnative<Stage>(L, this);

    renderState.alpha          = alpha;
    renderState.cachedClipRect = (unsigned short)-1;
    renderState.blendMode      = blendMode;


    renderChildren(L);

    lua_pop(L, 1);

    GFX::Graphics::endFrame();
}
}
