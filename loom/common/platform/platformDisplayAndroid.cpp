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

#include "platformDisplayAndroid.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID

#include "loom/common/core/log.h"
#include "loom/common/platform/platformAndroidJni.h"
#include "jni.h"

lmDefineLogGroup(gPlatformDisplayAndroidErrorLogGroup, "error", 1, LoomLogDebug);

extern "C" {

display_profile display_getProfile()
{
    loomJniMethodInfo t;

    if (LoomJni::getStaticMethodInfo(t
        , "co/theengine/loomplayer/LoomPlayer"
        , "getProfile"
        , "()I"))
    {
        jint p = (jint)t.getEnv()->CallStaticIntMethod(t.classID, t.methodID);
        t.getEnv()->DeleteLocalRef(t.classID);

        switch (p)
        {
        case 1:
            return PROFILE_MOBILE_SMALL;

        case 2:
            return PROFILE_MOBILE_NORMAL;

        case 3:
            return PROFILE_MOBILE_LARGE;

        default:
            return PROFILE_DESKTOP;
        }
    }
}

float display_getDPI()
{
    loomJniMethodInfo t;

    if (LoomJni::getStaticMethodInfo(t
        , "co/theengine/loomplayer/LoomPlayer"
        , "getDPI"
        , "()F"))
    {
        jfloat p = (jint)t.getEnv()->CallStaticFloatMethod(t.classID, t.methodID);
        t.getEnv()->DeleteLocalRef(t.classID);
        return p;
    }

    lmLogWarn(gPlatformDisplayAndroidErrorLogGroup, "Failed to get DPI.");

    return 200;
}

};

#endif
