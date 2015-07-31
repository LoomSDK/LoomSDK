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
#include "loom/script/runtime/lsLuaState.h"
#include "loom/common/platform/platformTime.h"
#include "loom/graphics/gfxMath.h"

namespace LS {

static loom_logGroup_t  gGCGroup = { "GC", 1 };


class GC 
{
    static int memoryWarningLevel;
    static int lastMemoryWarningTime;

    static int updateRunLimit;
    static int cycleUpdates;
    static int cycleRuns;
    static double cycleStepTime;
    static double cycleMaxTime;
    static int cycleStartTime;
    static int cycleCollectedBytes;
    static bool GC::hibernating;
    static int cycleKB;
    static int lastValidBPR;
    static loom_precision_timer_t timer;
    static double updateNanoLimit;
    static bool spikeCheck;
    static int spikeThreshold;
    static int runLimitMin;
    static int runLimitMax;
    static double targetGarbage;
    static double GC::cycleMemoryGrowthWarningRatio;
    static int cycleWarningExtraRunDivider;

public:

    static int collect(lua_State *L)
    {
        lua_gc(L, (int)lua_tonumber(L, 1), (int)lua_tonumber(L, 2));

        return 0;
    }

    static int getAllocatedMemory(lua_State *L)
    {        
        lua_pushnumber(L, ((double)lua_gc(L, LUA_GCCOUNT, 0) + (double)lua_gc(L, LUA_GCCOUNTB, 0) / 1024) / 1024);
        return 1;
    }    

    static int update(lua_State *L)
    {
        int startTime = platform_getMilliseconds();    

        if (memoryWarningLevel && (startTime - lastMemoryWarningTime) > 5000)
        {
            lastMemoryWarningTime = startTime;

            int ram = lua_gc(L, LUA_GCCOUNT, 0) / 1024;

            if (ram > memoryWarningLevel)
                lmLogError(gGCGroup, "VM Memory Warning: Usage is at %iMB (Threshold: %iMB)", ram, memoryWarningLevel);

        }

        int memoryBeforeKB = lua_gc(L, LUA_GCCOUNT, 0);
        int memoryBeforeB = lua_gc(L, LUA_GCCOUNTB, 0);

        int runLimit = updateRunLimit;
        int runs = 0;
        int cyclesFinished = 0;

        loom_resetTimer(timer);

        int stepTime;
        
        // Uncomment this to test a full GC collection cycle per frame
        //lua_gc(L, LUA_GCCOLLECT, 0); cycles++;

        // This loop is more or less equivalent to
        // int cycle = lua_gc(L, LUA_GCSTEP, runLimit);
        // except with an additional time limit and other features
        while (runs < runLimit && loom_readTimerNano(timer) < updateNanoLimit)
        {
            if (spikeCheck) stepTime = platform_getMilliseconds();
            
            // Returns 1 when the entire Lua GC cycle finishes
            // calling LUA_GCSTEP with 0 as the argument only
            // makes a single internal GC step
            int cycle = lua_gc(L, LUA_GCSTEP, 0);
            
            if (spikeCheck && platform_getMilliseconds() - stepTime > spikeThreshold)
            {
                lmLog(gGCGroup, "GC spike: %dms", platform_getMilliseconds() - stepTime);
            }
            
            if (cycle == 1) {
                cyclesFinished++;
                // Break immediately if it finished at least
                // an entire cycle in a single update loop
                if (cyclesFinished > 1) break;
            }
            runs++;
        }
            

        double timeDelta = loom_readTimerNano(timer);
        cycleStepTime += timeDelta;
        if (timeDelta > cycleMaxTime) cycleMaxTime = timeDelta;
        
        // Prevent the garbage collector from running on its own
        lua_gc(L, LUA_GCSTOP, 0);

        int memoryAfterKB = lua_gc(L, LUA_GCCOUNT, 0);
        int memoryAfterB = lua_gc(L, LUA_GCCOUNTB, 0);
        int memoryDelta = (memoryAfterKB - memoryBeforeKB) * 1024 + memoryAfterB - memoryBeforeB;

        cycleUpdates++;
        cycleRuns += runs;
        // Subtract so the negative memory delta gets counted in
        // terms of how many bytes were freed
        cycleCollectedBytes -= memoryDelta;

        // Memory difference in KB since cycle start
        int cycleKBDelta = memoryAfterKB - cycleKB;

        // cycleKBWarn is true if the difference is big enough to wake up with
        // a bigger collection next update.
        //
        // Warnings should be most useful when the system is in a low-churn
        // GC cycle (hibernating - the cycle time is long) and suddenly
        // experiences an explosion of allocation and has to suddenly wake up
        // so it doesn't bloat in memory too much until the next cycle.
        //
        // A warning can occur in a non-hibernation state as well, but
        // it can usually have more leeway as the rate will adjust
        // under normal conditions and only sudden changes benefit from
        // a faster response.
        bool cycleKBWarn = lastValidBPR > 0 && cycleKBDelta > cycleKB * (hibernating ? targetGarbage : cycleMemoryGrowthWarningRatio);

        if (cyclesFinished > 0 || cycleKBWarn)
        {
            double collectedKB = (double) cycleCollectedBytes / 1024;
            // How many extra runs to add to the auto-adjusted runs
            int extraRuns = 0;
            if (cycleKBWarn)
            {
                extraRuns += cycleKBDelta * 1024 / lastValidBPR / cycleWarningExtraRunDivider;
                lmLogDebug(gGCGroup, "Warning allocating %d KiB in a single cycle, waking up with %d emergency runs", cycleKBDelta, extraRuns);
            }
            int collectionTime = platform_getMilliseconds() - cycleStartTime;
            double runAmortization = 1.0;
            double cps = collectedKB * 1000 / collectionTime;
            double garbageRatio = collectedKB / (memoryAfterKB + collectedKB);
            //float targetMs = ratio * timeLimit / targetGarbage;
            double targetRuns = garbageRatio * runLimit / targetGarbage + extraRuns;
            int runsPerUpdate = cycleRuns / cycleUpdates;
            double timePerUpdate = cycleStepTime / cycleUpdates;
            int bytesPerRun = cycleCollectedBytes / cycleRuns;
            //timeLimit = (int)round(targetMs);
            //gcMs = timeLimit < 1 ? 1 : timeLimit > 1000 ? 1000 : timeLimit;
            runLimit = (int)round(runLimit + (targetRuns - runLimit) * runAmortization);
            /*if (hibernating)
            {
                runLimit *= collectionTime / 1000;
            }*/
            updateRunLimit = runLimit < runLimitMin ? runLimitMin : runLimit > runLimitMax ? runLimitMax : runLimit;
            /*if (hibernating && updateRunLimit != runLimitMin) {
                updateRunLimit *= 2;
            }*/
            hibernating = updateRunLimit == runLimitMin;
            if (garbageRatio > targetGarbage * 0.2) lastValidBPR = bytesPerRun;
            
            // Uncomment for GC cycle reports
            /*
            lmLog(gGCGroup, "GC cycle: %d / %d KiB in %d ms with %d runs in %d updates %.4f ms max, %.2f KiB/s, %.2f%% garb., %d rpu, %d bpr, %.2f%% -> %.2f (%d) runs",
                cycleCollectedBytes/1024, memoryAfterKB, collectionTime, cycleRuns, cycleUpdates, cycleMaxTime*1e-3, cps, garbageRatio * 100, runsPerUpdate, lastValidBPR, targetGarbage * 100, targetRuns, updateRunLimit
            );
            //*/

            cycleUpdates = 0;
            cycleRuns = 0;
            cycleCollectedBytes = 0;
            cycleStepTime = 0;
            cycleMaxTime = 0;
            cycleStartTime = platform_getMilliseconds();
            cycleKB = memoryAfterKB;

        }

        return 0;

    }

    static int setMemoryWarningLevel(lua_State *L)
    {
        memoryWarningLevel = (int) lua_tonumber(L, 1);
        return 0;
    }
};

loom_precision_timer_t GC::timer = loom_startTimer();

bool GC::spikeCheck = false;
int GC::spikeThreshold = 1;

// No VM warning default
int GC::memoryWarningLevel = 0;
double GC::targetGarbage = 0.1;
double GC::updateNanoLimit = 0.5e6;
int GC::runLimitMin = 1;
int GC::runLimitMax = 100000;
double GC::cycleMemoryGrowthWarningRatio = 0.5;
int GC::cycleWarningExtraRunDivider = 10;

// The amount of times a single GC step is run
// This is only the starting value, it is adjusted
// automatically from this point onward
int GC::updateRunLimit = 100;

int GC::lastMemoryWarningTime = 0;
int GC::cycleUpdates = 0;
int GC::cycleRuns = 0;
double GC::cycleStepTime = 0;
double GC::cycleMaxTime = 0;
int GC::cycleStartTime = 0;
int GC::cycleCollectedBytes = 0;
int GC::cycleKB = 0;
int GC::lastValidBPR = 0;
bool GC::hibernating = false;


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

       .endClass()

       .endPackage();

    return 0;
}

}


void installSystemGC()
{
    LS::NativeInterface::registerNativeType<LS::GC>(LS::registerSystemGC);
}
