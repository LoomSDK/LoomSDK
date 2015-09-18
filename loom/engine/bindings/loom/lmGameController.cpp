#include "loom/engine/bindings/loom/lmGameController.h"

using namespace LS;

#include "loom/common/core/log.h"

LoomGameController LoomGameController::controllers[MAX_CONTROLLERS];

lmDefineLogGroup(controllerLogGroup, "loom.controller", 1, LoomLogInfo);

LoomGameController::LoomGameController() : is_connected(false), is_haptic(false), gamepad(0), instance_id(-1), haptic(0) {}

void LoomGameController::openAll()
{
    lmLogInfo(controllerLogGroup, "Detected %d joysticks", SDL_NumJoysticks());
    int joyIndex = 0;
    for (int i = 0; i < SDL_NumJoysticks() && joyIndex < MAX_CONTROLLERS; i++)
    {
        LoomGameController::controllers[joyIndex++].open(i);
    }
}

void LoomGameController::closeAll()
{
    for (int i = 0; i < MAX_CONTROLLERS; ++i)
    {
        LoomGameController::controllers[i].close();
    }
}

int LoomGameController::addDevice(int device)
{
    if (device < MAX_CONTROLLERS)
    {
        LoomGameController& gc = controllers[device];
        gc.open(device);
        lmLog(controllerLogGroup, "Device [%d] connected", device);
        return device;
    }
    return -1;
}

int LoomGameController::removeDevice(int device)
{
    int controllerIndex = getControllerIndex(device);
    if (controllerIndex < 0) return -1;
    LoomGameController& gc = controllers[controllerIndex];
    gc.close();
    lmLog(controllerLogGroup, "Device [%d] removed", controllerIndex);
    return controllerIndex;
}

int LoomGameController::numDevices()
{
    int devices = 0;
    for (int i = 0; i < MAX_CONTROLLERS; i++)
    {
        if (LoomGameController::controllers[i].is_connected)
            ++devices;
    }
    return devices;
}

int LoomGameController::indexOfDevice(int device)
{
    return getControllerIndex(device);
}

bool LoomGameController::isHaptic(int device)
{
    if (device >= 0 && device < MAX_CONTROLLERS) {
        /*for (int i = 0; i < MAX_CONTROLLERS; i++) {
            if (i == device)
        }*/
        return LoomGameController::controllers[device].is_haptic;
    }

    return false;
}

void LoomGameController::stopRumble(int device)
{
    //for (int i = 0; i < MAX_CONTROLLERS; i++)
    //{
        if (LoomGameController::controllers[device].is_haptic)
            SDL_HapticRumbleStop(LoomGameController::controllers[device].getHaptic());
    //}
}

void LoomGameController::startRumble(int device, float intensity, Uint32 ms)
{
    if (device < 0 && device >= MAX_CONTROLLERS) return;

    if (intensity > 1) intensity = 1.0f;
    if (intensity < 0) intensity = 0.0f;

    //for (int i = 0; i < MAX_CONTROLLERS; i++)
    //{
        if (LoomGameController::controllers[device].is_haptic)
            SDL_HapticRumblePlay(LoomGameController::controllers[device].getHaptic(), intensity, (ms < 0 ? SDL_HAPTIC_INFINITY : ms));
    //}
}

SDL_Haptic *LoomGameController::getHaptic()
{
    return haptic;
}

int LoomGameController::getControllerIndex(SDL_JoystickID instance)
{
    for (int i = 0; i < MAX_CONTROLLERS; ++i)
    {
        if (LoomGameController::controllers[i].is_connected && LoomGameController::controllers[i].instance_id == instance) {
            return i;
        }
    }
    return -1;
}

void LoomGameController::open(int device)
{
    lmLogInfo(controllerLogGroup, "Opening device [%d]", device);
    is_haptic = false;

    // OUTPUT GUID OF DEVICE FOR TESTING //
    SDL_Joystick *joy = SDL_JoystickOpen(device);
    SDL_JoystickGUID guid = SDL_JoystickGetGUID(joy);
    char guid_str[1024];
    SDL_JoystickGetGUIDString(guid, guid_str, sizeof(guid_str));
    lmLogInfo(controllerLogGroup, "Device GUID: %s", guid_str);
    SDL_JoystickClose(joy);
    ///////////////////////////////////////

    if (SDL_IsGameController(device))
    {
        gamepad = SDL_GameControllerOpen(device);
        lmLogInfo(controllerLogGroup, "Device [%d] is a gamepad", device);
    }
    else
    {
        return;
    }

    gamepad = SDL_GameControllerOpen(device);

    SDL_Joystick *joystick = SDL_GameControllerGetJoystick(gamepad);
    instance_id = SDL_JoystickInstanceID(joystick);
    is_connected = true;

    if (SDL_JoystickIsHaptic(joystick))
    {
        haptic = SDL_HapticOpenFromJoystick(joystick);
        lmLogInfo(controllerLogGroup, "Haptic Effects: %d", SDL_HapticNumEffects(haptic));
        lmLogInfo(controllerLogGroup, "Haptic Query: %x", SDL_HapticQuery(haptic));
        if (SDL_HapticRumbleSupported(haptic))
        {
            if (SDL_HapticRumbleInit(haptic) != 0)
            {
                lmLogInfo(controllerLogGroup, "Haptic Rumble Init: %s", SDL_GetError());
                SDL_HapticClose(haptic);
                haptic = 0;
            }
            else
            {
                is_haptic = true;
            }
        }
        else
        {
            SDL_HapticClose(haptic);
            haptic = 0;
        }
    }
}

void LoomGameController::close()
{
    if (is_connected) {
        is_connected = false;
        if (haptic) {
            SDL_HapticClose(haptic);
            haptic = 0;
        }
        //SDL_JoystickClose(joystick);
        SDL_GameControllerClose(gamepad);
        gamepad = 0;
    }
}

int registerLoomGameController(lua_State *L)
{
    beginPackage(L, "loom.platform")

        .beginClass<LoomGameController>("GameController")

        .addStaticMethod("numDevices", &LoomGameController::numDevices)
        .addStaticMethod("isHaptic", &LoomGameController::isHaptic)
        .addStaticMethod("stopRumble", &LoomGameController::stopRumble)
        .addStaticMethod("startRumble", &LoomGameController::startRumble)

        //.addStaticProperty("assetCommandDelegate", &LoomGameController::getAssetCommandDelegate)

        .endClass()

        .endPackage();

    return 0;
}


void installLoomGameController()
{
    LOOM_DECLARE_NATIVETYPE(LoomGameController, registerLoomGameController);
}
