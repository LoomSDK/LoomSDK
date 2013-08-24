/****************************************************************************
*  Copyright (c) 2010 cocos2d-x.org
*
*  http://www.cocos2d-x.org
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
****************************************************************************/
#include "MessageJni.h"
#include "CCDirector.h"
#include "JniHelper.h"
#include "../CCApplication.h"
#include "../CCEGLView.h"
#include "platform/CCFileUtils.h"
#include "CCEventType.h"
#include "support/CCNotificationCenter.h"
#include "loom/CCLoomCocos2D.h"

#include <android/log.h>
#include <jni.h>


#if 0
#define  LOG_TAG    "MessageJni"
#define  LOGD(...)    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#else
#define  LOGD(...)
#endif

using namespace cocos2d;

extern "C"
{
//////////////////////////////////////////////////////////////////////////
// native renderer
//////////////////////////////////////////////////////////////////////////

void tasks_runAnyTaskForDuration(int millis);

void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeRender(JNIEnv *env)
{
    tasks_runAnyTaskForDuration(2);
    cocos2d::CCDirector::sharedDirector()->mainLoop();
}


// handle onPause and onResume

void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause()
{
    CCApplication::sharedApplication().applicationDidEnterBackground();

    CCNotificationCenter::sharedNotificationCenter()->postNotification(EVENT_COME_TO_BACKGROUND, NULL);
}


void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnResume()
{
    // Shared OpenGL View instance doesn't exist yet when Activity.onResume is first called
    if (CCDirector::sharedDirector()->getOpenGLView())
    {
        CCApplication::sharedApplication().applicationWillEnterForeground();
    }
}


void showMessageBoxJNI(const char *pszMsg, const char *pszTitle)
{
    if (!pszMsg)
    {
        return;
    }

    JniMethodInfo t;
    if (JniHelper::getStaticMethodInfo(t
                                       , "org/cocos2dx/lib/Cocos2dxActivity"
                                       , "showMessageBox"
                                       , "(Ljava/lang/String;Ljava/lang/String;)V"))
    {
        jstring stringArg1;

        if (!pszTitle)
        {
            stringArg1 = t.env->NewStringUTF("");
        }
        else
        {
            stringArg1 = t.env->NewStringUTF(pszTitle);
        }

        jstring stringArg2 = t.env->NewStringUTF(pszMsg);
        t.env->CallStaticVoidMethod(t.classID, t.methodID, stringArg1, stringArg2);

        t.env->DeleteLocalRef(stringArg1);
        t.env->DeleteLocalRef(stringArg2);
        t.env->DeleteLocalRef(t.classID);
    }
}


//////////////////////////////////////////////////////////////////////////
// terminate the process
//////////////////////////////////////////////////////////////////////////
void terminateProcessJNI()
{
    JniMethodInfo t;

    if (JniHelper::getStaticMethodInfo(t
                                       , "org/cocos2dx/lib/Cocos2dxActivity"
                                       , "terminateProcess"
                                       , "()V"))
    {
        t.env->CallStaticVoidMethod(t.classID, t.methodID);
        t.env->DeleteLocalRef(t.classID);
    }
}


#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>

extern "C"
{
void loom_setAssetManager(AAssetManager *am);

void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesBegin(JNIEnv *env, jobject thiz, jint id, jfloat x, jfloat y);
void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesEnd(JNIEnv *env, jobject thiz, jint id, jfloat x, jfloat y);
void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesMove(JNIEnv *env, jobject thiz, jintArray ids, jfloatArray xs, jfloatArray ys);
void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesCancel(JNIEnv *env, jobject thiz, jintArray ids, jfloatArray xs, jfloatArray ys);
jboolean Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeKeyDown(JNIEnv *env, jobject thiz, jint keyCode);
}

//////////////////////////////////////////////////////////////////////////
// set apk path
//////////////////////////////////////////////////////////////////////////
void Java_org_cocos2dx_lib_Cocos2dxActivity_nativeSetPaths(JNIEnv *env, jobject thiz, jstring apkPath, jobject a)
{
    // HACK to include other symbols.
    void *hax[] =
    {
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnPause,
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeOnResume,
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesBegin,
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesEnd,
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesMove,
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeTouchesCancel,
        (void *)Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeKeyDown
    };


    const char *str = env->GetStringUTFChars(apkPath, NULL);
    cocos2d::CCFileUtils::sharedFileUtils()->setResourcePath(str);

    env->ReleaseStringUTFChars(apkPath, str);

    loom_setAssetManager(AAssetManager_fromJava(env, a));
}


void Java_org_cocos2dx_lib_Cocos2dxActivity_nativeSetOrientation(JNIEnv *env, jobject thiz, jstring orientation)
{
    const char *str = env->GetStringUTFChars(orientation, NULL);
    CCLoomCocos2d::setOrientation(str);
}


void Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeReshapeProjection(JNIEnv *env, jobject thiz, jint width, jint height)
{
    cocos2d::CCEGLViewProtocol *view = cocos2d::CCDirector::sharedDirector()->getOpenGLView();

    if (view)
    {
        if ((view->getFrameSize().width != width) || (view->getFrameSize().height != height))
        {
            // set the frame size of the view
            view->setFrameSize(width, height);

            // invalidate it by reshaping the projection
            cocos2d::CCSize size;
            size.width  = width;
            size.height = height;
            cocos2d::CCDirector::sharedDirector()->reshapeProjection(size);
        }
    }
}
}
