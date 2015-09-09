#include "loom/engine/bindings/loom/lmGameController.h"
#include "loom/common/core/log.h"

GameController GameController::controllers[MAX_CONTROLLERS];

lmDefineLogGroup(controllerLogGroup, "loom.controller", 1, LoomLogInfo);

GameController::GameController() : is_connected(false), gamepad(0), instance_id(-1), haptic(0) {}

void GameController::open(int device)
{
    lmLogInfo(controllerLogGroup, "Opening device [%d]", device);

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
        }
        else
        {
            SDL_HapticClose(haptic);
            haptic = 0;
        }
    }
}

void GameController::close()
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

int GameController::getControllerIndex(SDL_JoystickID instance)
{
    for (int i = 0; i < MAX_CONTROLLERS; ++i)
    {
        if (GameController::controllers[i].is_connected && GameController::controllers[i].instance_id == instance) {
            return i;
        }
    }
    return -1;
}

void GameController::openAll()
{
    lmLogInfo(controllerLogGroup, "Detected %d joysticks", SDL_NumJoysticks());
    int joyIndex = 0;
    for (int i = 0; i < SDL_NumJoysticks() && joyIndex < MAX_CONTROLLERS; i++)
    {
        GameController::controllers[joyIndex++].open(i);
    }
}

void GameController::closeAll()
{
    for (int i = 0; i < MAX_CONTROLLERS; ++i)
    {
        GameController::controllers[i].close();
    }
}

int GameController::addDevice(int device)
{
    if (device < MAX_CONTROLLERS)
    {
        GameController& gc = controllers[device];
        gc.open(device);
        lmLog(controllerLogGroup, "Device [%d] connected", device);
        return device;
    }
    return -1;
}

int GameController::removeDevice(int device)
{
    int controllerIndex = getControllerIndex(device);
    if (controllerIndex < 0) return -1;
    GameController& gc = controllers[controllerIndex];
    gc.close();
    lmLog(controllerLogGroup, "Device [%d] removed", controllerIndex);
    return controllerIndex;
}