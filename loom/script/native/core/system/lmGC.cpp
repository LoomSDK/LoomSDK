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

#include "loom/common/core/log.h"
#include "loom/script/native/lsLuaBridge.h"
#include "loom/common/platform/platformTime.h"

namespace LS {

static loom_logGroup_t  gGCGroup = { "GC", 1 };

class GC 
{
    static int memoryWarningLevel;
    static int lastMemoryWarningTime;
    static int gcBackOffTime;
    static int gcIncrementSize;
    static int gcBackOffThreshold;

public:

    static int collect(lua_State *L)
    {
        lua_gc(L, (int)lua_tonumber(L, 1), (int)lua_tonumber(L, 2));

        return 0;
    }

    static int getAllocatedMemory(lua_State *L)
    {        
        lua_pushnumber(L, lua_gc(L, LUA_GCCOUNT, 0) / 1024);
        return 1;
    }    

    static int update(lua_State *L)
    {
        static int gcBackOff = 0;
        static int gcLastTime = 0;

        // start of GC calculations
        int startTime = platform_getMilliseconds();    

        if (memoryWarningLevel && (startTime - lastMemoryWarningTime) > 5000)
        {
            lastMemoryWarningTime = startTime;

            int ram = lua_gc(L, LUA_GCCOUNT, 0) / 1024;

            if (ram > memoryWarningLevel)
                lmLogError(gGCGroup, "VM Memory Warning: Usage is at %iMB (Threshold: %iMB)", ram, memoryWarningLevel);

        }

        // the delta
        int delta = startTime - gcLastTime;

        // calculate the backoff delta if any
        if (gcBackOff > 0 && (gcBackOff - delta) < 0 )
            gcBackOff = 0;

        // if it has been at least 8ms, and we're not backing off
        // run a gc step
        if (delta > 8 && gcBackOff <= 0)
        {        
            // run a gc step at size "16", which is roughly 64k
            // this is a relatively aggressive incrememnt though
            // use a full collection if you want to immediately flush the gc
            lua_gc(L, LUA_GCSTEP, gcIncrementSize);

            gcLastTime = platform_getMilliseconds();

            int gcTime =  gcLastTime - startTime;

            // if the collection took longer than 1 milliseconds
            // we could be in some incremental GC churn and will backoff 
            // running it again for a (default) 250ms
            if (gcTime > gcBackOffThreshold)
                gcBackOff = gcBackOffTime;

            //printf("GC Time: %i %i\n", gcTime, lua_gc(L, LUA_GCCOUNT, 0)/1024);
        }

        return 0;

    }

    static int setMemoryWarningLevel(lua_State *L)
    {
        memoryWarningLevel = (int) lua_tonumber(L, 1);
        return 0;
    }    

    static int setBackOffTime(lua_State *L)
    {
        gcBackOffTime = (int) lua_tonumber(L, 1);
        return 0;
    }    

    static int setIncrementSize(lua_State *L)
    {
        gcIncrementSize = (int) lua_tonumber(L, 1);
        return 0;
    }    

    static int setBackOffThreshold(lua_State *L)
    {
        gcBackOffThreshold = (int) lua_tonumber(L, 1);
        return 0;
    }    

};

// no VM warning default
int GC::memoryWarningLevel = 0;

int GC::lastMemoryWarningTime = 0;
// 250ms
int GC::gcBackOffTime = 250;
// 16k 
int GC::gcIncrementSize = 16;
// 1ms
int GC::gcBackOffThreshold = 1;

void lualoom_gc_update(lua_State *L)
{
    GC::update(L);
}

int registerSystemGC(lua_State *L)
{
    // verify that out enumeration hasn't changed in value
    lmAssert(LUA_GCSTOP == 0, "LUA_GCSTOP is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCRESTART == 1, "LUA_GCRESTART is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCCOLLECT == 2, "LUA_GCCOLLECT is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCCOUNT == 3, "LUA_GCCOUNT is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCCOUNTB == 4, "LUA_GCCOUNTB is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCSTEP == 5, "LUA_GCSTEP is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCSETPAUSE == 6, "LUA_GCSETPAUSE is unexpected value, please check this and adjust system.GC member accordingly");
    lmAssert(LUA_GCSETSTEPMUL == 7, "LUA_GCSETSTEPMUL is unexpected value, please check this and adjust system.GC member accordingly");


    beginPackage(L, "system")

       .beginClass<GC> ("GC")

       .addStaticLuaFunction("collect", &GC::collect)
       .addStaticLuaFunction("getAllocatedMemory", &GC::getAllocatedMemory)
       .addStaticLuaFunction("update", &GC::update)
       .addStaticLuaFunction("setMemoryWarningLevel", &GC::setMemoryWarningLevel)
       .addStaticLuaFunction("setBackOffTime", &GC::setBackOffTime)
       .addStaticLuaFunction("setIncrementSize", &GC::setIncrementSize)
       .addStaticLuaFunction("setBackOffThreshold", &GC::setBackOffThreshold)

       .endClass()

       .endPackage();

    return 0;
}

}


void installSystemGC()
{
    LS::NativeInterface::registerNativeType<LS::GC>(LS::registerSystemGC);
}
