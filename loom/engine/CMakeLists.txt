project(LoomCore)

include_directories(
    ${LOOM_INCLUDE_FOLDERS}
)

set (ENGINE_SRC

    allTests.cpp
            
    loom2d/l2dPoint.cpp
    loom2d/l2dMatrix.cpp
    loom2d/l2dDisplayObject.cpp
    loom2d/l2dDisplayObjectContainer.cpp
    loom2d/l2dSprite.cpp
    loom2d/l2dShape.cpp
    loom2d/l2dStage.cpp
    loom2d/l2dQuad.cpp
    loom2d/l2dImage.cpp
    loom2d/l2dQuadBatch.cpp
    loom2d/l2dBlendMode.cpp
    loom2d/l2dScript.cpp
    
    bindings/loom/lmApplication.cpp
    bindings/loom/lmApplicationTasks.cpp
    bindings/loom/lmWebView.cpp
    bindings/loom/lmAdMob.cpp
    bindings/loom/lmBox2D.cpp
    bindings/loom/lmHTTPRequest.cpp
    bindings/loom/lmStore.cpp
    bindings/loom/lmVideo.cpp
    bindings/loom/lmMobile.cpp
    bindings/loom/lmParse.cpp
    bindings/loom/lmPackageLoom.cpp
    bindings/loom/lmFacebook.cpp
    bindings/loom/lmTeak.cpp
    bindings/loom/lmSQLite.cpp
    bindings/loom/lmModestMaps.cpp
    bindings/loom/lmGameController.cpp
    bindings/loom/gameframework/lmPropertyManager.cpp
    
    bindings/sdl/lmSDL.cpp
    
    sound/lsSound.cpp
    sound/lsSoundPackage.cpp
)

if (APPLE)
    if(LOOM_BUILD_IOS EQUAL 1)
    set (ENGINE_SRC

        ${ENGINE_SRC}
        
    )

    else()
        set (ENGINE_SRC
    
            ${ENGINE_SRC}

            
            )
    endif()

endif(APPLE)

if(ANDROID)
set (ENGINE_SRC

    ${ENGINE_SRC}
        
)
endif(ANDROID)


if(LINUX)

set (ENGINE_SRC

    ${ENGINE_SRC}

    cocos2dx/platform/linux/CCApplication.cpp
    cocos2dx/platform/linux/CCCommon.cpp
    cocos2dx/platform/linux/CCEGLView.cpp
    cocos2dx/platform/linux/CCFileUtils.cpp
    cocos2dx/platform/linux/CCImage.cpp
    cocos2dx/platform/linux/CCStdC.cpp

)
endif(LINUX)


set (ENGINE_HDR
    bindings/loom/lmApplication.h
)

if(MSVC)
set (ENGINE_SRC ${ENGINE_SRC})
endif()


include_directories(
    vendor/zlib/include
)

add_library(${PROJECT_NAME} 
    ${ENGINE_HDR} ${ENGINE_SRC} 
)

if (ANDROID)    

    target_link_libraries(${PROJECT_NAME} -lz LoomVendor LoomCommon LoomScript LoomGraphics)  

endif(ANDROID)

if (LINUX)

    target_link_libraries(${PROJECT_NAME} -lz LoomVendor LoomCommon LoomScript LoomGraphics)

endif()
