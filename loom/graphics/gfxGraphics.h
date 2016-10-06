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

// Set to 1 to enable additional graphics debugging output and checks
#define GFX_DEBUG 0

// This flag enables extensive OpenGL checks including checking
// the OpenGL error state after every call. This can have a big
// impact on performance, so it's best used only while debugging.
// Follows GFX_DEBUG by default.
#define GFX_OPENGL_CHECK GFX_DEBUG

// Turn this off to disable checking all OpenGL calls
// but keep checking shaders, framebuffers and others.
#define GFX_CALL_CHECK GFX_OPENGL_CHECK

// Check Frame Buffer Object (FBO) status
#define GFX_FBO_CHECK GFX_OPENGL_CHECK

// Print all the OpenGL calls as they happen (a lot of overhead)
#define GFX_CALL_PRINT 0

// Enable profiling of all OpenGL calls
#define GFX_CALL_PROFILE 0

#include <SDL.h>

#ifdef LOOM_RENDERER_OPENGLES2
#include "SDL_opengles2.h"
#else
#include "SDL_opengl.h"
#endif

#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/performance.h"
#include "loom/common/core/log.h"

extern "C" {
#include "lua.h"
}

#include "loom/graphics/gfxColor.h"

namespace GFX {
    lmDeclareLogGroup(gGFXLogGroup);
}

#if GFX_OPENGL_CHECK
#ifdef _WIN32
#include <intrin.h>
#endif
#endif

namespace GFX
{
    typedef struct GL_Context
    {

#ifdef _WIN32
#define GFX_CALL __stdcall
#define GFX_DEBUG_BREAK __debugbreak();
#else
#define GFX_CALL
#define GFX_DEBUG_BREAK
#endif


#if GFX_CALL_CHECK

#define GFX_PREFIX gfx_internal_
#define GFX_PREFIX_CALL_INTERNAL_CONCAT(prefix, func, args) prefix ## func args
#define GFX_PREFIX_CALL_INTERNAL(prefix, func, args) GFX_PREFIX_CALL_INTERNAL_CONCAT(prefix, func, args)
#define GFX_PREFIX_CALL(func, args) GFX_PREFIX_CALL_INTERNAL(GFX_PREFIX, func, args)

#if GFX_CALL_PRINT
#define GFX_PROC_PRINT(func, params, args) \
        lmLogInfo(gGFXLogGroup, "OpenGL call: %s", #func);
#else
#define GFX_PROC_PRINT(func, params, args)
#endif

#if GFX_CALL_PROFILE
#define GFX_PROC_PROFILE_START(name) \
        LOOM_PROFILE_START(name);

#define GFX_PROC_PROFILE_END(name) \
        LOOM_PROFILE_END(name);
#else
#define GFX_PROC_PROFILE_START(name)
#define GFX_PROC_PROFILE_END(name)
#endif

#define GFX_PROC_BEGIN(ret, func, params) \
        ret (GFX_CALL *GFX_PREFIX_CALL(func,)) params; \
        ret func params { \
            GFX_PROC_PROFILE_START(func)



#define GFX_PROC_MID(func, params, args) \
        GFX_PROC_PROFILE_END(func) \
        GFX_PROC_PRINT(func, params, args) \
        GLenum error = GFX_PREFIX_CALL(glGetError, ()); \
        switch (error) { \
            case GL_NO_ERROR: break; \
            case GL_OUT_OF_MEMORY: lmLogWarn(gGFXLogGroup, "OpenGL reported to be out of memory"); break; \
            case 0x0507 /* GL_CONTEXT_LOST in OpenGL 4.5 */: lmLogWarn(gGFXLogGroup, "OpenGL reported context loss"); break; \
            default: \
                const char* errorName; \
                switch (error) { \
                    case GL_INVALID_ENUM: errorName = "GL_INVALID_ENUM"; break; \
                    case GL_INVALID_VALUE: errorName = "GL_INVALID_VALUE"; break; \
                    case GL_INVALID_OPERATION: errorName = "GL_INVALID_OPERATION"; break; \
                    case 0x0503 /* GL_STACK_OVERFLOW */: errorName = "GL_STACK_OVERFLOW"; break; \
                    case 0x0504 /* GL_STACK_UNDERFLOW */: errorName = "GL_STACK_UNDERFLOW"; break; \
                    case GL_INVALID_FRAMEBUFFER_OPERATION: errorName = "GL_INVALID_FRAMEBUFFER_OPERATION"; break; \
                    default: errorName = "Unknown error"; \
                } \
                lmLogError(gGFXLogGroup, "OpenGL error at %s: %s (0x%04x)", #func, errorName, error); \
                GFX_DEBUG_BREAK \
                lmAssert(error, "OpenGL error, see above for details."); \
        }

#define GFX_PROC_VOID(func, params, args) \
        GFX_PROC_BEGIN(void, func, params) \
            GFX_PREFIX_CALL(func, args); \
            GFX_PROC_MID(func, params, args) \
        }

#define GFX_PROC(ret, func, params, args) \
        GFX_PROC_BEGIN(ret, func, params) \
            ret returnValue = GFX_PREFIX_CALL(func, args); \
            GFX_PROC_MID(func, params, args) \
            return returnValue; \
        }

#else

#define GFX_PROC(ret, func, params, args) ret (GFX_CALL *func) params;
#define GFX_PROC_VOID(func, params, args) GFX_PROC(void, func, params, args)

#endif

#include "gfxGLES2EntryPoints.h"
#undef GFX_PROC
#undef GFX_PROC_VOID
    } GL_Context;



    typedef struct GL_ContextDummy
    {

//#define GFX_PROC(ret, func, params, args) static ret func ## params;

#define GFX_PROC(ret, func, params, args) 
#define GFX_PROC_VOID(func, params, args) static void GFX_CALL func params {};
    
#include "gfxGLES2EntryPoints.h"
#undef GFX_PROC
#undef GFX_PROC_VOID

        // Returning functions
        static GLenum GFX_CALL glCheckFramebufferStatus(GLenum target)
        {
            return GL_FRAMEBUFFER_UNSUPPORTED;
        }
        static GLuint GFX_CALL glCreateProgram()
        {
            return 1;
        }
        static GLuint GFX_CALL glCreateShader(GLenum type)
        {
            return 1;
        }
        static GLenum GFX_CALL glGetAttribLocation(GLuint program, const GLchar *name)
        {
            return 1;
        }
        static const GLubyte* GFX_CALL glGetError()
        {
            return (const GLubyte*)"dummy";
        }
        static const GLubyte* GFX_CALL glGetString(GLenum name)
        {
            return (const GLubyte*)"";
        }
        static GLint GFX_CALL glGetUniformLocation(GLuint program, const GLchar *name)
        {
            return 1;
        }
        static GLboolean GFX_CALL glIsBuffer(GLuint buffer)
        {
            return false;
        }
        static GLboolean GFX_CALL glIsEnabled(GLenum cap)
        {
            return false;
        }
        static GLboolean GFX_CALL glIsFramebuffer(GLuint framebuffer)
        {
            return false;
        }
        static GLboolean GFX_CALL glIsProgram(GLuint program)
        {
            return false;
        }
        static GLboolean GFX_CALL glIsRenderbuffer(GLuint renderbuffer)
        {
            return false;
        }
        static GLboolean GFX_CALL glIsShader(GLuint shader)
        {
            return false;
        }
        static GLboolean GFX_CALL glIsTexture(GLuint texture)
        {
            return false;
        }

        // Overrides
        
        // glGenBuffers + glGenFramebuffers + glGenRenderbuffers + glGenTextures
        static void GFX_CALL dummy_glGen_(GLsizei n, GLuint *buffers)
        {
            for (int i = 0; i < n; i++) buffers[i] = 1;
        }

        // glGetActiveAttrib + glGetActiveUniform
        static void GFX_CALL dummy_glGetActive_(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name)
        {
            *length = 0;
            *size = 0;
            *type = GL_FLOAT;
            *name = 0;
        }

        static void GFX_CALL dummy_glGetAttachedShaders(GLuint program, GLsizei maxCount, GLsizei *count, GLuint *shaders)
        {
            *count = 0;
        }

        static void GFX_CALL dummy_glGetShaderiv(GLuint shader, GLenum pname, GLint *params)
        {
            if (pname == GL_COMPILE_STATUS) *params = GL_TRUE;
            else *params = 0;
        }

        static void GFX_CALL dummy_glGetProgramiv(GLuint program, GLenum pname, GLint *params)
        {
            if (pname == GL_LINK_STATUS) *params = GL_TRUE;
            else *params = 0;
        }

        /*
        static void dummy_glGetBooleanv(GLenum pname, GLboolean *data)
        {
        }
        */


        /*
#define GFX_PROC_DUMMY_void(func, params)   static void dummy_ ## func ## params {};
#define GFX_PROC_DUMMY_GLenum(func, params) static void dummy_ ## func ## params {};
#define GFX_PROC_DUMMY_GLuint(func, params)   static void dummy_ ## func ## params {};
#define GFX_PROC_DUMMY_GLint(func, params)   static void dummy_ ## func ## params {};
#define GFX_PROC_DUMMY_const GLubyte*(func, params)   static void dummy_ ## func ## params {};
#define GFX_PROC_IMPL(procname, func, params) procname(func, params)
#define GFX_PROC(ret, func, params, args) GFX_PROC_IMPL(GFX_PROC_DUMMY_ ## ret, func, params)
*/
    } GL_ContextDummy;

// Represents graphics render target properties that can change from frame buffer to frame buffer
typedef struct GraphicsRenderTarget {
    // The current width of the graphics device
    int width;

    // The current height of the graphics device
    int height;

    // The flags used to create the graphics device
    uint32_t flags;

    // The current fill color used when clearing the color buffer
    Color fillColor;

    // Current OpenGL scissor clipping
    int clipX;
    int clipY;
    int clipWidth;
    int clipHeight;

    GraphicsRenderTarget() : width(0), height(0), flags(0), fillColor(0x000000FF), clipX(0), clipY(0), clipWidth(-1), clipHeight(-1) {};

} GraphicsRenderTarget;

/** 
  *  Graphics subsystem class in charge of initializing graphics and handling context loss
  */
class Graphics
{

public:

    // Delegate that provides screenshot data (in PNG format) when screenshotData is called
    LOOM_STATICDELEGATE(onScreenshotData);

    static const uint32_t FLAG_INVERTED            = 1 << 0;
    static const uint32_t FLAG_NOCLEAR             = 1 << 1;
    static const uint32_t FLAG_PREMULTIPLIED_ALPHA = 1 << 2;

    static GL_Context *context()
    {
        return &_context;
    }

    static void initialize();

    static bool isInitialized()
    {
        return sInitialized;
    }
    
    static void pause();
    static void resume();

    static void reset(int width, int height, uint32_t flags = 0);

    static void shutdown();
    
    static bool queryExtension(const char *extName);

    static void beginFrame();
    static void pushRenderTarget();
    static void popRenderTarget();
    static void applyRenderTarget(bool initial = true);
    static void endFrame();

    static int render(lua_State *L);
    //static void render(void *object, void *matrix, float alpha);

    static void handleContextLoss();

    static inline uint32_t getCurrentFrame() { return sCurrentFrame; }

    static inline void setNativeSize(int width, int height)
    {
        sTarget.width = width;
        sTarget.height = height;
    }
    
    static inline int getWidth() { return sTarget.width; }
    static inline int getHeight() { return sTarget.height; }
    static inline uint32_t getFlags() { return sTarget.flags; }
    static inline void setFlags(uint32_t flags) { sTarget.flags = flags; }
    static bool getStencilRequired();
    static inline float* getMVP() {
#if GFX_OPENGL_CHECK
        if (sCurrentModelViewProjection == NULL) {
            lmLogError(gGFXLogGroup, "Transformation matrix is NULL, did you call Graphics::reset?");
            GFX_DEBUG_BREAK
        }
#endif
        return sCurrentModelViewProjection;
    }

    static void setViewTransform(float *view, float *proj);

    static void setDebug(int flags);
    static void screenshot(const char *path);
    static void screenshotData();
    static void setFillColor(unsigned int color);
    static unsigned int getFillColor();

    static int getBackFramebuffer() { return sBackFramebuffer; }

    // Returns true if input rectangle is equal to current clip rect
    static bool checkClipRect(int x, int y, int width, int height);

    // Set a clip rect specified by the provided parameters
    static void setClipRect(int x, int y, int width, int height);

    // Reset clip rect
    static void clearClipRect();

private:

    // Once the Graphics system is initialized, this will be true!
    static bool sInitialized;

    // If we're currently in a OpenGL context loss situation (the application has changed orientation, etc), 
    // this will be true.  Once we're recovering the graphics subsystem will need to recreate vertex/index buffers, 
    // texture resources, etc
    static bool sContextLost;    

    // The current frame counter
    static uint32_t sCurrentFrame;
    
    static GraphicsRenderTarget sTarget;
    static utArray<GraphicsRenderTarget> sTargetStack;
    static int sBackFramebuffer;

    //static float sMVP[9];
    static float sMVP[16];
    //static float sMVPInverted[16];
    static float* sCurrentModelViewProjection;

    // Opaque platform data, such as HWND
//    static void *sPlatformData[3];

    // Internal method used to initialize platform data 
//    static void initializePlatform();

    // If set, at next opportunity we will store a screenshot to this path and clear it.
    static char pendingScreenshot[1024];

    // If set, at the next opportunity we will get screenshot data and return it with the onScreenshotData delegate
    static bool gettingScreenshotData;

    static GL_Context _context;

};

#if !GFX_FBO_CHECK
#define GFX_FRAMEBUFFER_CHECK
#else
#define GFX_FRAMEBUFFER_CHECK(framebuffer) \
{ \
    GLenum status; \
    status = GFX::Graphics::context()->glCheckFramebufferStatus(GL_FRAMEBUFFER); \
    switch (status) \
    { \
        case GL_FRAMEBUFFER_COMPLETE: \
            lmLogDebug(gGFXLogGroup, "Texture framebuffer #%d valid", framebuffer); \
            break; \
        default: \
            const char* errorName; \
            switch (status) { \
                /* We can check with literal values here because they are a part of OpenGL spec (but not defined as constants in every version). */ \
                case GL_INVALID_ENUM: errorName = "GL_INVALID_ENUM"; break; \
                case 0x8219 /* GL_FRAMEBUFFER_UNDEFINED */: errorName = "GL_FRAMEBUFFER_UNDEFINED"; break; \
                case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: errorName = "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT"; break; \
                case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: errorName = "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT"; break; \
                case 0x8CDB /* GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER */: errorName = "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER"; break; \
                case 0x8CDC /* GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER */: errorName = "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER"; break; \
                case GL_FRAMEBUFFER_UNSUPPORTED: errorName = "GL_FRAMEBUFFER_UNSUPPORTED"; break; \
                case 0x8D56 /* GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE */: errorName = "GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE"; break; \
                case 0x8DA8 /* GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS */: errorName = "GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS"; break; \
                default: errorName = "Unknown error"; \
            } \
            lmLogError(gGFXLogGroup, "Framebuffer #%d error: %s (0x%04x)", framebuffer, errorName, status); \
            GFX_DEBUG_BREAK \
            lmAssert(status, "OpenGL error, see above for details."); \
    } \
} \

#endif

}