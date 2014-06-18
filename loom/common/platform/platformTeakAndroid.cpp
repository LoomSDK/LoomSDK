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
#include "loom/common/platform/platformTeak.h"
#include "loom/vendor/jansson/jansson.h"
#include "loom/engine/cocos2dx/cocoa/CCString.h"


lmDefineLogGroup(gAndroidTeakLogGroup, "loom.teak.android", 1, 0);


static AuthStatusCallback gAuthStatusCallback = NULL;


extern "C"
{
    void Java_co_theengine_loomdemo_LoomTeak_authStatusCallback(JNIEnv* env, jobject thiz, jint authStatus)
    {
        if (gAuthStatusCallback)
        {
            gAuthStatusCallback((int)authStatus);
        }
    }
}


static loomJniMethodInfo gIsActive;
static loomJniMethodInfo gSetAccessToken;
static loomJniMethodInfo gGetStatus;
static loomJniMethodInfo gPostAchievement;
static loomJniMethodInfo gPostHighScore;
static loomJniMethodInfo gPostAction;


///initializes the data for the Teak class for Android
void platform_teakInitialize(AuthStatusCallback authStatusCB)
{
    lmLog(gAndroidTeakLogGroup, "INIT ***** TEAK ***** ANDROID ****");

    gAuthStatusCallback = authStatusCB;   
 
    // Bind to JNI entry points.
    LoomJni::getStaticMethodInfo(gIsActive,
                                    "co/theengine/loomdemo/LoomTeak",
                                    "isActive",
                                    "()Z");
    LoomJni::getStaticMethodInfo(gSetAccessToken,
                                    "co/theengine/loomdemo/LoomTeak",
                                    "setAccessToken",
                                    "(Ljava/lang/String;)V");
    LoomJni::getStaticMethodInfo(gGetStatus,
                                    "co/theengine/loomdemo/LoomTeak",
                                    "getStatus",
                                    "()I");
    LoomJni::getStaticMethodInfo(gPostAchievement,
                                    "co/theengine/loomdemo/LoomTeak",
                                    "postAchievement",
                                    "(Ljava/lang/String;)Z");
    LoomJni::getStaticMethodInfo(gPostHighScore,
                                    "co/theengine/loomdemo/LoomTeak",
                                    "postHighScore",
                                    "(I)Z");
    LoomJni::getStaticMethodInfo(gPostAction,
                                    "co/theengine/loomdemo/LoomTeak",
                                    "postAction",
                                    "(Ljava/lang/String;Ljava/lang/String;)Z");

}



bool platform_isTeakActive()
{
    return gIsActive.env->CallStaticBooleanMethod(gIsActive.classID, gIsActive.methodID);
}

void platform_setAccessToken(const char *fbAccessToken)
{
    jstring jAccessToken = gSetAccessToken.env->NewStringUTF(fbAccessToken);
    gSetAccessToken.env->CallStaticVoidMethod(gSetAccessToken.classID, 
                                                gSetAccessToken.methodID, 
                                                jAccessToken);
    gSetAccessToken.env->DeleteLocalRef(jAccessToken);
}

int platform_getStatus()
{
    jint status = gGetStatus.env->CallStaticIntMethod(gGetStatus.classID, 
                                                                gGetStatus.methodID);
    return (int)status;
}

bool platform_postAchievement(const char* achievementId)
{
    jstring jAchievementId = gPostAchievement.env->NewStringUTF(achievementId);
    jboolean result = gPostAchievement.env->CallStaticBooleanMethod(gPostAchievement.classID, 
                                                                    gPostAchievement.methodID, 
                                                                    jAchievementId);
    gPostAchievement.env->DeleteLocalRef(jAchievementId);
    return result;
}

bool platform_postHighScore(int score)
{
    jboolean result = gPostHighScore.env->CallStaticBooleanMethod(gPostHighScore.classID, 
                                                                    gPostHighScore.methodID, 
                                                                    score);
    return result;
}

bool platform_postAction(const char* actionId, const char* objectInstanceId)
{
    jstring jActionId = gPostAction.env->NewStringUTF(actionId);
    jstring jObjectInstanceId = gPostAction.env->NewStringUTF(objectInstanceId);
    jboolean result = gPostAction.env->CallStaticBooleanMethod(gPostAction.classID, 
                                                                gPostAction.methodID, 
                                                                jActionId, 
                                                                jObjectInstanceId);
    gPostAction.env->DeleteLocalRef(jActionId);
    gPostAction.env->DeleteLocalRef(jObjectInstanceId);
    return result;
}

#endif
