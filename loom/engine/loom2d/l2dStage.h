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

#include <SDL.h>
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"

namespace Loom2D
{

class Stage : public DisplayObjectContainer
{
protected:

public:

    Stage();
    ~Stage();

    static Stage *smMainStage;

    // The SDL window we're working with.
    SDL_Window *sdlWindow;
    int stageWidth;
    int stageHeight;

    // Rendering interface.
    void invokeRenderStage()
    {
        _RenderStageDelegate.invoke();
    }

    LOOM_STATICDELEGATE(RenderStage);

    static int renderStage(lua_State *L);

    void render(lua_State *L);

    // Interface for window state.
    LOOM_DELEGATE(OrientationChange);
    LOOM_DELEGATE(SizeChange);

    void noteNativeSize(int width, int height)
    {
        stageWidth = width;
        stageHeight = height;
        _SizeChangeDelegate.pushArgument(width);
        _SizeChangeDelegate.pushArgument(height);
        _SizeChangeDelegate.invoke();
    }

    void setWindowTitle(const char *title);
    const char *getWindowTitle();

    int getOrientation();

    int getWidth()
    {
        return stageWidth;
    }

    int getHeight()
    {
        return stageHeight;
    }

    void resize(int width, int height)
    {
        SDL_SetWindowSize(sdlWindow, width, height);
        noteNativeSize(width, height);
    }

    void toggleFullscreen();
    bool isFullScreen();

    // Interface for input events.
    LOOM_DELEGATE(TouchBegan);
    LOOM_DELEGATE(TouchMoved);
    LOOM_DELEGATE(TouchEnded);
    LOOM_DELEGATE(TouchCancelled);
    LOOM_DELEGATE(KeyBackClicked);
    LOOM_DELEGATE(KeyMenuClicked);
    LOOM_DELEGATE(KeyUp);
    LOOM_DELEGATE(KeyDown);
    LOOM_DELEGATE(MenuKey);
    LOOM_DELEGATE(BackKey);
    LOOM_DELEGATE(ScrollWheelYMoved);
    LOOM_DELEGATE(Accelerate);
};
}
