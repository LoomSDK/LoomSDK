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

#include <SDL.h>

#include "loom/script/loomscript.h"

#define MAX_CONTROLLERS 4

class LoomGameController
{
public:
    LoomGameController();
    static void openAll();
    static void closeAll();
    static int addDevice(int deviceID);
    static int removeDevice(int deviceID);
    static int numDevices();
    static int getControllerIndex(SDL_JoystickID instance);
    static LoomGameController *getGameController(int index);

    bool isHaptic();
    void stopRumble();
    void startRumble(float intensity, Uint32 ms);
    bool getButton(int buttonID);
    int getAxis(int axisID);
    int getID();

    SDL_Haptic *getHaptic();
    SDL_GameController *getController();

private:
    int id;
    SDL_GameController *controller;
    SDL_Haptic *haptic;
    SDL_JoystickID instance_id;
    bool is_haptic;
    bool is_connected;

    static LoomGameController controllers[MAX_CONTROLLERS];

    void open(int deviceID);
    void close();
};