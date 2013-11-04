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

#ifndef _LOOM_COMMON_PLATFORM_PLATFORMMOBILE_H_
#define _LOOM_COMMON_PLATFORM_PLATFORMMOBILE_H_

/**
 * Loom Mobile API
 *
 * For mobile specific functionality, Loom includes a cross-platform native API. This
 * abstraction handles various functionality on mobile devices, such as Vibration, etc..
 *
 */

///initializes the data for the Mobile class for this platform
void platform_mobileInitialize();

///checks if Dolby Audio is supported on this platform
bool platform_isDolbyAudioSupported();

///sets the Dolby Audio processing state
void platform_setDolbyAudioProcessingEnabled(bool enabled);

///checks if Dolby Audio processing is currently enabled
bool platform_isDolbyAudioProcessingEnabled();

///checks if the specified Dolby Audio processing profile is supported on this hardware
bool platform_isDolbyAudioProcessingProfileSupported(const char *profile);

///sets the Dolby Audio processing profile to use
bool platform_setDolbyAudioProcessingProfile(const char *profile);

///gets the currently in use Dolby Audio processing profile
const char *platform_getSelectedDolbyAudioProfile();

#endif
