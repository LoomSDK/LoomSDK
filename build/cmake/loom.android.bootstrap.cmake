# Set Android lib output dir
set( LIBRARY_OUTPUT_PATH_ROOT ${CMAKE_SOURCE_DIR}/application/android CACHE PATH "Root for Android binaries output, set this to change where Android libs are installed to" )
include(${CMAKE_CURRENT_LIST_DIR}/android.toolchain.cmake)