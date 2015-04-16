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

//#include <math.h>
//#define HAVE_M_PI

#include "loom/common/platform/platform.h"
#include "loom/common/core/log.h"

#include "loom/graphics/gfxMath.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxTexture.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxVectorRenderer.h"

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
// TODO: remove cast and figure out constness
#define SDL_PROC(ret,func,params) data->func = (ret(*)params)func;
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

    VectorRenderer::initialize();

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
        VectorRenderer::reset();
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

bool Graphics::queryExtension(char *extName)
{
    /*
    ** Search for extName in the extensions string. Use of strstr()
    ** is not sufficient because extension names can be prefixes of
    ** other extension names. Could use strtok() but the constant
    ** string returned by glGetString might be in read-only memory.
    */
    char *p;
    char *end;
    int extNameLen;   

    extNameLen = strlen(extName);
        
    p = (char *) context()->glGetString(GL_EXTENSIONS);
    if (NULL == p) {
        return true;
    }

    end = p + strlen(p);   

    while (p < end) {
        int n = strcspn(p, " ");
        if ((extNameLen == n) && (strncmp(extName, p, n) == 0)) {
            return GL_TRUE;
        }
        p += (n + 1);
    }
    return false;
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
                                      float((sFillColor >> 8) & 0xFF) / 255.0f,
                                      float((sFillColor >> 16) & 0xFF) / 255.0f,
                                      float((sFillColor >> 24) & 0xFF) / 255.0f,
                                      float((sFillColor >> 0) & 0xFF) / 255.0f
                                      );
    Graphics::context()->glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);


    QuadRenderer::beginFrame();
    VectorRenderer::setSize(sWidth, sHeight);
    //VectorRenderer::beginFrame();
}


void Graphics::endFrame()
{
    QuadRenderer::endFrame();
    //VectorRenderer::endFrame();

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
    VectorRenderer::destroyGraphicsResources();

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

void Graphics::setClipRect(int x, int y, int width, int height)
{
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

    context()->glEnable(GL_SCISSOR_TEST);
    context()->glScissor(x, sHeight-height-y, width, height);
}

void Graphics::clearClipRect()
{
    context()->glDisable(GL_SCISSOR_TEST);
}

}
