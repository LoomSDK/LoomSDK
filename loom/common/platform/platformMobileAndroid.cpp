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
#include "loom/common/platform/platformMobile.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAndroidMobileLogGroup, "loom.mobile.android", 1, 0);



static loomJniMethodInfo gIsDolbyAudioSupported;
static loomJniMethodInfo gSetDolbyAudioProcessingEnabled;
static loomJniMethodInfo gIsDolbyAudioProcessingEnabled;
static loomJniMethodInfo gIsDolbyAudioProcessingProfileSupported;
static loomJniMethodInfo gSetDolbyAudioProcessingProfile;
static loomJniMethodInfo gGetSelectedDolbyAudioProfile;



///initializes the data for the Mobile class for Android
void platform_mobileInitialize()
{
    lmLog(gAndroidMobileLogGroup, "INIT ***** MOBILE ***** ANDROID ****");

    // Bind to JNI entry points.
    LoomJni::getStaticMethodInfo(gIsDolbyAudioSupported,
                                 "com/dolby/DolbyAudio",
                                 "isProcessingSupported",
                                 "()Z");
    LoomJni::getStaticMethodInfo(gSetDolbyAudioProcessingEnabled,
                                 "com/dolby/DolbyAudio",
                                 "setProcessingEnabled",
                                 "(Z)V");
    LoomJni::getStaticMethodInfo(gIsDolbyAudioProcessingEnabled,
                                 "com/dolby/DolbyAudio",
                                 "isProcessingEnabled",
                                 "()Z");
    LoomJni::getStaticMethodInfo(gIsDolbyAudioProcessingProfileSupported,
                                 "com/dolby/DolbyAudio",
                                 "isProcessingProfileSupported",
                                 "(Ljava/lang/String;)Z");
    LoomJni::getStaticMethodInfo(gSetDolbyAudioProcessingProfile,
                                 "com/dolby/DolbyAudio",
                                 "setProcessingProfile",
                                 "(Ljava/lang/String;)Z");
    LoomJni::getStaticMethodInfo(gGetSelectedDolbyAudioProfile,
                                 "com/dolby/DolbyAudio",
                                 "getSelectedProfile",
                                 "()Ljava/lang/String;");
}




//checks if Dolby Audio is supported on this platform
bool platform_isDolbyAudioSupported()
{
    jboolean result = gIsDolbyAudioSupported.env->CallStaticBooleanMethod(gIsDolbyAudioSupported.classID, 
                                                                            gIsDolbyAudioSupported.methodID);
    return (bool)result;
}

///sets the Dolby Audio processing state
void platform_setDolbyAudioProcessingEnabled(bool enabled)
{
    gSetDolbyAudioProcessingEnabled.env->CallStaticVoidMethod(gSetDolbyAudioProcessingEnabled.classID, 
                                                                gSetDolbyAudioProcessingEnabled.methodID, 
                                                                (jboolean)enabled);    
}

///checks if Dolby Audio processing is currently enabled
bool platform_isDolbyAudioProcessingEnabled()
{
    jboolean result = gIsDolbyAudioProcessingEnabled.env->CallStaticBooleanMethod(gIsDolbyAudioProcessingEnabled.classID, 
                                                                                    gIsDolbyAudioProcessingEnabled.methodID);
    return (bool)result;
}

///checks if the Dolby Audio processing profile is supported
bool platform_isDolbyAudioProcessingProfileSupported(const char *profile)
{
    jstring jProfile = gIsDolbyAudioProcessingProfileSupported.env->NewStringUTF(profile);
    jboolean result = gIsDolbyAudioProcessingProfileSupported.env->CallStaticBooleanMethod(gIsDolbyAudioProcessingProfileSupported.classID, 
                                                                                            gIsDolbyAudioProcessingProfileSupported.methodID, 
                                                                                            jProfile);
    gIsDolbyAudioProcessingProfileSupported.env->DeleteLocalRef(jProfile);
    return (bool)result;
}

///sets the Dolby Audio processing profile to use
bool platform_setDolbyAudioProcessingProfile(const char *profile)
{
    jstring jProfile = gSetDolbyAudioProcessingProfile.env->NewStringUTF(profile);
    jboolean result = gSetDolbyAudioProcessingProfile.env->CallStaticBooleanMethod(gSetDolbyAudioProcessingProfile.classID, 
                                                                                    gSetDolbyAudioProcessingProfile.methodID, 
                                                                                    jProfile);
    gSetDolbyAudioProcessingProfile.env->DeleteLocalRef(jProfile);
    return (bool)result;
}

///gets the currently in use Dolby Audio processing profile
const char *platform_getSelectedDolbyAudioProfile()
{
    jstring result = (jstring)gGetSelectedDolbyAudioProfile.env->CallStaticObjectMethod(gGetSelectedDolbyAudioProfile.classID, 
                                                                                        gGetSelectedDolbyAudioProfile.methodID);

    ///convert jstring result into const char* for us to return
    cocos2d::CCString *profileName = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    profileName->autorelease();
    gGetSelectedDolbyAudioProfile.env->DeleteLocalRef(result);
    return profileName->m_sString.c_str();
}

#endif
