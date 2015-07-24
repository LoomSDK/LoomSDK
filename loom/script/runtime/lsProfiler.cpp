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

// we can use this here as we have no link dependencies
#include "loom/common/platform/platform.h"
#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsProfiler.h"
#include <string.h>

namespace LS
{
static utHashTable<utFastStringHash, LoomProfilerRoot *> dynamicProfilerRoots;

bool LSProfiler::enabled = false;
utStack<MethodBase *> LSProfiler::methodStack;
utHashTable<utPointerHashKey, LSProfilerTypeAllocation *> LSProfiler::allocations;

lmDefineLogGroup(gProfilerLogGroup, "profiler", 1, LoomLogInfo);

static inline void primeProfiler()
{
    const char       *path = ".......";
    LoomProfilerRoot **prd = dynamicProfilerRoots[path];

    if (prd == NULL)
    {
        dynamicProfilerRoots.insert(path, new LoomProfilerRoot(strdup(path)));
        prd = dynamicProfilerRoots[path];
    }

    gLoomProfiler->hashPush(*prd);
    gLoomProfiler->hashPop(*prd);
}


static inline bool shouldFilterFunction(const char *fullPath)
{
    if (!strncmp(fullPath, "system.Profiler.", 16))
    {
        return true;
    }

    if (!strncmp(fullPath, "system.debugger.", 16))
    {
        return true;
    }

    if (!strncmp(fullPath, "system.BaseDelegate.", 20))
    {
        return true;
    }

    if (!strncmp(fullPath, "system.Coroutine.", 17))
    {
        return true;
    }

    return false;
}


void LSProfiler::getCurrentStack(lua_State *L, utStack<MethodBase *>& stack)
{
    int       top = lua_gettop(L);
    lua_Debug lstack;
    int       stackFrame = 0;

    MethodBase *lastMethod = NULL;

    while (true)
    {
        // if we get a null result here, we are out of stack
        if (!lua_getstack(L, stackFrame++, &lstack))
        {
            lua_settop(L, top);
            return;
        }

        // something bad in denmark
        if (!lua_getinfo(L, "f", &lstack))
        {
            lua_settop(L, top);
            return;
        }

        bool cfunc = false;
        if (lua_iscfunction(L, -1))
        {
            cfunc = true;
        }

        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
        lua_pushvalue(L, -2);
        lua_rawget(L, -2);

        if (lua_isnil(L, -1))
        {
            lua_settop(L, top);
            continue;
        }

        MethodBase *methodBase = (MethodBase *)lua_topointer(L, -1);

        lua_settop(L, top);

#ifdef LOOM_ENABLE_JIT
        // We do not receive line return hooks for native calls under JIT :(
        // So, don't add to initial stack
        if (cfunc)
        {
            continue;
        }
#endif


        if (shouldFilterFunction(methodBase->getFullMemberName()))
        {
            continue;
        }

        // we only want the root call, not the pcall wrapper
        if (cfunc && (lastMethod == methodBase))
        {
            continue;
        }

        lastMethod = methodBase;

        stack.push(methodBase);
    }
}


MethodBase *LSProfiler::getTopMethod(lua_State *L)
{
    int       top = lua_gettop(L);
    lua_Debug stack;

    // if we get a null result here, we are out of stack
    if (!lua_getstack(L, 0, &stack))
    {
        lua_settop(L, top);
        return NULL;
    }

    if (!lua_getinfo(L, "f", &stack))
    {
        lua_settop(L, top);
        return NULL;
    }

    bool iscfunc = false;
    if (lua_iscfunction(L, -1))
    {
        iscfunc = true;
    }


#ifdef LOOM_ENABLE_JIT
    // We do not receive line return hooks for native calls under JIT :(
    // So, if we want to profile native methods, we need to be under interpreted VM
    if (iscfunc)
    {
        lua_settop(L, top);
        return NULL;
    }
#endif


    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
    lua_pushvalue(L, -2);
    lua_rawget(L, -2);

    if (lua_isnil(L, -1))
    {
        lua_settop(L, top);
        return NULL;
    }

    MethodBase *methodBase = (MethodBase *)lua_topointer(L, -1);

    lua_settop(L, top);

    if (iscfunc && !methodBase->isNative())
    {
        return NULL;
    }

    if (shouldFilterFunction(methodBase->getFullMemberName()))
    {
        return NULL;
    }

    return methodBase;
}


void LSProfiler::enable(lua_State *L)
{
    if (enabled)
    {
        return;
    }

    enabled = true;

    updateState(L);
}

void LSProfiler::disable(lua_State *L)
{
    if (!enabled)
    {
        return;
    }

    enabled = false;

    updateState(L);
}

void LSProfiler::updateState(lua_State *L) {
    gLoomProfiler->enable(enabled);

    // push pop to get the profiler enabled and on the next profiler frame
    primeProfiler();

    methodStack.clear();
    clearAllocations();

    if (enabled)
    {
        utStack<MethodBase *> stack;

        getCurrentStack(L, stack);

        while (stack.size())
        {
            if (!shouldFilterFunction(stack.peek(0)->getFullMemberName()))
            {
                methodStack.push(stack.peek(0));
                enterMethod(stack.peek(0)->getFullMemberName());
            }

            stack.pop();
        }

        lua_sethook(L, profileHook, LUA_MASKRET | LUA_MASKCALL, 1);
    }
    else
    {
        lua_sethook(L, profileHook, 0, 1);
    }
}


void LSProfiler::enterMethod(const char *fullPath)
{
    if (!isEnabled())
    {
        return;
    }

    //printf("Entering %s\n", fullPath);

    LoomProfilerRoot **prd = dynamicProfilerRoots[fullPath];
    if (prd == NULL)
    {
        dynamicProfilerRoots.insert(fullPath, new LoomProfilerRoot(strdup(fullPath)));
        prd = dynamicProfilerRoots[fullPath];
    }

    gLoomProfiler->hashPush(*prd);
}


void LSProfiler::leaveMethod(const char *fullPath)
{
    if (!isEnabled())
    {
        return;
    }

    //printf("Leaving %s\n", fullPath);

    LoomProfilerRoot **prd = dynamicProfilerRoots[fullPath];
    lmAssert(prd, "Should never leave a method we didn't enter first!");
    gLoomProfiler->hashPop(*prd);
}


// Main lua VM debug hook
void LSProfiler::profileHook(lua_State *L, lua_Debug *ar)
{
    MethodBase *methodBase = NULL;

    if (ar->event == LUA_HOOKCALL)
    {
        methodBase = getTopMethod(L);

        if (methodBase)
        {
            methodStack.push(methodBase);
            enterMethod(methodBase->getFullMemberName());
        }
    }

    if (ar->event == LUA_HOOKRET)
    {
        methodBase = getTopMethod(L);

        if (methodBase)
        {
            if (methodStack.size())
            {
                methodStack.pop();
                leaveMethod(methodBase->getFullMemberName());
            }
        }
    }
}


void LSProfiler::dump(lua_State *L)
{
    dumpAllocations(L);

    while (methodStack.size())
    {
        leaveMethod(methodStack.peek(0)->getFullMemberName());
        methodStack.pop();
    }

    gLoomProfiler->dumpToConsole();

#ifdef LOOM_ENABLE_JIT
    lmLog(gProfilerLogGroup, "Please note: Profiling under JIT does not include native function calls.");
    lmLog(gProfilerLogGroup, "switch to the interpreted VM in order to gather native method timings");
#endif
}


void LSProfiler::reset(lua_State *L)
{
    if (gLoomProfiler)
    {
        gLoomProfiler->reset();
    }

    disable(L);

    methodStack.clear();
    clearAllocations();
}


void LSProfiler::dumpAllocations(lua_State *L)
{
    lua_gc(L, LUA_GCCOLLECT, 0);

#ifdef LOOM_ENABLE_JIT
    lmLog(gProfilerLogGroup, "Please note: Profiling under JIT does not include native function calls.");
    lmLog(gProfilerLogGroup, "switch to the interpreted VM in order to gather native method allocation");
#endif

    lmLog(gProfilerLogGroup, "Object Allocation Dump");
    lmLog(gProfilerLogGroup, "----------------------");

    utList<LSProfilerTypeAllocation *> allocs;

    for (UTsize i = 0; i < allocations.size(); i++)
    {
        allocs.push_back(allocations.at(i));
    }

    while (allocs.size())
    {
        int best = -1;
        LSProfilerTypeAllocation *bestType = NULL;

        for (UTsize i = 0; i < allocs.size(); i++)
        {
            LSProfilerTypeAllocation *alloc = allocs.at(i);

            if (alloc->alive > best)
            {
                best     = alloc->alive;
                bestType = alloc;
            }
        }

        lmAssert(bestType, "couldn't get bestType");

        allocs.erase(bestType);

        lmLog(gProfilerLogGroup, "Alive: %i, Total: %i, Type: %s", bestType->alive, bestType->total, bestType->type->getFullName().c_str());

        if (bestType->anonTotal)
        {
            lmLog(gProfilerLogGroup, "    Alive: %i, Total %i (Anonymous)", bestType->anonTotal, bestType->anonCurrent);
        }

        for (UTsize j = 0; j < bestType->methodCurrent.size(); j++)
        {
            MethodBase *methodBase = (MethodBase *)bestType->methodCurrent.keyAt(j).key();
            lmAssert(methodBase == (MethodBase *)bestType->methodTotal.keyAt(j).key(), "mismatched methodbase");

            int *value1 = bestType->methodCurrent.get(methodBase);
            int *value2 = bestType->methodTotal.get(methodBase);

            lmAssert(value1 && value2, "bad pointer on allocation");

            lmLog(gProfilerLogGroup, "     Alive %i, Total %i (%s) ", (*value1), (*value2), methodBase->getFullMemberName());
        }
    }
}
}
