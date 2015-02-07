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
#include <SDL_opengl.h>
#include <stdint.h>
#include "loom/common/core/assert.h"

namespace GFX
{

    
    typedef struct GL_Context
    {
#define SDL_PROC(ret, func, params) ret (*func) params;
#include "gfxGLES2EntryPoints.h"
#undef SDL_PROC
    } GL_Context;


/** 
  *  Graphics subsystem class in charge of initializing bgfx graphics and handling context loss
  */    
class Graphics
{

public:
    
    static GL_Context *context()
    {
        return &_context;
    }

    static void initialize();

    static bool isInitialized()
    {
        return sInitialized;
    }

    static void reset(int width, int height, uint32_t flags = 0);

    static void shutdown();

    static void beginFrame();

    static void endFrame();

    static void handleContextLoss();

    static inline uint32_t getCurrentFrame() { return sCurrentFrame; }

    static inline int getWidth() { return sWidth; }
    static inline int getHeight() { return sHeight; }

    static void setViewTransform(float *view, float *proj);

    static void setDebug(int flags);
    static void screenshot(const char *path);
    static void setFillColor(int color);
    static int getFillColor();

    // Set the clip rect and return an ID referencing it that is valid
    // for the current frame. This can be used in the other setClipRect
    // overload to save on setup overhead. Note you must set the cliprect
    // before every bgfx::submit call.
    static int setClipRect(int x, int y, int width, int height);
    static void setClipRect(int cached);

    // Render with no cliprect.
    static void clearClipRect();

private:

    // Once the Graphics system is initialized, this will be true!
    static bool sInitialized;

    // If we're currently in a OpenGL context loss situation (the application has changed orientation, etc), 
    // this will be true.  Once we're recovering the graphics subsystem will need to recreate vertex/index buffers, 
    // texture resources, etc
    static bool sContextLost;    

    // The current width of the graphics device
    static int sWidth;

    // The current height of the graphics device
    static int sHeight;

    // The flags used to create the graphics device( see bgfx.h BGFX_RESET_ for a list of flags )
    static uint32_t sFlags;

    // The current fill color used when clearing the color buffer
    static int sFillColor;

    // The current view number being rendered
    static int sView;

    // The current frame counter
    static uint32_t sCurrentFrame;

    // Opaque platform data, such as HWND
//    static void *sPlatformData[3];

    // Internal method used to initialize platform data 
//    static void initializePlatform();

    // If set, at next opportunity we will store a screenshot to this path and clear it.
    static char pendingScreenshot[1024];
    
    static GL_Context _context;

};
}
