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

///sets the Dolby Audio processing profile to use
void platform_setDolbyAudioProcessingProfile(int profileIndex)
{
}

///gets the number of supported Dolby Audio processing profiles
int platform_getNumDolbyAudioProfiles()
{
    return 0;
}

///gets the name that represents the given Dolby Audio processing profile index
const char *platform_getDolbyAudioProfileName(int profileIndex)
{
    return "";
}

///gets the currently in use Dolby Audio processing profile
int platform_getSelectedDolbyAudioProfile()
{
    return -1;
}

///gets the pre-defined value of the Dolby Audio Private Profile
int platform_getDolbyAudioPrivateProfileID()
{
    return -1;
}


#if LOOM_PLATFORM != LOOM_PLATFORM_IOS

///Null Mobile class for all non-Mobile platforms

///initializes the data for the Mobile class for this platform
void platform_mobileInitialize()
{
}


///TODO:
///     -vibration
///     -screen timeout


#endif  //LOOM_PLATFORM != LOOM_PLATFORM_IOS

#endif //LOOM_PLATFORM != LOOM_PLATFORM_ANDROID

