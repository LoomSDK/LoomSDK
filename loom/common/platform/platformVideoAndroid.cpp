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

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include <jni.h>
#include "platformAndroidJni.h"

#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformVideo.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAndroidVideoLogGroup, "loom.video.android", 1, 0);

static VideoEventCallback gEventCallback = NULL;


extern "C"
{
void Java_co_theengine_loomdemo_LoomVideo_nativeCallback(JNIEnv *env, jobject thiz, jint callbackType, jstring data)
{
    lmLogError(gAndroidVideoLogGroup, "LoomVideo Android Callback fired! %d", callbackType);

    const char *dataString = env->GetStringUTFChars(data, 0);

    if (gEventCallback)
    {
        const char *typeString = NULL;
        switch (callbackType)
        {
            case 0:
                gEventCallback("fail", dataString);
                break;

            case 1:
                lmLogError(gAndroidVideoLogGroup, "Video playback complete");
                gEventCallback("complete", NULL);
                break;

            default:
                lmLogError(gAndroidVideoLogGroup, "Got Android Video event of type %d but don't know how to handle it, ignoring...", callbackType);
                break;
        }
    }
    else
    {
        lmLogError(gAndroidVideoLogGroup, "Got Android Video event of type %d but don't know how to handle it, ignoring...", callbackType);
    }

    env->ReleaseStringUTFChars(data, dataString);
}
}




static loomJniMethodInfo gPlayVideoFullscreen;


int platform_videoSupported()
{
    return true;
}


void platform_videoInitialize(VideoEventCallback eventCallback)
{
    gEventCallback = eventCallback;

    lmLog(gAndroidVideoLogGroup, "INIT ***** VIDEO ***** ANDROID ****");

    // Bind to JNI entry points.
    LoomJni::getStaticMethodInfo(gPlayVideoFullscreen,
                                 "co/theengine/loomdemo/LoomVideo",
                                 "playVideo",
                                 "(Ljava/lang/String;Ljava/lang/int;Ljava/lang/int;Ljava/lang/int;)V");
}


void platform_videoPlay(const char *video, int scaleMode, int controlMode, int bgColor)
{
    ///call java method to play the video
    jstring jVideo    = gPlayVideoFullscreen.env->NewStringUTF(video);
    gPlayVideoFullscreen.env->CallStaticVoidMethod(gPlayVideoFullscreen.classID, gPlayVideoFullscreen.methodID, jVideo, scaleMode, controlMode, bgColor);
    gPlayVideoFullscreen.env->DeleteLocalRef(jVideo);
}


#endif
