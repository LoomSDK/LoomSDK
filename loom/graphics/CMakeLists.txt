
# Debugging support
# add_definitions(-DBGFX_CONFIG_DEBUG=1)

set ( GRAPHICS_SRC gfxGraphics.cpp gfxQuadRenderer.cpp gfxTexture.cpp gfxScript.cpp gfxVectorRenderer.cpp gfxVectorGraphics.cpp)
set (LOOM_VENDOR ${CMAKE_CURRENT_SOURCE_DIR}/../vendor)
set (NANOVG ${LOOM_VENDOR}/nanovg/src)
set (NANOSVG ${LOOM_VENDOR}/nanosvg/src)

include_directories( ${NANOVG} ${NANOSVG} )

set ( NANOVG_SRC ${NANOVG}/nanovg.c )

if(APPLE)

    add_definitions( -U__STRICT_ANSI__ -Wfatal-errors -Wunused-value )


    if(LOOM_BUILD_IOS EQUAL 1)
        #set ( GRAPHICS_SRC ${GRAPHICS_SRC} gfxGraphicsIOS.mm )
        #if (LOOM_IOS_LEGACY EQUAL 1)
        #    include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/internal/bx/include/compat/osx )
        #endif()
        #set ( BGFX_SRC ${BGFX_SRC} ${LOOMBGFX_SOURCE_DIR}/glcontext_external.cpp )
        
        include_directories( ${LOOM_INCLUDE_FOLDERS} )

    else()
        # OSX
        #include_directories( /usr/local/include/SDL2 )
        include_directories( ${LOOM_INCLUDE_FOLDERS} )

        add_definitions( -msse2 )

    endif()    

endif()

if(ANDROID)
        add_definitions ( -std=c++0x )
        add_definitions( -DLOOM_RENDERER_OPENGLES2=1 )
        include_directories( ${LOOM_INCLUDE_FOLDERS} )
endif()    

if (MSVC)
    include_directories( ${LOOM_INCLUDE_FOLDERS} )
endif()

if (LINUX)
    include_directories( ${LOOM_INCLUDE_FOLDERS} )
    add_definitions ( -std=c++0x )
endif()

if (FLASH)
    
    add_definitions(-D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_CONSTANT_MACROS=1)
    include_directories( ${LOOMBGFX_INCLUDE_DIR}/compat/osx )

endif()

add_library( LoomGraphics ${NANOVG_SRC} ${GRAPHICS_SRC} )
target_link_libraries(LoomGraphics LoomVendor )



