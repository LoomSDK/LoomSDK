project (LoomScript)

# Set minimum version
cmake_minimum_required (VERSION 2.8.6)

add_definitions(-DLOOM_DISABLE_JEMALLOC -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY)

$INCLUDE_DIRS$

#jansson
file (GLOB JANSSON_SRC loom/vendor/jansson/src/*.c)

#lua (we'll add LuaJIT later)
file (GLOB LUA_SRC loom/vendor/lua/src/*.c)

#seatest (we'll add LuaJIT later)
set (SEATEST_SRC loom/vendor/seatest/seatest.c)

# Common files
file (GLOB COMMON_SRC 
    loom/common/xml/*.cpp 
    loom/common/utils/*.cpp 
    loom/common/core/*.cpp 
    loom/common/core/*.c 
    loom/common/platform/*.cpp 
    loom/common/platform/*.c )

if (APPLE)
    set (COMMON_SRC ${COMMON_SRC} loom/common/platform/platformFileIOS.m)        
    set(CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework Carbon -framework Foundation -lz -framework QuartzCore -lxml2")
    set(CMAKE_OSX_ARCHITECTURES "i386")
    set(CMAKE_OSX_DEPLOYMENT_TARGET 10.7)
endif(APPLE)

# Script Files

# Define source files
file (GLOB SCRIPT_SRC 
    loom/script/common/*.cpp 
    loom/script/native/*.cpp 
    loom/script/reflection/*.cpp 
    loom/script/runtime/*.cpp 
    loom/script/serialize/*.cpp 
    loom/script/native/core/*.cpp 
    loom/script/native/core/system/*.cpp
    loom/script/native/core/test/*.cpp 
    loom/script/native/core/system/Debugger/*.cpp
    loom/script/native/core/system/Metrics/*.cpp 
    loom/script/native/core/system/Reflection/*.cpp 
    loom/script/native/core/system/Socket/*.cpp 
    loom/script/native/core/system/Socket/*.c 
    loom/script/native/core/system/XML/*.cpp 
    loom/script/native/core/system/Platform/*.cpp
    loom/script/native/core/system/Utils/*.cpp 
    loom/script/native/core/assets/*.cpp )
                     
                     
if (MSVC OR APPLE OR LINUX)
    if (NOT LOOM_BUILD_IOS)                  
        file (GLOB COMPILER_SRC loom/script/compiler/*.cpp loom/script/compiler/builders/*.cpp loom/script/native/core/compiler/*.cpp)
        set (SCRIPT_SRC ${SCRIPT_SRC} ${COMPILER_SRC} )
    endif()
endif()

                                
if (MSVC)                                
    list(REMOVE_ITEM SCRIPT_SRC ${CMAKE_CURRENT_SOURCE_DIR}/loom/script/native/core/system/Socket/usocket.c)
    list(REMOVE_ITEM SCRIPT_SRC ${CMAKE_CURRENT_SOURCE_DIR}/loom/script/native/core/system/Socket/unix.c)
else() 
    list(REMOVE_ITEM SCRIPT_SRC ${CMAKE_CURRENT_SOURCE_DIR}/loom/script/native/core/system/Socket/wsocket.c)
endif()                  


add_library(tinyloomscript STATIC ${JANSSON_SRC} ${LUA_SRC} ${SEATEST_SRC} ${COMMON_SRC} ${SCRIPT_SRC})

#tinylsc 

add_executable(tinylsc loom/tinylsc/main.cpp)

target_link_libraries(tinylsc tinyloomscript -lz -lpthread)

get_target_property(TINYLSCBIN tinylsc LOCATION)

add_custom_command(TARGET tinylsc
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts
    COMMAND cp ${TINYLSCBIN} ${CMAKE_SOURCE_DIR}/artifacts/tinylsc
)

# tinyrun

add_executable(tinyrun loom/tinyrun/main.cpp)

target_link_libraries(tinyrun tinyloomscript -lz -lpthread)

get_target_property(TINYRUNBIN tinyrun LOCATION)

add_custom_command(TARGET tinyrun
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts
    COMMAND cp ${TINYRUNBIN} ${CMAKE_SOURCE_DIR}/artifacts/tinyrun
)