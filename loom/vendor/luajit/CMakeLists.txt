# Copyright (C) 2007-2013 LuaDist.
# Created by Peter Drahoš
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

# NOTE: This build is currently only supporting x86 targets, for other targets use the original makefile. Please do not submit bugs to the LuaJIT author in case this build fails, instead use http://github.com/LuaDist/luajit

project ( luajit C ASM)
cmake_minimum_required ( VERSION 2.8 )
include ( cmake/dist.cmake )
include ( lua )

## CONFIGURATION
# Default configuration (we assume POSIX by default)
set ( LUA_PATH "LUA_PATH" CACHE STRING "Environment variable to use as package.path." )
set ( LUA_CPATH "LUA_CPATH" CACHE STRING "Environment variable to use as package.cpath." )
set ( LUA_INIT "LUA_INIT" CACHE STRING "Environment variable for initial script." )

option ( LUA_ANSI "Use only ansi features." OFF )
option ( LUA_USE_RELATIVE_LOADLIB "Use modified loadlib.c with support for relative paths on posix systems." ON)
set ( LUA_IDSIZE 60 CACHE NUMBER "gives the maximum size for the description of the source." )
set ( LUA_PROMPT "> " CACHE STRING "Is the default prompt used by stand-alone Lua." )
set ( LUA_PROMPT2 ">> " CACHE STRING "Is the default continuation prompt used by stand-alone Lua." )
set ( LUA_MAXINPUT 512 CACHE NUMBER "Is the maximum length for an input line in the stand-alone interpreter.")

# Version
set ( MAJVER 2 )
set ( MINVER 0 )
set ( RELVER 2 )
set ( ABIVER 5.1 )
set ( NODOTABIVER 51 )

# Extra flags
option ( LUAJIT_DISABLE_FFI "Permanently disable the FFI extension to reduce the size of the LuaJIT executable. But please consider that the FFI library is compiled-in, but NOT loaded by default. It only allocates any memory, if you actually make use of it." OFF )
option ( LUAJIT_ENABLE_LUA52COMPAT "Features from Lua 5.2 that are unlikely to break existing code are enabled by default. Some other features that *might* break some existing code (e.g. __pairs or os.execute() return values) can be enabled here. Note: this does not provide full compatibility with Lua 5.2 at this time." ON )
option ( LUAJIT_DISABLE_JIT "Disable the JIT compiler, i.e. turn LuaJIT into a pure interpreter." OFF )

option ( LUAJIT_USE_SYSMALLOC "Use the system provided memory allocator (realloc) instead of the bundled memory allocator. This is slower, but sometimes helpful for debugging. It's helpful for Valgrind's memcheck tool, too. This option cannot be enabled on x64, since the built-in allocator is mandatory." OFF )
option ( LUAJIT_USE_VALGRIND "This option is required to run LuaJIT under Valgrind. The Valgrind header files must be installed. You should enable debug information, too." OFF )
option ( LUAJIT_USE_GDBJIT "This is the client for the GDB JIT API. GDB 7.0 or higher is required to make use of it. See lj_gdbjit.c for details. Enabling this causes a non-negligible overhead, even when not running under GDB." OFF )

option ( LUA_USE_APICHECK "Turn on assertions for the Lua/C API to debug problems with lua_* calls. This is rather slow, use only while developing C libraries/embeddings." OFF )
option ( LUA_USE_ASSERT "Turn on assertions for the whole LuaJIT VM. This significantly slows down everything. Use only if you suspect a problem with LuaJIT itself." OFF )

option ( LUAJIT_CPU_SSE2 "Disable SSE2." OFF )
option ( LUAJIT_CPU_NOCMOV "Disable NOCMOV." OFF )

option ( BOOTSTRAP_ONLY "Build only the host tools" OFF )
option ( TARGET_ONLY "Build only the library" OFF )

# Tunable variables
set ( LUAI_MAXSTACK 65500 CACHE NUMBER "Max. # of stack slots for a thread (<64K)." )
set ( LUAI_MAXCSTACK 8000 CACHE NUMBER "Max. # of stack slots for a C func (<10K)." )
set ( LUAI_GCPAUSE 200 CACHE NUMBER "Pause GC until memory is at 200%." )
set ( LUAI_GCMUL 200 CACHE NUMBER "Run GC at 200% of allocation speed." )
set ( LUA_MAXCAPTURES 32 CACHE NUMBER "Max. pattern captures." )

## SETUP
set ( LUA_DIRSEP "/" )
set ( LUA_MODULE_SUFFIX ${CMAKE_SHARED_MODULE_SUFFIX} )
set ( LUA_LDIR ${INSTALL_LMOD} )
set ( LUA_CDIR ${INSTALL_CMOD} )

if ( NOT DEFINED LUA_TARGET_ARCH )
    set ( LUA_TARGET_ARCH "x86")
endif ()

if ( LUA_USE_RELATIVE_LOADLIB )
  # This will set up relative paths to lib
  string ( REGEX REPLACE "[^!/]+" ".." LUA_DIR "!/${INSTALL_BIN}/" )
else ()
  # Direct path to installation
  set ( LUA_DIR ${CMAKE_INSTALL_PREFIX} CACHE STRING "Destination from which modules will be resolved. See INSTALL_LMOD and INSTALL_CMOD.")
endif ()

set ( LUA_PATH_DEFAULT "./?.lua;${LUA_DIR}${LUA_LDIR}/?.lua;${LUA_DIR}${LUA_LDIR}/?/init.lua;./?/init.lua" )
set ( LUA_CPATH_DEFAULT "./?${LUA_MODULE_SUFFIX};${LUA_DIR}${LUA_CDIR}/?${LUA_MODULE_SUFFIX};${LUA_DIR}${LUA_CDIR}/loadall${LUA_MODULE_SUFFIX}" )

if ( LUA_GC_PROFILE_ENABLED EQUAL 1 )
    add_definitions(-DLUA_GC_PROFILE_ENABLED=1)
endif ()

if ( WIN32 AND NOT CYGWIN )
  # Windows systems
  option ( LUA_BUILD_WLUA "Build wluajit interpreter for no-console applications." ON )
  set ( LJVM_MODE peobj )
  # Paths (Double escapes needed)
  set ( LUA_DIRSEP "\\\\" )
  string ( REPLACE "/" ${LUA_DIRSEP} LUA_DIR "${LUA_DIR}" )
  string ( REPLACE "/" ${LUA_DIRSEP} LUA_LDIR "${LUA_LDIR}" )
  string ( REPLACE "/" ${LUA_DIRSEP} LUA_CDIR "${LUA_CDIR}" )
  string ( REPLACE "/" ${LUA_DIRSEP} LUA_PATH_DEFAULT "${LUA_PATH_DEFAULT}" )
  string ( REPLACE "/" ${LUA_DIRSEP} LUA_CPATH_DEFAULT "${LUA_CPATH_DEFAULT}" )

elseif ( APPLE )
  if ( LUAJIT_X64 )
    set ( CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000" )
  endif ()
  option ( LUA_USE_POSIX "Use POSIX functionality." ON )
  option ( LUA_USE_DLOPEN "Use dynamic linker to load modules." ON )
  set ( LJVM_MODE machasm )
else ()
  option ( LUA_USE_POSIX "Use POSIX functionality." ON )
  option ( LUA_USE_DLOPEN "Use dynamic linker to load modules." ON )
  set ( LJVM_MODE elfasm )
endif ()

## LIBRARY DETECTION
# Optional libraries
find_package ( Readline )
if ( READLINE_FOUND )
  option ( LUA_USE_READLINE "Use readline in the Lua CLI." ON )
endif ()

find_package ( Curses )
if ( CURSES_FOUND )
  option ( LUA_USE_CURSES "Use curses in the Lua CLI." ON )
endif ()

# Setup needed variables and libraries
if ( LUA_USE_POSIX )
  # On POSIX Lua links to standard math library "m"
  list ( APPEND LIBS m )
endif ()

if ( LUA_USE_DLOPEN )
  # Link to dynamic linker library "dl"
  list ( APPEND LIBS dl )
endif ()

if ( LUA_USE_READLINE )
  # Add readline
  include_directories ( ${READLINE_INCLUDE_DIR} )
  list ( APPEND LIBS ${READLINE_LIBRARY} )
endif ()

if ( LUA_USE_CURSES )
  # Add curses
  include_directories ( ${CURSES_INCLUDE_DIR} )
  list ( APPEND LIBS ${CURSES_LIBRARY} )
endif ()

# First for the generic no-config case (e.g. with mingw)
set( CMAKE_EXECUTABLE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} )
# Second, for multi-config builds (e.g. msvc)
foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
    string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
    set( CMAKE_EXECUTABLE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_BINARY_DIR} )
    set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_BINARY_DIR} )
    set( CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_BINARY_DIR} )
    set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_CURRENT_BINARY_DIR} )
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

set (EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
set (LIBRARY_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})

## SOURCES
# Generate luaconf.h
configure_file ( src/luaconf.h.in ${CMAKE_CURRENT_BINARY_DIR}/luaconf.h )

set ( LJLIB_C
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_base.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_math.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_bit.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_string.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_table.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_io.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_os.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_debug.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_jit.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_ffi.c
)

## LuaJIT Library
include_directories ( ${CMAKE_CURRENT_BINARY_DIR} dynasm src src/host )

if ( LUA_USE_RELATIVE_LOADLIB )
  list ( APPEND LJLIB_C ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_package_rel.c )
else ()
  list ( APPEND LJLIB_C ${CMAKE_CURRENT_SOURCE_DIR}/src/lib_package.c )
endif ()

if ( BOOTSTRAP_ONLY AND TARGET_ONLY )
    message ( FATAL_ERROR "Only one of BOOTSTRAP_ONLY and TARGET_ONLY can be set." )
endif ()

if ( TARGET_ONLY )
    if ( NOT DEFINED BOOTSTRAP_PATH )
        message ( FATAL_ERROR "TARGET_ONLY is set, but no BOOTSTRAP_PATH is set!" )
    endif()
else ()
    set ( BOOTSTRAP_PATH ${CMAKE_CURRENT_BINARY_DIR} )
endif ()

# Dynasm
set ( DASM ${CMAKE_CURRENT_SOURCE_DIR}/dynasm/dynasm.lua )
set ( DASM_T ${CMAKE_CURRENT_BINARY_DIR}/buildvm_arch.h )

# 2DO: Proper detection of flags
set ( DASM_VER "" )
set ( DASM_FLAGS -D FPU -D HFABI )
set ( DASM_ARCH x86 )

# Raspberry PI, ARM
if ( ${CMAKE_SYSTEM_PROCESSOR} MATCHES "armv6l" OR LUA_TARGET_ARCH STREQUAL "arm")
  set ( DASM_ARCH arm )
  list ( APPEND DASM_FLAGS -D DUALNUM )
  set ( DASM_VER 60 )
  add_definitions ( -D__ARM_PCS_VFP=1 )
  if ( DEFINED LUAJIT_OS AND LUAJIT_OS STREQUAL "LUAJIT_OS_OSX" )
    list ( APPEND DASM_FLAGS -D IOS )
  endif ()
endif ()

# 32bit vs 64bit
if ( LUAJIT_X64 )
  list ( APPEND DASM_FLAGS -D P64 )
endif ()

if ( DEFINED LUAJIT_OS AND LUAJIT_OS STREQUAL "LUAJIT_OS_OSX" )
  if (LUAJIT_X64)
    set ( CMAKE_OSX_ARCHITECTURES "x86_64" )
  else ()
    set ( CMAKE_OSX_ARCHITECTURES "i386" )
  endif ()
endif ()

if ( NOT LUAJIT_DISABLE_JIT )
  list ( APPEND DASM_FLAGS -D JIT )
endif ()

if ( NOT LUAJIT_DISABLE_FFI )
  list ( APPEND DASM_FLAGS -D FFI )
endif ()

if ( NOT LUAJIT_CPU_SSE2 )
  list ( APPEND DASM_FLAGS -D SSE2 )
endif ()

if ( DEFINED LUAJIT_OS )
    add_definitions ( -DLUAJIT_OS=${LUAJIT_OS} )
    if ( ${LUAJIT_OS} STREQUAL "LUAJIT_OS_WINDOWS" )
        list ( APPEND DASM_FLAGS -D WIN )
    endif()
else()
    if ( WIN32 )
        add_definitions (-DLUAJIT_OS=LUAJIT_OS_WINDOWS)
        list ( APPEND DASM_FLAGS -D WIN )
    endif ()
endif()


if ( ${DASM_ARCH} STREQUAL "x86" )
  if ( LUAJIT_X64 )
    set ( LUAJIT_TARGET_ARCH_NUM LUAJIT_ARCH_X64 )
  else ()
    set ( LUAJIT_TARGET_ARCH_NUM LUAJIT_ARCH_X86 )
  endif()
elseif ( ${DASM_ARCH} STREQUAL "arm" )
  set ( LUAJIT_TARGET_ARCH_NUM LUAJIT_ARCH_ARM )
else ()
  message ( FATAL_ERROR "Architecture not suported" )
endif ()

add_definitions (-DLUAJIT_TARGET=${LUAJIT_TARGET_ARCH_NUM} )
add_definitions (-DLUAJIT_ENABLE_JIT=1)

list ( APPEND DASM_FLAGS -D VER=${DASM_VER} )

string ( REPLACE ";" " " DASM_FLAGS_STR "${DASM_FLAGS}")

message ( "DASM_FLAGS: ${DASM_FLAGS_STR}")
message ( "DASM_ARCH: ${DASM_ARCH}" )

set ( DASM_DASC ${CMAKE_CURRENT_SOURCE_DIR}/src/vm_${DASM_ARCH}.dasc )

if ( NOT TARGET_ONLY )
    ## GENERATE VM
    # Build minilua
    add_executable ( minilua src/host/minilua.c )
    target_link_libraries ( minilua ${LIBS} )

    # Generate buildvm arch header
    add_custom_command(OUTPUT ${DASM_T}
      COMMAND ${BOOTSTRAP_PATH}/minilua ${DASM} ${DASM_FLAGS} -o ${DASM_T} ${DASM_DASC}
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
      DEPENDS minilua
    )

    # Buildvm
    file ( GLOB SRC_BUILDVM src/host/buildvm*.c )
    add_executable ( buildvm ${SRC_BUILDVM} ${DASM_T} )

endif ()

if ( NOT BOOTSTRAP_ONLY )

    if ( DASM_ARCH STREQUAL arm AND DEFINED LUAJIT_OS AND LUAJIT_OS STREQUAL "LUAJIT_OS_OSX" )
      set(CMAKE_OSX_SYSROOT iphoneos6.1)
      set(CMAKE_OSX_ARCHITECTURES "armv7")
      set(CMAKE_XCODE_EFFECTIVE_PLATOFRMS "-iphoneos;-iphonesimulator")
    endif ()

    if ( NOT TARGET_ONLY )
      set ( BUILDVM_DEP "buildvm" )
    endif ()

    macro(add_buildvm_target _target _mode)
      add_custom_command(OUTPUT ${_target}
        COMMAND ${BOOTSTRAP_PATH}/buildvm ARGS -m ${_mode} -o ${CMAKE_CURRENT_BINARY_DIR}/${_target} ${ARGN}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS ${BUILDVM_DEP} ${ARGN}
      )
    endmacro(add_buildvm_target)

    if ( WIN32 AND NOT CYGWIN )
      add_buildvm_target ( lj_vm.obj peobj )
      set (LJ_VM_SRC ${CMAKE_CURRENT_BINARY_DIR}/lj_vm.obj)
    else ()
      add_buildvm_target ( lj_vm.s ${LJVM_MODE} )
      set (LJ_VM_SRC ${CMAKE_CURRENT_BINARY_DIR}/lj_vm.s)
    endif ()

    add_buildvm_target ( lj_ffdef.h   ffdef   ${LJLIB_C} )
    add_buildvm_target ( lj_bcdef.h  bcdef  ${LJLIB_C} )
    add_buildvm_target ( lj_folddef.h folddef ${CMAKE_CURRENT_SOURCE_DIR}/src/lj_opt_fold.c )
    add_buildvm_target ( lj_recdef.h  recdef  ${LJLIB_C} )
    add_buildvm_target ( lj_libdef.h  libdef  ${LJLIB_C} )
    add_buildvm_target ( jit/vmdef.lua  libvm  ${LJLIB_C} )

    SET ( DEPS
      ${LJ_VM_SRC}
      lj_ffdef.h
      lj_bcdef.h
      lj_libdef.h
      lj_recdef.h
      lj_folddef.h
    )

    set ( LJCORE_C
      src/lj_gc.c
      src/lj_err.c
      src/lj_char.c
      src/lj_bc.c
      src/lj_obj.c
      src/lj_str.c
      src/lj_tab.c
      src/lj_func.c
      src/lj_udata.c
      src/lj_meta.c
      src/lj_debug.c
      src/lj_state.c
      src/lj_dispatch.c
      src/lj_vmevent.c
      src/lj_vmmath.c
      src/lj_strscan.c
      src/lj_api.c
      src/lj_lex.c
      src/lj_parse.c
      src/lj_bcread.c
      src/lj_bcwrite.c
      src/lj_load.c
      src/lj_ir.c
      src/lj_opt_mem.c
      src/lj_opt_fold.c
      src/lj_opt_narrow.c
      src/lj_opt_dce.c
      src/lj_opt_loop.c
      src/lj_opt_split.c
      src/lj_opt_sink.c
      src/lj_mcode.c
      src/lj_snap.c
      src/lj_record.c
      src/lj_crecord.c
      src/lj_ffrecord.c
      src/lj_asm.c
      src/lj_trace.c
      src/lj_gdbjit.c
      src/lj_ctype.c
      src/lj_cdata.c
      src/lj_cconv.c
      src/lj_ccall.c
      src/lj_ccallback.c
      src/lj_carith.c
      src/lj_clib.c
      src/lj_cparse.c
      src/lj_lib.c
      src/lj_alloc.c
      src/lib_aux.c
      src/lib_init.c
      ${LJLIB_C}
    )

    if (MSVC)
     add_definitions(/MT)
    endif(MSVC)

    add_library ( libluajit STATIC ${LJCORE_C} ${DEPS} )
    target_link_libraries ( libluajit ${LIBS} )
    set_target_properties ( libluajit PROPERTIES OUTPUT_NAME luajit CLEAN_DIRECT_OUTPUT 1 )

endif ()

## LuaJIT Executable
#add_executable ( luajit src/luajit.c src/luajit.rc )
#target_link_libraries ( luajit libluajit )

# On Windows build a no-console variant also
#if ( LUA_BUILD_WLUA )
#  add_executable ( wluajit WIN32 src/wmain.c src/luajit.c src/luajit.rc )
#  target_link_libraries ( wluajit libluajit )
#  install_executable ( wluajit )
#endif ()

## INSTALL
#install_executable( luajit )
#install_library( libluajit )
#install_header( src/lua.h src/luajit.h src/lua.hpp ${CMAKE_CURRENT_BINARY_DIR}/luaconf.h src/lualib.h src/lauxlib.h )

#install_doc ( doc/ )
#install_foo ( etc/ )
#install_data ( COPYRIGHT README.md )
