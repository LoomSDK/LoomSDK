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


#ifndef _lslua_h
#define _lslua_h

#include <lua.hpp>

//==============================================================================

#if LUA_VERSION_NUM < 502

/**
 * Helpers for Lua versions prior to 5.2.0.
 */
inline int lua_absindex(lua_State *L, int idx)
{
    if ((idx > LUA_REGISTRYINDEX) && (idx < 0))
    {
        return lua_gettop(L) + idx + 1;
    }
    else
    {
        return idx;
    }
}


inline void lua_rawgetp(lua_State *L, int idx, void const *p)
{
    idx = lua_absindex(L, idx);
    lua_pushlightuserdata(L, const_cast<void *> (p));
    lua_rawget(L, idx);
}


inline void lua_rawsetp(lua_State *L, int idx, void const *p)
{
    idx = lua_absindex(L, idx);
    lua_pushlightuserdata(L, const_cast<void *> (p));
    // put key behind value
    lua_insert(L, -2);
    lua_rawset(L, idx);
}
#endif

extern "C" {
#ifdef LOOM_ENABLE_JIT
#include "lj_state.h"
#else
#include "lstate.h"
#endif
}
#endif
