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
void Java_co_theengine_loomplayer_LoomWebView_nativeCallback(JNIEnv *env, jobject thiz, jstring data, jlong callback, jlong payload, jint type)
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
                                     "co/theengine/loomplayer/LoomWebView",
                                     "create",
                                     "(JJ)I");

        LoomJni::getStaticMethodInfo(gDestroyMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "destroy",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gDestroyAllMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "destroyAll",
                                     "()V");

        LoomJni::getStaticMethodInfo(gShowMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "show",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gHideMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "hide",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gRequestMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "request",
                                     "(ILjava/lang/String;)V");

        LoomJni::getStaticMethodInfo(gGoBackMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "goBack",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gGoForwardMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "goForward",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gCanGoBackMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "canGoBack",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gCanGoForwardMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "canGoForward",
                                     "(I)Z");

        LoomJni::getStaticMethodInfo(gSetDimensionsMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "setDimensions",
                                     "(IIIII)V");

        LoomJni::getStaticMethodInfo(gGetXMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "getX",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetXMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "setX",
                                     "(II)V");

        LoomJni::getStaticMethodInfo(gGetYMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "getY",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetYMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "setY",
                                     "(II)V");

        LoomJni::getStaticMethodInfo(gGetWidthMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "getWidth",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetWidthMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "setWidth",
                                     "(II)V");

        LoomJni::getStaticMethodInfo(gGetHeightMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
                                     "getHeight",
                                     "(I)I");

        LoomJni::getStaticMethodInfo(gSetHeightMethodInfo,
                                     "co/theengine/loomplayer/LoomWebView",
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

    jint handle = gCreateMethodInfo.getEnv()->CallStaticIntMethod(gCreateMethodInfo.classID, gCreateMethodInfo.methodID, (jlong)callback, (jlong)payload);
    return (int)handle;
}


void platform_webViewDestroy(loom_webView handle)
{
    gDestroyMethodInfo.getEnv()->CallStaticVoidMethod(gDestroyMethodInfo.classID, gDestroyMethodInfo.methodID, (jint)handle);
}


void platform_webViewDestroyAll()
{
    android_webViewEnsureInitialized();
    gDestroyAllMethodInfo.getEnv()->CallStaticVoidMethod(gDestroyAllMethodInfo.classID, gDestroyAllMethodInfo.methodID);
}


void platform_webViewShow(loom_webView handle)
{
    gShowMethodInfo.getEnv()->CallStaticVoidMethod(gShowMethodInfo.classID, gShowMethodInfo.methodID, (jint)handle);
}


void platform_webViewHide(loom_webView handle)
{
    gHideMethodInfo.getEnv()->CallStaticVoidMethod(gHideMethodInfo.classID, gHideMethodInfo.methodID, (jint)handle);
}


void platform_webViewRequest(loom_webView handle, const char *url)
{
    jstring urlString = gRequestMethodInfo.getEnv()->NewStringUTF(url);

    gRequestMethodInfo.getEnv()->CallStaticVoidMethod(gRequestMethodInfo.classID, gRequestMethodInfo.methodID, (jint)handle, urlString);
    gRequestMethodInfo.getEnv()->DeleteLocalRef(urlString);
}


bool platform_webViewGoBack(loom_webView handle)
{
    jboolean result = gGoBackMethodInfo.getEnv()->CallStaticBooleanMethod(gGoBackMethodInfo.classID, gGoBackMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


bool platform_webViewGoForward(loom_webView handle)
{
    jboolean result = gGoForwardMethodInfo.getEnv()->CallStaticBooleanMethod(gGoForwardMethodInfo.classID, gGoForwardMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


bool platform_webViewCanGoBack(loom_webView handle)
{
    jboolean result = gCanGoBackMethodInfo.getEnv()->CallStaticBooleanMethod(gCanGoBackMethodInfo.classID, gCanGoBackMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


bool platform_webViewCanGoForward(loom_webView handle)
{
    jboolean result = gCanGoForwardMethodInfo.getEnv()->CallStaticBooleanMethod(gCanGoForwardMethodInfo.classID, gCanGoForwardMethodInfo.methodID, (jint)handle);

    return (bool)result;
}


void platform_webViewSetDimensions(loom_webView handle, float x, float y, float width, float height)
{
    gSetDimensionsMethodInfo.getEnv()->CallStaticVoidMethod(gSetDimensionsMethodInfo.classID, gSetDimensionsMethodInfo.methodID, (jint)handle, (jint)x, (jint)y, (jint)width, (jint)height);
}


float platform_webViewGetX(loom_webView handle)
{
    jint result = gGetXMethodInfo.getEnv()->CallStaticFloatMethod(gGetXMethodInfo.classID, gGetXMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetX(loom_webView handle, float x)
{
    gSetXMethodInfo.getEnv()->CallStaticVoidMethod(gSetXMethodInfo.classID, gSetXMethodInfo.methodID, (jint)handle, (jint)x);
}


float platform_webViewGetY(loom_webView handle)
{
    jint result = gGetYMethodInfo.getEnv()->CallStaticFloatMethod(gGetYMethodInfo.classID, gGetYMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetY(loom_webView handle, float y)
{
    gSetYMethodInfo.getEnv()->CallStaticVoidMethod(gSetYMethodInfo.classID, gSetYMethodInfo.methodID, (jint)handle, (jint)y);
}


float platform_webViewGetWidth(loom_webView handle)
{
    jint result = gGetWidthMethodInfo.getEnv()->CallStaticFloatMethod(gGetWidthMethodInfo.classID, gGetWidthMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetWidth(loom_webView handle, float width)
{
    gSetWidthMethodInfo.getEnv()->CallStaticVoidMethod(gSetWidthMethodInfo.classID, gSetWidthMethodInfo.methodID, (jint)handle, (jint)width);
}


float platform_webViewGetHeight(loom_webView handle)
{
    jint result = gGetHeightMethodInfo.getEnv()->CallStaticFloatMethod(gGetHeightMethodInfo.classID, gGetHeightMethodInfo.methodID, (jint)handle);

    return (float)result;
}


void platform_webViewSetHeight(loom_webView handle, float height)
{
    gSetHeightMethodInfo.getEnv()->CallStaticVoidMethod(gSetHeightMethodInfo.classID, gSetHeightMethodInfo.methodID, (jint)handle, (jint)height);
}
#endif
