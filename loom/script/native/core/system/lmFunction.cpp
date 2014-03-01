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

#include "loom/common/core/assert.h"
#include "loom/script/native/lsLuaBridge.h"

using namespace LS;

class LSFunction {
public:

    static int _length(lua_State *L)
    {
        lmAssert(lua_isfunction(L, 1) || lua_iscfunction(L, 1), "Non-function in Function._length");

        // first look in the global method lookup to see if we have a method base to go off
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
        lua_pushvalue(L, 1);
        lua_rawget(L, -2);

        if (!lua_isnil(L, -1))
        {
            MethodBase *methodBase = (MethodBase *)lua_topointer(L, -1);
            lua_pushnumber(L, methodBase->getNumParameters());
            return 1;
        }

        // we don't, so we better be a local function with an upvalue at index 1 describing the number of parameters
        const char *upvalue = lua_getupvalue(L, 1, 1);

        lmAssert(upvalue, "Internal Error: funcinfo not at upvalue 1");

#ifdef LOOM_DEBUG
        lmAssert(!strncmp(upvalue, "__ls_funcinfo_arginfo", 21), "Internal Error: funcinfo not __ls_funcinfo_arginfo");
#endif

        lmAssert(lua_isnumber(L, -1), "Internal Error: __ls_funcinfo_arginfo not a number");

        // number of args stored in upper 16 bits, so shift and return
        lua_pushnumber(L, ((unsigned int) lua_tonumber(L, -1)) >> 16);

        return 1;
    }

    static int _call(lua_State *L)
    {
        // position 1 is the function
        // position 2 is the thisObject
        // position 3 is the varargs

        // look in global method lookup for methodbase
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
        lua_pushvalue(L, 1);
        lua_rawget(L, -2);

        MethodBase *methodBase = NULL;
        int varArgs = -1;

        if (!lua_isnil(L, -1))
        {
            methodBase = (MethodBase *)lua_topointer(L, -1);
            varArgs = methodBase->getVarArgIndex();
            lua_pop(L, 2);
        }
        else
        {            
            //  we better be a local function with an upvalue at index 1 describing the parameter index of varargs
            const char *upvalue = lua_getupvalue(L, 1, 1);


            lmAssert(upvalue, "Internal Error: funcinfo not at upvalue 1");

    #ifdef LOOM_DEBUG
            lmAssert(!strncmp(upvalue, "__ls_funcinfo_arginfo", 21), "Internal Error: funcinfo not __ls_funcinfo_arginfo");
    #endif

            lmAssert(lua_isnumber(L, -1), "Internal Error: __ls_funcinfo_arginfo not a number");

            // vararg count is packed into lower 16 bits, with 0xFFFF stored for no-varargs
            unsigned int mask = ((( unsigned int) lua_tonumber(L, -1)) & 0x0000FFFF);
            varArgs =  mask == 0xFFFF ? -1 : mask;

            lua_pop(L, 3);

        }

        // check for static call
        if (lua_isnil(L, 2))
        {
            // remove the this object (which should be null for static call/apply)
            lua_remove(L, 2);
        }
        else
        {
            // otherwise, we better be an instance method

            int top = lua_gettop(L);

            if (!methodBase)
            {
                lua_pushstring(L, "MethodBase is missing from function table in Function.call(this, ...)");
                lua_error(L);
            }

            lua_pushnumber(L, methodBase->getOrdinal());
            lua_gettable(L, 2);

            if (lua_isnil(L, -1))
            {
                char error[512];
                snprintf(error, 512, "Unable to resolve instance method %s for Function.call(this, ...)", methodBase->getStringSignature().c_str());
                lua_pushstring(L, error);
                lua_error(L);
            }

            lua_replace(L, 1);
            lua_settop(L, top);
            lua_remove(L, 2);
        }

        int nargs = 0;

        if (!lua_isnil(L, 2))
        {
            // we have a varargs array of values

            // get the length
            int vlength = lsr_vector_get_length(L, 2);

            // retrieve the interval vector store
            lua_rawgeti(L, 2, LSINDEXVECTOR);
            int vindex = lua_gettop(L);

            // loop through the values and unwind
            for (int i = 0; i < vlength; i++)
            {
                // if we hit the varArgs index, the rest wants to be a vector
                if (i == varArgs)
                {
                    // we're at the var args argument and have some left
                    if (i)
                    {
                        // shift and store new length
                        for (int j  = 0; j < vlength - i; j++)
                        {
                            lua_rawgeti(L, vindex, j + varArgs);
                            lua_rawseti(L, vindex, j);
                        }

                        lsr_vector_set_length(L, 2, vlength - varArgs);
                    }
                    // reuse the varargs vector in the call, as an arg
                    lua_pushvalue(L, 2);
                    nargs++;

                    // outta here
                    break;
                }
                else
                {
                    // unwind and keep going
                    lua_rawgeti(L, vindex, i);
                    nargs++;
                }

            }

            // remove vector table
            lua_remove(L, vindex);

            // ... and varargs
            lua_remove(L, 2);

        }
        else
        {
            // no args, so remove the null
            lua_remove(L, 2);
        }

        // and call
        lua_call(L, nargs, 1);

        return 1;
    }
};


static int registerSystemFunction(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<LSFunction> ("Function")

       .addStaticLuaFunction("_call", &LSFunction::_call)

    // internally apply and call operate in exactly the same way, winning
       .addStaticLuaFunction("_apply", &LSFunction::_call)

       .addStaticLuaFunction("_length", &LSFunction::_length)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemFunction()
{
    NativeInterface::registerNativeType<LSFunction>(registerSystemFunction);
}
