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

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <jni.h>
#include "platformAndroidJni.h"

lmDefineLogGroup(gAndroidHTTPLogGroup, "http.android", 1, LoomLogInfo);

extern "C"
{
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

    lmLog(gAndroidHTTPLogGroup, "Sending fail to %x %s\n", payload, dataString);

    cb((void *)payload, LOOM_HTTP_ERROR, dataString);

    env->ReleaseStringUTFChars(data, dataString);
}
}

void platform_HTTPSend(const char *url, const char *method, loom_HTTPCallback callback, void *payload,
                       const char *body, int bodyLength, utHashTable<utHashedString, utString>& headers,
                       const char *responseCacheFile, bool base64EncodeResponseData, bool followRedirects)
{
    // get the method info for loomhttp::addHeader
    loomJniMethodInfo addHeaderMethodInfo;
    LoomJni::getStaticMethodInfo(addHeaderMethodInfo,
                                 "co/theengine/loomdemo/LoomHTTP",
                                 "addHeader",
                                 "(Ljava/lang/String;Ljava/lang/String;)V");

    // Iterate over the header hashtable and add them on the java side
    utHashTableIterator<utHashTable<utHashedString, utString> > headersIterator(headers);
    while (headersIterator.hasMoreElements())
    {
        utHashedString key   = headersIterator.peekNextKey();
        utString       value = headersIterator.peekNextValue();

        jstring headerKey   = addHeaderMethodInfo.env->NewStringUTF(key.str().c_str());
        jstring headerValue = addHeaderMethodInfo.env->NewStringUTF(value.c_str());
        addHeaderMethodInfo.env->CallStaticVoidMethod(addHeaderMethodInfo.classID, addHeaderMethodInfo.methodID, headerKey, headerValue);
        addHeaderMethodInfo.env->DeleteLocalRef(headerKey);
        addHeaderMethodInfo.env->DeleteLocalRef(headerValue);

        headersIterator.next();
    }

    // get the method info for loomhttp::send
    loomJniMethodInfo sendMethodInfo;
    LoomJni::getStaticMethodInfo(sendMethodInfo,
                                 "co/theengine/loomdemo/LoomHTTP",
                                 "send",
                                 "(Ljava/lang/String;Ljava/lang/String;JJ[BLjava/lang/String;ZZ)V");

    // pass in the URL and pointers
    jstring reqURL    = sendMethodInfo.env->NewStringUTF(url);
    jstring reqMethod = sendMethodInfo.env->NewStringUTF(method);

    jbyteArray reqBody = sendMethodInfo.env->NewByteArray(bodyLength);
    sendMethodInfo.env->SetByteArrayRegion(reqBody, 0, bodyLength, (jbyte *)body);

    jstring reqResponseCacheFile = sendMethodInfo.env->NewStringUTF(responseCacheFile);
    sendMethodInfo.env->CallStaticVoidMethod(sendMethodInfo.classID, sendMethodInfo.methodID, reqURL, reqMethod, (jlong)callback, (jlong)payload, reqBody, reqResponseCacheFile, (jboolean)base64EncodeResponseData, (jboolean)followRedirects);
    sendMethodInfo.env->DeleteLocalRef(reqURL);
    sendMethodInfo.env->DeleteLocalRef(reqMethod);
    sendMethodInfo.env->DeleteLocalRef(reqBody);
    sendMethodInfo.env->DeleteLocalRef(reqResponseCacheFile);
}


bool platform_HTTPIsConnected()
{
    loomJniMethodInfo isConnectedMethodInfo;
    LoomJni::getStaticMethodInfo(isConnectedMethodInfo,
                                 "co/theengine/loomdemo/LoomHTTP",
                                 "isConnected",
                                 "()Z");
    jboolean result = isConnectedMethodInfo.env->CallStaticBooleanMethod(isConnectedMethodInfo.classID, isConnectedMethodInfo.methodID);

    return (bool)result;
}


void platform_HTTPInit()
{
    // stub for android
}


void platform_HTTPCleanup()
{
    // stub for android
}


void platform_HTTPUpdate()
{
    // stub for android
}
#endif
