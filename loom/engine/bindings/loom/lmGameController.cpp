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

#include "loom/engine/bindings/loom/lmGameController.h"

using namespace LS;

#include "loom/common/core/log.h"

LoomGameController LoomGameController::controllers[MAX_CONTROLLERS];

lmDefineLogGroup(controllerLogGroup, "loom.controller", 1, LoomLogInfo);

LoomGameController::LoomGameController() {
    is_connected = false;
    is_haptic = false;
    gamepad = 0;
    instance_id = -1;
    haptic = 0;
}

void LoomGameController::openAll()
{
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
        return LoomGameController::controllers[device].is_haptic;
    }

    return false;
}

void LoomGameController::stopRumble(int device)
{
    if (LoomGameController::controllers[device].is_haptic)
        SDL_HapticRumbleStop(LoomGameController::controllers[device].getHaptic());
}

void LoomGameController::startRumble(int device, float intensity, Uint32 ms)
{
    if (device < 0 && device >= MAX_CONTROLLERS) return;

    if (intensity > 1) intensity = 1.0f;
    if (intensity < 0) intensity = 0.0f;

    if (LoomGameController::controllers[device].is_haptic)
        SDL_HapticRumblePlay(LoomGameController::controllers[device].getHaptic(), intensity, (ms < 0 ? SDL_HAPTIC_INFINITY : ms));
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
    // lmLogInfo(controllerLogGroup, "Opening device [%d]", device);
    is_haptic = false;

    if (SDL_IsGameController(device))
    {
        gamepad = SDL_GameControllerOpen(device);
        // lmLogInfo(controllerLogGroup, "Device [%d] is a gamepad", device);
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
        // lmLogInfo(controllerLogGroup, "Haptic Effects: %d", SDL_HapticNumEffects(haptic));
        // lmLogInfo(controllerLogGroup, "Haptic Query: %x", SDL_HapticQuery(haptic));
        if (SDL_HapticRumbleSupported(haptic))
        {
            if (SDL_HapticRumbleInit(haptic) != 0)
            {
                // lmLogInfo(controllerLogGroup, "Haptic Rumble Init: %s", SDL_GetError());
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

        .endClass()

        .endPackage();

    return 0;
}


void installLoomGameController()
{
    LOOM_DECLARE_NATIVETYPE(LoomGameController, registerLoomGameController);
}
