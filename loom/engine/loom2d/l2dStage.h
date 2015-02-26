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

#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"

namespace Loom2D
{
class Stage : public DisplayObjectContainer
{
public:

    Stage();
    ~Stage();

    static Stage *smMainStage;

    // Rendering interface.
    static void invokeRenderStage()
    {
        _RenderStageDelegate.invoke();
    }

    LOOM_STATICDELEGATE(RenderStage);

    static int renderStage(lua_State *L);

    void render(lua_State *L);

    // Interface for window state.
    LOOM_DELEGATE(OrientationChange);
    LOOM_DELEGATE(SizeChange);

    void setWindowTitle(const char *title);
    const char *getWindowTitle();

    int getOrientation();

    int getWidth();
    int getHeight();

    void resize(int width, int height);

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
