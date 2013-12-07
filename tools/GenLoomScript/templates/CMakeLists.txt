 
project (LoomScript)

# Set minimum version
cmake_minimum_required (VERSION 2.8.6)

add_definitions(-DLOOM_DISABLE_JEMALLOC -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY -DLOOMSCRIPT_STANDALONE)

#use CMAKE_CURRENT_SOURCE_DIR so we can build in other CMake source hierarchies
include_directories( 
    ${CMAKE_CURRENT_SOURCE_DIR}
    loom/common
    loom/vendor/jansson
    loom/vendor/lua/src
    loom/vendor/seatest
    loom/vendor/jemalloc-3.4.0/include
)

set (VENDOR_SOURCE $$VENDOR_SOURCE$$)

set (LUA_SOURCE $$LUA_SOURCE$$)

set (CORE_SOURCE $$CORE_SOURCE$$)

set (COMPILER_SOURCE $$COMPILER_SOURCE$$)

if (MSVC OR APPLE OR LINUX)
    if (NOT LOOM_BUILD_IOS)                          
        set (CORE_SOURCE ${CORE_SOURCE} ${COMPILER_SOURCE} )
    endif()
endif()
                                
if (MSVC)                                
    list(REMOVE_ITEM CORE_SOURCE loom/script/native/core/system/Socket/usocket.c)
    list(REMOVE_ITEM CORE_SOURCE loom/script/native/core/system/Socket/unix.c)
else() 
    list(REMOVE_ITEM CORE_SOURCE loom/script/native/core/system/Socket/wsocket.c)
endif()                  

if (APPLE)
    set (OBJC_SOURCE $$OBJC_SOURCE$$)    
    set(CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework Carbon -framework Foundation -lz -framework QuartzCore -lxml2")
endif(APPLE)

add_library(loomscript STATIC ${VENDOR_SOURCE} ${LUA_SOURCE} ${CORE_SOURCE} ${COMPILER_SOURCE} ${OBJC_SOURCE})

#tinylsc 

add_executable(lsc tools/lsc/main.cpp)

target_link_libraries(lsc loomscript -lz -lpthread)

get_target_property(LSCBIN lsc LOCATION)

add_custom_command(TARGET lsc
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/artifacts
    COMMAND cp ${LSCBIN} ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/lsc
)

# loomrun

add_executable(loomrun tools/loomrun/main.cpp)

target_link_libraries(loomrun loomscript -lz -lpthread)

get_target_property(LOOMRUNBIN loomrun LOCATION)

add_custom_command(TARGET loomrun
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/artifacts
    COMMAND cp ${LOOMRUNBIN} ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/loomrun
)


