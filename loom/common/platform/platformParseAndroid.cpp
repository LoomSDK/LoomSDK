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

#include "loom/engine/cocos2dx/cocoa/CCString.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformParse.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAndroidParseLogGroup, "loom.parse.android", 1, 0);


static loomJniMethodInfo gStartUp;


///initializes the data for the Parse class for Android
void platform_parseInitialize()
{
    lmLog(gAndroidParseLogGroup, "INIT ***** PARSE ***** ANDROID ****");

    ///Bind to JNI entry points.
    LoomJni::getStaticMethodInfo(gStartUp,
                                 "co/theengine/loomdemo/LoomParse",
                                 "startUp",
                                 "(Ljava/lang/String;Ljava/lang/String;)Z");

}


///starts up the Parse service
bool platform_startUp(const char *appID, const char *clientKey)
{
    jstring jAppID = gStartUp.env->NewStringUTF(appID);
    jstring jClientKey = gStartUp.env->NewStringUTF(clientKey);
    jboolean result = gStartUp.env->CallStaticBooleanMethod(gStartUp.classID, 
                                                            gStartUp.methodID, 
                                                            jAppID,
                                                            jClientKey);
    gStartUp.env->DeleteLocalRef(jAppID);
    gStartUp.env->DeleteLocalRef(jClientKey);
    return (bool)result;
}

#endif
