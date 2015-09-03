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

class BaseDelegate {
public:

    static int call(lua_State *L)
    {
        int top = lua_gettop(L);

        lua_getfield(L, 1, "__ls_callbacks");

        int tidx = lua_gettop(L);

        assert(lua_istable(L, tidx)); //, "non-table");

        lua_pushnil(L);               /* first key */
        bool gotone = false;

        while (lua_next(L, tidx) != 0)
        {
            gotone = true;

            int t = lua_gettop(L);

            for (int i = 1; i < top; i++)
            {
                lua_pushvalue(L, i + 1);
            }

            lua_call(L, top - 1, 1);
            //tricky, replace object with result
            lua_replace(L, 1);

            lua_settop(L, t);

            /* removes 'value'; keeps 'key' for next iteration */
            lua_pop(L, 1);
        }

        if (!gotone)
        {
            lua_pushnil(L);
            lua_replace(L, 1);
        }

        lua_settop(L, 1);

        return 1;
    }

    static int __op_plusassignment(lua_State *L)
    {
        lua_getfield(L, 1, "__ls_callbacks");

        lua_pushvalue(L, 2);
        lua_pushvalue(L, 2);
        lua_settable(L, -3);

        return 0;
    }

    static int __op_minusassignment(lua_State *L)
    {
        lua_getfield(L, 1, "__ls_callbacks");

        lua_pushvalue(L, 2);
        lua_pushnil(L);
        lua_settable(L, -3);

        return 0;
    }

    static int __op_assignment(lua_State *L)
    {
        // if we're setting null, drop
        // the current callback table and return the delegate instance
        if (lua_isnil(L, 2))
        {
            lua_newtable(L);
            lua_setfield(L, 1, "__ls_callbacks");
            lua_pushvalue(L, 1);
            return 1;
        }

        // drop the callback table
        lua_newtable(L);
        lua_pushvalue(L, -1);
        lua_pushvalue(L, -1);
        lua_setfield(L, 1, "__ls_callbacks");

        lua_pushvalue(L, 2);
        lua_pushvalue(L, 2);
        lua_settable(L, -3);

        lua_pushvalue(L, 1);

        return 1;
    }

    static int _BaseDelegate(lua_State *L)
    {
        lua_newtable(L);
        lua_setfield(L, 1, "__ls_callbacks");

        return 0;
    }
};

static int registerSystemBaseDelegate(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<BaseDelegate> ("BaseDelegate")

       .addStaticLuaFunction("BaseDelegate", &BaseDelegate::_BaseDelegate)
       .addStaticLuaFunction("__ls_constructor", &BaseDelegate::_BaseDelegate)
       .addStaticLuaFunction("__op_assignment", &BaseDelegate::__op_assignment)
       .addStaticLuaFunction("call", &BaseDelegate::call)
       .addStaticLuaFunction("__op_plusassignment", &BaseDelegate::__op_plusassignment)
       .addStaticLuaFunction("__op_minusassignment", &BaseDelegate::__op_minusassignment)


       .endClass()

   .endPackage();

    return 0;
}


void installSystemBaseDelegate()
{
    NativeInterface::registerNativeType<BaseDelegate>(registerSystemBaseDelegate);
}
