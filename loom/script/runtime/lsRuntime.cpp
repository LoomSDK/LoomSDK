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

void installPackageSystem();

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


#ifdef LOOMSCRIPT_STANDALONE

#include "loom/common/core/log.h"
#include "loom/common/core/performance.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformNetwork.h"

lmDefineLogGroup(applicationLogGroup, "loom.application", 1, LoomLogInfo);
lmDefineLogGroup(scriptLogGroup, "loom.script", 1, LoomLogInfo);

static LSLuaState *sExecState    = NULL;

static void lsr_handle_assert()
{
    // Try to display the VM stack.
    sExecState->triggerRuntimeError("Native Assertion - see above for full error text");
}

LSLuaState* lsr_getexecstate()
{
    return sExecState;
}

void lsr_loomscript_open(int argc, const char **argv)
{
    if (sExecState)
    {
        return;
    }

    // Mark the main thread for NativeDelegates.
    NativeDelegate::markMainThread();

    // Initialize logging.
    loom_log_initialize();

    // Set up assert handling callback.
    loom_setAssertCallback(lsr_handle_assert);

    performance_initialize();

    platform_timeInitialize();

    stringtable_initialize();

    installPackageSystem();

    loom_net_initialize();

    // Initialize script hooks.
    LS::LSLogInitialize((LS::FunctionLog)loom_log, (void *)&scriptLogGroup, LoomLogInfo, LoomLogWarn, LoomLogError);

    LSLuaState::initCommandLine(argc, argv);

    sExecState = new LSLuaState();
    sExecState->open();

}

void lsr_loomscript_close()
{
    if (sExecState)
    {
        sExecState->close();
        delete sExecState;
    }

    sExecState = NULL;

}

#endif

}
