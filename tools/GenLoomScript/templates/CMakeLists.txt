 
project (LoomScript)

# Set minimum version
cmake_minimum_required (VERSION 2.8.6)

#use CMAKE_CURRENT_SOURCE_DIR so we can build in other CMake source hierarchies
include_directories( 
    ${CMAKE_CURRENT_SOURCE_DIR}/source
    source/loom/common
    source/loom/vendor/jansson
    source/loom/vendor/lua/src
    source/loom/vendor/seatest
    source/loom/vendor/jemalloc-4.0.1/include
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
                                
#source twiddling
if (MSVC)
    list(REMOVE_ITEM CORE_SOURCE source/loom/script/native/core/system/Socket/usocket.c)
    list(REMOVE_ITEM CORE_SOURCE source/loom/script/native/core/system/Socket/unix.c)
else() 
    list(REMOVE_ITEM CORE_SOURCE source/loom/script/native/core/system/Socket/wsocket.c)
endif()                  


add_definitions(-DLOOMSCRIPT_STANDALONE -DLOOM_BUILD_JIT=0 -DLOOM_BUILD_ADMOB=1 -DLOOM_BUILD_FACEBOOK=1)

if (APPLE)

    add_definitions(-DLOOM_DISABLE_JEMALLOC -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY)

    set (OBJC_SOURCE $$OBJC_SOURCE$$)    
    set(CMAKE_EXE_LINKER_FLAGS "-framework IOKit -framework Carbon -framework Foundation -lz -framework QuartzCore -lxml2 -lz -lpthread")

endif(APPLE)

if (MSVC)
    add_definitions(-DLOOM_DISABLE_JEMALLOC -D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_CONSTANT_MACROS=1)
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE)
    include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/source/loom/vendor/jemalloc-4.0.1/include/msvc_compat )
    include_directories( ${CMAKE_SOURCE_DIR}/source/loom/vendor/zlib/include )

    set(CMAKE_EXE_LINKER_FLAGS "kernel32.lib advapi32.lib COMCTL32.lib COMDLG32.lib USER32.lib ADVAPI32.lib GDI32.lib WINMM.lib WSOCK32.lib Ws2_32.lib")

endif(MSVC)

add_library(loomscript STATIC ${VENDOR_SOURCE} ${LUA_SOURCE} ${CORE_SOURCE} ${COMPILER_SOURCE} ${OBJC_SOURCE})

macro(copy_binary TARGET DESTINATION)

get_target_property(TARGETBIN ${TARGET} LOCATION)

message(${TARGETBIN})

if (MSVC)
add_custom_command(TARGET ${TARGET}
    POST_BUILD
    COMMAND echo f | xcopy /F /Y \"${TARGETBIN}\" \"${DESTINATION}\\${TARGET}.exe\") | find /v "File(s) copied"
endif(MSVC)

endmacro()

add_executable(bin2c source/tools/bin2c/bin2c.c)
copy_binary(bin2c "${CMAKE_CURRENT_SOURCE_DIR}/temp")

#lscbootstrap
add_executable(lscbootstrap source/tools/lsc/main.cpp)
target_link_libraries(lscbootstrap loomscript)

copy_binary(lscbootstrap "${CMAKE_CURRENT_SOURCE_DIR}/temp")

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/temp/system_loomlib.c
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR}/sdk && ${CMAKE_CURRENT_SOURCE_DIR}/temp/lscbootstrap System.build
    COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR}/sdk && ${CMAKE_CURRENT_SOURCE_DIR}/temp/bin2c -o ${CMAKE_CURRENT_SOURCE_DIR}/temp/system_loomlib.c --name system_loomlib ./libs/System.loomlib
    DEPENDS lscbootstrap bin2c ${SDK_SOURCES}
    COMMENT "Building System Loom Library" )


add_executable(lsc source/tools/lsc/main.cpp ${CMAKE_CURRENT_SOURCE_DIR}/temp/system_loomlib.c)
set_target_properties(lsc PROPERTIES COMPILE_DEFINITIONS "LOOM_EMBEDDED_SYSTEMLIB=1")
target_link_libraries(lsc loomscript)

copy_binary(lsc "${ARTIFACTS_DIR}/tools")


# loomrun
add_executable(loomrun source/tools/loomrun/main.cpp)

target_link_libraries(loomrun loomscript)

copy_binary(loomrun "${ARTIFACTS_DIR}/tools")