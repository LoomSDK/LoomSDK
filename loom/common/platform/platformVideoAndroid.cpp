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
    lmLog(gAndroidVideoLogGroup, "LoomVideo Android Callback fired! %d", callbackType);

    const char *dataString = env->GetStringUTFChars(data, 0);
    if (gEventCallback)
    {
        const char *typeString = NULL;
        switch (callbackType)
        {
            case 0:
                lmLog(gAndroidVideoLogGroup, "Video playback failed");
                gEventCallback("fail", dataString);
                break;

            case 1:
                lmLog(gAndroidVideoLogGroup, "Video playback complete");
                gEventCallback("complete", dataString);
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
                                 "playFullscreen",
                                 "(Ljava/lang/String;III)V");
}


void platform_videoPlayFullscreen(const char *video, int scaleMode, int controlMode, unsigned int bgColor)
{
    ///error and don't play if the video name does not start with "assets/videos/"
    if(strstr(video, ROOT_FOLDER) != video)
    {
        lmLogError(gAndroidVideoLogGroup, "Unable to play Video %s that does not reside in '%s'", video, ROOT_FOLDER);
        gEventCallback("fail", "Video path does not begin with 'assets/videos/'");      
        return;
    }


    ///strip out the raw filename only to use on Android
    int index = 0;
    int firstChar = 0;
    int lastChar = strlen(video) - 1;
    while(video[index] != '\0')
    {
        ///track extention start if found
        if(video[index] == '.')
        {
            lastChar = index - 1;
        }
        else if((video[index] == '/') || (video[index] == '\\'))
        {
            firstChar = index + 1;
        }
        index++;
    }
    int len = (lastChar - firstChar) + 1;
    char *newVideoName = new char[len + 1];
    memcpy(newVideoName, &video[firstChar], len * sizeof(char));
    newVideoName[len] = '\0';

    ///call java method to play the video
    lmLog(gAndroidVideoLogGroup, "videoPlayFullscreen: '%s' became '%s'", video, newVideoName);
    jstring jVideo    = gPlayVideoFullscreen.env->NewStringUTF(newVideoName);
    gPlayVideoFullscreen.env->CallStaticVoidMethod(gPlayVideoFullscreen.classID, gPlayVideoFullscreen.methodID, jVideo, scaleMode, controlMode, bgColor);
    gPlayVideoFullscreen.env->DeleteLocalRef(jVideo);
    delete []newVideoName;
}
#endif
