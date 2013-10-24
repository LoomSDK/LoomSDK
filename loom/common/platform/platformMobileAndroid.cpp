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

#include "loom/common/utils/utString.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformMobile.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAndroidMobileLogGroup, "loom.mobile.android", 1, 0);



static loomJniMethodInfo gIsDolbyAudioSupported;
static loomJniMethodInfo gSetDolbyAudioProcessingEnabled;
static loomJniMethodInfo gIsDolbyAudioProcessingEnabled;
static loomJniMethodInfo gSetDolbyAudioProcessingProfile;
static loomJniMethodInfo gGetNumDolbyAudioProfiles;
static loomJniMethodInfo gGetDolbyAudioProfileName;
static loomJniMethodInfo gGetSelectedDolbyAudioProfile;
static loomJniMethodInfo gGetDolbyAudioPrivateProfileID;



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
    LoomJni::getStaticMethodInfo(gSetDolbyAudioProcessingProfile,
                                 "com/dolby/DolbyAudio",
                                 "setProcessingProfile",
                                 "(I)V");
    LoomJni::getStaticMethodInfo(gGetNumDolbyAudioProfiles,
                                 "com/dolby/DolbyAudio",
                                 "getNumProfiles",
                                 "()I");
    LoomJni::getStaticMethodInfo(gGetDolbyAudioProfileName,
                                 "com/dolby/DolbyAudio",
                                 "getProfileName",
                                 "(I)Ljava/lang/String;");
    LoomJni::getStaticMethodInfo(gGetSelectedDolbyAudioProfile,
                                 "com/dolby/DolbyAudio",
                                 "getSelectedProfile",
                                 "()I");
    LoomJni::getStaticMethodInfo(gGetDolbyAudioPrivateProfileID,
                                 "com/dolby/DolbyAudio",
                                 "getPrivateProfileID",
                                 "()I");
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

///sets the Dolby Audio processing profile to use
void platform_setDolbyAudioProcessingProfile(int profileIndex)
{
    gSetDolbyAudioProcessingProfile.env->CallStaticVoidMethod(gSetDolbyAudioProcessingProfile.classID, 
                                                                gSetDolbyAudioProcessingProfile.methodID, 
                                                                profileIndex);
}

///gets the number of supported Dolby Audio processing profiles
int platform_getNumDolbyAudioProfiles()
{
    jint result = gGetNumDolbyAudioProfiles.env->CallStaticIntMethod(gGetNumDolbyAudioProfiles.classID, 
                                                                        gGetNumDolbyAudioProfiles.methodID);
    return (int)result;
}

///gets the name that represents the given Dolby Audio processing profile index
const char *platform_getDolbyAudioProfileName(int profileIndex)
{
    jstring result = (jstring)gGetDolbyAudioProfileName.env->CallStaticObjectMethod(gGetDolbyAudioProfileName.classID, 
                                                                                    gGetDolbyAudioProfileName.methodID,
                                                                                    profileIndex);

    ///convert jstring result into const char* for us to return
    utString profileName = LoomJni::jstring2string(result);
    gGetDolbyAudioProfileName.env->DeleteLocalRef(result);
    return profileName.c_str();
}

///gets the currently in use Dolby Audio processing profile
int platform_getSelectedDolbyAudioProfile()
{
    jint result = gGetSelectedDolbyAudioProfile.env->CallStaticIntMethod(gGetSelectedDolbyAudioProfile.classID, 
                                                                            gGetSelectedDolbyAudioProfile.methodID);
    return (int)result;
}

///gets the pre-defined value of the Dolby Audio Private Profile
int platform_getDolbyAudioPrivateProfileID()
{
    jint result = gGetDolbyAudioPrivateProfileID.env->CallStaticIntMethod(gGetDolbyAudioPrivateProfileID.classID, 
                                                                            gGetDolbyAudioPrivateProfileID.methodID);
    return (int)result;
}

#endif
