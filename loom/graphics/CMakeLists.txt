
# Debugging support
# add_definitions(-DBGFX_CONFIG_DEBUG=1)

set ( GRAPHICS_SRC gfxGraphics.cpp gfxQuadRenderer.cpp gfxShaders.cpp gfxTexture.cpp gfxScript.cpp)

set (LOOM_VENDOR ${CMAKE_CURRENT_SOURCE_DIR}/../vendor)

set (LOOMBGFX_SOURCE_DIR ${LOOM_VENDOR}/bgfx/src)
set (LOOMBGFX_INCLUDE_DIR ${LOOM_VENDOR}/bgfx/include)

set (LOOMBX_INCLUDE_DIR ${LOOM_VENDOR}/bx/include)

include_directories( ${LOOM_INCLUDE_FOLDERS} ${LOOMBX_INCLUDE_DIR} ${LOOMBGFX_INCLUDE_DIR}  ${LOOM_VENDOR}/bgfx/3rdparty )

if (NOT ANDROID)
    include_directories( ${LOOMBGFX_INCLUDE_DIR}/glext )
    endif()

set ( BGFX_SRC ${LOOMBGFX_SOURCE_DIR}/bgfx.cpp ${LOOMBGFX_SOURCE_DIR}/vertexdecl.cpp ${LOOMBGFX_SOURCE_DIR}/image.cpp )

set ( BGFX_SRC ${BGFX_SRC}
  ${LOOMBGFX_SOURCE_DIR}/renderer_null.cpp
  ${LOOMBGFX_SOURCE_DIR}/renderer_gl.cpp
  ${LOOMBGFX_SOURCE_DIR}/renderer_d3d9.cpp
  ${LOOMBGFX_SOURCE_DIR}/renderer_d3d11.cpp
  ${LOOMBGFX_SOURCE_DIR}/renderer_d3d12.cpp
)
    
if(APPLE)

    add_definitions( -U__STRICT_ANSI__ -Wfatal-errors -Wunused-value )



    if(LOOM_BUILD_IOS EQUAL 1)
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsIOS.mm )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGLES2=1 )
        if (LOOM_IOS_LEGACY EQUAL 1)
            include_directories( ${LOOMBX_INCLUDE_DIR}/compat/osx )
        endif()
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
        
    else()
        # OSX
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsOSX.mm )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGL=1 -msse2 )
        include_directories( ${LOOMBX_INCLUDE_DIR}/compat/osx )
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )

    endif()    

endif()

if(ANDROID)
        add_definitions ( -std=c++0x )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGLES2=1 )    
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsAndroid.cpp )
endif()    

if (MSVC)
        # add_definitions(-DBGFX_CONFIG_RENDERER_OPENGL=1)
        include_directories( ${LOOMBX_INCLUDE_DIR}/compat/msvc )
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsWindows.cpp )
endif()

if (LINUX)
    add_definitions ( -std=c++0x )
    set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/renderer_gl.cpp ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
    set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsAndroid.cpp )

endif()

if (FLASH)
    
    add_definitions(-D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_CONSTANT_MACROS=1)
    include_directories( ${LOOMBGFX_INCLUDE_DIR}/compat/osx )

endif()

add_library( LoomGraphics ${BGFX_SRC} ${GRAPHICS_SRC} )
target_link_libraries(LoomGraphics LoomVendor )



