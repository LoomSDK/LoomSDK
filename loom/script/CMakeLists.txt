set (TARGET_NAME LoomScript)

include_directories(
    ${LOOM_INCLUDE_FOLDERS}
    ../common
)

# Define source files
file (GLOB CPP_FILES common/*.cpp native/*.cpp reflection/*.cpp runtime/*.cpp serialize/*.cpp 
                     native/core/*.cpp native/core/system/*.cpp
                     native/core/test/*.cpp 
                     native/core/system/Debugger/*.cpp
                     native/core/system/Metrics/*.cpp native/core/system/Reflection/*.cpp 
                     native/core/system/Socket/*.cpp native/core/system/Socket/*.c 
                     native/core/system/XML/*.cpp native/core/system/Platform/*.cpp
                     native/core/system/Utils/*.cpp native/core/assets/*.cpp )
                     
                     
if (MSVC OR APPLE OR LINUX)
    if (NOT LOOM_BUILD_IOS)                  
        file (GLOB COMPILER_FILES compiler/*.cpp compiler/builders/*.cpp native/core/compiler/*.cpp)
        set (CPP_FILES ${CPP_FILES} ${COMPILER_FILES} )
    endif()
endif()

                                
if (MSVC)                                
    list(REMOVE_ITEM CPP_FILES ${CMAKE_SOURCE_DIR}/loom/script/native/core/system/Socket/usocket.c)
    list(REMOVE_ITEM CPP_FILES ${CMAKE_SOURCE_DIR}/loom/script/native/core/system/Socket/unix.c)
else() 
    list(REMOVE_ITEM CPP_FILES ${CMAKE_SOURCE_DIR}/loom/script/native/core/system/Socket/wsocket.c)
endif()                  

file (GLOB H_FILES common/*.h compiler/*.h compiler/builders/*.h native/*.h native/core/*.h reflection/*.h runtime/*.h serialize/*.h)

set (SOURCE_FILES ${CPP_FILES} ${H_FILES})

# Define target & libraries to link
add_library (${TARGET_NAME} STATIC ${SOURCE_FILES})

if (MSVC OR (APPLE AND NOT LOOM_BUILD_IOS))
    target_link_libraries(${TARGET_NAME} "SDL2-static" "SDL2main")
else()
    target_link_libraries(${TARGET_NAME} "${LOOM_SDL2_LIB}" )
endif()

if (ANDROID)
    target_link_libraries(${TARGET_NAME} -lz LoomVendor LoomCommon )
endif(ANDROID)

if (LINUX)
    target_link_libraries(${TARGET_NAME} -lz LoomVendor LoomCommon SDL2-static ) # SDL2-static for SDL_qsort
endif(LINUX)
