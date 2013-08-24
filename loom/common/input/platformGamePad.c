/*
 * Based on
 * Simple DirectMedia Layer
 * Copyright (C) 1997-2012 Sam Lantinga <slouken@libsdl.org>
 */

#include <stdio.h>
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "platformSysGamePad.h"
#include "platformGamePad_c.h"

int _numgamepads = 0;
static InputGamepad    **_gamepads     = NULL;
static loom_logGroup_t gamepadLogGroup = { "gamepad", 1 };

int
input_gamepadInit(void)
{
    int arraylen;
    int status;

    _numgamepads = 0;
    status       = input_sysGamepadInit();
    if (status >= 0)
    {
        arraylen  = (status + 1) * sizeof(*_gamepads);
        _gamepads = (InputGamepad **)malloc(arraylen);
        if (_gamepads == NULL)
        {
            _numgamepads = 0;
        }
        else
        {
            memset(_gamepads, 0, arraylen);
            _numgamepads = status;
        }
        status = 0;
    }
    return(status);
}


/*
 * Count the number of gamepads attached to the system
 */
int
input_numGamepads(void)
{
    return _numgamepads;
}


/*
 * Get the implementation dependent name of a gamepad
 */
const char *
input_gamepadName(int device_index)
{
    if ((device_index < 0) || (device_index >= _numgamepads))
    {
        lmLog(gamepadLogGroup, "There are %d gamepads available", _numgamepads);
        return(NULL);
    }
    return(input_sysGamepadName(device_index));
}


/*
 * Open a gamepad for use - the index passed as an argument refers to
 * the N'th gamepad on the system.  This index is the value which will
 * identify this gamepad in future gamepad events.
 *
 * This function returns a gamepad identifier, or NULL if an error occurred.
 */
InputGamepad *
input_gamepadOpen(int device_index)
{
    int          i;
    InputGamepad *gamepad;

    if ((device_index < 0) || (device_index >= _numgamepads))
    {
        lmLog(gamepadLogGroup, "There are %d gamepads available", _numgamepads);
        return(NULL);
    }

    /* If the gamepad is already open, return it */
    for (i = 0; _gamepads[i]; ++i)
    {
        if (device_index == _gamepads[i]->index)
        {
            gamepad = _gamepads[i];
            ++gamepad->ref_count;
            return(gamepad);
        }
    }

    /* Create and initialize the gamepad */
    gamepad = (InputGamepad *)malloc((sizeof *gamepad));
    if (gamepad == NULL)
    {
        lmAssert(0, "Out of Memory");
        return NULL;
    }

    memset(gamepad, 0, (sizeof *gamepad));
    gamepad->index = device_index;
    if (input_sysGamepadOpen(gamepad) < 0)
    {
        free(gamepad);
        return NULL;
    }
    if (gamepad->naxes > 0)
    {
        gamepad->axes = (int *)malloc
                            (gamepad->naxes * sizeof(int));
    }

    if (gamepad->nhats > 0)
    {
        gamepad->hats = (int *)malloc
                            (gamepad->nhats * sizeof(int));
    }

    if (gamepad->nbuttons > 0)
    {
        gamepad->buttons = (int *)malloc
                               (gamepad->nbuttons * sizeof(int));
    }
    if (((gamepad->naxes > 0) && !gamepad->axes) ||
        ((gamepad->nbuttons > 0) && !gamepad->buttons) ||
        ((gamepad->nhats > 0) && !gamepad->hats))
    {
        lmAssert(0, "Out of Memory");
        input_gamepadClose(gamepad);
        return NULL;
    }
    if (gamepad->axes)
    {
        memset(gamepad->axes, 0, gamepad->naxes * sizeof(int));
    }

    if (gamepad->buttons)
    {
        memset(gamepad->buttons, 0, gamepad->nbuttons * sizeof(int));
    }

    if (gamepad->hats)
    {
        memset(gamepad->hats, 0, gamepad->nhats * sizeof(int));
    }
    /* Add gamepad to list */
    ++gamepad->ref_count;
    for (i = 0; _gamepads[i]; ++i)
    {
        /* Skip to next gamepad */
    }
    _gamepads[i] = gamepad;

    return(gamepad);
}


/*
 * Returns 1 if the gamepad has been opened, or 0 if it has not.
 */
int
input_gamepadOpened(int device_index)
{
    int i, opened;

    opened = 0;
    for (i = 0; _gamepads[i]; ++i)
    {
        if (_gamepads[i]->index == (int)device_index)
        {
            opened = 1;
            break;
        }
    }
    return(opened);
}


/*
 * Checks to make sure the gamepad is valid.
 */
int
input_privateGamepadValid(InputGamepad **gamepad)
{
    int valid;

    if (*gamepad == NULL)
    {
        lmLog(gamepadLogGroup, "Gamepad hasn't been opened yet");
        valid = 0;
    }
    else
    {
        valid = 1;
    }
    return valid;
}


/*
 * Get the device index of an opened gamepad.
 */
int
input_gamepadIndex(InputGamepad *gamepad)
{
    if (!input_privateGamepadValid(&gamepad))
    {
        return(-1);
    }
    return(gamepad->index);
}


/*
 * Get the number of multi-dimensional axis controls on a gamepad
 */
int
input_gamepadNumAxes(InputGamepad *gamepad)
{
    if (!input_privateGamepadValid(&gamepad))
    {
        return(-1);
    }
    return(gamepad->naxes);
}


/*
 * Get the number of hats on a gamepad
 */
int
input_gamepadNumHats(InputGamepad *gamepad)
{
    if (!input_privateGamepadValid(&gamepad))
    {
        return(-1);
    }
    return(gamepad->nhats);
}


/*
 * Get the number of buttons on a gamepad
 */
int
input_gamepadNumButtons(InputGamepad *gamepad)
{
    if (!input_privateGamepadValid(&gamepad))
    {
        return(-1);
    }
    return(gamepad->nbuttons);
}


/*
 * Get the current state of an axis control on a gamepad
 */
int
input_gamepadGetAxis(InputGamepad *gamepad, int axis)
{
    int state;

    if (!input_privateGamepadValid(&gamepad))
    {
        return(0);
    }
    if (axis < gamepad->naxes)
    {
        state = gamepad->axes[axis];
    }
    else
    {
        lmLog(gamepadLogGroup, "Gamepad only has %d axes", gamepad->naxes);
        state = 0;
    }
    return(state);
}


/*
 * Get the current state of a button on a gamepad
 */
int
input_gamepadGetButton(InputGamepad *gamepad, int button)
{
    int state;

    if (!input_privateGamepadValid(&gamepad))
    {
        return(0);
    }
    if (button < gamepad->nbuttons)
    {
        state = gamepad->buttons[button];
    }
    else
    {
        lmLog(gamepadLogGroup, "Gamepad only has %d buttons", gamepad->nbuttons);
        state = 0;
    }
    return(state);
}


/*
 * Get the current state of a hat on a joystick
 */
int
input_gamepadGetHat(InputGamepad *gamepad, int hat)
{
    int state;

    if (!input_privateGamepadValid(&gamepad))
    {
        return(0);
    }
    if (hat < gamepad->nhats)
    {
        state = gamepad->hats[hat];
    }
    else
    {
        lmLog(gamepadLogGroup, "Gamepad only has %d hats", gamepad->nhats);
        state = 0;
    }
    return(state);
}


/*
 * Close a gamepad previously opened with input_gamepadOpen()
 */
void
input_gamepadClose(InputGamepad *gamepad)
{
    int i;

    if (!input_privateGamepadValid(&gamepad))
    {
        return;
    }

    /* First decrement ref count */
    if (--gamepad->ref_count > 0)
    {
        return;
    }

    input_sysGamepadClose(gamepad);

    /* Remove gamepad from list */
    for (i = 0; _gamepads[i]; ++i)
    {
        if (gamepad == _gamepads[i])
        {
            memmove(&_gamepads[i], &_gamepads[i + 1],
                    (_numgamepads - i) * sizeof(gamepad));
            break;
        }
    }

    /* Free the data associated with this gamepad */
    if (gamepad->axes)
    {
        free(gamepad->axes);
    }

    if (gamepad->buttons)
    {
        free(gamepad->buttons);
    }

    if (gamepad->hats)
    {
        free(gamepad->hats);
    }

    free(gamepad);
}


void
input_gamepadQuit(void)
{
    const int numsticks = _numgamepads;
    int       i;

    /* Stop the event polling */
    _numgamepads = 0;

    for (i = numsticks; i--; )
    {
        InputGamepad *stick = _gamepads[i];
        if (stick && (stick->ref_count >= 1))
        {
            stick->ref_count = 1;
            input_gamepadClose(stick);
        }
    }

    /* Quit the gamepad setup */
    input_sysGamepadQuit();
    if (_gamepads)
    {
        free(_gamepads);
        _gamepads = NULL;
    }
}


/* These are global for input_sysGamepad.c and input_events.c */

int
input_privateGamepadAxis(InputGamepad *gamepad, int axis, int value)
{
    /* Make sure we're not getting garbage events */
    if (axis >= gamepad->naxes)
    {
        return 0;
    }

    /* Update internal gamepad state */
    gamepad->axes[axis] = value;

    return 0;
}


int
input_privateGamepadHat(InputGamepad *gamepad, int hat, int value)
{
    /* Make sure we're not getting garbage events */
    if (hat >= gamepad->nhats)
    {
        return 0;
    }

    /* Update internal gamepad state */
    gamepad->hats[hat] = value;

    return 0;
}


int
input_privateGamepadButton(InputGamepad *gamepad, int button, int state)
{
    /* Make sure we're not getting garbage events */
    if (button >= gamepad->nbuttons)
    {
        return 0;
    }

    /* Update internal gamepad state */
    gamepad->buttons[button] = state;

    return 0;
}


void
input_gamepadUpdate(void)
{
    int i;

    if (!_gamepads)
    {
        return;
    }

    for (i = 0; _gamepads[i]; ++i)
    {
        input_sysGamepadUpdate(_gamepads[i]);
    }
}


int
input_gamepadEventState(int state)
{
    return 0;
}
