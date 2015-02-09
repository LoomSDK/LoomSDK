
# Debugging support
# add_definitions(-DBGFX_CONFIG_DEBUG=1)

set ( GRAPHICS_SRC gfxGraphics.cpp gfxQuadRenderer.cpp gfxShaders.cpp gfxTexture.cpp gfxScript.cpp)


if (NOT ANDROID)
    include_directories( ${LOOMBGFX_INCLUDE_DIR}/glext )
endif()

if(APPLE)

    add_definitions( -U__STRICT_ANSI__ -Wfatal-errors -Wunused-value )


    if(LOOM_BUILD_IOS EQUAL 1)
        set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsIOS.mm )
        add_definitions( -DBGFX_CONFIG_RENDERER_OPENGLES2=1 )
        if (LOOM_IOS_LEGACY EQUAL 1)
            include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/internal/bx/include/compat/osx )
        endif()
        set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
        
    else()
        # OSX
        include_directories( /usr/local/include/SDL2 )
        include_directories( ${LOOM_INCLUDE_FOLDERS} )

        add_definitions( -msse2 )

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

add_library( LoomGraphics ${GRAPHICS_SRC} )
target_link_libraries(LoomGraphics LoomVendor )



