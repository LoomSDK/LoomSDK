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

#if LOOM_ALLOW_FACEBOOK && (LOOM_PLATFORM == LOOM_PLATFORM_ANDROID)

#include <jni.h>
#include "platformAndroidJni.h"

#include "loom/engine/cocos2dx/cocoa/CCString.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformParse.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAndroidParseLogGroup, "parse", 1, 0);


static loomJniMethodInfo gIsActive;
static loomJniMethodInfo gGetInstallationID;
static loomJniMethodInfo gGetInstallationObjectID;
static loomJniMethodInfo gUpdateInstallationUserID;


///initializes the data for the Parse class for Android
void platform_parseInitialize()
{
    lmLog(gAndroidParseLogGroup, "INIT ***** PARSE ***** ANDROID ****");

    ///Bind to JNI entry points.
    LoomJni::getStaticMethodInfo(gIsActive,
                                 "co/theengine/loomdemo/LoomParse",
                                 "isActive",
                                 "()Z");
    LoomJni::getStaticMethodInfo(gGetInstallationID,
                                 "co/theengine/loomdemo/LoomParse",
                                 "getInstallationID",
                                 "()Ljava/lang/String;");
    LoomJni::getStaticMethodInfo(gGetInstallationObjectID,
                                 "co/theengine/loomdemo/LoomParse",
                                 "getInstallationObjectID",
                                 "()Ljava/lang/String;");
    LoomJni::getStaticMethodInfo(gUpdateInstallationUserID,
                                 "co/theengine/loomdemo/LoomParse",
                                 "updateInstallationUserID",
                                 "(Ljava/lang/String;)Z");
}


///checks if the Parse service is active for use
bool platform_isParseActive()
{
    return gIsActive.getEnv()->CallStaticBooleanMethod(gIsActive.classID, gIsActive.methodID);
}

///gets Parse installation ID
const char* platform_getInstallationID()
{       
    jstring result = (jstring)gGetInstallationID.getEnv()->CallStaticObjectMethod(gGetInstallationID.classID, gGetInstallationID.methodID);
    if(result == NULL)
    {
        return "";
    }
    
    ///convert jstring result into const char* for us to return
    cocos2d::CCString *installID = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    installID->autorelease();
    gGetInstallationID.getEnv()->DeleteLocalRef(result);
    return installID->m_sString.c_str();
}


///gets Parse installation object's objectId
const char* platform_getInstallationObjectID()
{       
    jstring result = (jstring)gGetInstallationObjectID.getEnv()->CallStaticObjectMethod(gGetInstallationObjectID.classID, gGetInstallationObjectID.methodID);
    if(result == NULL)
    {
        return "";
    }
    
    ///convert jstring result into const char* for us to return
    cocos2d::CCString *installID = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    installID->autorelease();
    gGetInstallationObjectID.getEnv()->DeleteLocalRef(result);
    return installID->m_sString.c_str();
}

bool platform_updateInstallationUserID(const char* userId)
{
    jstring jUserID = gUpdateInstallationUserID.getEnv()->NewStringUTF(userId);
	jboolean result = gUpdateInstallationUserID.getEnv()->CallStaticBooleanMethod(gUpdateInstallationUserID.classID, gUpdateInstallationUserID.methodID, jUserID);
    gUpdateInstallationUserID.getEnv()->DeleteLocalRef(jUserID);
    return (bool)result;
}
#endif
