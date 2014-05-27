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

#include "loom/common/platform/platformThread.h"
#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/native/lsNativeDelegate.h"

namespace LS {
utHashTable<utPointerHashKey, utArray<NativeDelegate *> *> NativeDelegate::sActiveNativeDelegates;
static const int scmBadThreadID = 0xBAADF00D;
int              NativeDelegate::smMainThreadID = scmBadThreadID;

NativeDelegate::NativeDelegate()
    : L(NULL), _argumentCount(0), _callbackCount(0)
{
}


void NativeDelegate::createCallbacks()
{
    //lmAssert(gNativeDelegateMainThread == platform_getCurrentThreadId(), "Working with a NativeDelegate outside of the main thread!");

    if (!L)
    {
        LSError("NativeDelegate attempting to create callbacks table without valid VM");
    }

    // we must create a lua table to hold our script callbacks
    // these cannot be held in the context of the script binding
    // as they may change/be stripped via mechanisms of pure native
    // handling
    int top = lua_gettop(L);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);
    lua_pushlightuserdata(L, this);
    lua_newtable(L);
    lua_newtable(L);
    lua_rawseti(L, -2, LSINDEXNATIVEDELEGATECALLBACKS);
    lua_settable(L, -3);
    lua_settop(L, top);
}


void NativeDelegate::registerDelegate(lua_State *L, NativeDelegate *delegate)
{
    assertMainThread();

    utArray<NativeDelegate *> *delegates = NULL;

    if (sActiveNativeDelegates.find(L) != UT_NPOS)
    {
        delegates = *(sActiveNativeDelegates.get(L));
    }

    if (!delegates)
    {
        delegates = new utArray<NativeDelegate *>;
        sActiveNativeDelegates.insert(L, delegates);
    }

    delegates->push_back(delegate);
}


void NativeDelegate::setVM(lua_State *vm, bool newCallbacks)
{
    if (L)
    {
        if (newCallbacks)
        {
            createCallbacks();
        }
        return;
    }

    L = vm;

    registerDelegate(vm, this);

    // first time we're setting VM, so make sure callbacks table exists
    createCallbacks();
}


void NativeDelegate::getCallbacks(lua_State *L) const
{
    lua_pushnil(L);
    int top = lua_gettop(L);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);
    lua_pushlightuserdata(L, (void *)this);
    lua_gettable(L, -2);
    lua_rawgeti(L, -1, LSINDEXNATIVEDELEGATECALLBACKS);
    lua_replace(L, top);
    lua_settop(L, top);
}


void NativeDelegate::pushArgument(const char *value) const
{
    if (!L)
    {
        return;
    }

    lua_pushstring(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(int value) const
{
    if (!L)
    {
        return;
    }

    lua_pushinteger(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(float value) const
{
    if (!L)
    {
        return;
    }

    lua_pushnumber(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(double value) const
{
    if (!L)
    {
        return;
    }

    lua_pushnumber(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(bool value) const
{
    if (!L)
    {
        return;
    }

    lua_pushboolean(L, value);
    _argumentCount++;
}


int NativeDelegate::getCount() const
{
    return _callbackCount;
}


// We don't currently support return values as this makes it the responsibility
// of the caller to clean up the stack, this can be changed if we automate
void NativeDelegate::invoke(bool checkMainThread) const
{
    // Don't do this from non-main thread.
    if(checkMainThread)
    {
        assertMainThread();
    }

    // if we have no callbacks defined, the VM state will be NULL
    if (!L)
    {
        // Even if we don't do anything, need to reset arg count.
        _argumentCount = 0;
        return;
    }

    int top = lua_gettop(L);

    int numArgs = _argumentCount;

    // Reset argument count, so recursion is properly handled
    _argumentCount = 0;

    getCallbacks(L);

    int tidx = lua_gettop(L);

    if (!lua_istable(L, tidx))
    {
        LSError("Error getting native delegate callback table");
    }

    for (int i = 0; i < _callbackCount; i++)
    {
        lua_pushnumber(L, (double)i);
        lua_gettable(L, tidx);

        int t = lua_gettop(L);

        for (int i = top - numArgs; i < top; i++)
        {
            lua_pushvalue(L, i + 1);
        }

        lua_call(L, numArgs, 1);

        lua_settop(L, t);

        /* removes last lua_function called */
        lua_pop(L, 1);
    }

    lua_settop(L, top);

    // clean up arguments off stack
    lua_pop(L, numArgs);
}


int NativeDelegate::__op_assignment(lua_State *L)
{
    NativeDelegate *delegate = (NativeDelegate *)lualoom_getnativepointer(L, 1,
                                                                          true, "system.NativeDelegate");

    if (!delegate)
    {
        LSError("Unable to get native delegate on += operator");
    }

    // set the VM, and recreate callbacks table
    delegate->setVM(L, true);

    delegate->getCallbacks(L);

    if (!lua_istable(L, -1))
    {
        LSError("Bad native delegates table");
    }

    // clear current callbacks
    for (int i = 0; i < delegate->_callbackCount; i++)
    {
        lua_pushnumber(L, (double)i);
        lua_pushnil(L);
        lua_settable(L, -3);
    }

    // reset
    delegate->_callbackCount = 0;

    if (lua_isnil(L, 2))
    {
        return 0;
    }

    if (!lua_isfunction(L, 2) && !lua_iscfunction(L, 2))
    {
        LSError("Unknown type on NativeDelegate assignment operator");
    }

    // add the lua function or cfunction to our delegate's callback table
    lua_pushnumber(L, (double)0);
    lua_pushvalue(L, 2);
    lua_settable(L, -3);
    lua_pop(L, 1);
    // pop __lscallbacks

    delegate->_callbackCount++;

    return 0;
}


int NativeDelegate::__op_minusassignment(lua_State *L)
{
    NativeDelegate *delegate = (NativeDelegate *)lualoom_getnativepointer(L, 1,
                                                                          "system.NativeDelegate");

    if (!delegate)
    {
        LSError("Unable to get native delegate on += operator");
    }

    if (!delegate->_callbackCount)
    {
        return 0;
    }

    delegate->setVM(L);

    delegate->getCallbacks(L);

    int tidx = lua_gettop(L);

    if (!lua_istable(L, tidx))
    {
        LSError("Bad native delegates table");
    }

    if (lua_isfunction(L, 2) || lua_iscfunction(L, 2))
    {
        int idx = -1;
        for (int i = 0; i < delegate->_callbackCount; i++)
        {
            lua_rawgeti(L, tidx, i);
            if (lua_equal(L, 2, -1))
            {
                idx = i;
                lua_pop(L, 1);
                break;
            }
            lua_pop(L, 1);
        }


        // this function was never added in the first place
        if (idx == -1)
        {
            return 0;
        }

        // shift the other delegates down
        lua_pushnumber(L, (double)idx);
        lua_pushnil(L);
        lua_settable(L, tidx);

        int ntable = 0;
        if (delegate->_callbackCount > 1)
        {
            // temp table
            lua_newtable(L);
            ntable = lua_gettop(L);

            int c = 0;
            for (int nidx = 0; nidx < delegate->_callbackCount; nidx++)
            {
                lua_pushnumber(L, (double)nidx);
                lua_gettable(L, tidx);
                if (lua_isnil(L, -1))
                {
                    lua_pop(L, 1);
                    continue;
                }

                lua_pushnumber(L, (double)c);
                lua_pushvalue(L, -2);
                lua_settable(L, ntable);
                // pop lua_function
                lua_pop(L, 1);
                c++;
            }
        }

        // clear it
        delegate->_callbackCount--;

        // and copy from new temp table
        for (int nidx = 0; nidx < delegate->_callbackCount; nidx++)
        {
            lua_pushnumber(L, (double)nidx);
            lua_pushnumber(L, (double)nidx);
            lua_gettable(L, ntable);
            lua_settable(L, tidx);
        }
    }
    else
    {
        LSError("Unknown type on NativeDelegate -= operator");
    }

    return 0;
}


int NativeDelegate::__op_plusassignment(lua_State *L)
{
    NativeDelegate *delegate = (NativeDelegate *)lualoom_getnativepointer(L, 1,
                                                                          "system.NativeDelegate");

    if (!delegate)
    {
        LSError("Unable to get native delegate on += operator");
    }

    delegate->setVM(L);

    delegate->getCallbacks(L);

    int tidx = lua_gettop(L);

    if (!lua_istable(L, -1))
    {
        LSError("Bad native delegates table");
    }

    if (lua_isfunction(L, 2) || lua_iscfunction(L, 2))
    {
        // check if we already added this callback
        for (int i = 0; i < delegate->_callbackCount; i++)
        {
            lua_rawgeti(L, tidx, i);
            if (lua_equal(L, 2, -1))
            {
                lua_pop(L, 1);
                return 0; // already added
            }
            lua_pop(L, 1);
        }

        // add the lua function or cfunction to our delegate's callback table
        lua_pushnumber(L, (double)delegate->_callbackCount++);
        lua_pushvalue(L, 2);
        lua_settable(L, -3);
        lua_pop(L, 1);
        // pop __lscallbacks
    }
    else
    {
        LSError("Unknown type on NativeDelegate += operator");
    }

    return 0;
}


void NativeDelegate::invalidate()
{
    _callbackCount = 0;

    if (L)
    {
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);
        lua_pushlightuserdata(L, this);
        lua_pushnil(L);
        lua_settable(L, -3);
        lua_pop(L, 1);
    }

    L = NULL;
}


void NativeDelegate::invalidateLuaStateDelegates(lua_State *L)
{
    utArray<NativeDelegate *> *delegates = NULL;

    if (sActiveNativeDelegates.find(L) != UT_NPOS)
    {
        delegates = *(sActiveNativeDelegates.get(L));
    }

    if (delegates)
    {
        for (UTsize i = 0; i < delegates->size(); i++)
        {
            NativeDelegate *delegate = delegates->at(i);
            delegate->invalidate();
        }

        sActiveNativeDelegates.erase(L);
        delete delegates;
    }
}


NativeDelegate::~NativeDelegate()
{
    // If we are in the native delegate list, remove ourselves.
    utArray<NativeDelegate *> *delegates = NULL;
    if (sActiveNativeDelegates.find(L) != UT_NPOS)
    {
        delegates = *(sActiveNativeDelegates.get(L));
    }

    if (delegates)
    {
        UTsize idx = delegates->find(this);
        if(idx != UT_NPOS)
            delegates->erase(idx);
    }

    // And clean up our Lua VM state.
    invalidate();
}


void NativeDelegate::markMainThread()
{
    smMainThreadID = platform_getCurrentThreadId();
}


void NativeDelegate::assertMainThread()
{
    lmAssert(smMainThreadID != scmBadThreadID,
             "Tried to touch a NativeDelegate before the main thread was marked. "
             "Probably need to add a markMainThread call?");

    lmAssert(platform_getCurrentThreadId() == smMainThreadID,
             "Trying to fire a NativeDelegate from thread %x that is not the main "
             "thread %x. This will result in memory corruption and race conditions!",
             platform_getCurrentThreadId(), smMainThreadID);
}
}
