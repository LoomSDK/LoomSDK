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
    bindings/loom/lmHTTPRequest.cpp
    bindings/loom/lmStore.cpp
    bindings/loom/lmVideo.cpp
    bindings/loom/lmMobile.cpp
    bindings/loom/lmParse.cpp
    bindings/loom/lmPackageLoom.cpp
    bindings/loom/lmFacebook.cpp
    bindings/loom/lmTeak.cpp
    bindings/loom/gameframework/lmPropertyManager.cpp
    
    physics/lsPhysics.cpp
    physics/lsPhysicsPackage.cpp

    sound/lsSound.cpp
    sound/lsSoundPackage.cpp
)

if (APPLE)
    if(LOOM_BUILD_IOS EQUAL 1)
    set (ENGINE_SRC

        ${ENGINE_SRC}
        
        cocos2dx/platform/ios/AccelerometerDelegateWrapper.mm
        cocos2dx/platform/ios/CCAccelerometer.mm
        cocos2dx/platform/ios/CCApplication.mm
        cocos2dx/platform/ios/CCCommon.mm
        cocos2dx/platform/ios/CCDirectorCaller.mm
        cocos2dx/platform/ios/CCEGLView.mm
        cocos2dx/platform/ios/CCES2Renderer.mm
        cocos2dx/platform/ios/CCFileUtils.mm
        cocos2dx/platform/ios/CCImage.mm
        cocos2dx/platform/ios/CCThread.mm
        cocos2dx/platform/ios/EAGLView.mm
        
        cocos2dx/platform/ios/FontLabel/FontLabel.m
        cocos2dx/platform/ios/FontLabel/FontLabelStringDrawing.m
        cocos2dx/platform/ios/FontLabel/FontManager.m
        cocos2dx/platform/ios/FontLabel/ZAttributedString.m
        cocos2dx/platform/ios/FontLabel/ZFont.m
        
        cocos2dx/platform/ios/Simulation/AccelerometerSimulation.m
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

    cocos2dx/platform/android/CCAccelerometer.cpp
    cocos2dx/platform/android/CCApplication.cpp
    cocos2dx/platform/android/CCCommon.cpp
    cocos2dx/platform/android/CCEGLView.cpp
    cocos2dx/platform/android/CCFileUtils.cpp
    cocos2dx/platform/android/CCImage.cpp
    cocos2dx/platform/android/platformMain.cpp
    cocos2dx/platform/android/jni/IMEJni.cpp
    cocos2dx/platform/android/jni/JniHelper.cpp
    cocos2dx/platform/android/jni/MessageJni.cpp
    cocos2dx/platform/android/jni/SensorJni.cpp
    cocos2dx/platform/android/jni/SystemInfoJni.cpp
    cocos2dx/platform/android/jni/TouchesJni.cpp
        
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
set (ENGINE_SRC

    ${ENGINE_SRC}
    
    cocos2dx/platform/win32/CCAccelerometer.cpp
    cocos2dx/platform/win32/CCApplication.cpp
    cocos2dx/platform/win32/CCCommon.cpp
    cocos2dx/platform/win32/CCEGLView.cpp
    cocos2dx/platform/win32/CCFileUtils.cpp
    cocos2dx/platform/win32/CCImage.cpp
    cocos2dx/platform/win32/CCStdC.cpp
   
)
endif()


include_directories(
    vendor/zlib/include
)

add_library(${PROJECT_NAME} 
    ${ENGINE_HDR} ${ENGINE_SRC} 
)

if (ANDROID)    

    target_link_libraries(${PROJECT_NAME} -lz LoomVendor LoomCommon LoomScript LoomGraphics)
           
    if (LOOM_BUILD_JIT EQUAL 1)
    
        target_link_libraries(${PROJECT_NAME} 
        -L"${CMAKE_SOURCE_DIR}/build/luajit_android/lib"
        -lluajit-5.1
        )
    
    endif()       

endif(ANDROID)

if (LINUX)

    target_link_libraries(${PROJECT_NAME} -lz LoomVendor LoomCommon LoomScript LoomGraphics)

    if (LOOM_BUILD_JIT EQUAL 1)
    
        target_link_libraries(${PROJECT_NAME} 
        -L"${CMAKE_SOURCE_DIR}/build/luajit_x86/lib"
        -lluajit-5.1
        )
    
    endif()       


endif()
