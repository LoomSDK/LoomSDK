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
#include "loom/common/platform/platformMobile.h"

#if LOOM_PLATFORM != LOOM_PLATFORM_ANDROID

///Null Dolby Mobile class for all non-Android platforms


//checks if Dolby Audio is supported on this platform
bool platform_isDolbyAudioSupported()
{
    return false;
}

///sets the Dolby Audio processing state
void platform_setDolbyAudioProcessingEnabled(bool enabled)
{
}

///checks if Dolby Audio processing is currently enabled
bool platform_isDolbyAudioProcessingEnabled()
{
    return false;
}

///checks if the specified Dolby Audio processing profile is supported on this hardware
bool platform_isDolbyAudioProcessingProfileSupported(const char *profile)
{
    return false;
}

///sets the Dolby Audio processing profile to use
bool platform_setDolbyAudioProcessingProfile(const char *profile)
{
    return false;
}

///gets the currently in use Dolby Audio processing profile
const char *platform_getSelectedDolbyAudioProfile()
{
    return "";
}



#if LOOM_PLATFORM != LOOM_PLATFORM_IOS

///Null Mobile class for all non-Mobile platforms

///initializes the data for the Mobile class for this platform
void platform_mobileInitialize(SensorTripleChangedCallback sensorTripleChangedCB)
{
}

///tells the device to do a short vibration, if supported by the hardware
void platform_vibrate()
{
}

///sets whether or not to use the system screen sleep timeout
void platform_allowScreenSleep(bool sleep)
{
}

///shares the specfied text via other applications on the device (ie. Twitter, Facebook)
bool platform_shareText(const char *subject, const char *text)
{
    return false;
}

///returns if the application was launched via a Custom URL Scheme
bool platform_wasOpenedViaCustomURL()
{
    return false;
}

///gets the the specified query key data from any custom scheme URL path that the application was launched with, or "" if not found
const char *platform_getOpenURLQueryData(const char *queryKey)
{
    return "";
}

///checks if a given sensor is supported on this hardware
bool platform_isSensorSupported(int sensor)
{
    return false;
}

///checks if a given sensor is currently enabled
bool platform_isSensorEnabled(int sensor)
{
    return false;
}

///checks if a given sensor has received any data yet
bool platform_hasSensorReceivedData(int sensor)
{
    return false;
}

///enables the given sensor
bool platform_enableSensor(int sensor)
{
    return false;
}

///disables the given sensor
void platform_disableSensor(int sensor)
{
}



#endif  //LOOM_PLATFORM != LOOM_PLATFORM_IOS

#endif //LOOM_PLATFORM != LOOM_PLATFORM_ANDROID

