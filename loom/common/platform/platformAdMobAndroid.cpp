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

#include "platformAdMob.h"
#include "platform.h"

#if LOOM_ALLOW_ADMOB && (LOOM_PLATFORM == LOOM_PLATFORM_ANDROID)

#include <jni.h>
#include "platformAndroidJni.h"

extern "C"
{
void Java_co_theengine_loomplayer_LoomAdMob_nativeCallback(JNIEnv *env, jobject thiz, jstring data, jlong callback, jlong payload, jint type)
{
    loom_adMobCallback cb          = (loom_adMobCallback)callback;
    const char         *dataString = env->GetStringUTFChars(data, 0);

    cb((void *)payload, (loom_adMobCallbackType)type, dataString);

    env->ReleaseStringUTFChars(data, dataString);
}
}

//_________________________________________________________________________
// JNI Helpers
//_________________________________________________________________________
static loomJniMethodInfo gCreateMethodInfo;
static loomJniMethodInfo gShowMethodInfo;
static loomJniMethodInfo gHideMethodInfo;
static loomJniMethodInfo gDestroyMethodInfo;
static loomJniMethodInfo gDestroyAllMethodInfo;
static loomJniMethodInfo gSetDimensionsMethodInfo;
static loomJniMethodInfo gGetDimensionsMethodInfo;

static loomJniMethodInfo gCreateInterstitialInfo;
static loomJniMethodInfo gShowInterstitialMethodInfo;
static loomJniMethodInfo gDestroyInterstitialMethodInfo;

static void android_adMobEnsureInitialized()
{
    static bool initialized = false;

    if (!initialized)
    {
        // initialize all of our jni method infos
        LoomJni::getStaticMethodInfo(gCreateMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "create",
                                     "(Ljava/lang/String;I)I");

        LoomJni::getStaticMethodInfo(gDestroyMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "destroy",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gDestroyAllMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "destroyAll",
                                     "()V");

        LoomJni::getStaticMethodInfo(gShowMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "show",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gHideMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "hide",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gSetDimensionsMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "setDimensions",
                                     "(IIIII)V");

        LoomJni::getStaticMethodInfo(gGetDimensionsMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "getDimensions",
                                     "(I)[I");

        LoomJni::getStaticMethodInfo(gCreateInterstitialInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "createInterstitial",
                                     "(Ljava/lang/String;JJ)I");

        LoomJni::getStaticMethodInfo(gDestroyInterstitialMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "destroyInterstitial",
                                     "(I)V");

        LoomJni::getStaticMethodInfo(gShowInterstitialMethodInfo,
                                     "co/theengine/loomplayer/LoomAdMob",
                                     "showInterstitial",
                                     "(I)V");

        initialized = true;
    }
}


loom_adMobHandle platform_adMobCreate(const char *publisherID, loom_adMobBannerSize size)
{
    android_adMobEnsureInitialized();

    jstring jPublisherID = gCreateMethodInfo.getEnv()->NewStringUTF(publisherID);
    jint    handle       = gCreateMethodInfo.getEnv()->CallStaticIntMethod(gCreateMethodInfo.classID, gCreateMethodInfo.methodID, jPublisherID, (jint)size);
    gCreateMethodInfo.getEnv()->DeleteLocalRef(jPublisherID);

    return (int)handle;
}


void platform_adMobShow(loom_adMobHandle handle)
{
    gShowMethodInfo.getEnv()->CallStaticVoidMethod(gShowMethodInfo.classID, gShowMethodInfo.methodID, (jint)handle);
}


void platform_adMobHide(loom_adMobHandle handle)
{
    gHideMethodInfo.getEnv()->CallStaticVoidMethod(gHideMethodInfo.classID, gHideMethodInfo.methodID, (jint)handle);
}


void platform_adMobDestroy(loom_adMobHandle handle)
{
    gDestroyMethodInfo.getEnv()->CallStaticVoidMethod(gDestroyMethodInfo.classID, gDestroyMethodInfo.methodID, (jint)handle);
}


void platform_adMobDestroyAll()
{
    android_adMobEnsureInitialized();
    gDestroyAllMethodInfo.getEnv()->CallStaticVoidMethod(gDestroyAllMethodInfo.classID, gDestroyAllMethodInfo.methodID);
}


void platform_adMobSetDimensions(loom_adMobHandle handle, loom_adMobDimensions frame)
{
    gSetDimensionsMethodInfo.getEnv()->CallStaticVoidMethod(gSetDimensionsMethodInfo.classID, gSetDimensionsMethodInfo.methodID, (jint)handle, (jint)frame.x, (jint)frame.y, (jint)frame.width, (jint)frame.height);
}


loom_adMobDimensions platform_adMobGetDimensions(loom_adMobHandle handle)
{
    jintArray arr   = (jintArray)gGetDimensionsMethodInfo.getEnv()->CallStaticObjectMethod(gGetDimensionsMethodInfo.classID, gGetDimensionsMethodInfo.methodID, (jint)handle);
    jint      *body = gGetDimensionsMethodInfo.getEnv()->GetIntArrayElements(arr, 0);

    loom_adMobDimensions frame;

    frame.x      = body[0];
    frame.y      = body[1];
    frame.width  = body[2];
    frame.height = body[3];

    return frame;
}


loom_adMobHandle platform_adMobCreateInterstitial(const char *publisherID, loom_adMobCallback callback, void *payload)
{
    android_adMobEnsureInitialized();


    jstring jPublisherID = gCreateInterstitialInfo.getEnv()->NewStringUTF(publisherID);
    jint    handle       = gCreateInterstitialInfo.getEnv()->CallStaticIntMethod(gCreateInterstitialInfo.classID, gCreateInterstitialInfo.methodID, jPublisherID, (jlong)callback, (jlong)payload);
    gCreateInterstitialInfo.getEnv()->DeleteLocalRef(jPublisherID);

    return (int)handle;
}


void platform_adMobShowInterstitial(loom_adMobHandle handle)
{
    gShowInterstitialMethodInfo.getEnv()->CallStaticVoidMethod(gShowInterstitialMethodInfo.classID, gShowInterstitialMethodInfo.methodID, (jint)handle);
}


void platform_adMobDestroyInterstitial(loom_adMobHandle handle)
{
    gDestroyInterstitialMethodInfo.getEnv()->CallStaticVoidMethod(gDestroyInterstitialMethodInfo.classID, gDestroyInterstitialMethodInfo.methodID, (jint)handle);
}
#endif
