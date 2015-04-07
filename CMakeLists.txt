cmake_minimum_required(VERSION 2.8.7)
SET(CMAKE_SUPPRESS_REGENERATION  1)
SET(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/build/cmake/")

#--------------------------------------
# Configuration Options
#--------------------------------------

# This is the name of the binaries/.apps we generate
set(APPLICATION_NAME LoomDemo)

# The package for the application.
set(APPLICATION_PACKAGE co.theengine.LoomDemo)

project(LoomEngine)

#--------------------------------------
# Basic Setup
#--------------------------------------

set (LOOM_INCLUDE_FOLDERS
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/loom/vendor
    ${CMAKE_SOURCE_DIR}/loom/vendor/seatest
    ${CMAKE_SOURCE_DIR}/loom/vendor/stb
    ${CMAKE_SOURCE_DIR}/loom/vendor/minimp3
    ${CMAKE_SOURCE_DIR}/loom/vendor/smslib
    ${CMAKE_SOURCE_DIR}/loom/vendor/geldreich
    ${CMAKE_SOURCE_DIR}/loom/vendor/jansson
    ${CMAKE_SOURCE_DIR}/loom/vendor/admob/include
    ${CMAKE_SOURCE_DIR}/loom/vendor/jemalloc-3.4.0/include
    ${CMAKE_SOURCE_DIR}/loom/vendor/teak/ios/Carrot.framework/Headers
    ${CMAKE_SOURCE_DIR}/loom/vendor/sqlite3
    ${CMAKE_SOURCE_DIR}/loom/vendor/facebook/ios/FacebookSDK.framework/Headers
    ${CMAKE_SOURCE_DIR}/loom/vendor/parse/ios/Parse.framework/Headers
    )

# Allow Admob and/or Facebook to be built into the SDK?
if(LOOM_BUILD_ADMOB EQUAL 1)
    add_definitions(-DLOOM_ALLOW_ADMOB)
endif()
if(LOOM_BUILD_FACEBOOK EQUAL 1)
    add_definitions(-DLOOM_ALLOW_FACEBOOK)
endif()

if (LOOM_BUILD_JIT EQUAL 1)

    add_definitions(-DLOOM_ENABLE_JIT)
    list(APPEND LOOM_INCLUDE_FOLDERS ${CMAKE_SOURCE_DIR}/loom/vendor/luajit/src )

else() 

    list(APPEND LOOM_INCLUDE_FOLDERS ${CMAKE_SOURCE_DIR}/loom/vendor/lua/src )

endif(LOOM_BUILD_JIT EQUAL 1)

# Check if we're under Linux and add a nice platform variable 
# like the other platforms have
if (NOT ANDROID)
if(CMAKE_SYSTEM_NAME STREQUAL Linux)
    set (LINUX 1)
endif()
endif()

# define LOOM_DEBUG if this is a Debug build
if (LOOM_IS_DEBUG EQUAL 1)
    add_definitions(-DLOOM_DEBUG)
endif()


#--------------------------------------
# SDL
#--------------------------------------

if (MSVC OR (APPLE AND NOT LOOM_BUILD_IOS) OR LINUX)
	# Used for generated config include
	include_directories( ${CMAKE_BINARY_DIR}/loom/vendor/sdl2/include)
	include_directories( ${CMAKE_SOURCE_DIR}/loom/vendor/sdl2/include)
	
	# Set initial options via cmake cache
	set(LIBC ON CACHE BOOL "Enable system libraries")
	set(SDL_STATIC ON CACHE BOOL "Enable static linking")
	set(SDL_SHARED OFF CACHE BOOL "Enable dynamic linking")
	set(FORCE_STATIC_VCRT ON CACHE BOOL "Force /MT for static linking")
	set(DIRECTX OFF CACHE BOOL "Enable DirectX on Windows")
	
    set(VIDEO_X11 OFF CACHE BOOL "Disable X11")

	add_subdirectory(loom/vendor/sdl2)
endif()

#--------------------------------------
# Windows
#--------------------------------------

if (MSVC) 

    add_definitions(-DCURL_STATICLIB)

    set (LOOM_INCLUDE_FOLDERS ${LOOM_INCLUDE_FOLDERS}
    
    ${CMAKE_SOURCE_DIR}/loom/vendor/zlib/include
    ${CMAKE_SOURCE_DIR}/loom/vendor/libcurl/include )

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(VC_LIB_PATH_SUFFIX lib/x64)
    else()
      set(VC_LIB_PATH_SUFFIX lib/x86)
    endif()

    link_directories(${CMAKE_SOURCE_DIR}/loom/vendor/dxsdk/Include)    
    link_directories(${CMAKE_SOURCE_DIR}/loom/vendor/dxsdk/${VC_LIB_PATH_SUFFIX})

    
    # move this?
    add_definitions(-DLOOM_DISABLE_JEMALLOC -D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_CONSTANT_MACROS=1)
    
    # MSVC compatibility stuffs
    include_directories( ${CMAKE_SOURCE_DIR}/loom/vendor/jemalloc-3.4.0/include/msvc_compat )

    set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_windows/lua51.lib )

    add_definitions(-D_CRT_SECURE_NO_WARNINGS -D_HAS_EXCEPTIONS=0 -DWIN32 -D_WINDOWS -DWin32 -DFREEGLUT_STATIC -DFREEGLUT_LIB_PRAGMAS=0 -DGLEW_STATIC)

    # Warnings as errors
    add_definitions (/wd4819)

    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /WX /arch:SSE2")
    SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc /WX /arch:SSE2")    
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /NODEFAULTLIB:msvcrt.lib")
    
    STRING(REPLACE "/GX" "" CMAKE_CXX_FLAGS_INIT ${CMAKE_CXX_FLAGS_INIT})
    STRING(REPLACE "/GX" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})

    #statically link
    FOREACH(flag_var CMAKE_CXX_FLAGS 
    CMAKE_CXX_FLAGS_DEBUG 
    CMAKE_CXX_FLAGS_RELEASE 
    CMAKE_CXX_FLAGS_MINSIZEREL 
    CMAKE_CXX_FLAGS_RELWITHDEBINFO
    CMAKE_C_FLAGS_DEBUG
    CMAKE_C_FLAGS_RELEASE
    CMAKE_C_FLAGS_MINSIZEREL 
    CMAKE_C_FLAGS_RELWITHDEBINFO )
        IF(${flag_var} MATCHES "/MD")
            STRING(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
        ENDIF(${flag_var} MATCHES "/MD")
        
        IF(${flag_var} MATCHES "/MDd")
            STRING(REGEX REPLACE "/MDd" "/MTd" ${flag_var} "${${flag_var}}")
        ENDIF(${flag_var} MATCHES "/MDd")

        SET(${flag_var} "${${flag_var}} /MP${LOOM_BUILD_NUMCORES}")

    ENDFOREACH(flag_var)        

endif(MSVC)


#--------------------------------------
# OSX and iOS
#--------------------------------------

if(APPLE)

    include (BundleUtilities)

    add_definitions(-DLOOM_DISABLE_JEMALLOC -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY)

    # If this is defined, it will use OpenGL 2.1 instead of OpenGL 3.2
    add_definitions(-DLOOM_LEGACY_GL)

    list(APPEND LOOM_INCLUDE_FOLDERS /usr/include/libxml2 ${CMAKE_SOURCE_DIR}/loom/engine/cocos2dx/cocoa ${CMAKE_SOURCE_DIR}/loom/vendor/glew-1.7.0/include) 

    if(LOOM_BUILD_IOS EQUAL 1)

        # Apple changed some stuff in XCode5/SDK7 which we need to account for, however we still need to build out on 
        # XCode4/SDK6
        if(LOOM_IOS_VERSION LESS 7)
            set (LOOM_IOS_LEGACY 1)
        else()        
            set (LOOM_IOS_LEGACY 0)
        endif()

        set(CMAKE_EXE_LINKER_FLAGS "-framework Foundation -lz -framework QuartzCore -framework MediaPlayer -lxml2")

        set(CMAKE_OSX_SYSROOT iphoneos$(LOOM_IOS_VERSION) )
        set(CMAKE_OSX_ARCHITECTURES "armv7")
        set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos;-iphonesimulator")
        
        set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_ios/lib/libluajit-5.1.a)
        set (LOOM_SDL2_LIB ${CMAKE_SOURCE_DIR}/build/sdl2/ios/libSDL2.a)
        
        add_definitions(-DLOOM_RENDERER_OPENGLES2)

        include_directories( ${CMAKE_SOURCE_DIR}/loom/vendor/sdl2/include)

        list(APPEND LOOM_INCLUDE_FOLDERS ${CMAKE_SOURCE_DIR}/loom/engine/cocos2dx/platform/ios )

    else()

        set(CMAKE_EXE_LINKER_FLAGS "-framework Carbon -framework IOKit -framework Foundation -lz -framework QuartzCore -lxml2 -L/usr/local/lib")

        set(CMAKE_OSX_ARCHITECTURES "i386")
        set(CMAKE_OSX_DEPLOYMENT_TARGET 10.7)

        set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_x86/lib/libluajit-5.1.a)
        
    endif()

endif(APPLE)

#--------------------------------------
# Android
#--------------------------------------

if (ANDROID) 

    include (loom.android.toolchain)
	
    include_directories( ${CMAKE_SOURCE_DIR}/loom/vendor/sdl2/include)
	
    set (LOOM_INCLUDE_FOLDERS
    ${LOOM_INCLUDE_FOLDERS}
    ${CMAKE_SOURCE_DIR}/loom/vendor/glew-1.7.0/include
    ${CMAKE_SOURCE_DIR}/loom/engine/cocos2dx/platform/android )

    add_definitions(-DLOOM_DISABLE_JEMALLOC -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY)
    add_definitions(-DANDROID_NDK -DDISABLE_IMPORTGL -DBYTE_ORDER=_BYTE_ORDER)
    add_definitions(-DLUAJIT_OS=LUAJIT_OS_LINUX)
    add_definitions(-DLUAJIT_TARGET=LUAJIT_ARCH_ARM -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE)
    add_definitions(-D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_INT64__)
    add_definitions(-DLOOM_RENDERER_OPENGLES2)
    
    set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_android/lib/libluajit-5.1)
    set (LOOM_SDL2_LIB ${CMAKE_SOURCE_DIR}/build/sdl2/android/armeabi/libSDL2.a)
    

endif()

#--------------------------------------
# Linux
#--------------------------------------

if (LINUX)

    set (LOOM_INCLUDE_FOLDERS
        ${LOOM_INCLUDE_FOLDERS}
        ${CMAKE_SOURCE_DIR}/loom/engine/cocos2dx/platform/linux
        ${CMAKE_SOURCE_DIR}/loom/vendor/glew-1.7.0/include 
        /opt/vc/include)

    add_definitions(-DLOOM_DISABLE_JEMALLOC -DLOOM_LINUX_BUILD -DLINUX -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY)
    
    add_definitions(-DLOOM_RENDERER_OPENGLES2)

    add_definitions(-D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_CONSTANT_MACROS=1)

    # set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_x86/lib/libluajit-5.1.a)
    # set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_android/lib/libluajit-5.1)

    set (LOOM_LUAJIT_LIB ${CMAKE_SOURCE_DIR}/build/luajit_linux_arm/lib/libluajit-5.1.a)
    set (LOOM_SDL2_LIB ${CMAKE_SOURCE_DIR}/build/sdl2/android/armeabi/libSDL2.a)
    
endif()

#--------------------------------------
# Core Engine
#--------------------------------------
add_subdirectory(loom)

#--------------------------------------
# Application
#--------------------------------------
add_subdirectory(application)

#--------------------------------------
# Tools
#--------------------------------------
add_subdirectory(tools)

#--------------------------------------
# Artifacts
#--------------------------------------
include (loom.artifacts)
