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

using namespace LS;

class Dictionary {
public:

    static inline bool hasWeakKeys(lua_State *L, int idx)
    {
        lua_rawgeti(L, idx, LSINDEXDICTIONARYWEAKKEYS);

        bool v = lua_toboolean(L, -1) ? true : false;

        lua_pop(L, 1);

        return v;
    }

    static int clear(lua_State *L)
    {
        lua_newtable(L);

        if (hasWeakKeys(L, 1))
        {
            lua_newtable(L);
            lua_pushstring(L, "k");
            lua_setfield(L, -2, "__mode");
            lua_setmetatable(L, -2);
        }


        lua_rawseti(L, 1, LSINDEXDICTPAIRS);

        return 0;
    }

    static int length(lua_State *L)
    {
        lua_rawgeti(L, 1, LSINDEXDICTPAIRS);

        int tidx = lua_gettop(L);

        int count = 0;
        lua_pushnil(L);         /* first key */
        while (lua_next(L, tidx) != 0)
        {
            count++;
            /* removes 'value'; keeps 'key' for next iteration */
            lua_pop(L, 1);
        }

        lua_pushnumber(L, count);
        return 1;
    }

    static int deleteKey(lua_State *L)
    {
        lua_rawgeti(L, 1, LSINDEXDICTPAIRS);

        lua_pushvalue(L, 2);
        lua_pushnil(L);
        lua_rawset(L, -3);

        return 0;
    }

    static int _Dictionary(lua_State *L)
    {
        // key value pairs table

        lua_newtable(L);
        lua_rawseti(L, 1, LSINDEXDICTPAIRS);

        lua_pushvalue(L, 2);
        lua_rawseti(L, 1, LSINDEXDICTIONARYWEAKKEYS);

        if (hasWeakKeys(L, 1))
        {
            lua_rawgeti(L, 1, LSINDEXDICTPAIRS);
            lua_newtable(L);
            lua_pushstring(L, "k");
            lua_setfield(L, -2, "__mode");
            lua_setmetatable(L, -2);
            lua_pop(L, 1);
        }

        return 0;
    }

    static int intercept(lua_State *L)
    {
        // Arg 1 is a Dictionary. TODO: Check the type.
        lmAssert(lua_istable(L, 1), "Expected table as argument 1.");

        // Arg 2 is the function with which to watch reads.
        lmAssert(lua_isfunction(L, 2), "Expected function as argument 2.");

        // Arg 3 is the function with which to watch writes.
        lmAssert(lua_isfunction(L, 3), "Expected function as argument 3.");

        // Create a metatable or use existing one to call our function.
        lua_rawgeti(L, 1, LSINDEXDICTPAIRS);
        if (lua_getmetatable(L, -1) == 0)
        {
            lua_newtable(L);
        }

        // Set the callback function.
        lua_pushvalue(L, 2);
        lmAssert(lua_istable(L, -2), "WTF");
        lua_setfield(L, -2, "__index");

        lmAssert(lua_istable(L, -1), "WTF");

        lua_pushvalue(L, 3);
        lmAssert(lua_istable(L, -2), "WTF");
        lua_setfield(L, -2, "__newindex");

        // Set the table as the metatable for this Dictionary.
        lmAssert(lua_istable(L, -1), "WTF");
        lmAssert(lua_istable(L, 1), "WTF");
        lua_setmetatable(L, -2);

        // No return values.
        return 0;
    }
};

int registerSystemDictionary(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<Dictionary>("Dictionary")

       .addStaticLuaFunction("Dictionary", &Dictionary::_Dictionary)
       .addStaticLuaFunction("__pget_length", &Dictionary::length)
       .addStaticLuaFunction("clear", &Dictionary::clear)
       .addStaticLuaFunction("deleteKey", &Dictionary::deleteKey)
       .addStaticLuaFunction("intercept", &Dictionary::intercept)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemDictionary()
{
    NativeInterface::registerNativeType<Dictionary>(registerSystemDictionary);
}
