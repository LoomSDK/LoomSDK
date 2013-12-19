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

using namespace LS;

extern "C" {
#include "math.h"
#include "lauxlib.h"
}

class Math {
public:

    static int _abs(lua_State *L)
    {
        lua_pushnumber(L, fabs((float)lua_tonumber(L, 1)));
        return 1;
    }

    static int __pget_RAND_MAX(lua_State *L)
    {
        lua_pushnumber(L, RAND_MAX);
        return 1;
    }

    static int _random(lua_State *L)
    {
        lua_pushnumber(L, ((double)rand()) / ((double)RAND_MAX));
        return 1;
    }

    static int _randomRange(lua_State *L)
    {
        double min = lua_tonumber(L, 1);
        double max = lua_tonumber(L, 2);
        lua_pushnumber(L, min + (((double)rand() / (double)RAND_MAX) * (max - min)));
        return 1;
    }

    static int _randomRangeInt(lua_State *L)
    {
        int min = (int)lua_tonumber(L, 1);
        int max = (int)lua_tonumber(L, 2);
        lua_pushnumber(L, (rand() % (max - min + 1)) + min);
        return 1;
    }    

    static int _pow(lua_State *L)
    {
        lua_pushnumber(L, pow(lua_tonumber(L, 1), lua_tonumber(L, 2)));
        return 1;
    }

    static int _sin(lua_State *L)
    {
        lua_pushnumber(L, sin(lua_tonumber(L, 1)));
        return 1;
    }

    static int _cos(lua_State *L)
    {
        lua_pushnumber(L, cos(lua_tonumber(L, 1)));
        return 1;
    }

    static int _tan(lua_State *L)
    {
        lua_pushnumber(L, tan(lua_tonumber(L, 1)));
        return 1;
    }

    static int _sqrt(lua_State *L)
    {
        lua_pushnumber(L, sqrt(lua_tonumber(L, 1)));
        return 1;
    }

    static int _floor(lua_State *L)
    {
        lua_pushnumber(L, floor(lua_tonumber(L, 1)));
        return 1;
    }

    static int _ceil(lua_State *L)
    {
        lua_pushnumber(L, ceil(lua_tonumber(L, 1)));
        return 1;
    }

    static int _round(lua_State *L)
    {
        // round not present in VS2010, so per http://www.gamedev.net/topic/436496-mathh-round-and-windows-vs2005-pro/
        // doing workaround with floor and addition.
        lua_pushnumber(L, floor(lua_tonumber(L, 1) + 0.5));
        return 1;
    }

    static int _atan2(lua_State *L)
    {
        lua_pushnumber(L, atan2(lua_tonumber(L, 1), lua_tonumber(L, 2)));
        return 1;
    }

    static int _acos(lua_State *L)
    {
        lua_pushnumber(L, acos(lua_tonumber(L, 1)));
        return 1;
    }

    static int _asin(lua_State *L)
    {
        lua_pushnumber(L, asin(lua_tonumber(L, 1)));
        return 1;
    }

    static int _atan(lua_State *L)
    {
        lua_pushnumber(L, atan(lua_tonumber(L, 1)));
        return 1;
    }

    static int _exp(lua_State *L)
    {
        lua_pushnumber(L, exp(lua_tonumber(L, 1)));
        return 1;
    }

    static int _log(lua_State *L)
    {
        lua_pushnumber(L, log(lua_tonumber(L, 1)));
        return 1;
    }

    static int _min(lua_State *L)
    {
        double min;
        double n = lua_tonumber(L, 1);

        min = lua_tonumber(L, 2);

        if (n < min)
        {
            min = n;
        }

        if ((lua_gettop(L) == 3) && !lua_isnil(L, 3))
        {
            // get the ...rest length
            int vlength = lsr_vector_get_length(L, 3);

            // get the vector table into stack position 4
            lua_rawgeti(L, 3, LSINDEXVECTOR);

            for (int i = 0; i < vlength; i++)
            {
                lua_rawgeti(L, 4, i);

                if (!lua_isnumber(L, -1))
                {
                    lua_pop(L, 1);
                    continue;
                }

                n = lua_tonumber(L, -1);
                lua_pop(L, 1);

                min = n < min ? n : min;
            }
        }

        lua_pushnumber(L, min);
        return 1;
    }

    static int _max(lua_State *L)
    {
        double max;
        double n = lua_tonumber(L, 1);

        max = lua_tonumber(L, 2);

        if (n > max)
        {
            max = n;
        }

        if ((lua_gettop(L) == 3) && !lua_isnil(L, 3))
        {
            // get the ...rest length
            int vlength = lsr_vector_get_length(L, 3);

            // get the vector table into stack position 4
            lua_rawgeti(L, 3, LSINDEXVECTOR);

            for (int i = 0; i < vlength; i++)
            {
                lua_rawgeti(L, 4, i);

                if (!lua_isnumber(L, -1))
                {
                    lua_pop(L, 1);
                    continue;
                }

                n = lua_tonumber(L, -1);
                lua_pop(L, 1);

                max = n > max ? n : max;
            }
        }

        lua_pushnumber(L, max);
        return 1;
    }
};

static int registerSystemMath(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<Math> ("Math")

       .addStaticLuaFunction("__pget_RAND_MAX", &Math::__pget_RAND_MAX)
       .addStaticLuaFunction("random", &Math::_random)
       .addStaticLuaFunction("randomRange", &Math::_randomRange)
       .addStaticLuaFunction("randomRangeInt", &Math::_randomRangeInt)
       .addStaticLuaFunction("abs", &Math::_abs)
       .addStaticLuaFunction("sin", &Math::_sin)
       .addStaticLuaFunction("cos", &Math::_cos)
       .addStaticLuaFunction("tan", &Math::_tan)
       .addStaticLuaFunction("atan2", &Math::_atan2)
       .addStaticLuaFunction("sqrt", &Math::_sqrt)

       .addStaticLuaFunction("floor", &Math::_floor)
       .addStaticLuaFunction("ceil", &Math::_ceil)
       .addStaticLuaFunction("round", &Math::_round)

       .addStaticLuaFunction("pow", &Math::_pow)

       .addStaticLuaFunction("acos", &Math::_acos)
       .addStaticLuaFunction("asin", &Math::_asin)
       .addStaticLuaFunction("atan", &Math::_atan)
       .addStaticLuaFunction("exp", &Math::_exp)
       .addStaticLuaFunction("log", &Math::_log)
       .addStaticLuaFunction("max", &Math::_max)
       .addStaticLuaFunction("min", &Math::_min)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemMath()
{
    NativeInterface::registerNativeType<Math>(registerSystemMath);
}
