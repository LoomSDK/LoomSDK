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

#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/common/platform/platformMobile.h"

using namespace LS;


/// Script bindings to the native Mobile API.
///
/// See Mobile.ls for documentation on this API.
class Mobile
{
private:
    /// Event handler; this is called by the C mobile API when there is a recorded sensor change
    static void sensorTripleChanged(int sensor, float x, float y, float z)
    {
        ///Convert to delegate calls.
        _OnSensorTripleChangedDelegate.pushArgument(sensor);
        _OnSensorTripleChangedDelegate.pushArgument(x);
        _OnSensorTripleChangedDelegate.pushArgument(y);
        _OnSensorTripleChangedDelegate.pushArgument(z);
        _OnSensorTripleChangedDelegate.invoke();
    }
    /// Event handler; this is called by the C mobile API when the app is launched via a custom URL
    static void openedViaCustomURL()
    {
        ///Convert to delegate calls.
        _OnOpenedViaCustomURLDelegate.invoke();
    }

public:
    LOOM_STATICDELEGATE(OnSensorTripleChanged);
    LOOM_STATICDELEGATE(OnOpenedViaCustomURL);

    static void initialize()
    {
        platform_mobileInitialize(sensorTripleChanged, openedViaCustomURL);
    }
    static void vibrate()
    {
        platform_vibrate();
    }
    static void allowScreenSleep(bool sleep)
    {
        platform_allowScreenSleep(sleep);
    }
    static bool shareText(const char *subject, const char *text)
    {
        return platform_shareText(subject, text);
    }       
    static bool wasOpenedViaCustomURL()
    {
        return platform_wasOpenedViaCustomURL();
    }       
    static const char *getOpenURLQueryData(const char *queryKey)
    {
        return platform_getOpenURLQueryData(queryKey);
    }       
    static bool isSensorSupported(int sensor)
    {
        return platform_isSensorSupported(sensor);
    }
    static bool isSensorEnabled(int sensor)
    {
        return platform_isSensorEnabled(sensor);
    }
    static bool hasSensorReceivedData(int sensor)
    {
        return platform_hasSensorReceivedData(sensor);
    }
    static bool enableSensor(int sensor)
    {
        return platform_enableSensor(sensor);
    }
    static void disableSensor(int sensor)
    {
        platform_disableSensor(sensor);
    }
};


///Dolby Audio access class... Android Only... treated as though a sub-class of Mobile 
///...hence the reason it doesn't have it's own 'initialize'
class DolbyAudio
{   
public:
    static bool supported()
    {
        return platform_isDolbyAudioSupported();
    }
    static void setProcessingEnabled(bool enable)
    {
        platform_setDolbyAudioProcessingEnabled(enable);
    }
    static bool isProcessingEnabled()
    {
        return platform_isDolbyAudioProcessingEnabled();
    }
    static bool isProfileSupported(const char *profile)
    {
        return platform_isDolbyAudioProcessingProfileSupported(profile);
    }
    static bool setProfile(const char *profile)
    {
        return platform_setDolbyAudioProcessingProfile(profile);
    }
    static const char *getSelectedProfile()
    {
        return platform_getSelectedDolbyAudioProfile();
    }
};




NativeDelegate Mobile::_OnSensorTripleChangedDelegate;
NativeDelegate Mobile::_OnOpenedViaCustomURLDelegate;


static int registerLoomMobile(lua_State *L)
{
    ///set up lua bindings
    beginPackage(L, "loom.platform")

        .beginClass<Mobile>("Mobile")

            .addStaticMethod("vibrate", &Mobile::vibrate)
            .addStaticMethod("allowScreenSleep", &Mobile::allowScreenSleep)
            .addStaticMethod("shareText", &Mobile::shareText)
            .addStaticMethod("wasOpenedViaCustomURL", &Mobile::wasOpenedViaCustomURL)
            .addStaticMethod("getOpenURLQueryData", &Mobile::getOpenURLQueryData)
            .addStaticMethod("isSensorSupported", &Mobile::isSensorSupported)
            .addStaticMethod("isSensorEnabled", &Mobile::isSensorEnabled)
            .addStaticMethod("hasSensorReceivedData", &Mobile::hasSensorReceivedData)
            .addStaticMethod("enableSensor", &Mobile::enableSensor)
            .addStaticMethod("disableSensor", &Mobile::disableSensor)
            .addStaticProperty("onSensorTripleChanged", &Mobile::getOnSensorTripleChangedDelegate)
            .addStaticProperty("onOpenedViaCustomURL", &Mobile::getOnOpenedViaCustomURLDelegate)

        .endClass()

    .endPackage();

    return 0;
}


static int registerLoomDolbyAudio(lua_State *L)
{
    beginPackage(L, "loom.platform")

        .beginClass<DolbyAudio>("DolbyAudio")

            .addStaticProperty("supported", &DolbyAudio::supported)

            .addStaticMethod("setProcessingEnabled", &DolbyAudio::setProcessingEnabled)
            .addStaticMethod("isProcessingEnabled", &DolbyAudio::isProcessingEnabled)
            .addStaticMethod("isProfileSupported", &DolbyAudio::isProfileSupported)
            .addStaticMethod("setProfile", &DolbyAudio::setProfile)
            .addStaticMethod("getSelectedProfile", &DolbyAudio::getSelectedProfile)
   
        .endClass()

    .endPackage();
    return 0;
}



void installLoomMobile()
{
    LOOM_DECLARE_NATIVETYPE(Mobile, registerLoomMobile);
    LOOM_DECLARE_NATIVETYPE(DolbyAudio, registerLoomDolbyAudio);
    Mobile::initialize();
}
