
# Debugging support
# add_definitions(-DBGFX_CONFIG_DEBUG=1)

set ( GRAPHICS_SRC gfxGraphics.cpp gfxQuadRenderer.cpp gfxShaders.cpp gfxTexture.cpp gfxScript.cpp)

set (LOOMBGFX_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/internal/bgfx/src)
set (LOOMBGFX_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/internal/bgfx/include)

include_directories( ${LOOM_INCLUDE_FOLDERS} ${CMAKE_CURRENT_SOURCE_DIR}/internal/bx/include ${LOOMBGFX_INCLUDE_DIR} )

if (NOT ANDROID)
    include_directories( ${LOOMBGFX_INCLUDE_DIR}/glext )
    endif()

set ( BGFX_SRC ${LOOMBGFX_SOURCE_DIR}/bgfx.cpp ${LOOMBGFX_SOURCE_DIR}/dds.cpp ${LOOMBGFX_SOURCE_DIR}/vertexdecl.cpp ${LOOMBGFX_SOURCE_DIR}/image.cpp )

if(APPLE)

    add_definitions( -U__STRICT_ANSI__ -Wfatal-errors -Wunused-value )

    set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/renderer_gl.cpp )


    if(LOOM_BUILD_IOS EQUAL 1)
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsIOS.mm )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGLES2=1 )
        include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/internal/bx/include/compat/osx )
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
        
    else()
        # OSX
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsOSX.mm )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGL=1 -msse2 )
        include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/internal/bx/include/compat/osx )
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )

    endif()    

endif()

if(ANDROID)
        add_definitions ( -std=c++0x )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGLES2=1 )    
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/renderer_gl.cpp ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsAndroid.cpp )
endif()    

if (MSVC)
        # add_definitions(-DBGFX_CONFIG_RENDERER_OPENGL=1)
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/renderer_d3d9.cpp )
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



