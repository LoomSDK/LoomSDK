# Set the TOOLCHAIN_PREFIX to wherever you installed the toolchain
#
# NOTE: If you change this, change the path in the CROSS variable in
#       BBBToolchain class in build/libs/toolchains.rb as well.

set(TOOLCHAIN_PREFIX /usr/local/loom/toolchain-bbb)

#
# Don't change anything below this line
#

set(TOOLCHAIN_BIN_PREFIX ${TOOLCHAIN_PREFIX}/bin/)
set(USERSPACE_PREFIX ${TOOLCHAIN_PREFIX}/arm-linux-musleabihf)

#
# rake clean && time rake build:bbb && cp -R artifacts/linux-bbb ~/.loom/sdks/dev/bin/.
#


set(LOOM_BUILD_BBB 1)
add_definitions(-DLOOM_BUILD_BBB=1)

set(CMAKE_SYSTEM_NAME  Linux)
set(CMAKE_C_COMPILER   ${TOOLCHAIN_BIN_PREFIX}arm-linux-musleabihf-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_BIN_PREFIX}arm-linux-musleabihf-g++)
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_BIN_PREFIX}arm-linux-musleabihf-gcc)
set(CMAKE_AR           ${TOOLCHAIN_BIN_PREFIX}arm-linux-musleabihf-ar CACHE FILEPATH "Archiver")
set(CMAKE_RANLIB       ${TOOLCHAIN_BIN_PREFIX}arm-linux-musleabihf-ranlib CACHE FILEPATH "Ranlib")
set(CMAKE_LD           ${TOOLCHAIN_BIN_PREFIX}arm-linux-musleabihf-ld CACHE FILEPATH "Linker")

set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_CXX_FLAGS_RELEASE        "-O3 -DNDEBUG -fno-keep-static-consts" CACHE STRING "")
set(CMAKE_CXX_FLAGS_MINSIZEREL     "-Os -DNDEBUG -fno-keep-static-consts" CACHE STRING "")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS         "-Wl,--gc-sections" CACHE STRING "")

add_definitions("-fPIC")

set(ARTIFACTS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/artifacts/linux-bbb)

add_definitions(-DLOOM_DISABLE_JEMALLOC -DLOOM_LINUX_BUILD -DLINUX -DHAVE_CXA_DEMANGLE -DNPERFORMANCE -DNTELEMETRY)
add_definitions(-D__STDC_LIMIT_MACROS=1 -D__STDINT_MACROS=1 -D__STDC_CONSTANT_MACROS=1)
add_definitions(-DLOOM_BUILD_64BIT=0)

add_definitions(-DLOOM_RENDERER_OPENGLES2=1)

# musl-libc lacks this
add_definitions(-DGLOB_TILDE=0)

add_definitions(-I${USERSPACE_PREFIX}/include)
add_definitions(-I${USERSPACE_PREFIX}/include/OGLES2)
add_definitions(-I${USERSPACE_PREFIX}/include/SDL2)

set(LOOM_SDL2_LIB -L${USERSPACE_PREFIX}/lib libSDL2.a libSDL2main.a libasound.a)

link_libraries(-L${USERSPACE_PREFIX}/lib libcurl.a libssl.a libcrypto.a)
