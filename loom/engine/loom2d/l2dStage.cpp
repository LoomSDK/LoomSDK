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
#include "loom/engine/loom2d/l2dStage.h"
#include "loom/common/config/applicationConfig.h"
#include "loom/common/core/log.h"

lmDefineLogGroup(gStageLogGroup, "Stage", 1, LoomLogInfo);

extern SDL_Window *gSDLWindow;

namespace Loom2D
{

Stage *Stage::smMainStage = NULL;
NativeDelegate Stage::_RenderStageDelegate;
bool Stage::sizeDirty = true;
bool Stage::visDirty = true;

Stage::Stage()
{
    smMainStage = this;
    sdlWindow = gSDLWindow;
    updateFromConfig();
    SDL_GL_GetDrawableSize(sdlWindow, &stageWidth, &stageHeight);
    noteNativeSize(stageWidth, stageHeight);
}

Stage::~Stage()
{
    smMainStage = NULL;
}

void Stage::updateFromConfig()
{
    SDL_Window *sdlWindow = gSDLWindow;
    SDL_SetWindowTitle(sdlWindow, LoomApplicationConfig::displayTitle().c_str());
    if (smMainStage != NULL) {
        smMainStage->setOrientation(LoomApplicationConfig::displayOrientation().c_str());
    }
    if (sizeDirty) {
        int width = LoomApplicationConfig::displayWidth();
        int height = LoomApplicationConfig::displayHeight();
        SDL_SetWindowSize(sdlWindow, width, height);
        sizeDirty = false;
    }
    if (visDirty && smMainStage != NULL) {
        smMainStage->show();
        visDirty = false;
    }
}

void Stage::show()
{
    SDL_ShowWindow(sdlWindow);
}

void Stage::hide()
{
    SDL_HideWindow(sdlWindow);
}

void Stage::render(lua_State *L)
{
    GFX::Graphics::setNativeSize(getWidth(), getHeight());
    GFX::Graphics::beginFrame();

    updateLocalTransform();

    lualoom_pushnative<Stage>(L, this);

    renderState.alpha          = alpha;
    renderState.cachedClipRect = (unsigned short)-1;
    renderState.blendMode      = blendMode;

    renderChildren(L);

    lua_pop(L, 1);

    GFX::Graphics::endFrame();

    /* Update the screen! */
    SDL_GL_SwapWindow(sdlWindow);
}
}
