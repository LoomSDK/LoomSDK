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



#include "loom/script/native/lsLuaBridge.h"
#include "loom/common/utils/utRandom.h"

using namespace LS;

extern "C" {
#include "lauxlib.h"
}

 

class Random {
public:
    static utRandomNumberGenerator *utRand;

    static int _setSeed(lua_State *L)
    {
        utRand->setSeed((UTuint32)lua_tonumber(L, 1));
        return 0;
    }

    static int _rand(lua_State *L)
    {
        lua_pushnumber(L, utRand->randUnit());
        return 1;
    }

    static int _randRange(lua_State *L)
    {
        float min = (float)lua_tonumber(L, 1);
        float max = (float)lua_tonumber(L, 2);
        lua_pushnumber(L, utRand->randRange(min, max));
        return 1;
    }

    static int _randRangeInt(lua_State *L)
    {
        int min = (int)lua_tonumber(L, 1);
        int max = (int)lua_tonumber(L, 2);
        lua_pushnumber(L, utRand->randRangeInt(min, max));
        return 1;
    }    

    static int _randNormal(lua_State *L)
    {
        float mean = (float)lua_tonumber(L, 1);
        float deviation = (float)lua_tonumber(L, 2);
        lua_pushnumber(L, utRand->randNormal(mean, deviation));
        return 1;
    }

    static int _randNegativeExponential(lua_State *L)
    {
        float halfLife = (float)lua_tonumber(L, 1);
        lua_pushnumber(L, utRand->randNegativeExponential(halfLife));
        return 1;
    }

    static int _randPoisson(lua_State *L)
    {
        float mean = (float)lua_tonumber(L, 1);
        lua_pushnumber(L, utRand->randPoisson(mean));
        return 1;
    }
};


// always seed to fixed value; up to the user to change the seed in script if they want a unique set
utRandomNumberGenerator *Random::utRand = new utRandomNumberGenerator(736);



static int registerSystemRandom(lua_State *L)
{
   beginPackage(L, "system")

       .beginClass<Random> ("Random")

       .addStaticLuaFunction("setSeed", &Random::_setSeed)
       .addStaticLuaFunction("rand", &Random::_rand)
       .addStaticLuaFunction("randRange", &Random::_randRange)
       .addStaticLuaFunction("randRangeInt", &Random::_randRangeInt)
       .addStaticLuaFunction("randNormal", &Random::_randNormal)
       .addStaticLuaFunction("randNegativeExponential", &Random::_randNegativeExponential)
       .addStaticLuaFunction("randPoisson", &Random::_randPoisson)

       .endClass()

    .endPackage();

    return 0;
}


void installSystemRandom()
{
    NativeInterface::registerNativeType<Random>(registerSystemRandom);
}
