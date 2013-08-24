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

#ifndef _PLATFORM_PLATFORMDISPLAY_H_
#define _PLATFORM_PLATFORMDISPLAY_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include "loom/common/core/assert.h"

/**************************************************************************
 * Loom Display Management API
 *
 * A display can show frames to a user, and accept input from that user.
 * Some platforms can have lots of displays, others can only have one.
 *
 * @todo Multiple display support.
 * @todo Extend input a display can report.
 *************************************************************************/

typedef enum display_profile
{
    PROFILE_DESKTOP,
    PROFILE_MOBILE_SMALL,
    PROFILE_MOBILE_NORMAL,
    PROFILE_MOBILE_LARGE
} display_profile;

display_profile display_getProfile();
float display_getDPI();

/*
 *
 * typedef void(*display_callback_t)();
 * typedef void(*resize_callback_t)(int width, int height);
 * typedef void(*startup_callback_t)();
 * typedef void(*tick_callback_t)();
 *
 * void display_create(const char *caption, display_callback_t dc, resize_callback_t rc);
 * void display_present();
 * int display_getKeyState(display_key_t key);
 * void display_close();
 * void display_registerCallbacks( startup_callback_t sc, tick_callback_t tc );
 * void display_mainloop();
 *
 * void display_getSize(int* w, int* h);
 *
 *
 *
 * void platform_enableAccelerometer( unsigned char enabled );
 * void platform_setAccelerometerDebugMode( unsigned char enabled );
 *
 * display_profile display_getProfile();
 * float display_getDPI();
 */

#ifdef __cplusplus
};
#endif
#endif
