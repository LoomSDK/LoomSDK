 
project (LoomScript)

# Set minimum version
cmake_minimum_required (VERSION 2.8.6)

add_definitions(-DLOOM_DISABLE_JEMALLOC -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY -DLOOMSCRIPT_STANDALONE)

#use CMAKE_CURRENT_SOURCE_DIR so we can build in other CMake source hierarchies
include_directories( 
    ${CMAKE_CURRENT_SOURCE_DIR}/source
    source/loom/common
    source/loom/vendor/jansson
    source/loom/vendor/lua/src
    source/loom/vendor/seatest
    source/loom/vendor/jemalloc-3.4.0/include
)

set (VENDOR_SOURCE $$VENDOR_SOURCE$$)

set (LUA_SOURCE $$LUA_SOURCE$$)

set (CORE_SOURCE $$CORE_SOURCE$$)

set (COMPILER_SOURCE $$COMPILER_SOURCE$$)

set (SDK_SOURCES $$SDK_SOURCE$$)

if (MSVC OR APPLE OR LINUX)
    if (NOT LOOM_BUILD_IOS)                          
        set (CORE_SOURCE ${CORE_SOURCE} ${COMPILER_SOURCE} )
    endif()
endif()
                                
if (MSVC)                                
    list(REMOVE_ITEM CORE_SOURCE source/loom/script/native/core/system/Socket/usocket.c)
    list(REMOVE_ITEM CORE_SOURCE source/loom/script/native/core/system/Socket/unix.c)
else() 
    list(REMOVE_ITEM CORE_SOURCE source/loom/script/native/core/system/Socket/wsocket.c)
endif()                  

if (APPLE)
    set (OBJC_SOURCE $$OBJC_SOURCE$$)    
    set(CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework Carbon -framework Foundation -lz -framework QuartzCore -lxml2")
endif(APPLE)

add_library(loomscript STATIC ${VENDOR_SOURCE} ${LUA_SOURCE} ${CORE_SOURCE} ${COMPILER_SOURCE} ${OBJC_SOURCE})

add_executable(bin2c source/tools/bin2c/bin2c.c)

get_target_property(BIN2CBIN bin2c LOCATION)

add_custom_command(TARGET bin2c
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/temp && mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/bin && mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/libs
    COMMAND cp ${BIN2CBIN} ${CMAKE_CURRENT_SOURCE_DIR}/temp/bin2c
)

#lscbootstrap
add_executable(lscbootstrap source/tools/lsc/main.cpp)
target_link_libraries(lscbootstrap loomscript -lz -lpthread)

get_target_property(LSCBOOTSTRAPBIN lscbootstrap LOCATION)

add_custom_command(TARGET lscbootstrap
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/temp
    COMMAND cp ${LSCBOOTSTRAPBIN} ${CMAKE_CURRENT_SOURCE_DIR}/temp/lscbootstrap
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/temp/system_loomlib.c
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR}/sdk && ../temp/lscbootstrap System.build
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR}/sdk && ../temp/bin2c -o ${CMAKE_CURRENT_SOURCE_DIR}/temp/system_loomlib.c --name system_loomlib ./libs/System.loomlib
    DEPENDS lscbootstrap bin2c ${SDK_SOURCES}
    COMMENT "Building System Loom Library" )


add_executable(lsc source/tools/lsc/main.cpp ${CMAKE_CURRENT_SOURCE_DIR}/temp/system_loomlib.c)
set_target_properties(lsc PROPERTIES COMPILE_DEFINITIONS "LOOM_EMBEDDED_SYSTEMLIB=1")
target_link_libraries(lsc loomscript -lz -lpthread)

get_target_property(LSCBIN lsc LOCATION)

add_custom_command(TARGET lsc
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/artifacts
    COMMAND cp ${LSCBIN} ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/lsc
)

# loomrun
add_executable(loomrun source/tools/loomrun/main.cpp)

target_link_libraries(loomrun loomscript -lz -lpthread)

get_target_property(LOOMRUNBIN loomrun LOCATION)

add_custom_command(TARGET loomrun
    POST_BUILD
    COMMAND mkdir -p ${CMAKE_CURRENT_SOURCE_DIR}/artifacts
    COMMAND cp ${LOOMRUNBIN} ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/loomrun
)


