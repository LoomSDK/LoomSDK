#include "loom/engine/bindings/loom/lmGameController.h"
#include "loom/common/core/log.h"

GameController GameController::controllers[MAX_CONTROLLERS];

lmDefineLogGroup(controllerLogGroup, "loom.controller", 1, LoomLogInfo);

GameController::GameController() : is_connected(false), gamepad(0), instance_id(-1), haptic(0) {}

void GameController::open(int device)
{
    lmLogInfo(controllerLogGroup, "Opened joystick [%d]", device);
    gamepad = SDL_JoystickOpen(device);
    instance_id = SDL_JoystickInstanceID(gamepad);
    is_connected = true;

    if (SDL_JoystickIsHaptic(gamepad))
    {
        haptic = SDL_HapticOpenFromJoystick(gamepad);
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
        SDL_JoystickClose(gamepad);
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
    for (int i = 0; i < SDL_NumJoysticks() && i < MAX_CONTROLLERS; i++)
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