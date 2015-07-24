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

#ifndef _ls_profiler_h
#define _ls_profiler_h

#include "loom/common/core/performance.h"
#include "loom/common/utils/utTypes.h"
#include "loom/script/loomscript.h"

namespace LS {
struct LSProfilerTypeAllocation
{
    Type                               *type;

    utHashTable<utPointerHashKey, int> methodCurrent;
    utHashTable<utPointerHashKey, int> methodTotal;

    int                                anonCurrent;
    int                                anonTotal;

    int                                alive;
    int                                total;
};

class LSProfiler
{
private:
    static void enterMethod(const char *fullPath);
    static void leaveMethod(const char *fullPath);

    static void profileHook(lua_State *L, lua_Debug *ar);

    static bool enabled;
    static utStack<MethodBase *> methodStack;
    // Type -> allocations
    static utHashTable<utPointerHashKey, LSProfilerTypeAllocation *> allocations;

    static void getCurrentStack(lua_State *L, utStack<MethodBase *>& stack);
    static MethodBase *getTopMethod(lua_State *L);

public:

    inline static bool isEnabled()
    {
        if (!gLoomProfiler)
        {
            return false;
        }

        return enabled;
    }

    static void clearAllocations()
    {
        for (UTsize i = 0; i < allocations.size(); i++)
        {
            delete allocations.at(i);
        }

        allocations.clear();
    }

    inline static MethodBase *registerAllocation(Type *type)
    {
        MethodBase *methodBase = NULL;

        if (methodStack.size())
        {
            methodBase = methodStack.peek(0);
        }

        LSProfilerTypeAllocation **oalloc = allocations.get(type);

        // no allocations of type registered yet?
        if (!oalloc || !*oalloc)
        {
            LSProfilerTypeAllocation *n = new LSProfilerTypeAllocation;
            allocations.insert(type, n);

            n->type        = type;
            n->total       = 1;
            n->alive       = 1;
            n->anonCurrent = 0;
            n->anonTotal   = 0;

            if (methodBase)
            {
                n->methodCurrent.insert(methodBase, 1);
                n->methodTotal.insert(methodBase, 1);
            }
            else
            {
                n->anonCurrent = 1;
                n->anonTotal   = 1;
            }

            return methodBase;
        }

        (*oalloc)->total++;
        (*oalloc)->alive++;

        if (methodBase)
        {
            int *value = (*oalloc)->methodCurrent.get(methodBase);

            if (!value)
            {
                (*oalloc)->methodCurrent.insert(methodBase, 1);
            }
            else
            {
                *value = *value + 1;
            }

            value = (*oalloc)->methodTotal.get(methodBase);

            if (!value)
            {
                (*oalloc)->methodTotal.insert(methodBase, 1);
            }
            else
            {
                *value = *value + 1;
            }
        }
        else
        {
            (*oalloc)->anonCurrent++;
            (*oalloc)->anonTotal++;
        }

        return methodBase;
    }

    inline static void registerGC(Type *type, MethodBase *methodBase)
    {
        LSProfilerTypeAllocation **oalloc = allocations.get(type);

        if (!oalloc || !*oalloc)
        {
            return;
        }

        (*oalloc)->alive--;

        if (!methodBase)
        {
            (*oalloc)->anonCurrent--;
        }
        else
        {
            int *value = (*oalloc)->methodCurrent.get(methodBase);

            if (value)
            {
                *value = *value - 1;
            }
        }
    }

    static void updateState(lua_State *L);

    static void enable(lua_State *L);
    static void disable(lua_State *L);

    static void dumpAllocations(lua_State *L);

    static void dump(lua_State *L);

    static void reset(lua_State *L);
};
}
#endif
