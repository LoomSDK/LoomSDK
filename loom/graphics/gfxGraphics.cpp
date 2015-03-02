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

#include <math.h>
#define HAVE_M_PI

#include <SDL.h>

#include "loom/common/platform/platform.h"
#include "loom/common/core/log.h"

#include "loom/graphics/gfxTexture.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxMath.h"

namespace GFX
{
    lmDefineLogGroup(gGFXLogGroup, "GFX", 1, LoomLogInfo);

    bool Graphics::sInitialized = false;

    // start with context loss as flagged so resources are created
    bool Graphics::sContextLost = true;

    int Graphics::sWidth      = 0;
    int Graphics::sHeight     = 0;
    uint32_t Graphics::sFlags = 0xFFFFFFFF;
    int Graphics::sFillColor  = 0x000000FF;
    int Graphics::sView       = 0;

    uint32_t Graphics::sCurrentFrame = 0;

    char Graphics::pendingScreenshot[1024] = { 0, };

    extern SDL_GLContext context;
    GL_Context Graphics::_context;
    
    static int LoadContext(GL_Context * data)
    {
#if SDL_VIDEO_DRIVER_UIKIT
#define __SDL_NOGETPROCADDR__
#elif SDL_VIDEO_DRIVER_ANDROID
#define __SDL_NOGETPROCADDR__
#elif SDL_VIDEO_DRIVER_PANDORA
#define __SDL_NOGETPROCADDR__
#endif
        
#if defined __SDL_NOGETPROCADDR__
#define SDL_PROC(ret,func,params) data->func=func;
#else
#define SDL_PROC(ret,func,params) \
do { \
void **tmp = (void**)&data->func; \
*tmp = SDL_GL_GetProcAddress(#func); \
if ( ! data->func ) { \
return SDL_SetError("Couldn't load GL function %s: %s\n", #func, SDL_GetError()); \
} \
} while ( 0 );
#endif /* _SDL_NOGETPROCADDR_ */
        
#include "gfxGLES2EntryPoints.h"
#undef SDL_PROC
        return 0;
    }

void Graphics::initialize()
{
    LoadContext(&_context);

    //context()->glDebugMessageCallback(gldebughandler, 0);

    // initialize the static Texture initialize
    Texture::initialize();

    // initialize the static QuadRenderer initialize
    QuadRenderer::initialize();

    sInitialized = true;

    ///   BGFX_DEBUG_STATS - Display internal statistics.
    ///
    ///   BGFX_DEBUG_TEXT - Display debug text.
    ///
    ///   BGFX_DEBUG_WIREFRAME - Wireframe rendering. All rendering
    ///     primitives will be rendered as lines.
    ///

    // bgfx::setDebug(BGFX_DEBUG_STATS | BGFX_DEBUG_TEXT);
}


void Graphics::shutdown()
{
//    bgfx::shutdown();
}


void Graphics::reset(int width, int height, uint32_t flags)
{
    lmAssert(sInitialized, "Please make sure to call Graphics::initialize first");

    lmLogDebug(gGFXLogGroup, "Graphics::reset - %dx%d %x", width, height, flags);

    // if we're experiencing a context loss we must reset regardless
    if (sContextLost)
    {
        //bgfx::reset(width, height, flags);
        QuadRenderer::reset();
        Texture::reset();        
    }
    else
    {
        // otherwise, reset only on width/height/flag change
        if (width != sWidth || height != sHeight || sFlags != flags)
        {
            //bgfx::reset(width, height, flags);
        }
    }

    // clear context loss state
    sContextLost = false;

    // cache current values
    sWidth  = width;
    sHeight = height;
    sFlags = flags;
}

void Graphics::beginFrame()
{
    if (!sInitialized)
    {
        return;
    }

    sCurrentFrame++;

    Graphics::context()->glViewport(0, 0, Graphics::getWidth(), Graphics::getHeight());

    // Issue clear.
    Graphics::context()->glClearColor(
                                      float((sFillColor >> 0) & 0xFF) / 255.0f,
                                      float((sFillColor >> 8) & 0xFF) / 255.0f + 0.5f,
                                      float((sFillColor >> 16) & 0xFF) / 255.0f,
                                      float((sFillColor >> 24) & 0xFF) / 255.0f
                                      );
    Graphics::context()->glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);



    QuadRenderer::beginFrame();
}


void Graphics::endFrame()
{
    QuadRenderer::endFrame();

    if(pendingScreenshot[0] != 0)
    {
        //bgfx::saveScreenShot(pendingScreenshot);
        pendingScreenshot[0] = 0;
    }
}


static int _scount = 0;
void Graphics::handleContextLoss()
{
    sContextLost = true;

    lmLog(gGFXLogGroup, "Graphics::handleContextLoss - %dx%d", sWidth, sHeight);

    lmLog(gGFXLogGroup, "Handle context loss: Shutdown %i", _scount++);

    // make sure the QuadRenderer resources are freed before we shutdown bgfx
    QuadRenderer::destroyGraphicsResources();

    lmLog(gGFXLogGroup, "Handle context loss: Init");

    lmLog(gGFXLogGroup, "Handle context loss: Reset");
    reset(sWidth, sHeight);
    lmLog(gGFXLogGroup, "Handle context loss: Done");
}


void Graphics::screenshot(const char *path)
{
    strcpy(pendingScreenshot, path);
}


void Graphics::setDebug(int flags)
{
    //bgfx::setDebug(flags);
}


void Graphics::setFillColor(int color)
{
    sFillColor = color;
}


int Graphics::getFillColor()
{
    return sFillColor;
}


int Graphics::setClipRect(int x, int y, int width, int height)
{
    // Make sure the cliprect is always in positive coords; some arguments
    // are unsigned so passing negative will break rendering.
    if (x < 0)
    {
        width += x;
        x      = 0;
    }

    if (y < 0)
    {
        height += y;
        y       = 0;
    }

    context()->glScissor(x, y, width, height);
    return -1; //bgfx::setScissor(x, y, width, height);
}


void Graphics::setClipRect(int cached)
{
    //bgfx::setScissor(cached);
}


void Graphics::clearClipRect()
{
    context()->glScissor(0, 0, sWidth, sHeight);
    //bgfx::setScissor();
}
}
