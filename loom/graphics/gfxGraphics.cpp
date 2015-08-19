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

#include "loom/common/platform/platform.h"
#include "loom/common/core/log.h"

#include "loom/graphics/gfxMath.h"

#include "loom/engine/loom2d/l2dDisplayObject.h"

#include "loom/engine/loom2d/l2dMatrix.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxTexture.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxVectorRenderer.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Get a reference to the global window.
extern SDL_Window *gSDLWindow;

namespace GFX
{

lmDefineLogGroup(gGFXLogGroup, "GFX", 1, LoomLogInfo);

bool Graphics::sInitialized = false;

// start with context loss as flagged so resources are created
bool Graphics::sContextLost = true;

int Graphics::sWidth      = 0;
int Graphics::sHeight     = 0;
uint32_t Graphics::sFlags = 0x00000000;
int Graphics::sFillColor  = 0x000000FF;
int Graphics::sView       = 0;
int Graphics::sBackFramebuffer = -1;

uint32_t Graphics::sCurrentFrame = 0;

float Graphics::sMVP[16] = {
    1.0f, 0.0f, 0.0f, 0.0f,
    0.0f, 1.0f, 0.0f, 0.0f,
    0.0f, 0.0f, 1.0f, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f
};

float *Graphics::sCurrentModelViewProjection = NULL;

char Graphics::pendingScreenshot[1024] = { 0, };
bool Graphics::gettingScreenshotData = false;
LS::NativeDelegate Graphics::_onScreenshotDataDelegate;

extern SDL_GLContext context;
GL_Context Graphics::_context;

/**
 * Resolve function pointers for GL calls into the GL_Context structure.
 *
 * This is done in an OS specific way; we might assign them directly or
 * do a symbol lookup. The GFX_CALL_CHECK macro also lets us instrument
 * all GL calls for debug purposes.
 */
static int LoadContext(GL_Context * data)
{
#if SDL_VIDEO_DRIVER_UIKIT
#define __SDL_NOGETPROCADDR__
#elif SDL_VIDEO_DRIVER_ANDROID
#define __SDL_NOGETPROCADDR__
#elif SDL_VIDEO_DRIVER_PANDORA
#define __SDL_NOGETPROCADDR__
#endif

#if GFX_CALL_CHECK
#define GFX_OPENGL_FUNC(func) gfx_internal_ ## func
#else
#define GFX_OPENGL_FUNC(func) func
#endif

#if defined __SDL_NOGETPROCADDR__
// TODO: remove cast and figure out constness
#define GFX_PROC(ret,func,params,args) data->GFX_OPENGL_FUNC(func) = (ret(*)params)func;
#define GFX_PROC_VOID(func, params, args) GFX_PROC(void, func, params, args)
#else
#define GFX_PROC(ret,func,params,args) \
do { \
void **tmp = (void**)&data->GFX_OPENGL_FUNC(func); \
*tmp = SDL_GL_GetProcAddress(#func); \
if ( ! data->GFX_OPENGL_FUNC(func) ) { \
    return SDL_SetError("Couldn't load GL function %s: %s\n", #func, SDL_GetError()); \
} \
} while ( 0 );
#define GFX_PROC_VOID(func, params, args) GFX_PROC(void, func, params, args)
#endif /* _SDL_NOGETPROCADDR_ */
    
#include "gfxGLES2EntryPoints.h"
#undef GFX_PROC
#undef GFX_PROC_VOID

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
    
    // Required on iOS (at least), because the back framebuffer might not be 0
    // as it appears to be on other platforms
    Graphics::context()->glGetIntegerv(GL_FRAMEBUFFER_BINDING, &sBackFramebuffer);

    sInitialized = true;
}

void Graphics::shutdown()
{
    Texture::shutdown();
}

void Graphics::reset(int width, int height, uint32_t flags)
{
    lmAssert(sInitialized, "Please make sure to call Graphics::initialize first");

    lmLogDebug(gGFXLogGroup, "Graphics::reset - %dx%d %x", width, height, flags);

    // clear context loss state
    sContextLost = false;

    Loom2D::Matrix mvp;
    mvp.scale(2.0f / width, 2.0f / height);
    mvp.translate(-1.0f, -1.0f);

    // Inverted is normal due to OpenGL origin being bottom left
    if (!(flags & FLAG_INVERTED)) {
        mvp.scale(1.0f, -1.0f);
    }
    mvp.copyToMatrix4f(sMVP);
    
    sCurrentModelViewProjection = sMVP;

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
    
    Graphics::reset(sWidth, sHeight, sFlags);
    
    Graphics::context()->glViewport(0, 0, Graphics::getWidth(), Graphics::getHeight());

    if (!(sFlags & FLAG_NOCLEAR)) {
        Graphics::context()->glClearColor(
                                          float((sFillColor >> 24) & 0xFF) / 255.0f,
                                          float((sFillColor >> 16) & 0xFF) / 255.0f,
                                          float((sFillColor >> 8) & 0xFF) / 255.0f,
                                          float((sFillColor >> 0) & 0xFF) / 255.0f
                                          );
        Graphics::context()->glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    }

    QuadRenderer::beginFrame();
    VectorRenderer::setSize(sWidth, sHeight);
}


void Graphics::endFrame()
{
    QuadRenderer::endFrame();

    if(pendingScreenshot[0] != 0 || gettingScreenshotData)
    {
        SDL_ClearError();
        SDL_Window* sdlWindow = gSDLWindow;

        // Create a PNG image and save it to the requested file location
        // Original algorithm (heavily modified) by neilf (http://stackoverflow.com/a/20233470)
        if (sWidth == 0 || sHeight == 0) {
            lmLog(gGFXLogGroup, "Graphics dimensions invalid %d x %d: %s", sWidth, sHeight, SDL_GetError());
            return;
        }

        utByteArray *pixels = lmNew(NULL) utByteArray();
        if (pixels == NULL) {
            lmLog(gGFXLogGroup, "Unable to allocate memory for screenshot pixel data buffer");
            return;
        }

        const int bpp = 4;

        pixels->resize(sWidth * sHeight * bpp);

        // The OpenGL method is a lot cleaner, but inverts the image
        context()->glPixelStorei(GL_PACK_ALIGNMENT, 1);
        context()->glReadPixels(0, 0, sWidth, sHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixels->getDataPtr());

        // Invert dat image
        utByteArray *invertedPixels = lmNew(NULL) utByteArray();
        if (invertedPixels == NULL) {
            lmLog(gGFXLogGroup, "Unable to allocate memory for transformed pixels data buffer");
            return;
        }
        invertedPixels->resize(pixels->getSize());

        for (int i = sHeight - 1; i >= 0; i--) {
            invertedPixels->writeBytes(pixels, i * sWidth * bpp, sWidth * bpp);
        }
        
        // If there is a pending screenshot write, do that
        if (pendingScreenshot[0] != 0 && stbi_write_png(pendingScreenshot, sWidth, sHeight, 4 /* RGBA */, invertedPixels->getDataPtr(), sWidth * bpp) != 1) {
            lmLog(gGFXLogGroup, "Unable to generate PNG");
        }

        // If there is a pending data request, do that
        if (gettingScreenshotData) {
            utByteArray *retData = stbi_data_png(sWidth, sHeight, 4 /* RGBA */, invertedPixels->getDataPtr(), sWidth * bpp);

            // Send the delegate along
            _onScreenshotDataDelegate.pushArgument(retData);
            _onScreenshotDataDelegate.invoke();
        }
        
        lmDelete(NULL, pixels);
        lmDelete(NULL, invertedPixels);

        pendingScreenshot[0] = 0;
        gettingScreenshotData = false;
    }
}

int Graphics::render(lua_State *L)
{
    Loom2D::DisplayObject *object = (Loom2D::DisplayObject*) lualoom_getnativepointer(L, 1);
    Loom2D::Matrix *matrix = lua_isnil(L, 2) ? NULL : (Loom2D::Matrix*) lualoom_getnativepointer(L, 2);
    float alpha = (float)lua_tonumber(L, 3);

    // Update positions and buffers early
    // since we can't wait for rendering to begin
    object->validate(L, 1); // The 1 here is the index of the object on the stack

    // Save and setup state
    Loom2D::DisplayObjectContainer *prevParent = object->parent;
    object->parent = NULL;

    Loom2D::Matrix prevTransformMatrix;
    if (matrix != NULL)
    {
        object->updateLocalTransform();
        prevTransformMatrix.copyFrom(&object->transformMatrix);
        object->transformMatrix.copyFrom(matrix);
    }

    lmscalar prevAlpha = object->alpha;
    object->alpha = prevAlpha*alpha;

    // Render the object.
    object->render(L);

    // Restore state
    object->parent = prevParent;
    if (matrix != NULL) object->transformMatrix.copyFrom(&prevTransformMatrix);
    object->alpha = prevAlpha;

    return 0;
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
    if (strlen(path) > 1024) {
        lmLog(gGFXLogGroup, "Screenshot name too big! Screenshots must be 1024 characters or less");
        return;
    }
    strcpy(pendingScreenshot, path);
}

void Graphics::screenshotData()
{
    gettingScreenshotData = true;
}


void Graphics::setDebug(int flags)
{
    //bgfx::setDebug(flags);
}


void Graphics::setFillColor(int color)
{
    sFillColor = color;
}

// NanoVG requires stencil buffer for fills, so this is always true for now
bool Graphics::getStencilRequired()
{
    return true || (VectorRenderer::quality & VectorRenderer::QUALITY_STENCIL_STROKES) > 0;
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
