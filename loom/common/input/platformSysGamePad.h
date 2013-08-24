/*
 * Based on
 * Simple DirectMedia Layer
 * Copyright (C) 1997-2012 Sam Lantinga <slouken@libsdl.org>
 */

#include "platformGamePad.h"

#ifdef __cplusplus
extern "C" {
#endif


/* The  gamepad structure */
struct _InputGamepad
{
    int                   index;     /* Device index */
    const char            *name;     /* Joystick name - system dependent */

    int                   naxes;     /* Number of axis controls on the gamepad */
    int                   *axes;     /* Current axis states */

    int                   nhats;     /* Number of hats on the joystick */
    int                   *hats;     /* Current hat states */

    int                   nbuttons;  /* Number of buttons on the gamepad */
    int                   *buttons;  /* Current button states */

    struct gamepad_hwdata *hwdata;   /* Driver dependent information */

    int                   ref_count; /* Reference count for multiple opens */
};

/* Function to scan the system for gamepads.
 * Joystick 0 should be the system default gamepad.
 * This function should return the number of available gamepads, or -1
 * on an unrecoverable fatal error.
 */
extern int input_sysGamepadInit(void);

/* Function to get the device-dependent name of a gamepad */
extern const char *input_sysGamepadName(int index);

/* Function to open a gamepad for use.
 * The gamepad to open is specified by the index field of the gamepad.
 * This should fill the nbuttons and naxes fields of the gamepad structure.
 * It returns 0, or -1 if there is an error.
 */
extern int input_sysGamepadOpen(InputGamepad *gamepad);

/* Function to update the state of a gamepad - called as a device poll.
 * This function shouldn't update the gamepad structure directly,
 * but instead should call input_PrivateGamepad*() to deliver events
 * and update gamepad device state.
 */
extern void input_sysGamepadUpdate(InputGamepad *gamepad);

/* Function to close a gamepad after use */
extern void input_sysGamepadClose(InputGamepad *gamepad);

/* Function to perform any system-specific gamepad related cleanup */
extern void input_sysGamepadQuit(void);

#ifdef __cplusplus
}
#endif
