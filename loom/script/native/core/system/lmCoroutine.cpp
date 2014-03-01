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

class Coroutine {
public:

    static int resume(lua_State *L)
    {
        // get the coroutine resume function
        lua_getglobal(L, "coroutine");
        lua_getfield(L, -1, "resume");

        // push the thread on the stack
        lua_pushvalue(L, 1);

        // unwind our var args
        int length = lsr_vector_get_length(L, 2);

        lua_rawgeti(L, 2, LSINDEXVECTOR);
        int vidx = lua_gettop(L);

        for (int i = 0; i < length; i++)
        {
            lua_rawgeti(L, vidx, i);
        }

        // get rid of the vector table
        lua_remove(L, vidx);

        // call resume on the thread
        lua_call(L, length + 1, LUA_MULTRET);

        int top = lua_gettop(L);

        // get the coroutine status
        // and flag coroutine instance as dead
        // if necessary
        lua_getglobal(L, "coroutine");
        lua_getfield(L, -1, "status");
        lua_pushvalue(L, 1);
        lua_call(L, 1, 1);
        if (!strcmp(lua_tostring(L, -1), "dead"))
        {
            lua_pushboolean(L, 0);
            lualoom_setmember(L, 3, "alive");
        }

        lua_settop(L, top);

        // return the value of the yield(x) if any
        return 1;
    }

    static int create(lua_State *L)
    {
        if (lua_iscfunction(L, 1))
        {
            // get the method
            lua_getupvalue(L, 1, 1);
            MethodBase *method = (MethodBase *)lua_topointer(L, -1);
            lua_pop(L, 1);

            // set the _initMethod on the coroutine
            // instance, as methods require a setup resume
            // call (they start in suspended state)

            lua_rawgeti(L, 2, LSINDEXTYPE);
            Type *type = (Type *)lua_topointer(L, -1);
            lua_pop(L, 1);

            assert(type);

            lua_pushboolean(L, 1);
            lualoom_setmember(L, 2, "_initMethod");

            // if we're not static, we also need to store off the instance
            if (!method->isStatic())
            {
                lua_getupvalue(L, 1, 2);
                lualoom_setmember(L, 2, "_this");
            }

            int methodIdx = method->isStatic() ? 2 : 3;

            lua_getglobal(L, "coroutine");
            lua_getfield(L, -1, "create");
            lua_getupvalue(L, 1, methodIdx);
            lua_call(L, 1, LUA_MULTRET);

            return 1;
        }

        if (lua_isfunction(L, 1))
        {
            lua_getglobal(L, "coroutine");
            lua_getfield(L, -1, "create");
            lua_pushvalue(L, 1);
            lua_call(L, 1, LUA_MULTRET);

            lmAssert(lua_isthread(L, -1), "non thread");

            return 1;
        }

        lua_pushnil(L);
        return 1;
    }
};

static int registerSystemCoroutine(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<Coroutine> ("Coroutine")

       .addStaticLuaFunction("_resume", &Coroutine::resume)
       .addStaticLuaFunction("_create", &Coroutine::create)


       .endClass()

       .endPackage();

    return 0;
}


void installSystemCoroutine()
{
    NativeInterface::registerNativeType<Coroutine>(registerSystemCoroutine);
}
