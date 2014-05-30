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
 * Loom Facebook API
 *
 * Implementation of the Facebook API in Loom
 *
 */


///Callback for facebook session status API events
typedef void (*SessionStatusCallback)(const char *state, const char *permissions);

///Initializes the video playback for the platform
void platform_facebookInitialize(SessionStatusCallback sessionStatusCB);

///Opens up a Facebook session with Read Permissions
bool platform_openSessionWithReadPermissions(const char* permissionsString);

///Requests new permissions for publishing
bool platform_requestNewPublishPermissions(const char* permissionsString);

///Shows a Frictionless Request Dialog
void platform_showFrictionlessRequestDialog(const char* recipientsString, const char* titleString, const char* messageString);

///Returns the Facebook Access Token
const char* platform_getAccessToken();

///Closes Facebook the session and clears Token information
void platform_closeAndClearTokenInformation();

///Retruns the expiration date of the current Facebook Session
const char* platform_getExpirationDate(const char* dateFormat);


#endif
