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
#include "loom/common/platform/platformMobile.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAndroidMobileLogGroup, "mobile", 1, LoomLogDefault);


static SensorTripleChangedCallback gTripleChangedCallback = NULL;
static OpenedViaCustomURLCallback gOpenedViaCustomURLCallback = NULL;
static OpenedViaRemoteNotificationCallback gOpenedViaRemoteNotificationCallback = NULL;


extern "C"
{
void Java_co_theengine_loomplayer_LoomSensors_onRotationChangedNative(JNIEnv *env, jobject thiz, jfloat x, jfloat y, jfloat z)
{
    if (gTripleChangedCallback)
    {
        ///3 == MobileSensorType.Rotation
        gTripleChangedCallback(3, x, y, z);
    }
}

void Java_co_theengine_loomplayer_LoomSensors_onAccelerometerChangedNative(JNIEnv *env, jobject thiz, jfloat x, jfloat y, jfloat z)
{
    if (gTripleChangedCallback)
    {
        ///0 == MobileSensorType.Accelerometer
        gTripleChangedCallback(0, x, y, z);
    }
}

void Java_co_theengine_loomplayer_LoomSensors_onGravityChangedNative(JNIEnv *env, jobject thiz, jfloat x, jfloat y, jfloat z)
{
    if (gTripleChangedCallback)
    {
        ///4 == MobileSensorType.Gravity
        gTripleChangedCallback(4, x, y, z);
    }
}
void Java_co_theengine_loomplayer_LoomMobile_onOpenedViaCustomURL(JNIEnv *env, jobject thiz)
{
    if (gOpenedViaCustomURLCallback)
    {
        gOpenedViaCustomURLCallback();
    }
}
void Java_co_theengine_loomplayer_LoomMobile_onOpenedViaRemoteNotification(JNIEnv *env, jobject thiz)
{
    if (gOpenedViaRemoteNotificationCallback)
    {
        gOpenedViaRemoteNotificationCallback();
    }
}
}


static loomJniMethodInfo gVibrate;
static loomJniMethodInfo gAllowScreenSleep;
static loomJniMethodInfo gStartLocationTracking;
static loomJniMethodInfo gStopLocationTracking;
static loomJniMethodInfo gGetLocation;
static loomJniMethodInfo gShareText;
static loomJniMethodInfo gIsSensorSupported;
static loomJniMethodInfo gDidCustomURLOpen;
static loomJniMethodInfo gDidRemoteNotificationOpen;
static loomJniMethodInfo gGetCustomSchemeData;
static loomJniMethodInfo gGetRemoteNotificationData;
static loomJniMethodInfo gIsSensorEnabled;
static loomJniMethodInfo gHasSensorReceivedData;
static loomJniMethodInfo gEnableSensor;
static loomJniMethodInfo gDisableSensor;

static loomJniMethodInfo gIsDolbyAudioSupported;
static loomJniMethodInfo gSetDolbyAudioProcessingEnabled;
static loomJniMethodInfo gIsDolbyAudioProcessingEnabled;
static loomJniMethodInfo gIsDolbyAudioProcessingProfileSupported;
static loomJniMethodInfo gSetDolbyAudioProcessingProfile;
static loomJniMethodInfo gGetSelectedDolbyAudioProfile;



///initializes the data for the Mobile class for Android
void platform_mobileInitialize(SensorTripleChangedCallback sensorTripleChangedCB, 
                                OpenedViaCustomURLCallback customURLCB,
                                OpenedViaRemoteNotificationCallback remoteNotificationCB)
{
    lmLog(gAndroidMobileLogGroup, "Initializing Mobile for Android");

    gTripleChangedCallback = sensorTripleChangedCB;    
    gOpenedViaCustomURLCallback = customURLCB;    
    gOpenedViaRemoteNotificationCallback = remoteNotificationCB;    


    ///Bind to JNI entry points.
    ///Mobile
    LoomJni::getStaticMethodInfo(gVibrate,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "vibrate",
                                 "()V");
    LoomJni::getStaticMethodInfo(gAllowScreenSleep,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "allowScreenSleep",
                                 "(Z)V");
    LoomJni::getStaticMethodInfo(gStartLocationTracking,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "startLocationTracking",
                                 "(II)V");
    LoomJni::getStaticMethodInfo(gStopLocationTracking,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "stopLocationTracking",
                                 "()V");
    LoomJni::getStaticMethodInfo(gGetLocation,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "getLocation",
                                 "()Ljava/lang/String;");
    LoomJni::getStaticMethodInfo(gShareText,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "shareText",
                                 "(Ljava/lang/String;Ljava/lang/String;)Z");
    LoomJni::getStaticMethodInfo(gDidCustomURLOpen,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "openedWithCustomScheme",
                                 "()Z");
    LoomJni::getStaticMethodInfo(gDidRemoteNotificationOpen,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "openedWithRemoteNotification",
                                 "()Z");
    LoomJni::getStaticMethodInfo(gGetCustomSchemeData,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "getCustomSchemeQueryData",
                                 "(Ljava/lang/String;)Ljava/lang/String;");
    LoomJni::getStaticMethodInfo(gGetRemoteNotificationData,
                                 "co/theengine/loomplayer/LoomMobile",
                                 "getRemoteNotificationData",
                                 "(Ljava/lang/String;)Ljava/lang/String;");
    LoomJni::getStaticMethodInfo(gIsSensorSupported,
                                 "co/theengine/loomplayer/LoomSensors",
                                 "isSensorSupported",
                                 "(I)Z");
    LoomJni::getStaticMethodInfo(gIsSensorEnabled,
                                 "co/theengine/loomplayer/LoomSensors",
                                 "isSensorEnabled",
                                 "(I)Z");
    LoomJni::getStaticMethodInfo(gHasSensorReceivedData,
                                 "co/theengine/loomplayer/LoomSensors",
                                 "hasSensorReceivedData",
                                 "(I)Z");
    LoomJni::getStaticMethodInfo(gEnableSensor,
                                 "co/theengine/loomplayer/LoomSensors",
                                 "enableSensor",
                                 "(I)Z");
    LoomJni::getStaticMethodInfo(gDisableSensor,
                                 "co/theengine/loomplayer/LoomSensors",
                                 "disableSensor",
                                 "(I)V");

    ///Dolby
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


///tells the device to do a short vibration, if supported by the hardware
void platform_vibrate()
{
    gVibrate.getEnv()->CallStaticVoidMethod(gVibrate.classID, gVibrate.methodID);
}

///sets whether or not to use the system screen sleep timeout
void platform_allowScreenSleep(bool sleep)
{
    gAllowScreenSleep.getEnv()->CallStaticVoidMethod(gAllowScreenSleep.classID, 
                                                gAllowScreenSleep.methodID, 
                                                (jboolean)sleep);    
}

///enables location tracking for this device
void platform_startLocationTracking(int minDist, int minTime)
{
    gStartLocationTracking.getEnv()->CallStaticVoidMethod(gStartLocationTracking.classID, 
                                                            gStartLocationTracking.methodID, 
                                                            (jint)minDist,
                                                            (jint)minTime);    
}

///disables location tracking for this device
void platform_stopLocationTracking()
{
    gStopLocationTracking.getEnv()->CallStaticVoidMethod(gStopLocationTracking.classID, gStopLocationTracking.methodID);    
}

///returns the device's location using GPS and/or NETWORK signals
const char *platform_getLocation()
{
    jstring result = (jstring)gGetLocation.getEnv()->CallStaticObjectMethod(gGetLocation.classID, gGetLocation.methodID);
    if(result == NULL)
    {
        return "";
    }

    ///convert jstring result into const char* for us to return
    // cocos2d::CCString *locationString = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    // locationString->autorelease();
    utString *locationString = new utString(LoomJni::jstring2string(result).c_str());
    gGetLocation.getEnv()->DeleteLocalRef(result);
    return locationString->c_str();
}

///shares the specfied text via other applications on the device (ie. Twitter, Facebook)
bool platform_shareText(const char *subject, const char *text)
{
    jstring jSubject = gShareText.getEnv()->NewStringUTF(subject);
    jstring jText = gShareText.getEnv()->NewStringUTF(text);
    jboolean result = gShareText.getEnv()->CallStaticBooleanMethod(gShareText.classID, 
                                                                gShareText.methodID, 
                                                                jSubject,
                                                                jText);    
    gShareText.getEnv()->DeleteLocalRef(jSubject);
    gShareText.getEnv()->DeleteLocalRef(jText);
    return (bool)result;
}


///returns if the application was launched via a Custom URL Scheme
bool platform_wasOpenedViaCustomURL()
{
    jboolean result = gDidCustomURLOpen.getEnv()->CallStaticBooleanMethod(gDidCustomURLOpen.classID, gDidCustomURLOpen.methodID);    
    return (bool)result;
}

///returns if the application was launched via a Remote Notification
bool platform_wasOpenedViaRemoteNotification()
{
    jboolean result = gDidRemoteNotificationOpen.getEnv()->CallStaticBooleanMethod(gDidRemoteNotificationOpen.classID, gDidRemoteNotificationOpen.methodID);    
    return (bool)result;
}

void platform_setOpenURLQueryData(const char *query)
{
    // Android has alternative ways of setting this
    lmAssert(false, "Should not be called");
}

///gets the the specified query key data from any custom scheme URL path that the application was launched with, or "" if not found
const char *platform_getOpenURLQueryData(const char *queryKey)
{
    jstring jQuery = gGetCustomSchemeData.getEnv()->NewStringUTF(queryKey);
    jstring result = (jstring)gGetCustomSchemeData.getEnv()->CallStaticObjectMethod(gGetCustomSchemeData.classID, 
                                                                                gGetCustomSchemeData.methodID,
                                                                                jQuery);
    if(result == NULL)
    {
        return "";
    }
    ///convert jstring result into const char* for us to return
    //cocos2d::CCString *queryData = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    //queryData->autorelease();
    utString *queryData = new utString(LoomJni::jstring2string(result).c_str());
    gGetCustomSchemeData.getEnv()->DeleteLocalRef(jQuery);
    return queryData->c_str();
}

///gets the the data associated with the specified key from any potential custom payload attached to a 
///Remote Notification that the application was launched with, or "" if not found
const char *platform_getRemoteNotificationData(const char *key)
{
    jstring jQuery = gGetRemoteNotificationData.getEnv()->NewStringUTF(key);
    jstring result = (jstring)gGetRemoteNotificationData.getEnv()->CallStaticObjectMethod(gGetRemoteNotificationData.classID, 
                                                                                gGetRemoteNotificationData.methodID,
                                                                                jQuery);
    if(result == NULL)
    {
        return "";
    }
    ///convert jstring result into const char* for us to return
    //cocos2d::CCString *queryData = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    //queryData->autorelease();
    utString *queryData = new utString(LoomJni::jstring2string(result).c_str());
    gGetRemoteNotificationData.getEnv()->DeleteLocalRef(jQuery);
    return queryData->c_str();
}

///checks if a given sensor is supported on this hardware
bool platform_isSensorSupported(int sensor)
{
    jboolean result = gIsSensorSupported.getEnv()->CallStaticBooleanMethod(gIsSensorSupported.classID, 
                                                                        gIsSensorSupported.methodID,
                                                                        sensor);
    return (bool)result;
}

///checks if a given sensor is currently enabled
bool platform_isSensorEnabled(int sensor)
{
    jboolean result = gIsSensorEnabled.getEnv()->CallStaticBooleanMethod(gIsSensorEnabled.classID, 
                                                                        gIsSensorEnabled.methodID,
                                                                        sensor);
    return (bool)result;
}

///checks if a given sensor has received any data yet
bool platform_hasSensorReceivedData(int sensor)
{
    jboolean result = gHasSensorReceivedData.getEnv()->CallStaticBooleanMethod(gHasSensorReceivedData.classID, 
                                                                            gHasSensorReceivedData.methodID,
                                                                            sensor);
    return (bool)result;
}

///enables the given sensor
bool platform_enableSensor(int sensor)
{
    jboolean result = gEnableSensor.getEnv()->CallStaticBooleanMethod(gEnableSensor.classID, 
                                                                    gEnableSensor.methodID,
                                                                    sensor);
    return (bool)result;
}

///disables the given sensor
void platform_disableSensor(int sensor)
{
    gDisableSensor.getEnv()->CallStaticVoidMethod(gDisableSensor.classID, 
                                                gDisableSensor.methodID, 
                                                sensor);    
}




//checks if Dolby Audio is supported on this platform
bool platform_isDolbyAudioSupported()
{
    jboolean result = gIsDolbyAudioSupported.getEnv()->CallStaticBooleanMethod(gIsDolbyAudioSupported.classID, 
                                                                            gIsDolbyAudioSupported.methodID);
    return (bool)result;
}

///sets the Dolby Audio processing state
void platform_setDolbyAudioProcessingEnabled(bool enabled)
{
    gSetDolbyAudioProcessingEnabled.getEnv()->CallStaticVoidMethod(gSetDolbyAudioProcessingEnabled.classID, 
                                                                gSetDolbyAudioProcessingEnabled.methodID, 
                                                                (jboolean)enabled);    
}

///checks if Dolby Audio processing is currently enabled
bool platform_isDolbyAudioProcessingEnabled()
{
    jboolean result = gIsDolbyAudioProcessingEnabled.getEnv()->CallStaticBooleanMethod(gIsDolbyAudioProcessingEnabled.classID, 
                                                                                    gIsDolbyAudioProcessingEnabled.methodID);
    return (bool)result;
}

///checks if the Dolby Audio processing profile is supported
bool platform_isDolbyAudioProcessingProfileSupported(const char *profile)
{
    jstring jProfile = gIsDolbyAudioProcessingProfileSupported.getEnv()->NewStringUTF(profile);
    jboolean result = gIsDolbyAudioProcessingProfileSupported.getEnv()->CallStaticBooleanMethod(gIsDolbyAudioProcessingProfileSupported.classID, 
                                                                                            gIsDolbyAudioProcessingProfileSupported.methodID, 
                                                                                            jProfile);
    gIsDolbyAudioProcessingProfileSupported.getEnv()->DeleteLocalRef(jProfile);
    return (bool)result;
}

///sets the Dolby Audio processing profile to use
bool platform_setDolbyAudioProcessingProfile(const char *profile)
{
    jstring jProfile = gSetDolbyAudioProcessingProfile.getEnv()->NewStringUTF(profile);
    jboolean result = gSetDolbyAudioProcessingProfile.getEnv()->CallStaticBooleanMethod(gSetDolbyAudioProcessingProfile.classID, 
                                                                                    gSetDolbyAudioProcessingProfile.methodID, 
                                                                                    jProfile);
    gSetDolbyAudioProcessingProfile.getEnv()->DeleteLocalRef(jProfile);
    return (bool)result;
}

///gets the currently in use Dolby Audio processing profile
const char *platform_getSelectedDolbyAudioProfile()
{
    jstring result = (jstring)gGetSelectedDolbyAudioProfile.getEnv()->CallStaticObjectMethod(gGetSelectedDolbyAudioProfile.classID, 
                                                                                        gGetSelectedDolbyAudioProfile.methodID);

    ///convert jstring result into const char* for us to return
    //cocos2d::CCString *profileName = new cocos2d::CCString(LoomJni::jstring2string(result).c_str());
    //profileName->autorelease();
    utString *profileName = new utString(LoomJni::jstring2string(result).c_str());
    gGetSelectedDolbyAudioProfile.getEnv()->DeleteLocalRef(result);
    return profileName->c_str();
}

#endif
