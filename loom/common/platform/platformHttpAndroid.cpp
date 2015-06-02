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

#include "loom/common/platform/platform.h"
#include "platformHttp.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"
#include "loom/common/core/log.h"
#include "loom/script/runtime/lsProfiler.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <jni.h>
#include "platformAndroidJni.h"

lmDefineLogGroup(gAndroidHTTPLogGroup, "http.android", 1, LoomLogInfo);

extern "C"
{

static loomJniMethodInfo jniAddHeader;
static loomJniMethodInfo jniSend;
static loomJniMethodInfo jniIsConnected;
static loomJniMethodInfo jniCancel;
static loomJniMethodInfo jniComplete;

static JNIEnv *env;

void Java_co_theengine_loomdemo_LoomHTTP_onSuccess(JNIEnv *env, jobject thiz, jstring data, jlong callback, jlong payload)
{
    loom_HTTPCallback cb          = (loom_HTTPCallback)callback;
    int               dataLen     = env->GetStringUTFLength(data);
    const char        *dataString = env->GetStringUTFChars(data, 0);

    // Commented out below because long responses can break logging
    //lmLog(gAndroidHTTPLogGroup, "Sending success to %x %s (%x long) %x\n", payload, strlen(dataString), dataString, dataLen, data);

    cb((void *)payload, LOOM_HTTP_SUCCESS, dataString);

    env->ReleaseStringUTFChars(data, dataString);
}


void Java_co_theengine_loomdemo_LoomHTTP_onFailure(JNIEnv *env, jobject thiz, jstring data, jlong callback, jlong payload)
{
    loom_HTTPCallback cb          = (loom_HTTPCallback)callback;
    const char        *dataString = env->GetStringUTFChars(data, 0);

    // Commented out because lmLog, Android, and HTTP reponse strings don't play nice together and tend to CRASH!!!
    // lmLog(gAndroidHTTPLogGroup, "Sending fail to %x %s\n", payload, dataString);

    cb((void *)payload, LOOM_HTTP_ERROR, dataString);

    env->ReleaseStringUTFChars(data, dataString);
}
}

int platform_HTTPSend(const char *url, const char *method, loom_HTTPCallback callback, void *payload,
                       const char *body, int bodyLength, utHashTable<utHashedString, utString>& headers,
                       const char *responseCacheFile, bool base64EncodeResponseData, bool followRedirects)
{
    LOOM_PROFILE_START(httpSendHeader);
    // Iterate over the header hashtable and add them on the java side
    utHashTableIterator<utHashTable<utHashedString, utString> > headersIterator(headers);
    while (headersIterator.hasMoreElements())
    {
        utHashedString key   = headersIterator.peekNextKey();
        utString       value = headersIterator.peekNextValue();

        jstring headerKey   = env->NewStringUTF(key.str().c_str());
        jstring headerValue = env->NewStringUTF(value.c_str());
        LOOM_PROFILE_START(httpSendHeader2c);
        env->CallStaticVoidMethod(jniAddHeader.classID, jniAddHeader.methodID, headerKey, headerValue);
        LOOM_PROFILE_END(httpSendHeader2c);
        env->DeleteLocalRef(headerKey);
        env->DeleteLocalRef(headerValue);

        headersIterator.next();
    }
    LOOM_PROFILE_END(httpSendHeader);

    LOOM_PROFILE_START(httpSendNative);
    // get the method info for loomhttp::send

    // pass in the URL and pointers
    jstring reqURL    = env->NewStringUTF(url);
    jstring reqMethod = env->NewStringUTF(method);

    jbyteArray reqBody = env->NewByteArray(bodyLength);
    env->SetByteArrayRegion(reqBody, 0, bodyLength, (jbyte *)body);

    jstring reqResponseCacheFile = env->NewStringUTF(responseCacheFile);
    
    LOOM_PROFILE_START(httpSendNativeCall);
    jint index = (jint)env->CallStaticIntMethod(jniSend.classID, 
                                                jniSend.methodID, 
                                                reqURL, 
                                                reqMethod, 
                                                (jlong)callback, 
                                                (jlong)payload, 
                                                reqBody, 
                                                reqResponseCacheFile, 
                                                (jboolean)base64EncodeResponseData, 
                                                (jboolean)followRedirects);
    LOOM_PROFILE_END(httpSendNativeCall);

    env->DeleteLocalRef(reqURL);
    env->DeleteLocalRef(reqMethod);
    env->DeleteLocalRef(reqBody);
    env->DeleteLocalRef(reqResponseCacheFile);
    LOOM_PROFILE_END(httpSendNative);
    return index;
}


bool platform_HTTPIsConnected()
{
    jboolean result = env->CallStaticBooleanMethod(jniIsConnected.classID, jniIsConnected.methodID);
    return (bool)result;
}

void platform_HTTPInit()
{
    LoomJni::getStaticMethodInfo(jniAddHeader,
        "co/theengine/loomdemo/LoomHTTP",
        "addHeader",
        "(Ljava/lang/String;Ljava/lang/String;)V");

    LoomJni::getStaticMethodInfo(jniSend,
        "co/theengine/loomdemo/LoomHTTP",
        "send",
        "(Ljava/lang/String;Ljava/lang/String;JJ[BLjava/lang/String;ZZ)I");

    LoomJni::getStaticMethodInfo(jniIsConnected,
        "co/theengine/loomdemo/LoomHTTP",
        "isConnected",
        "()Z");

    LoomJni::getStaticMethodInfo(jniCancel,
        "co/theengine/loomdemo/LoomHTTP",
        "cancel",
        "(I)Z");

    LoomJni::getStaticMethodInfo(jniComplete,
        "co/theengine/loomdemo/LoomHTTP",
        "complete",
        "(I)V");

    env = jniSend.getEnv();
}


void platform_HTTPCleanup()
{
    // stub for android
}


void platform_HTTPUpdate()
{
    // stub for android
}

bool platform_HTTPCancel(int index)
{
    jboolean ret = env->CallStaticBooleanMethod(jniCancel.classID, jniCancel.methodID, (jint)index);
    return ret;
}

void platform_HTTPComplete(int index)
{
    env->CallStaticVoidMethod(jniComplete.classID, jniComplete.methodID, (jint)index);
}

#endif
