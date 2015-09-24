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


#include "loom/engine/loom2d/l2dStage.h"
#include "loom/engine/bindings/loom/lmApplication.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/common/config/applicationConfig.h"
#include "loom/common/core/log.h"
#include "loom/script/runtime/lsProfiler.h"

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
    pendingResize = true;
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
    
    if (smMainStage != NULL) 
    {
        smMainStage->setOrientation(LoomApplicationConfig::displayOrientation().c_str());
    }
    
    if (sizeDirty) 
    {
        int width = LoomApplicationConfig::displayWidth();
        int height = LoomApplicationConfig::displayHeight();
        SDL_SetWindowSize(sdlWindow, width, height);
        sizeDirty = false;
    }
    
    if (visDirty && smMainStage != NULL) 
    {
        smMainStage->show();
        visDirty = false;
    }
}

void Stage::firePendingResizeEvent()
{
    // Fire a resize event.
    if(smMainStage && pendingResize)
    {
        // Fire a resize event. We do this at startup so apps can size them
        // selves properly before first render.
        int winWidth, winHeight;
        SDL_GetWindowSize(gSDLWindow, &winWidth, &winHeight);
        SDL_GL_GetDrawableSize(gSDLWindow, &winWidth, &winHeight);
        smMainStage->noteNativeSize(winWidth, winHeight);
        GFX::Graphics::setNativeSize(winWidth, winHeight);
        pendingResize = false;
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
    LOOM_PROFILE_START(stageRenderBegin);
    GFX::Graphics::setNativeSize(getWidth(), getHeight());
    GFX::Graphics::beginFrame();
    
    updateLocalTransform();

    lualoom_pushnative<Stage>(L, this);

    renderState.alpha          = alpha;
    renderState.clipRect       = Loom2D::Rectangle(0, 0, -1, -1);
    renderState.blendMode      = blendMode;
    LOOM_PROFILE_END(stageRenderBegin);


    LOOM_PROFILE_START(stageRenderDisplayList);
    renderChildren(L);
    LOOM_PROFILE_END(stageRenderDisplayList);

    
    LOOM_PROFILE_START(stageRenderEnd);
    lua_pop(L, 1);
    GFX::Graphics::endFrame();
    LOOM_PROFILE_END(stageRenderEnd);

    LSLuaState *vm = LoomApplication::getReloadQueued() ? NULL : LoomApplication::getRootVM();
    LOOM_PROFILE_START(garbageCollection);
    if (vm) lualoom_gc_update(vm->VM());
    LOOM_PROFILE_END(garbageCollection);

    LOOM_PROFILE_START(finishRender);
    GFX::Graphics::context()->glFinish();
    LOOM_PROFILE_END(finishRender);

    LOOM_PROFILE_START(waitForVSync);
    /* Update the screen! */
    SDL_GL_SwapWindow(sdlWindow);
    LOOM_PROFILE_END(waitForVSync);
}
}
