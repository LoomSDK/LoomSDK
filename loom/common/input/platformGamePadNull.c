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

#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "platformGamePad.h"
#include "platformSysGamePad.h"
#include "platformGamePad_c.h"

#include <stdio.h>

// Null gamepad device

void input_sysGamepadUpdate(InputGamepad *gamepad)
{
}


/* Function to close a gamepad after use */
void input_sysGamepadClose(InputGamepad *gamepad)
{
}


/* Function to get the device-dependent name of a gamepad */
const char *input_sysGamepadName(int index)
{
    return "";
}


/* Function to perform any system-specific gamepad related cleanup */
void input_sysGamepadQuit(void)
{
}


/* Function to open a gamepad for use.
 * The gamepad to open is specified by the index field of the gamepad.
 * This should fill the nbuttons and naxes fields of the gamepad structure.
 * It returns 0, or -1 if there is an error.
 */
int input_sysGamepadOpen(InputGamepad *gamepad)
{
    return 0;
}


/* Function to scan the system for gamepads.
 * This function should set SDL_numgamepads to the number of available
 * gamepads.  Joystick 0 should be the system default gamepad.
 * It should return 0, or -1 on an unrecoverable fatal error.
 */
int input_sysGamepadInit(void)
{
    return 0;
}
