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

#ifndef _LOOM_COMMON_PLATFORM_PLATFORMFACEBOOK_H_
#define _LOOM_COMMON_PLATFORM_PLATFORMFACEBOOK_H_

/**
 * Loom Teak API
 *
 * Implementation of the Teak API in Loom
 *
 */


///Callback for Teak authoriziation status change event
typedef void (*AuthStatusCallback)(int authState);

///Initializes Teak for the platform
void platform_teakInitialize(AuthStatusCallback sessionStatusCB);

//TODO: make nice for LoomSDK
bool platform_isTeakActive();
void platform_setAccessToken(const char *fbAccessToken);
int platform_getStatus();
bool platform_postAchievement(const char *achievementId);
bool platform_postHighScore(int score);
bool platform_postAction(const char *actionId, const char *objectInstanceId);



#endif