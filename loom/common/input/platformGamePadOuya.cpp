#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformAndroidJni.h"
#include "platformGamePad.h"
#include "platformSysGamePad.h"
#include "platformGamePad_c.h"

#include <stdio.h>

// Ouya gamepad device

// If these change in the OUYA SDK they must be changed here as well!
#define OUYA_AXIS_L2              17
#define OUYA_AXIS_LS_X            0
#define OUYA_AXIS_LS_Y            1
#define OUYA_AXIS_R2              18
#define OUYA_AXIS_RS_X            11
#define OUYA_AXIS_RS_Y            14
#define OUYA_BUTTON_A             97
#define OUYA_BUTTON_DPAD_DOWN     20
#define OUYA_BUTTON_DPAD_LEFT     21
#define OUYA_BUTTON_DPAD_RIGHT    22
#define OUYA_BUTTON_DPAD_UP       19
#define OUYA_BUTTON_L1            102
#define OUYA_BUTTON_L2            104
#define OUYA_BUTTON_L3            106
#define OUYA_BUTTON_O             96
#define OUYA_BUTTON_R1            103
#define OUYA_BUTTON_R2            105
#define OUYA_BUTTON_R3            107
#define OUYA_BUTTON_SYSTEM        3
#define OUYA_BUTTON_U             99
#define OUYA_BUTTON_Y             100
#define OUYA_MAX_CONTROLLERS      4

static loom_logGroup_t ouyaLogGroup = { "ouya", 1 };

static int SYS_NumJoysticks = 0;

class OuyaControllerBinder
{
public:

    static loomJniMethodInfo _getControllerAxisValue;
    static loomJniMethodInfo _getControllerButton;

    static float getControllerAxisValue(int playerNum, int axis)
    {
        jfloat jvalue = (jfloat)_getControllerAxisValue.env->CallStaticFloatMethod(_getControllerAxisValue.classID,
                                                                                   _getControllerAxisValue.methodID,
                                                                                   playerNum, axis);

        return jvalue;
    }

    static bool getControllerButton(int playerNum, int button)
    {
        jboolean jvalue = (jboolean)_getControllerButton.env->CallStaticBooleanMethod(_getControllerButton.classID,
                                                                                      _getControllerButton.methodID,
                                                                                      playerNum, button);

        return jvalue;
    }

    static bool initBinderMethod(loomJniMethodInfo& methodInfo, const char *name, const char *sig)
    {
        bool result = LoomJni::getStaticMethodInfo(methodInfo,
                                                   "co/theengine/loomdemo/OuyaControllerBinder",
                                                   name,
                                                   sig);

        if (!result)
        {
            lmLog(ouyaLogGroup, "Error: unable to get method %s:%s", name, sig);
        }

        return result;
    }

    static bool initialize()
    {
        if (!initBinderMethod(_getControllerAxisValue,
                              "getControllerAxisValue",
                              "(II)F"))
        {
            return false;
        }

        if (!initBinderMethod(_getControllerButton,
                              "getControllerButton",
                              "(II)Z"))
        {
            return false;
        }


        return true;
    }
};

loomJniMethodInfo OuyaControllerBinder::_getControllerAxisValue;
loomJniMethodInfo OuyaControllerBinder::_getControllerButton;

/* The private structure used to keep track of a gamepad */
struct gamepad_hwdata
{
    int playerNum;
};

extern "C"
{
void input_sysGamepadUpdate(InputGamepad *gamepad)
{
    if (!SYS_NumJoysticks)
    {
        return;
    }

    gamepad_hwdata *gdata = (gamepad_hwdata *)gamepad->hwdata;

    input_privateGamepadAxis(gamepad, 0, OuyaControllerBinder::getControllerAxisValue(gdata->playerNum, OUYA_AXIS_LS_X) * 32768);
    input_privateGamepadAxis(gamepad, 1, OuyaControllerBinder::getControllerAxisValue(gdata->playerNum, OUYA_AXIS_LS_Y) * 32768);
    input_privateGamepadAxis(gamepad, 2, OuyaControllerBinder::getControllerAxisValue(gdata->playerNum, OUYA_AXIS_RS_X) * 32768);
    input_privateGamepadAxis(gamepad, 3, OuyaControllerBinder::getControllerAxisValue(gdata->playerNum, OUYA_AXIS_RS_Y) * 32768);
    input_privateGamepadAxis(gamepad, 4, OuyaControllerBinder::getControllerAxisValue(gdata->playerNum, OUYA_AXIS_L2) * 32768);
    input_privateGamepadAxis(gamepad, 5, OuyaControllerBinder::getControllerAxisValue(gdata->playerNum, OUYA_AXIS_R2) * 32768);

    input_privateGamepadButton(gamepad, 0, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_O) ? 1 : 0);
    input_privateGamepadButton(gamepad, 1, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_U) ? 1 : 0);
    input_privateGamepadButton(gamepad, 2, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_Y) ? 1 : 0);
    input_privateGamepadButton(gamepad, 3, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_A) ? 1 : 0);
    input_privateGamepadButton(gamepad, 4, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_L1) ? 1 : 0);
    input_privateGamepadButton(gamepad, 5, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_R1) ? 1 : 0);
    input_privateGamepadButton(gamepad, 6, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_L2) ? 1 : 0);
    input_privateGamepadButton(gamepad, 7, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_R2) ? 1 : 0);
    input_privateGamepadButton(gamepad, 8, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_L3) ? 1 : 0);
    input_privateGamepadButton(gamepad, 9, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_R3) ? 1 : 0);
    input_privateGamepadButton(gamepad, 10, OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_SYSTEM) ? 1 : 0);

    bool down  = OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_DPAD_DOWN);
    bool left  = OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_DPAD_LEFT);
    bool right = OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_DPAD_RIGHT);
    bool up    = OuyaControllerBinder::getControllerButton(gdata->playerNum, OUYA_BUTTON_DPAD_UP);

    int hat = GAMEPAD_HAT_CENTERED;
    if (down)
    {
        hat = GAMEPAD_HAT_DOWN;
        if (left)
        {
            hat = GAMEPAD_HAT_LEFTDOWN;
        }
        if (right)
        {
            hat = GAMEPAD_HAT_RIGHTDOWN;
        }
    }
    else if (up)
    {
        hat = GAMEPAD_HAT_UP;
        if (left)
        {
            hat = GAMEPAD_HAT_LEFTUP;
        }
        if (right)
        {
            hat = GAMEPAD_HAT_RIGHTUP;
        }
    }
    else if (left)
    {
        hat = GAMEPAD_HAT_LEFT;
    }
    else if (right)
    {
        hat = GAMEPAD_HAT_RIGHT;
    }

    input_privateGamepadHat(gamepad, 0, hat);
}


/* Function to close a gamepad after use */
void input_sysGamepadClose(InputGamepad *gamepad)
{
}


/* Function to get the device-dependent name of a gamepad */
const char *input_sysGamepadName(int index)
{
    return "Ouya Controller";
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
    gamepad->hwdata = (struct gamepad_hwdata *)malloc(sizeof(struct gamepad_hwdata));

    if (gamepad->hwdata == NULL)
    {
        lmAssert(0, "Out of memory");
        return(-1);
    }

    memset(gamepad->hwdata, 0, sizeof(struct gamepad_hwdata));

    // controller I am testing with appears to be player 2
    gamepad->hwdata->playerNum = gamepad->index;

    gamepad->nbuttons = 11;
    gamepad->naxes    = 6;
    gamepad->nhats    = 1;

    return 0;
}


/* Function to scan the system for gamepads.
 * This function should set SDL_numgamepads to the number of available
 * gamepads.  Joystick 0 should be the system default gamepad.
 * It should return 0, or -1 on an unrecoverable fatal error.
 */
int input_sysGamepadInit(void)
{
    SYS_NumJoysticks = 0;

    // if we can't iniitialize the ouya binder,
    // we are either not running under the ouya build
    // or there was a problem, either way report
    // no gamepads
    if (!OuyaControllerBinder::initialize())
    {
        return 0;
    }

    // ouya supports 4 controllers
    SYS_NumJoysticks = 4;
    return SYS_NumJoysticks;
}
}
