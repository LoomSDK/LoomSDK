/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#include "platformWebView.h"
#include "loom/common/platform/platform.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <jni.h>
#include "platformAndroidJni.h"

extern "C"
{
void Java_co_theengine_loomdemo_LoomWebView_nativeCallback(JNIEnv *env, jobject thiz, jstring data, jlong callback, jlong payload, jint type)
{
    loom_webViewCallback cb          = (loom_webViewCallback)callback;
    const char           *dataString = env->GetStringUTFChars(data, 0);

    cb((void *)payload, (loom_webViewCallbackType)type, dataString);

    env->ReleaseStringUTFChars(data, dataString);
}
}

//_________________________________________________________________________
// JNI Helpers
//_________________________________________________________________________
static loomJniMethodInfo gCreateMethodInfo;
static loomJniMethodInfo gDestroyMethodInfo;
static loomJniMethodInfo gDestroyAllMethodInfo;
static loomJniMethodInfo gShowMethodInfo;
static loomJniMethodInfo gHideMethodInfo;
static loomJniMethodInfo gRequestMethodInfo;
static loomJniMethodInfo gGoBackMethodInfo;
static loomJniMethodInfo gGoForwardMethodInfo;
static loomJniMethodInfo gCanGoBackMethodInfo;
static loomJniMethodInfo gCanGoForwardMethodInfo;
static loomJniMethodInfo gSetDimensionsMethodInfo;
static loomJniMethodInfo gGetXMethodInfo;
static loomJniMethodInfo gSetXMethodInfo;
static loomJniMethodInfo gGetYMethodInfo;
static loomJniMethodInfo gSetYMethodInfo;
static loomJniMethodInfo gGetWidthMethodInfo;
static loomJniMethodInfo gSetWidthMethodInfo;
static loomJniMethodInfo gGetHeightMethodInfo;
static loomJniMethodInfo gSetHeightMethodInfo;

static void android_webViewEnsureInitialized()
{
    static bool initialized = false;

    if (!initialized)
    {
        // initialize all of our jni method infos
        LoomJni::getStaticMethodInfo(gCreateMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "create",
                                     "(JJ)I");

        LoomJni::getStaticMethodInfo(gDestroyMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "destroy",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gDestroyAllMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "destroyAll",
                                     "()V");

        LoomJni::getStaticMethodInfo(gShowMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "show",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gHideMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "hide",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gRequestMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "request",
                                     "(ILjava/lang/String;)V");

        LoomJni::getStaticMethodInfo(gGoBackMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "goBack",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gGoForwardMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "goForward",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gCanGoBackMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "canGoBack",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gCanGoForwardMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "canGoForward",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gSetDimensionsMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "setDimensions",
                                     "(IIIII)V");

        LoomJni::getStaticMethodInfo(gGetXMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "getX",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetXMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "setX",
                                     "(II)V");

        LoomJni::getStaticMethodInfo(gGetYMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "getY",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetYMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "setY",
                                     "(II)V");

        LoomJni::getStaticMethodInfo(gGetWidthMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "getWidth",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetWidthMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "setWidth",
                                     "(II)V");

        LoomJni::getStaticMethodInfo(gGetHeightMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "getHeight",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetHeightMethodInfo,
                                     "co/theengine/loomdemo/LoomWebView",
                                     "setHeight",
                                     "(II)V");

        initialized = true;
    }
}


//_________________________________________________________________________
// platformWebView implementation
//_________________________________________________________________________
loom_webView platform_webViewCreate(loom_webViewCallback callback, void *payload)
{
    android_webViewEnsureInitialized();

    jint handle = gCreateMethodInfo.env->CallStaticIntMethod(gCreateMethodInfo.classID, gCreateMethodInfo.methodID, (jlong)callback, (jlong)payload);
    return (int)handle;
}


void platform_webViewDestroy(loom_webView handle)
{
    gDestroyMethodInfo.env->CallStaticVoidMethod(gDestroyMethodInfo.classID, gDestroyMethodInfo.methodID, (jint)handle);
}


void platform_webViewDestroyAll()
{
    android_webViewEnsureInitialized();
    gDestroyAllMethodInfo.env->CallStaticVoidMethod(gDestroyAllMethodInfo.classID, gDestroyAllMethodInfo.methodID);
}


void platform_webViewShow(loom_webView handle)
{
    gShowMethodInfo.env->CallStaticVoidMethod(gShowMethodInfo.classID, gShowMethodInfo.methodID, (jint)handle);
}


void platform_webViewHide(loom_webView handle)
{
    gHideMethodInfo.env->CallStaticVoidMethod(gHideMethodInfo.classID, gHideMethodInfo.methodID, (jint)handle);
}


void platform_webViewRequest(loom_webView handle, const char *url)
{
    jstring urlString = gRequestMethodInfo.env->NewStringUTF(url);

    gRequestMethodInfo.env->CallStaticVoidMethod(gRequestMethodInfo.classID, gRequestMethodInfo.methodID, (jint)handle, urlString);
    gRequestMethodInfo.env->DeleteLocalRef(urlString);
}


bool platform_webViewGoBack(loom_webView handle)
{
    jboolean result = gGoBackMethodInfo.env->CallStaticBooleanMethod(gGoBackMethodInfo.classID, gGoBackMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


bool platform_webViewGoForward(loom_webView handle)
{
    jboolean result = gGoForwardMethodInfo.env->CallStaticBooleanMethod(gGoForwardMethodInfo.classID, gGoForwardMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


bool platform_webViewCanGoBack(loom_webView handle)
{
    jboolean result = gCanGoBackMethodInfo.env->CallStaticBooleanMethod(gCanGoBackMethodInfo.classID, gCanGoBackMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


bool platform_webViewCanGoForward(loom_webView handle)
{
    jboolean result = gCanGoForwardMethodInfo.env->CallStaticBooleanMethod(gCanGoForwardMethodInfo.classID, gCanGoForwardMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height)
{
    gSetDimensionsMethodInfo.env->CallStaticVoidMethod(gSetDimensionsMethodInfo.classID, gSetDimensionsMethodInfo.methodID, (jint)handle, (jint)x, (jint)y, (jint)width, (jint)height);
}


float platform_webViewGetX(loom_webView handle)
{
    jint result = gGetXMethodInfo.env->CallStaticFloatMethod(gGetXMethodInfo.classID, gGetXMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetX(loom_webView handle, float x)
{
    gSetXMethodInfo.env->CallStaticVoidMethod(gSetXMethodInfo.classID, gSetXMethodInfo.methodID, (jint)handle, (jint)x);
}


float platform_webViewGetY(loom_webView handle)
{
    jint result = gGetYMethodInfo.env->CallStaticFloatMethod(gGetYMethodInfo.classID, gGetYMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetY(loom_webView handle, float y)
{
    gSetYMethodInfo.env->CallStaticVoidMethod(gSetYMethodInfo.classID, gSetYMethodInfo.methodID, (jint)handle, (jint)y);
}


float platform_webViewGetWidth(loom_webView handle)
{
    jint result = gGetWidthMethodInfo.env->CallStaticFloatMethod(gGetWidthMethodInfo.classID, gGetWidthMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetWidth(loom_webView handle, float width)
{
    gSetWidthMethodInfo.env->CallStaticVoidMethod(gSetWidthMethodInfo.classID, gSetWidthMethodInfo.methodID, (jint)handle, (jint)width);
}


float platform_webViewGetHeight(loom_webView handle)
{
    jint result = gGetHeightMethodInfo.env->CallStaticFloatMethod(gGetHeightMethodInfo.classID, gGetHeightMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetHeight(loom_webView handle, float height)
{
    gSetHeightMethodInfo.env->CallStaticVoidMethod(gSetHeightMethodInfo.classID, gSetHeightMethodInfo.methodID, (jint)handle, (jint)height);
}
#endif
