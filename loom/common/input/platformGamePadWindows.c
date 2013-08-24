/*
 * Based on
 * Simple DirectMedia Layer
 * Copyright (C) 1997-2012 Sam Lantinga <slouken@libsdl.org>
 */

#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "platformGamePad.h"
#include "platformSysGamePad.h"
#include "platformGamePad_c.h"

#include <stdio.h>
#include <windows.h>

#define INITGUID
#include <InitGuid.h>
#define DIRECTINPUT_VERSION    0x0700   /* Need version 7 for force feedback. */
#include <dinput.h>


#define MAX_INPUTS    256   /* each gamepad can have up to 256 inputs */


/* local types */
typedef enum Type
{
    BUTTON, AXIS, HAT
} Type;

typedef struct input_t
{
    /* DirectInput offset for this input type: */
    DWORD ofs;

    /* Button, axis or hat: */
    Type  type;

    /* SDL input offset: */
    int   num;
} input_t;

/* The private structure used to keep track of a gamepad */
struct gamepad_hwdata
{
    LPDIRECTINPUTDEVICE2 InputDevice;
    DIDEVCAPS            Capabilities;
    int                  buffered;

    input_t              Inputs[MAX_INPUTS];
    int                  NumInputs;
};



#ifndef DIDFT_OPTIONAL
#define DIDFT_OPTIONAL    0x80000000
#endif


#define INPUT_QSIZE           32                              /* Buffer up to 32 input messages */
#define MAX_JOYSTICKS         8
#define AXIS_MIN              -32768                          /* minimum value for axis coordinate */
#define AXIS_MAX              32767                           /* maximum value for axis coordinate */
#define JOY_AXIS_THRESHOLD    (((AXIS_MAX)-(AXIS_MIN)) / 100) /* 1% motion */

/* local variables */
static int           coinitialized = 0;
static LPDIRECTINPUT dinput        = NULL;
extern HRESULT(WINAPI * DInputCreate) (HINSTANCE hinst, DWORD dwVersion,
                                       LPDIRECTINPUT * ppDI,
                                       LPUNKNOWN punkOuter);
static DIDEVICEINSTANCE SYS_Joystick[MAX_JOYSTICKS];    /* array to hold gamepad ID values */
static char             *SYS_JoystickNames[MAX_JOYSTICKS];
static int              SYS_NumJoysticks;
static HINSTANCE        DInputDLL = NULL;

static loom_logGroup_t gamepadLogGroup = { "win32gamepad", 1 };

/* local prototypes */
static void SetDIerror(const char *function, HRESULT code);
static BOOL CALLBACK EnumJoysticksCallback(const DIDEVICEINSTANCE *
                                           pdidInstance, VOID *pContext);
static BOOL CALLBACK EnumDevObjectsCallback(LPCDIDEVICEOBJECTINSTANCE dev,
                                            LPVOID                    pvRef);
static void SortDevObjects(InputGamepad *gamepad);
static int TranslatePOV(DWORD value);
static int input_privateGamepadAxis_Int(InputGamepad *gamepad, int axis,
                                        int value);
static int input_privateGamepadButton_Int(InputGamepad *gamepad,
                                          int button, int state);

static int input_privateGamepadHat_Int(InputGamepad *gamepad, int hat, int value);

/* Taken from Wine - Thanks! */
DIOBJECTDATAFORMAT dfDIJoystick2[] =
{
    { &GUID_XAxis,  DIJOFS_X,                 DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_YAxis,  DIJOFS_Y,                 DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_ZAxis,  DIJOFS_Z,                 DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_RxAxis, DIJOFS_RX,                DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_RyAxis, DIJOFS_RY,                DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_RzAxis, DIJOFS_RZ,                DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_Slider, DIJOFS_SLIDER(0),         DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_Slider, DIJOFS_SLIDER(1),         DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE,   0 },
    { &GUID_POV,    DIJOFS_POV(0),            DIDFT_OPTIONAL | DIDFT_POV | DIDFT_ANYINSTANCE,    0 },
    { &GUID_POV,    DIJOFS_POV(1),            DIDFT_OPTIONAL | DIDFT_POV | DIDFT_ANYINSTANCE,    0 },
    { &GUID_POV,    DIJOFS_POV(2),            DIDFT_OPTIONAL | DIDFT_POV | DIDFT_ANYINSTANCE,    0 },
    { &GUID_POV,    DIJOFS_POV(3),            DIDFT_OPTIONAL | DIDFT_POV | DIDFT_ANYINSTANCE,    0 },
    { NULL,         DIJOFS_BUTTON(0),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(1),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(2),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(3),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(4),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(5),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(6),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(7),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(8),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(9),         DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(10),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(11),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(12),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(13),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(14),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(15),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(16),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(17),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(18),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(19),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(20),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(21),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(22),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(23),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(24),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(25),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(26),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(27),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(28),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(29),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(30),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(31),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(32),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(33),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(34),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(35),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(36),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(37),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(38),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(39),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(40),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(41),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(42),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(43),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(44),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(45),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(46),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(47),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(48),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(49),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(50),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(51),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(52),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(53),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(54),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(55),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(56),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(57),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(58),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(59),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(60),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(61),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(62),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(63),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(64),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(65),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(66),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(67),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(68),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(69),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(70),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(71),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(72),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(73),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(74),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(75),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(76),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(77),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(78),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(79),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(80),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(81),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(82),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(83),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(84),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(85),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(86),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(87),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(88),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(89),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(90),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(91),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(92),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(93),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(94),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(95),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(96),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(97),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(98),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(99),        DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(100),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(101),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(102),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(103),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(104),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(105),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(106),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(107),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(108),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(109),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(110),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(111),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(112),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(113),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(114),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(115),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(116),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(117),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(118),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(119),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(120),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(121),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(122),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(123),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(124),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(125),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(126),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { NULL,         DIJOFS_BUTTON(127),       DIDFT_OPTIONAL | DIDFT_BUTTON | DIDFT_ANYINSTANCE, 0 },
    { &GUID_XAxis,  FIELD_OFFSET(DIJOYSTATE2, lVX),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_YAxis,  FIELD_OFFSET(DIJOYSTATE2, lVY),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_ZAxis,  FIELD_OFFSET(DIJOYSTATE2, lVZ),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RxAxis, FIELD_OFFSET(DIJOYSTATE2, lVRx),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RyAxis, FIELD_OFFSET(DIJOYSTATE2, lVRy),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RzAxis, FIELD_OFFSET(DIJOYSTATE2, lVRz),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_Slider, FIELD_OFFSET(DIJOYSTATE2, rglVSlider[0]),                                    DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_Slider, FIELD_OFFSET(DIJOYSTATE2, rglVSlider[1]),                                    DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_XAxis,  FIELD_OFFSET(DIJOYSTATE2, lAX),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_YAxis,  FIELD_OFFSET(DIJOYSTATE2, lAY),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_ZAxis,  FIELD_OFFSET(DIJOYSTATE2, lAZ),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RxAxis, FIELD_OFFSET(DIJOYSTATE2, lARx),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RyAxis, FIELD_OFFSET(DIJOYSTATE2, lARy),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RzAxis, FIELD_OFFSET(DIJOYSTATE2, lARz),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_Slider, FIELD_OFFSET(DIJOYSTATE2, rglASlider[0]),                                    DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_Slider, FIELD_OFFSET(DIJOYSTATE2, rglASlider[1]),                                    DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_XAxis,  FIELD_OFFSET(DIJOYSTATE2, lFX),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_YAxis,  FIELD_OFFSET(DIJOYSTATE2, lFY),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_ZAxis,  FIELD_OFFSET(DIJOYSTATE2, lFZ),                                              DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RxAxis, FIELD_OFFSET(DIJOYSTATE2, lFRx),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RyAxis, FIELD_OFFSET(DIJOYSTATE2, lFRy),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_RzAxis, FIELD_OFFSET(DIJOYSTATE2, lFRz),                                             DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_Slider, FIELD_OFFSET(DIJOYSTATE2, rglFSlider[0]),                                    DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
    { &GUID_Slider, FIELD_OFFSET(DIJOYSTATE2, rglFSlider[1]),                                    DIDFT_OPTIONAL | DIDFT_AXIS | DIDFT_ANYINSTANCE, 0},
};

#define _arraysize(array)    (sizeof(array) / sizeof(array[0]))

const DIDATAFORMAT c_dfDIJoystick2 =
{
    sizeof(DIDATAFORMAT),
    sizeof(DIOBJECTDATAFORMAT),
    DIDF_ABSAXIS,
    sizeof(DIJOYSTATE2),
    _arraysize(dfDIJoystick2),
    dfDIJoystick2
};

HRESULT
WIN_CoInitialize(void)
{
    const HRESULT hr = CoInitialize(NULL);

    /* S_FALSE means success, but someone else already initialized. */
    /* You still need to call CoUninitialize in this case! */
    if (hr == S_FALSE)
    {
        return S_OK;
    }

    return hr;
}


void
WIN_CoUninitialize(void)
{
    CoUninitialize();
}


/* Convert a DirectInput return code to a text message */
static void
SetDIerror(const char *function, HRESULT code)
{
    lmLog(gamepadLogGroup, "%s() DirectX error %d", function, code);
}


/* Function to scan the system for gamepads.
 * This function should set SDL_numgamepads to the number of available
 * gamepads.  Joystick 0 should be the system default gamepad.
 * It should return 0, or -1 on an unrecoverable fatal error.
 */
int
input_sysGamepadInit(void)
{
    HRESULT   result;
    HINSTANCE instance;

    SYS_NumJoysticks = 0;

    result = WIN_CoInitialize();
    if (FAILED(result))
    {
        SetDIerror("CoInitialize", result);
        return(-1);
    }

    coinitialized = 1;

    result = CoCreateInstance(&CLSID_DirectInput, NULL, CLSCTX_INPROC_SERVER,
                              &IID_IDirectInput, (LPVOID)&dinput);

    if (FAILED(result))
    {
        input_sysGamepadQuit();
        SetDIerror("CoCreateInstance", result);
        return(-1);
    }

    /* Because we used CoCreateInstance, we need to Initialize it, first. */
    instance = GetModuleHandle(NULL);
    if (instance == NULL)
    {
        input_sysGamepadQuit();
        lmLog(gamepadLogGroup, "GetModuleHandle() failed with error code %d.", GetLastError());
        return(-1);
    }
    result = IDirectInput_Initialize(dinput, instance, DIRECTINPUT_VERSION);

    if (FAILED(result))
    {
        input_sysGamepadQuit();
        SetDIerror("IDirectInput::Initialize", result);
        return(-1);
    }

    /* Look for gamepads, wheels, head trackers, gamepads, etc.. */
    result = IDirectInput_EnumDevices(dinput,
                                      DIDEVTYPE_JOYSTICK,
                                      EnumJoysticksCallback,
                                      NULL, DIEDFL_ATTACHEDONLY);

    return SYS_NumJoysticks;
}


static BOOL CALLBACK
EnumJoysticksCallback(const DIDEVICEINSTANCE *pdidInstance, VOID *pContext)
{
    memcpy(&SYS_Joystick[SYS_NumJoysticks], pdidInstance,
           sizeof(DIDEVICEINSTANCE));
    SYS_JoystickNames[SYS_NumJoysticks] = _strdup(pdidInstance->tszProductName);
    SYS_NumJoysticks++;

    if (SYS_NumJoysticks >= MAX_JOYSTICKS)
    {
        return DIENUM_STOP;
    }

    return DIENUM_CONTINUE;
}


/* Function to get the device-dependent name of a gamepad */
const char *
input_sysGamepadName(int index)
{
    return SYS_JoystickNames[index];
}


/* Function to open a gamepad for use.
 * The gamepad to open is specified by the index field of the gamepad.
 * This should fill the nbuttons and naxes fields of the gamepad structure.
 * It returns 0, or -1 if there is an error.
 */
int
input_sysGamepadOpen(InputGamepad *gamepad)
{
    HRESULT             result;
    LPDIRECTINPUTDEVICE device;
    DIPROPDWORD         dipdw;

    memset(&dipdw, 0, sizeof(DIPROPDWORD));
    dipdw.diph.dwSize       = sizeof(DIPROPDWORD);
    dipdw.diph.dwHeaderSize = sizeof(DIPROPHEADER);


    /* allocate memory for system specific hardware data */
    gamepad->hwdata =
        (struct gamepad_hwdata *)malloc(sizeof(struct gamepad_hwdata));
    if (gamepad->hwdata == NULL)
    {
        lmAssert(0, "Out of memory");
        return(-1);
    }
    memset(gamepad->hwdata, 0, sizeof(struct gamepad_hwdata));
    gamepad->hwdata->buffered            = 1;
    gamepad->hwdata->Capabilities.dwSize = sizeof(DIDEVCAPS);

    result =
        IDirectInput_CreateDevice(dinput,
                                  &SYS_Joystick[gamepad->index].
                                     guidInstance, &device, NULL);
    if (FAILED(result))
    {
        SetDIerror("IDirectInput::CreateDevice", result);
        return(-1);
    }

    /* Now get the IDirectInputDevice2 interface, instead. */
    result = IDirectInputDevice_QueryInterface(device,
                                               &IID_IDirectInputDevice2,
                                               (LPVOID *)&gamepad->
                                                  hwdata->InputDevice);
    /* We are done with this object.  Use the stored one from now on. */
    IDirectInputDevice_Release(device);

    if (FAILED(result))
    {
        SetDIerror("IDirectInputDevice::QueryInterface", result);
        return(-1);
    }

    /* Aquire shared access. Exclusive access is required for forces,
     * though. */
    result = IDirectInputDevice2_SetCooperativeLevel(gamepad->hwdata->
                                                        InputDevice, NULL /*SDL_HelperWindow*/,
                                                     DISCL_NONEXCLUSIVE /*DISCL_EXCLUSIVE*/ |
                                                     DISCL_BACKGROUND);
    if (FAILED(result))
    {
        SetDIerror("IDirectInputDevice2::SetCooperativeLevel", result);
        return(-1);
    }

    /* Use the extended data structure: DIJOYSTATE2. */
    result =
        IDirectInputDevice2_SetDataFormat(gamepad->hwdata->InputDevice,
                                          &c_dfDIJoystick2);
    if (FAILED(result))
    {
        SetDIerror("IDirectInputDevice2::SetDataFormat", result);
        return(-1);
    }

    /* Get device capabilities */
    result =
        IDirectInputDevice2_GetCapabilities(gamepad->hwdata->InputDevice,
                                            &gamepad->hwdata->Capabilities);

    if (FAILED(result))
    {
        SetDIerror("IDirectInputDevice2::GetCapabilities", result);
        return(-1);
    }

    /* Force capable? */
    if (gamepad->hwdata->Capabilities.dwFlags & DIDC_FORCEFEEDBACK)
    {
        result = IDirectInputDevice2_Acquire(gamepad->hwdata->InputDevice);

        if (FAILED(result))
        {
            SetDIerror("IDirectInputDevice2::Acquire", result);
            return(-1);
        }

        /* reset all accuators. */
        result =
            IDirectInputDevice2_SendForceFeedbackCommand(gamepad->hwdata->
                                                            InputDevice,
                                                         DISFFC_RESET);

        /* Not necessarily supported, ignore if not supported.
         * if (FAILED(result)) {
         *  SetDIerror("IDirectInputDevice2::SendForceFeedbackCommand",
         *             result);
         *  return (-1);
         * }
         */

        result = IDirectInputDevice2_Unacquire(gamepad->hwdata->InputDevice);

        if (FAILED(result))
        {
            SetDIerror("IDirectInputDevice2::Unacquire", result);
            return(-1);
        }

        /* Turn on auto-centering for a ForceFeedback device (until told
         * otherwise). */
        dipdw.diph.dwObj = 0;
        dipdw.diph.dwHow = DIPH_DEVICE;
        dipdw.dwData     = DIPROPAUTOCENTER_ON;

        result =
            IDirectInputDevice2_SetProperty(gamepad->hwdata->InputDevice,
                                            DIPROP_AUTOCENTER, &dipdw.diph);

        /* Not necessarily supported, ignore if not supported.
         * if (FAILED(result)) {
         *  SetDIerror("IDirectInputDevice2::SetProperty", result);
         *  return (-1);
         * }
         */
    }

    /* What buttons and axes does it have? */
    IDirectInputDevice2_EnumObjects(gamepad->hwdata->InputDevice,
                                    EnumDevObjectsCallback, gamepad,
                                    DIDFT_BUTTON | DIDFT_AXIS | DIDFT_POV);

    /* Reorder the input objects. Some devices do not report the X axis as
     * the first axis, for example. */
    SortDevObjects(gamepad);

    dipdw.diph.dwObj = 0;
    dipdw.diph.dwHow = DIPH_DEVICE;
    dipdw.dwData     = INPUT_QSIZE;

    /* Set the buffer size */
    result =
        IDirectInputDevice2_SetProperty(gamepad->hwdata->InputDevice,
                                        DIPROP_BUFFERSIZE, &dipdw.diph);

    if (result == DI_POLLEDDEVICE)
    {
        /* This device doesn't support buffering, so we're forced
         * to use less reliable polling. */
        gamepad->hwdata->buffered = 0;
    }
    else if (FAILED(result))
    {
        SetDIerror("IDirectInputDevice2::SetProperty", result);
        return(-1);
    }

    return(0);
}


/* Sort using the data offset into the DInput struct.
* This gives a reasonable ordering for the inputs. */
static int
SortDevFunc(const void *a, const void *b)
{
    const input_t *inputA = (const input_t *)a;
    const input_t *inputB = (const input_t *)b;

    if (inputA->ofs < inputB->ofs)
    {
        return -1;
    }
    if (inputA->ofs > inputB->ofs)
    {
        return 1;
    }
    return 0;
}


/* Sort the input objects and recalculate the indices for each input. */
static void
SortDevObjects(InputGamepad *gamepad)
{
    input_t *inputs  = gamepad->hwdata->Inputs;
    int     nButtons = 0;
    int     nHats    = 0;
    int     nAxis    = 0;
    int     n;

    qsort(inputs, gamepad->hwdata->NumInputs, sizeof(input_t), SortDevFunc);

    for (n = 0; n < gamepad->hwdata->NumInputs; n++)
    {
        switch (inputs[n].type)
        {
        case BUTTON:
            inputs[n].num = nButtons;
            nButtons++;
            break;

        case HAT:
            inputs[n].num = nHats;
            nHats++;
            break;

        case AXIS:
            inputs[n].num = nAxis;
            nAxis++;
            break;
        }
    }
}


static BOOL CALLBACK
EnumDevObjectsCallback(LPCDIDEVICEOBJECTINSTANCE dev, LPVOID pvRef)
{
    InputGamepad *gamepad = (InputGamepad *)pvRef;
    HRESULT      result;
    input_t      *in = &gamepad->hwdata->Inputs[gamepad->hwdata->NumInputs];

    in->ofs = dev->dwOfs;

    if (dev->dwType & DIDFT_BUTTON)
    {
        in->type = BUTTON;
        in->num  = gamepad->nbuttons;
        gamepad->nbuttons++;
    }
    else if (dev->dwType & DIDFT_POV)
    {
        in->type = HAT;
        in->num  = gamepad->nhats;
        gamepad->nhats++;
    }
    else if (dev->dwType & DIDFT_AXIS)
    {
        DIPROPRANGE diprg;
        DIPROPDWORD dilong;

        in->type = AXIS;
        in->num  = gamepad->naxes;

        diprg.diph.dwSize       = sizeof(diprg);
        diprg.diph.dwHeaderSize = sizeof(diprg.diph);
        diprg.diph.dwObj        = dev->dwOfs;
        diprg.diph.dwHow        = DIPH_BYOFFSET;
        diprg.lMin = AXIS_MIN;
        diprg.lMax = AXIS_MAX;

        result =
            IDirectInputDevice2_SetProperty(gamepad->hwdata->InputDevice,
                                            DIPROP_RANGE, &diprg.diph);
        if (FAILED(result))
        {
            return DIENUM_CONTINUE;     /* don't use this axis */
        }

        /* Set dead zone to 0. */
        dilong.diph.dwSize       = sizeof(dilong);
        dilong.diph.dwHeaderSize = sizeof(dilong.diph);
        dilong.diph.dwObj        = dev->dwOfs;
        dilong.diph.dwHow        = DIPH_BYOFFSET;
        dilong.dwData            = 0;
        result =
            IDirectInputDevice2_SetProperty(gamepad->hwdata->InputDevice,
                                            DIPROP_DEADZONE, &dilong.diph);
        if (FAILED(result))
        {
            return DIENUM_CONTINUE;     /* don't use this axis */
        }

        gamepad->naxes++;
    }
    else
    {
        /* not supported at this time */
        return DIENUM_CONTINUE;
    }

    gamepad->hwdata->NumInputs++;

    if (gamepad->hwdata->NumInputs == MAX_INPUTS)
    {
        return DIENUM_STOP;     /* too many */
    }

    return DIENUM_CONTINUE;
}


static int
TranslatePOV(DWORD value)
{
    const int HAT_VALS[] =
    {
        GAMEPAD_HAT_UP,
        GAMEPAD_HAT_UP | GAMEPAD_HAT_RIGHT,
        GAMEPAD_HAT_RIGHT,
        GAMEPAD_HAT_DOWN | GAMEPAD_HAT_RIGHT,
        GAMEPAD_HAT_DOWN,
        GAMEPAD_HAT_DOWN | GAMEPAD_HAT_LEFT,
        GAMEPAD_HAT_LEFT,
        GAMEPAD_HAT_UP | GAMEPAD_HAT_LEFT
    };

    if (LOWORD(value) == 0xFFFF)
    {
        return GAMEPAD_HAT_CENTERED;
    }

    /* Round the value up: */
    value += 4500 / 2;
    value %= 36000;
    value /= 4500;

    if (value >= 8)
    {
        return GAMEPAD_HAT_CENTERED;        /* shouldn't happen */
    }
    return HAT_VALS[value];
}


/* Function to update the state of a gamepad - called as a device poll.
 * This function shouldn't update the gamepad structure directly,
 * but instead should call input_privateGamepad*() to deliver events
 * and update gamepad device state.
 */
void
input_sysGamepad_Polled(InputGamepad *gamepad)
{
    DIJOYSTATE2 state;
    HRESULT     result;
    int         i;

    result =
        IDirectInputDevice2_GetDeviceState(gamepad->hwdata->InputDevice,
                                           sizeof(DIJOYSTATE2), &state);
    if ((result == DIERR_INPUTLOST) || (result == DIERR_NOTACQUIRED))
    {
        IDirectInputDevice2_Acquire(gamepad->hwdata->InputDevice);
        result =
            IDirectInputDevice2_GetDeviceState(gamepad->hwdata->InputDevice,
                                               sizeof(DIJOYSTATE2), &state);
    }

    /* Set each known axis, button and POV. */
    for (i = 0; i < gamepad->hwdata->NumInputs; ++i)
    {
        const input_t *in = &gamepad->hwdata->Inputs[i];

        switch (in->type)
        {
        case AXIS:
            switch (in->ofs)
            {
            case DIJOFS_X:
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.lX);
                break;

            case DIJOFS_Y:
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.lY);
                break;

            case DIJOFS_Z:
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.lZ);
                break;

            case DIJOFS_RX:
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.lRx);
                break;

            case DIJOFS_RY:
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.lRy);
                break;

            case DIJOFS_RZ:
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.lRz);
                break;

            case DIJOFS_SLIDER(0):
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.rglSlider[0]);
                break;

            case DIJOFS_SLIDER(1):
                input_privateGamepadAxis_Int(gamepad, in->num,
                                             (int)state.rglSlider[1]);
                break;
            }

            break;

        case BUTTON:
            input_privateGamepadButton_Int(gamepad, in->num,
                                           (int)(state.
                                                    rgbButtons[in->ofs -
                                                               DIJOFS_BUTTON0]
                                                 ? GAMEPAD_BUTTON_PRESSED :
                                                 GAMEPAD_BUTTON_RELEASED));
            break;

        case HAT:
           {
               int pos = TranslatePOV(state.rgdwPOV[in->ofs -
                                                    DIJOFS_POV(0)]);
               input_privateGamepadHat_Int(gamepad, in->num, pos);
               break;
           }
        }
    }
}


void
input_sysGamepad_Buffered(InputGamepad *gamepad)
{
    int                i;
    HRESULT            result;
    DWORD              numevents;
    DIDEVICEOBJECTDATA evtbuf[INPUT_QSIZE];

    numevents = INPUT_QSIZE;
    result    =
        IDirectInputDevice2_GetDeviceData(gamepad->hwdata->InputDevice,
                                          sizeof(DIDEVICEOBJECTDATA), evtbuf,
                                          &numevents, 0);
    if ((result == DIERR_INPUTLOST) || (result == DIERR_NOTACQUIRED))
    {
        IDirectInputDevice2_Acquire(gamepad->hwdata->InputDevice);
        result =
            IDirectInputDevice2_GetDeviceData(gamepad->hwdata->InputDevice,
                                              sizeof(DIDEVICEOBJECTDATA),
                                              evtbuf, &numevents, 0);
    }

    /* Handle the events or punt */
    if (FAILED(result))
    {
        return;
    }

    for (i = 0; i < (int)numevents; ++i)
    {
        int j;

        for (j = 0; j < gamepad->hwdata->NumInputs; ++j)
        {
            const input_t *in = &gamepad->hwdata->Inputs[j];

            if (evtbuf[i].dwOfs != in->ofs)
            {
                continue;
            }

            switch (in->type)
            {
            case AXIS:
                input_privateGamepadAxis(gamepad, in->num,
                                         (int)evtbuf[i].dwData);
                break;

            case BUTTON:
                input_privateGamepadButton(gamepad, in->num,
                                           (int)(evtbuf[i].
                                                    dwData ? GAMEPAD_BUTTON_PRESSED :
                                                 GAMEPAD_BUTTON_RELEASED));
                break;

            case HAT:
               {
                   int pos = TranslatePOV(evtbuf[i].dwData);
                   input_privateGamepadHat(gamepad, in->num, pos);
               }
            }
        }
    }
}


/* input_privateGamepad* doesn't discard duplicate events, so we need to
 * do it. */
static int
input_privateGamepadAxis_Int(InputGamepad *gamepad, int axis, int value)
{
    if (gamepad->axes[axis] != value)
    {
        return input_privateGamepadAxis(gamepad, axis, value);
    }
    return 0;
}


static int
input_privateGamepadButton_Int(InputGamepad *gamepad, int button,
                               int state)
{
    if (gamepad->buttons[button] != state)
    {
        return input_privateGamepadButton(gamepad, button, state);
    }
    return 0;
}


static int
input_privateGamepadHat_Int(InputGamepad *gamepad, int hat, int value)
{
    if (gamepad->hats[hat] != value)
    {
        return input_privateGamepadHat(gamepad, hat, value);
    }
    return 0;
}


void
input_sysGamepadUpdate(InputGamepad *gamepad)
{
    HRESULT result;

    result = IDirectInputDevice2_Poll(gamepad->hwdata->InputDevice);
    if ((result == DIERR_INPUTLOST) || (result == DIERR_NOTACQUIRED))
    {
        IDirectInputDevice2_Acquire(gamepad->hwdata->InputDevice);
        IDirectInputDevice2_Poll(gamepad->hwdata->InputDevice);
    }

    if (gamepad->hwdata->buffered)
    {
        input_sysGamepad_Buffered(gamepad);
    }
    else
    {
        input_sysGamepad_Polled(gamepad);
    }
}


/* Function to close a gamepad after use */
void
input_sysGamepadClose(InputGamepad *gamepad)
{
    IDirectInputDevice2_Unacquire(gamepad->hwdata->InputDevice);
    IDirectInputDevice2_Release(gamepad->hwdata->InputDevice);

    if (gamepad->hwdata != NULL)
    {
        /* free system specific hardware data */
        free(gamepad->hwdata);
    }
}


/* Function to perform any system-specific gamepad related cleanup */
void
input_sysGamepadQuit(void)
{
    int i;

    for (i = 0; i < _arraysize(SYS_JoystickNames); ++i)
    {
        if (SYS_JoystickNames[i])
        {
            free(SYS_JoystickNames[i]);
            SYS_JoystickNames[i] = NULL;
        }
    }

    if (dinput != NULL)
    {
        IDirectInput_Release(dinput);
        dinput = NULL;
    }

    if (coinitialized)
    {
        WIN_CoUninitialize();
        coinitialized = 0;
    }
}
