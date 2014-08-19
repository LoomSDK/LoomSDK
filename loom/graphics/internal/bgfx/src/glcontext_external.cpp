#include "bgfx_p.h"
#include "renderer_gl.h"
#include "glcontext_external.h"

namespace bgfx
{

#if BX_PLATFORM_IOS
    int GlContext::fbo = 0;
    int GlContext::msaaFbo = 0;
#endif

#if BX_PLATFORM_OSX
    #include <mach-o/dyld.h>
    #include <dlfcn.h>
    #include <stdlib.h>
    #include <string.h>
    #include <OpenGL/OpenGL.h>

    static void* NSGLGetProcAddress (const char* name) {
        static void* const dylib =
        dlopen("/System/Library/Frameworks/"
               "OpenGL.framework/Versions/Current/OpenGL",
               RTLD_LAZY);
        return dylib ? dlsym(dylib, name) : NULL;
    }

    #define GL_IMPORT(_optional, _proto, _func, _import) _proto _func
    #include "glimports.h"
    #undef GL_IMPORT
#endif // OSX

#if BX_PLATFORM_ANDROID
    #include <EGL/egl.h>
    #define GL_IMPORT(_optional, _proto, _func, _import) _proto _func
    #include "glimports.h"
    #undef GL_IMPORT
#endif // ANDROID

#if BX_PLATFORM_LINUX
    # define GL_IMPORT(_optional, _proto, _func, _import) _proto _func
    # include "glimports.h" 
    # undef GL_IMPORT    
#endif // LINUX


#if BX_PLATFORM_WINDOWS

    PFNWGLGETPROCADDRESSPROC wglGetProcAddress;
    PFNWGLMAKECURRENTPROC wglMakeCurrent;
    PFNWGLCREATECONTEXTPROC wglCreateContext;
    PFNWGLDELETECONTEXTPROC wglDeleteContext;
    PFNWGLGETEXTENSIONSSTRINGARBPROC wglGetExtensionsStringARB;
    PFNWGLCHOOSEPIXELFORMATARBPROC wglChoosePixelFormatARB;
    PFNWGLCREATECONTEXTATTRIBSARBPROC wglCreateContextAttribsARB;
    PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT;

#   define GL_IMPORT(_optional, _proto, _func, _import) _proto _func
#       include "glimports.h"
#   undef GL_IMPORT

#endif // WINDOWS    

void GlContext::create(uint32_t _width, uint32_t _height)
{
#if BX_PLATFORM_WINDOWS

    m_opengl32dll = LoadLibrary("opengl32.dll");
    BGFX_FATAL(NULL != m_opengl32dll, Fatal::UnableToInitialize, "Failed to load opengl32.dll.");

    wglGetProcAddress = (PFNWGLGETPROCADDRESSPROC)GetProcAddress(m_opengl32dll, "wglGetProcAddress");
    BGFX_FATAL(NULL != wglGetProcAddress, Fatal::UnableToInitialize, "Failed get wglGetProcAddress.");

    wglMakeCurrent = (PFNWGLMAKECURRENTPROC)GetProcAddress(m_opengl32dll, "wglMakeCurrent");
    BGFX_FATAL(NULL != wglMakeCurrent, Fatal::UnableToInitialize, "Failed get wglMakeCurrent.");

    wglCreateContext = (PFNWGLCREATECONTEXTPROC)GetProcAddress(m_opengl32dll, "wglCreateContext");
    BGFX_FATAL(NULL != wglCreateContext, Fatal::UnableToInitialize, "Failed get wglCreateContext.");

    wglDeleteContext = (PFNWGLDELETECONTEXTPROC)GetProcAddress(m_opengl32dll, "wglDeleteContext");
    BGFX_FATAL(NULL != wglDeleteContext, Fatal::UnableToInitialize, "Failed get wglDeleteContext.");   

#endif    
    import();
}

void GlContext::destroy()
{
}

void GlContext::resize(uint32_t _width, uint32_t _height, bool _vsync)
{
}

void GlContext::swap()
{

}

void GlContext::import()
{

    #if BX_PLATFORM_OSX

    #define GL_IMPORT(_optional, _proto, _func, _import) \
    { \
        _func = (_proto)NSGLGetProcAddress(#_func); \
        BGFX_FATAL(_optional || NULL != _func, Fatal::UnableToInitialize, "Failed to create OpenGL context. NSGLGetProcAddress(\"%s\")", #_func); \
    }
    #include "glimports.h"
    #undef GL_IMPORT
 
    #endif // OSX

// ANDROID ------------------------
#if BX_PLATFORM_ANDROID
#define GL_IMPORT(_optional, _proto, _func, _import) \
{ \
    _func = (_proto)eglGetProcAddress(#_func); \
    BX_TRACE(#_func " 0x%08x", _func); \
    BGFX_FATAL(_optional || NULL != _func, Fatal::UnableToInitialize, "Failed to create OpenGLES context. eglGetProcAddress(\"%s\")", #_func); \
}
#include "glimports.h"
#undef GL_IMPORT
#endif // ANDROID
// ANDROID ------------------------

#if BX_PLATFORM_WINDOWS

#   define GL_IMPORT(_optional, _proto, _func, _import) \
        { \
            _func = (_proto)wglGetProcAddress(#_func); \
            if (_func == NULL) \
            { \
                _func = (_proto)GetProcAddress(m_opengl32dll, #_func); \
            } \
            BGFX_FATAL(_optional || NULL != _func, Fatal::UnableToInitialize, "Failed to create OpenGL context. wglGetProcAddress(\"%s\")", #_func); \
        }
#   include "glimports.h"
#   undef GL_IMPORT        
#endif // WINDOWS
        
}

} // namespace bgfx
