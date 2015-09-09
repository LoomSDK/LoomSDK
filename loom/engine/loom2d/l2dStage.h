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
#include "loom/graphics/gfxVectorRenderer.h"
#include <SDL.h>

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
    }

    inline int getVectorQuality() const
    {
        return GFX::VectorRenderer::quality;
    }
    inline void setVectorQuality(int vectorQuality)
    {
        if (vectorQuality != GFX::VectorRenderer::quality)
        {
            int prevQuality = GFX::VectorRenderer::quality;
            GFX::VectorRenderer::quality = vectorQuality;
            GFX::VectorRenderer::reset();
            // If a stencil buffer is required, update textures so they can be converted
            if (!(prevQuality & GFX::VectorRenderer::QUALITY_STENCIL_STROKES) && (vectorQuality & GFX::VectorRenderer::QUALITY_STENCIL_STROKES)) {
                GFX::Texture::validate();
            }
        }
    }

    inline void setTessellationQuality(int value)
    {
        if (value < 1 || value > 10)
            return;

        GFX::VectorRenderer::tessellationQuality = value;
    }
    inline int getTessellationQuality() const
    {
        return GFX::VectorRenderer::tessellationQuality;
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
    LOOM_DELEGATE(ControllerAxisMoved);
    LOOM_DELEGATE(ControllerButtonDown);
    LOOM_DELEGATE(ControllerButtonUp);
    LOOM_DELEGATE(ControllerAdded);
    LOOM_DELEGATE(ControllerRemoved);
};
}
