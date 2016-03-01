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
#include "loom/graphics/gfxBitmapData.h"
#include "loom/graphics/gfxStateManager.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Get a reference to the global window.
extern SDL_Window *gSDLWindow;

namespace GFX
{



lmDefineLogGroup(gGFXLogGroup, "gfx", 1, LoomLogInfo);

bool Graphics::sInitialized = false;

// start with context loss as flagged so resources are created
bool Graphics::sContextLost = true;

int Graphics::sBackFramebuffer = -1;

uint32_t Graphics::sCurrentFrame = 0;
GraphicsRenderTarget Graphics::sTarget;
utArray<GraphicsRenderTarget> Graphics::sTargetStack;

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
    QuadRenderer::destroyGraphicsResources();
    VectorRenderer::destroyGraphicsResources();
}

void Graphics::reset(int width, int height, uint32_t flags)
{
    lmAssert(sInitialized, "Please make sure to call Graphics::initialize first");

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
    sTarget.width  = width;
    sTarget.height = height;
    sTarget.flags = flags;
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

    QuadRenderer::beginFrame();

    applyRenderTarget();
}

void Graphics::pushRenderTarget()
{
    QuadRenderer::submit();
    sTargetStack.push_back(sTarget);
}

void Graphics::popRenderTarget()
{
    sTarget = sTargetStack.back();
    sTargetStack.pop_back();
    applyRenderTarget(false);
}

void Graphics::applyRenderTarget(bool initial)
{
    Graphics::reset(sTarget.width, sTarget.height, sTarget.flags);

    VectorRenderer::setSize(sTarget.width, sTarget.height);
    Graphics::context()->glViewport(0, 0, sTarget.width, sTarget.height);

    if (initial && !(sTarget.flags & FLAG_NOCLEAR)) {
        Graphics::context()->glClearColor(sTarget.fillColor.r, sTarget.fillColor.g, sTarget.fillColor.b, sTarget.fillColor.a);
        Graphics::context()->glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    }
}

void Graphics::endFrame()
{
    QuadRenderer::endFrame();

    if(pendingScreenshot[0] != 0 || gettingScreenshotData)
    {
        SDL_ClearError();
        SDL_Window* sdlWindow = gSDLWindow;

        const BitmapData* fb = BitmapData::fromFramebuffer();


        // If there is a pending screenshot write, do that
        if (pendingScreenshot[0] != 0) {
            fb->save(pendingScreenshot);
        }

        // If there is a pending data request, do that
        if (gettingScreenshotData) {
            utByteArray *retData = stbi_data_png(sTarget.width, sTarget.height, 4 /* RGBA */, fb->getData(), sTarget.width * fb->getBpp());

            // Send the delegate along
            _onScreenshotDataDelegate.pushArgument(retData);
            _onScreenshotDataDelegate.invoke();
        }

        pendingScreenshot[0] = 0;
        gettingScreenshotData = false;
    }
}

int Graphics::render(lua_State *L)
{
    // Get arguments
    Loom2D::DisplayObject *object = (Loom2D::DisplayObject*) lualoom_getnativepointer(L, -3);
    Loom2D::Matrix *matrix = lua_isnil(L, -2) ? NULL : (Loom2D::Matrix*) lualoom_getnativepointer(L, -2);
    float alpha = (float)lua_tonumber(L, -1);

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

    // Reset state
    Graphics_SetCurrentGLState(GFX_OPENGL_STATE_QUAD);
    Graphics_InvalidateGLState(GFX_OPENGL_STATE_QUAD);

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

    lmLog(gGFXLogGroup, "Graphics::handleContextLoss - %dx%d", sTarget.width, sTarget.height);

    lmLog(gGFXLogGroup, "Handle context loss: Shutdown %i", _scount++);

    // make sure the QuadRenderer resources are freed before we shutdown bgfx
    QuadRenderer::destroyGraphicsResources();
    VectorRenderer::destroyGraphicsResources();

    lmLog(gGFXLogGroup, "Handle context loss: Init");

    lmLog(gGFXLogGroup, "Handle context loss: Reset");
    reset(sTarget.width, sTarget.height);
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


void Graphics::setFillColor(unsigned int color)
{
    sTarget.fillColor = Color(color);
}

// NanoVG requires stencil buffer for fills, so this is always true for now
bool Graphics::getStencilRequired()
{
    return true || (VectorRenderer::quality & VectorRenderer::QUALITY_STENCIL_STROKES) > 0;
}

unsigned int Graphics::getFillColor()
{
    return sTarget.fillColor.getHex();
}

// Returns true if input rectangle is equal to current clip rect
bool Graphics::checkClipRect(int x, int y, int width, int height)
{
    return x == sTarget.clipX && y == sTarget.clipY && width == sTarget.clipWidth && height == sTarget.clipHeight;
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

    // Sets current clip rect
    sTarget.clipX = x;
    sTarget.clipY = y;
    sTarget.clipWidth = width;
    sTarget.clipHeight = height;

    context()->glEnable(GL_SCISSOR_TEST);
    context()->glScissor(x, sTarget.height-height-y, width, height);
}

void Graphics::clearClipRect()
{
    sTarget.clipX = sTarget.clipY = 0;
    sTarget.clipWidth = sTarget.clipHeight = -1;
    context()->glDisable(GL_SCISSOR_TEST);
}

}
