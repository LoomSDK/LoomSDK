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

#include <math.h>
#include "loom/script/loomscript.h"
#include "loom/common/input/platformGamePad.h"

using namespace LS;

class Gamepad
{
public:

    InputGamepad *gamepad;

    int numAxis;
    int numButtons;
    int numHats;

    static utHashTable<utPointerHashKey, Gamepad *> openGamePads;

    Gamepad()
    {
        gamepad    = NULL;
        numAxis    = 0;
        numButtons = 0;
        numHats    = 0;
    }

    ~Gamepad()
    {
        LS::lualoom_managedpointerreleased(this);
    }

    static int initialize(lua_State *L)
    {
        lua_pushboolean(L, input_gamepadInit() ? 0 : 1);
        return 1;
    }

    static int getNumGamepads()
    {
        return input_numGamepads();
    }

    static const char *getGamePadName(int index)
    {
        return input_gamepadName(index);
    }

    static Gamepad *open(int index)
    {
        InputGamepad *_gamepad = input_gamepadOpen(index);

        if (!_gamepad)
        {
            return NULL;
        }

        Gamepad **lookup = openGamePads.get(_gamepad);
        if (lookup)
        {
            return *lookup;
        }

        Gamepad *gamepad = new Gamepad();
        gamepad->gamepad    = _gamepad;
        gamepad->numAxis    = input_gamepadNumAxes(_gamepad);
        gamepad->numButtons = input_gamepadNumButtons(_gamepad);
        gamepad->numHats    = input_gamepadNumHats(_gamepad);

        openGamePads.insert(_gamepad, gamepad);

        return gamepad;
    }

    static int update(lua_State *L)
    {
        if (!openGamePads.size())
        {
            return 0;
        }

        input_gamepadUpdate();

        for (UTsize i = 0; i < openGamePads.size(); i++)
        {
            Gamepad *gamepad = openGamePads[i];

            if (!lualoom_pushnative<Gamepad>(L, gamepad))
            {
                continue;
            }

            // get the button vector
            lua_getfield(L, -1, "buttons");
            lua_rawgeti(L, -1, LSINDEXVECTOR);

            for (int i = 0; i < gamepad->numButtons; i++)
            {
                int value = input_gamepadGetButton(gamepad->gamepad, i);
                lua_pushboolean(L, value);
                lua_rawseti(L, -2, i);
            }

            // pop buttons vector
            lua_pop(L, 2);

            // get the axis vector
            lua_getfield(L, -1, "axis");
            lua_rawgeti(L, -1, LSINDEXVECTOR);

            for (int i = 0; i < gamepad->numAxis; i++)
            {
                float value = ((float)input_gamepadGetAxis(gamepad->gamepad, i)) / 32768.0f;

                // clamp
                if (fabs(value) > .98f)
                {
                    value = value < 0 ? -1.0f : 1.0f;
                }

                lua_pushnumber(L, value);
                lua_rawseti(L, -2, i);
            }

            // pop axis vector
            lua_pop(L, 2);

            // get the hats vector
            lua_getfield(L, -1, "hats");
            lua_rawgeti(L, -1, LSINDEXVECTOR);

            for (int i = 0; i < gamepad->numHats; i++)
            {
                int value = input_gamepadGetHat(gamepad->gamepad, i);
                lua_pushnumber(L, value);
                lua_rawseti(L, -2, i);
            }

            // pop hats vector
            lua_pop(L, 2);
        }

        return 0;
    }
};

utHashTable<utPointerHashKey, Gamepad *> Gamepad::openGamePads;


static int _registerSystemGamepad(lua_State *L)
{
    beginPackage(L, "system.platform")

       .beginClass<Gamepad>("Gamepad")
       .addVar("numButtons", &Gamepad::numButtons)
       .addVar("numAxis", &Gamepad::numAxis)
       .addVar("numHats", &Gamepad::numHats)

       .addStaticProperty("numGamepads", &Gamepad::getNumGamepads)
       .addStaticLuaFunction("_initialize", &Gamepad::initialize)
       .addStaticMethod("getGamePadName", &Gamepad::getGamePadName)
       .addStaticMethod("open", &Gamepad::open)
       .addStaticLuaFunction("_update", &Gamepad::update)
       .endClass()

       .endPackage();

    return 0;
}


void installSystemPlatformGamepad()
{
    LOOM_DECLARE_MANAGEDNATIVETYPE(Gamepad, _registerSystemGamepad);
}
