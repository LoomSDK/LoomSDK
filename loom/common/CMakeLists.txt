set (TARGET_NAME LoomCommon)

include_directories( ${LOOM_INCLUDE_FOLDERS} )

# Define source files
file (GLOB CPP_FILES xml/*.cpp utils/*.cpp utils/*.c core/*.cpp core/*.c platform/*.cpp platform/*.c config/*.cpp)
file (GLOB H_FILES utils/*.h xml/*.h platform/*.h assets/*.c assets/*.cpp)

if (APPLE)
    set (CPP_FILES ${CPP_FILES}
        platform/platformCocoa.mm
    )
    if (LOOM_BUILD_IOS EQUAL 1)
        set (CPP_FILES ${CPP_FILES} 
            platform/platformDisplayIOS.mm 
            platform/platformFileIOS.mm
            platform/platformHTTPOSX.mm 
            platform/platformWebViewCocoa.mm 
            platform/platformStoreiOS.mm
            platform/platformVideoiOS.mm
            platform/platformMobileiOS.mm
            platform/platformFontIOS.mm
            platform/EBPurchase.m
        )
        
        # Allow Admob and/or Facebook to be included for iOS?
        if(LOOM_BUILD_ADMOB EQUAL 1)
            set (CPP_FILES ${CPP_FILES} 
                platform/platformAdMobIOS.mm
            )
        endif()
        if(LOOM_BUILD_FACEBOOK EQUAL 1)
            set (CPP_FILES ${CPP_FILES} 
                platform/platformFacebookiOS.mm
            )
        endif()

        set (CPP_FILES ${CPP_FILES} 
            platform/platformParseiOS.mm
        )

    else()
        set (CPP_FILES ${CPP_FILES} 
            platform/platformFileIOS.mm
            platform/platformWebViewCocoa.mm 
            platform/platformHTTPOSX.mm
        )
    endif()
endif(APPLE)

if (ANDROID)
    set (CPP_FILES ${CPP_FILES}
        platform/android/fts.c
        platform/android/ftw.cpp
        platform/android/reallocarray.c)
endif(ANDROID)

set (SOURCE_FILES ${CPP_FILES} ${H_FILES})

# Define target & libraries to link
add_library (${TARGET_NAME} STATIC ${SOURCE_FILES})


if (ANDROID)
    target_link_libraries(${TARGET_NAME} -lz LoomVendor )
endif(ANDROID)

if (LINUX)
    target_link_libraries(${TARGET_NAME} -lz -lrt -lcurl LoomVendor)
endif(LINUX)
