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

#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"

#include <math.h>
#include <float.h>

// Workaround for no NAN on Windows.
// From http://tdistler.com/2011/03/24/how-to-define-nan-not-a-number-on-windows
#ifdef _MSC_VER
#define INFINITY    (DBL_MAX + DBL_MAX)
#define NAN         (INFINITY - INFINITY)
#endif

class LSNumber {
public:

    static int _toFixed(lua_State *L)
    {
        if (!lua_isnumber(L, 1) || !lua_isnumber(L, 2))
        {
            lua_pushstring(L, "NaN");
            return 1;
        }

        float n   = (float)lua_tonumber(L, 1);
        int   dec = (int)lua_tonumber(L, 2);

        if (dec > 250)
        {
            dec = 250;
        }

        char format[256];
        sprintf(format, "%%.%if", dec);

        // setup string.format call
        lua_getglobal(L, "string");
        lua_getfield(L, -1, "format");
        lua_pushstring(L, format);
        lua_pushnumber(L, n);

        // call leaving formatted string on stack
        lua_call(L, 2, 1);

        return 1;
    }

    static int fromString(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushstring(L, "NaN");
            return 1;
        }

        lua_pushnumber(L, lua_tonumber(L, 1));
        return 1;
    }

    static int getMAX_VALUE(lua_State *L)
    {
        lua_pushnumber(L, DBL_MAX);
        return 1;
    }

    static int getMIN_VALUE(lua_State *L)
    {
        lua_pushnumber(L, DBL_MIN);
        return 1;
    }

    static int getPOSITIVE_INFINITY(lua_State *L)
    {
        lua_pushnumber(L, INFINITY);
        return 1;
    }

    static int getNEGATIVE_INFINITY(lua_State *L)
    {
        lua_pushnumber(L, -INFINITY);
        return 1;
    }
};


static int registerSystemNumber(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<LSNumber> ("Number")

       .addStaticLuaFunction("_toFixed", &LSNumber::_toFixed)
       .addStaticLuaFunction("fromString", &LSNumber::fromString)

       .addStaticLuaFunction("__pget_MAX_VALUE", &LSNumber::getMAX_VALUE)
       .addStaticLuaFunction("__pget_MIN_VALUE", &LSNumber::getMIN_VALUE)
       .addStaticLuaFunction("__pget_POSITIVE_INFINITY", &LSNumber::getPOSITIVE_INFINITY)
       .addStaticLuaFunction("__pget_NEGATIVE_INFINITY", &LSNumber::getNEGATIVE_INFINITY)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemNumber()
{
    NativeInterface::registerNativeType<LSNumber>(registerSystemNumber);
}
