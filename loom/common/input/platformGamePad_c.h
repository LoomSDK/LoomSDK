/*
 * Based on
 * Simple DirectMedia Layer
 * Copyright (C) 1997-2012 Sam Lantinga <slouken@libsdl.org>
 */

#include "platformGamePad.h"

#ifdef __cplusplus
extern "C" {
#endif


/* The number of available joysticks on the system */
extern int _numjoysticks;

/* Initialization and shutdown functions */
extern int input_gamepadInit(void);
extern void input_gamepadQuit(void);

/* Internal event queueing functions */
extern int input_privateGamepadAxis(InputGamepad *gamepad, int axis, int value);

extern int input_privateGamepadButton(InputGamepad *gamepad, int button, int state);

extern int input_privateGamepadHat(InputGamepad *gamepad, int hat, int value);

/* Internal sanity checking functions */
extern int input_privateGamepadValid(InputGamepad **gamepad);


#ifdef __cplusplus
}
#endif
