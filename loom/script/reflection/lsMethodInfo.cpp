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

#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/reflection/lsMethodInfo.h"

namespace LS {
Object *MethodBase::invoke(void *othis, int numParams)
{
    if (!attr.isNative)
    {
        // Why was this here?
        //assert(byteCode);
    }

    LSLuaState *ls = getModule()->getAssembly()->getLuaState();
    lua_State  *L  = ls->VM();

    // get the type
    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXCLASSES);
    lua_getfield(L, -1, declaringType->getFullName().c_str());

    assert(!lua_isnil(L, -1));

    // get the method
    lua_pushnumber(L, ordinal);
    lua_gettable(L, -2);

    assert(!lua_isnil(L, -1));

    lua_remove(L, -2);
    lua_remove(L, -2);

    if (othis)
    {
        assert(0);
        //lua_pushobject(L, othis);
        lua_call(L, 1, LUA_MULTRET);
    }
    else
    {
        if (numParams)
        {
            int t = lua_gettop(L);
            lua_insert(L, t - numParams);
        }

        lua_call(L, numParams, LUA_MULTRET);
    }


    return NULL;
}


void MethodBase::push()
{
    if (!attr.isNative)
    {
        // Why was this here?
        //assert(byteCode);
    }

    LSLuaState *ls = getModule()->getAssembly()->getLuaState();
    lua_State  *L  = ls->VM();

    // get the type
    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXCLASSES);
    lua_getfield(L, -1, declaringType->getFullName().c_str());

    // get the method

    lua_pushnumber(L, ordinal);
    lua_gettable(L, -2);

    lua_remove(L, -2);
    lua_remove(L, -2);
}


void lsr_getclasstable(lua_State *L, Type *type);

int MethodInfo::_invoke(lua_State *L)
{
    // index 1 = MethodInfo
    // index 2 = this (for non-static) or null for static
    // index 3 = var arg table

    int nargs = lsr_vector_get_length(L, 3);

    lua_rawgeti(L, 3, LSINDEXVECTOR);
    lua_replace(L, 3);

    if (!isStatic())
    {
        // get method from instance
        lua_pushnumber(L, ordinal);
        lua_gettable(L, 2);
    }
    else
    {
        // get method from class table
        lsr_getclasstable(L, getDeclaringType());
        lua_pushnumber(L, ordinal);
        lua_gettable(L, -2);
        lua_remove(L, -2);
    }

    // replace MethodInfo with function
    lua_replace(L, 1);

    for (int i = 0; i < nargs; i++)
    {
        lua_pushnumber(L, i);
        lua_gettable(L, 3);
    }

    // varargs
    lua_remove(L, 3);
    // this is handled in runtime
    lua_remove(L, 2);

    // and call
    lua_call(L, nargs, 1);

    // todo, catch void return and return 0
    return 1;
}


int MethodInfo::_invokeSingle(lua_State *L)
{
    // index 1 = MethodInfo
    // index 2 = this (for non-static) or null for static
    // index 3 = arg

    if (!isStatic())
    {
        // get method from instance
        lua_pushnumber(L, ordinal);
        lua_gettable(L, 2);
    }
    else
    {
        // get method from class table
        lsr_getclasstable(L, getDeclaringType());
        lua_pushnumber(L, ordinal);
        lua_gettable(L, -2);
        lua_remove(L, -2);
    }

    // replace MethodInfo with function
    lua_replace(L, 1);

    // "this" is handled in runtime
    lua_remove(L, 2);

    // and call
    lua_call(L, 1, 1);

    // todo, catch void return and return 0
    return 1;
}


void lsr_createinstance(lua_State *L, Type *type);

int ConstructorInfo::_invoke(lua_State *L)
{
    // index 1 = ConstructorInfo (UserData)
    // index 2 = var arg table

    // see MethodInfo::_invoke for var arg handling once we support it

    ConstructorInfo *cinfo = (ConstructorInfo *)lualoom_getnativepointer(L, 1, true, "system.reflection.ConstructorInfo");

    lsr_createinstance(L, cinfo->declaringType);

    return 1;
}
}
