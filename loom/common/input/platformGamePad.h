#ifndef _INPUT_PLATFORMGAMEPAD_H_
#define _INPUT_PLATFORMGAMEPAD_H_

/* Based on
 * Simple DirectMedia Layer
 * Copyright (C) 1997-2012 Sam Lantinga <slouken@libsdl.org>
 */

#ifdef __cplusplus
extern "C" {
#endif

/* The gamepad structure used to identify a gamepad */
struct _InputGamepad;
typedef struct _InputGamepad   InputGamepad;

#define GAMEPAD_BUTTON_PRESSED     1
#define GAMEPAD_BUTTON_RELEASED    0

extern int input_gamepadInit(void);

extern void input_gamepadQuit(void);

/* Function prototypes */

/**
 *  Count the number of gamepads attached to the system
 */
extern int input_numGamepads(void);

/**
 *  Get the implementation dependent name of a gamepad.
 *  This can be called before any gamepads are opened.
 *  If no name can be found, this function returns NULL.
 */
extern const char *input_gamepadName(int device_index);

/**
 *  Open a gamepad for use.
 *  The index passed as an argument refers tothe N'th gamepad on the system.
 *  This index is the value which will identify this gamepad in future gamepad
 *  events.
 *
 *  \return A gamepad identifier, or NULL if an error occurred.
 */
extern InputGamepad *input_gamepadOpen(int device_index);

/**
 *  Returns 1 if the gamepad has been opened, or 0 if it has not.
 */
extern int input_gamepadOpened(int device_index);

/**
 *  Get the device index of an opened gamepad.
 */
extern int input_gamepadIndex(InputGamepad *gamepad);

/**
 *  Get the number of general axis controls on a gamepad.
 */
extern int input_gamepadNumAxes(InputGamepad *gamepad);

/**
 *  Get the number of POV hats on a gamepad.
 */
extern int input_gamepadNumHats(InputGamepad *gamepad);

/**
 *  Get the number of buttons on a gamepad.
 */
extern int input_gamepadNumButtons(InputGamepad *gamepad);

/**
 *  Update the current state of the open gamepads.
 *
 *  This is called automatically by the event loop if any gamepad
 *  events are enabled.
 */
extern void input_gamepadUpdate(void);

/**
 *  Enable/disable gamepad event polling.
 *
 *  If gamepad events are disabled, you must call InputGamepadUpdate()
 *  yourself and check the state of the gamepad when you want gamepad
 *  information.
 *
 *  The state can be one of ::INPUT_QUERY, ::INPUT_ENABLE or ::INPUT_IGNORE.
 */
extern int input_gamepadEventState(int state);

/**
 *  Get the current state of an axis control on a gamepad.
 *
 *  The state is a value ranging from -32768 to 32767.
 *
 *  The axis indices start at index 0.
 */
extern int input_gamepadGetAxis(InputGamepad *gamepad, int axis);


#define GAMEPAD_HAT_CENTERED     0x00
#define GAMEPAD_HAT_UP           0x01
#define GAMEPAD_HAT_RIGHT        0x02
#define GAMEPAD_HAT_DOWN         0x04
#define GAMEPAD_HAT_LEFT         0x08
#define GAMEPAD_HAT_RIGHTUP      (GAMEPAD_HAT_RIGHT | GAMEPAD_HAT_UP)
#define GAMEPAD_HAT_RIGHTDOWN    (GAMEPAD_HAT_RIGHT | GAMEPAD_HAT_DOWN)
#define GAMEPAD_HAT_LEFTUP       (GAMEPAD_HAT_LEFT | GAMEPAD_HAT_UP)
#define GAMEPAD_HAT_LEFTDOWN     (GAMEPAD_HAT_LEFT | GAMEPAD_HAT_DOWN)
/*@}*/

/**
 *  Get the current state of a POV hat on a joystick.
 *
 *  The hat indices start at index 0.
 *
 *  \return The return value is one of the following positions:
 *           - ::GAMEPAD_HAT_CENTERED
 *           - ::GAMEPAD_HAT_UP
 *           - ::GAMEPAD_HAT_RIGHT
 *           - ::GAMEPAD_HAT_DOWN
 *           - ::GAMEPAD_HAT_LEFT
 *           - ::GAMEPAD_HAT_RIGHTUP
 *           - ::GAMEPAD_HAT_RIGHTDOWN
 *           - ::GAMEPAD_HAT_LEFTUP
 *           - ::GAMEPAD_HAT_LEFTDOWN
 */
extern int input_gamepadGetHat(InputGamepad *gamepad, int hat);

/**
 *  Get the current state of a button on a gamepad.
 *
 *  The button indices start at index 0.
 */
extern int input_gamepadGetButton(InputGamepad *gamepad, int button);

/**
 *  Close a gamepad previously opened with InputGamepadOpen().
 */
extern void input_gamepadClose(InputGamepad *gamepad);

#ifdef __cplusplus
};
#endif
#endif
