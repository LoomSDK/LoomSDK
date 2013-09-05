if(NOT LOOM_BUILD_IOS EQUAL 1)
    set(CMAKE_OSX_ARCHITECTURES "i386;x86_64")
endif()

set (TARGET_NAME LoomCommon)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

# Define source files
file (GLOB CPP_FILES xml/*.cpp utils/*.cpp core/*.cpp core/*.c platform/*.cpp platform/*.c config/*.cpp)
file (GLOB H_FILES utils/*.h xml/*.h platform/*.h assets/*.c assets/*.cpp)

if (APPLE)
    if (LOOM_BUILD_IOS EQUAL 1)
        set (CPP_FILES ${CPP_FILES} 
            platform/platformDisplayIOS.mm 
            platform/platformFileIOS.m 
            platform/platformHTTPOSX.mm 
            platform/platformWebViewIOS.mm 
            platform/platformAdMobIOS.mm
            platform/platformStoreiOS.mm
            platform/platformVideoiOS.mm
            platform/EBPurchase.m
        )
    else()
        set (CPP_FILES ${CPP_FILES} 
            platform/platformFileIOS.m 
            platform/platformWebViewOSX.mm 
            platform/platformHTTPOSX.mm
        )
    endif()
endif(APPLE)

set (CPP_FILES ${CPP_FILES} input/platformGamePad.c)

if (MSVC)
    set (CPP_FILES ${CPP_FILES} input/platformGamePadWindows.c)
elseif(ANDROID)
	set (CPP_FILES ${CPP_FILES} input/platformGamePadOuya.cpp)
elseif(APPLE)
    if (LOOM_BUILD_IOS EQUAL 1)
        set (CPP_FILES ${CPP_FILES} input/platformGamePadNull.c)
    else()
        set (CPP_FILES ${CPP_FILES} input/platformGamePadOSX.cpp)
    endif()
else()
	set (CPP_FILES ${CPP_FILES} input/platformGamePadNull.c)
endif()

set (SOURCE_FILES ${CPP_FILES} ${H_FILES})

# Define target & libraries to link
add_library (${TARGET_NAME} STATIC ${SOURCE_FILES})


if (ANDROID)
    target_link_libraries(${TARGET_NAME} -lz LoomVendor )
endif(ANDROID)

if (LINUX)
    target_link_libraries(${TARGET_NAME} -lz -lrt -lcurl LoomVendor )
endif(LINUX)
