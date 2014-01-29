#include "loom/common/platform/platformDisplay.h"
#include "loom/common/platform/platformFile.h"
#include "loom/engine/tasks/tasks.h"

extern "C"
{
void loom_appSetup();
void display_mainloop();
void loom_appShutdown();
};

#include "loom/common/platform/platform.h"

#include <jni.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

#include "loom/common/core/log.h"

#include "platform/android/jni/JniHelper.h"
#include <jni.h>
#include <android/log.h>
#include "platform/android/CCEGLView.h"
#include "platform/android/CCApplication.h"
#include "CCDirector.h"
#include "CCEventType.h"
#include "support/CCNotificationCenter.h"

#include "loom/graphics/gfxGraphics.h"

#define  LOG_TAG    "main"
#define  LOGD(...)    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

using namespace cocos2d;

extern "C"
{
jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
    JniHelper::setJavaVM(vm);

    return JNI_VERSION_1_4;
}


JNIEXPORT void JNICALL Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeInit(JNIEnv *env, jobject thiz, jint w, jint h)
{
    if (!CCDirector::sharedDirector()->getOpenGLView())
    {
        CCEGLView *view = &CCEGLView::sharedOpenGLView();
        view->setFrameSize(w, h);

        loom_appSetup();

        GFX::Graphics::setPlatformData(NULL, NULL, NULL);

        GFX::Graphics::initialize();

        // set initial width and height
        GFX::Graphics::reset(w, h);

        CCApplication::sharedApplication().run();
    }
    else
    {
        GFX::Graphics::handleContextLoss();

        CCNotificationCenter::sharedNotificationCenter()->postNotification(EVNET_COME_TO_FOREGROUND, NULL);
    }
}


// HACK: function reference to keep strip from removing these symbols.
// TODO: Find a better way around this.
// References in CCApplication.cpp

JNIEXPORT void evenMoreMadness()
{
    JNI_OnLoad(NULL, NULL);
    Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeInit(NULL, NULL, 0, 0);
}
}
