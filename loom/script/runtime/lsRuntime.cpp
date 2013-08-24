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

#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/runtime/lsLuaState.h"

namespace LS {
// temporary buffers which avoid buffer allocation
// in templated typename methods
static char typeNameBuffer[TYPENAME_BUFFER_SIZE];
static char normalizedTypeNameBuffer[TYPENAME_BUFFER_SIZE];

char *_typeNameBuffer           = typeNameBuffer;
char *_normalizedTypeNameBuffer = normalizedTypeNameBuffer;

const char *lsr_objecttostring(lua_State *L, int index)
{
    index = lua_absindex(L, index);

    if (lua_isstring(L, index))
    {
        return lua_tostring(L, index);
    }

    if (lua_isnumber(L, index))
    {
        static char nbuffer[1024];
        snprintf(nbuffer, 1024, "%f", lua_tonumber(L, 1));
        return nbuffer;
    }

    if (lua_isboolean(L, index))
    {
        return lua_toboolean(L, index) ? "true" : "false";
    }

    if (lua_isfunction(L, index) || lua_iscfunction(L, index))
    {
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
        lua_pushvalue(L, 1);
        lua_rawget(L, -2);

        if (lua_isnil(L, -1))
        {
            lua_pop(L, 2);

            // anonymous function
            return "system.Function";
        }

        MethodBase *methodBase = (MethodBase *)lua_topointer(L, -1);

        lua_pop(L, 2);

        return methodBase->getStringSignature().c_str();
    }

    if (lua_isnil(L, index))
    {
        return "null";
    }

    lualoom_getmember(L, index, "toString");
    lua_call(L, 0, 1);

    const char *sreturn = lua_tostring(L, -1);
    lua_pop(L, 1);

    return sreturn;
}


Type *lsr_gettype(lua_State *L, int index)
{
    LSLuaState *lstate = LSLuaState::getLuaState(L);

    // Infer type directly.
    int type = lua_type(L, index);

    switch (type)
    {
    case LUA_TNIL:
        return lstate->nullType;

        break;

    case LUA_TNUMBER:
        return lstate->numberType;

        break;

    case LUA_TBOOLEAN:
        return lstate->booleanType;

        break;

    case LUA_TSTRING:
        return lstate->stringType;

        break;

    case LUA_TFUNCTION:
        return lstate->functionType;

        break;

    case LUA_TTABLE:
        lua_rawgeti(L, 1, LSINDEXTYPE);
        return (Type *)lua_topointer(L, -1);

        break;

    case LUA_TUSERDATA:
    case LUA_TTHREAD:
    case LUA_TLIGHTUSERDATA:
        lua_pushstring(L, "instance expected");
        lua_error(L);
        break;

    default:
        lmAssert(false, "Got an unknown lua type!");
        break;
    }

    // Should never get here.
    return NULL;
}
}
