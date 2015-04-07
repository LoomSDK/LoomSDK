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

    static bool sizeDirty;
    static bool visDirty;

    // The SDL window we're working with.
    SDL_Window *sdlWindow;
    int stageWidth;
    int stageHeight;
    utString orientation;
    bool pendingResize;

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

    void firePendingResizeEvent();

    void noteNativeSize(int width, int height)
    {
        stageWidth = width;
        stageHeight = height;
        _SizeChangeDelegate.pushArgument(width);
        _SizeChangeDelegate.pushArgument(height);
        _SizeChangeDelegate.invoke();
    }

    static void updateFromConfig();
    void show();
    void hide();

    void setWindowTitle(const char *title);
    const char *getWindowTitle();

    inline const char* getOrientation() const
    {
        return orientation.c_str();
    }
    inline void setOrientation(const char* orient)
    {
        orientation = orient;
        if (strcmp(orientation.c_str(), "portrait") == 0) {
            SDL_SetHint(SDL_HINT_ORIENTATIONS, "Portrait");
        }
        else if (strcmp(orientation.c_str(), "landscape") == 0)
        {
            SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
        }
        else if (strcmp(orientation.c_str(), "auto") == 0)
        {
            SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight Portrait");
        }
        else
        {
            lmAssert(false, "Unknown orientation value: %s", orientation.c_str());
        }
        _OrientationChangeDelegate.pushArgument(orientation.c_str());
        _OrientationChangeDelegate.invoke();
    }

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
        SDL_GL_GetDrawableSize(sdlWindow, &stageWidth, &stageHeight);
        noteNativeSize(stageWidth, stageHeight);
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
