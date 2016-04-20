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
#include "loom/common/core/telemetry.h"

namespace LS {

static loom_logGroup_t  gGCGroup = { "GC", 1 };


class GC 
{
    static int memoryWarningLevel;
    static int lastMemoryWarningTime;
    static int updateRunLimit;
    static int cycleUpdates;
    static int cycleRuns;
    static double cycleUpdateTime;
    static double cycleMaxTime;
    static int cycleStartTime;
    static int cycleCollectedBytes;
    static bool hibernating;
    static int cycleKB;
    static int lastValidBPR;
    static loom_precision_timer_t timer;
    static double updateNanoLimit;
    static bool spikeCheck;
    static int spikeThreshold;
    static int runLimitMin;
    static int runLimitMax;
    static double targetGarbage;
    static double cycleMemoryGrowthWarningRatio;
    static int cycleWarningExtraRunDivider;
    static double bprValidityThreshold;
    static double cyclePrevGarbage;

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
                lmLogWarn(gGCGroup, "VM Memory Warning: Usage is at %iMB (Threshold: %iMB)", ram, memoryWarningLevel);

        }

        int memoryBeforeKB = lua_gc(L, LUA_GCCOUNT, 0);
        int memoryBeforeB = lua_gc(L, LUA_GCCOUNTB, 0);

        int runLimit = updateRunLimit;
        int runs = 0;
        int cyclesFinished = 0;

        loom_resetTimer(timer);

        int stepTime;
        
        // Uncomment this to test a full GC collection cycle per frame
        //lua_gc(L, LUA_GCCOLLECT, 0); cyclesFinished++; cycleRuns++;

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
                lmLogWarn(gGCGroup, "GC spike: %dms", platform_getMilliseconds() - stepTime);
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
        cycleUpdateTime += timeDelta;
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

        // cycleWarn is true if the difference is big enough to wake up with
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
        double cycleWarnThreshold = cycleKB*(hibernating ? targetGarbage : cycleMemoryGrowthWarningRatio);
        bool cycleWarn = cycleWarnThreshold > 0 && cycleKBDelta > cycleWarnThreshold;

        if (cyclesFinished > 0 || cycleWarn)
        {
            double collectedKB = (double) cycleCollectedBytes / 1024;
            // How many extra runs to add to the auto-adjusted runs
            int extraRuns = 0;
            if (cycleWarn)
            {
                if (lastValidBPR == 0) lastValidBPR = 64;
                extraRuns += cycleKBDelta * 1024 / lastValidBPR / cycleWarningExtraRunDivider;
                lmLogDebug(gGCGroup, "Allocating %d KiB in a single cycle, waking up with %d emergency runs", cycleKBDelta, extraRuns);
            }

            // GC cycle time
            int collectionTime = platform_getMilliseconds() - cycleStartTime;
            
            // Run limit adjustment value easing,
            // so far I haven't seen any benefit from it, so it's disabled with 1 for now
            double runAmortization = 1.0;

            // Collected KB per second
            double cps = collectedKB * 1000 / collectionTime;

            // Ratio of garbage collected against the total memory taken
            double garbageRatio = collectedKB / (memoryAfterKB + collectedKB);
            
            // Self-correction adjustment for the number of runs based on the
            // current garbage ratio and the target garbage ratio + extra runs
            double targetRuns = garbageRatio * runLimit / targetGarbage + extraRuns;

            int runsPerUpdate = cycleRuns / cycleUpdates;
            double timePerUpdate = cycleUpdateTime / cycleUpdates;
            int bytesPerRun = cycleCollectedBytes / cycleRuns;
            
            // The new run limit
            runLimit = (int)floor(0.5 + runLimit + (targetRuns - runLimit) * runAmortization);
            
            // Limit the persistent limit based on the min and max
            updateRunLimit = runLimit < runLimitMin ? runLimitMin : runLimit > runLimitMax ? runLimitMax : runLimit;
            
            // The system is said to be hibernating when the run limit falls below the minimum,
            // which means that the GC cycles are long (with little to no work each update),
            // so the entire system is slow to update and is in a sleeping state.
            //
            // The system can be woken up from hibernation due to rapid changes
            // with the cycle warning described above.
            hibernating = updateRunLimit == runLimitMin;

            // Only update the valid bytes per run if enough garbage
            // was collected to make it a valid metric.
            if (garbageRatio > targetGarbage * bprValidityThreshold) lastValidBPR = bytesPerRun;
            
            // Uncomment for GC cycle reports
            /*
            lmLog(gGCGroup, "Cycle: %d / %d KiB in %d ms with %d runs in %d updates %.4f ms avg %.4f ms max, %.2f KiB/s, %d rpu, %d bpr, %.2f%% garb., %.2f%% -> %.2f (%d) runs",
                cycleCollectedBytes/1024, memoryAfterKB, collectionTime, cycleRuns, cycleUpdates, timePerUpdate*1e-6, cycleMaxTime*1e-6, cps, runsPerUpdate, lastValidBPR, garbageRatio * 100, targetGarbage * 100, targetRuns, updateRunLimit
            );
            //*/

            // Reset cycle state
            cycleUpdates = 0;
            cycleRuns = 0;
            cycleCollectedBytes = 0;
            cycleUpdateTime = 0;
            cycleMaxTime = 0;
            cycleStartTime = platform_getMilliseconds();
            cycleKB = memoryAfterKB;
            cyclePrevGarbage = garbageRatio;

        }

        Telemetry::setTickValue("gc.cycle.previous.garbage", cyclePrevGarbage);
        Telemetry::setTickValue("gc.cycle.runs.limit", updateRunLimit);
        Telemetry::setTickValue("gc.cycle.update.count", cycleUpdates);
        Telemetry::setTickValue("gc.cycle.update.time.sum", cycleUpdateTime);
        Telemetry::setTickValue("gc.cycle.update.time.max", cycleMaxTime);
        Telemetry::setTickValue("gc.cycle.runs.sum", cycleRuns);
        Telemetry::setTickValue("gc.cycle.collected", cycleCollectedBytes);
        Telemetry::setTickValue("gc.cycle.previous.collectedKB", cycleKB);
        Telemetry::setTickValue("gc.cycle.lastValidBPR", lastValidBPR);
        Telemetry::setTickValue("gc.cycle.hibernating", hibernating ? 1 : 0);
        Telemetry::setTickValue("gc.memory", (double) memoryAfterKB * 1024 + memoryAfterB);


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

// The target garbage ratio to be collected each cycle.
// The system adjusts each cycle to try to meet this garbage ratio.
double GC::targetGarbage = 0.1;

// The max time in nanoseconds each GC update is allowed to
// run for.
double GC::updateNanoLimit = 2e9;

// The minimum number of runs each update.
int GC::runLimitMin = 1;

// The maximum number of runs each update.
int GC::runLimitMax = 100000;

// How much the memory has to grow from the previous
// cycle to this one for it to be a warning and for
// the GC to ramp up collection.
//
// E.g. a ratio of 0.5 means that when the memory
// grows by 50% from the last cycle, it triggers a warning.
// So if the memory goes from 100MB to 150MB it triggers
// a warning and collects garbage more aggresively
// next update.
//
// This applies to the non-hibernating state.
// In hibernation, the ratio equals targetGarbage,
// so that the system wakes up when it's time to collect.
double GC::cycleMemoryGrowthWarningRatio = 0.5;

// Determines how many runs to allocate as extra runs
// on a cycle warning. The higher the number the fewer
// the runs. First, the number of runs required
// to clear all the garbage collected in the
// warning period is calculated based on the
// lastValidBPR and memory growth. This number is then
// used as a divider that brings that number down, as
// you usually don't want to use that many runs at a time.
int GC::cycleWarningExtraRunDivider = 10;

// The amount of times a single GC step is run
// This is only the starting value, it is adjusted
// automatically from this point onward.
int GC::updateRunLimit = 100;

// Ratio of how much garbage has to be collected
// against the target garbage for the last
// collected bytes per run to be considered valid.
double GC::bprValidityThreshold = 0.2;


// Last valid bytes per run metric, see above for details
int GC::lastValidBPR = 0;

// The last time a memory warning was issued.
// Used to prevent memory warning spam.
int GC::lastMemoryWarningTime = 0;

// The number of updates in the current cycle
int GC::cycleUpdates = 0;

// The number of runs in the current cycle
int GC::cycleRuns = 0;

// The cumulated time taken for updates in the current cycle in nanoseconds
double GC::cycleUpdateTime = 0;

// The maximum time taken for an update in the current cycle in nanoseconds
double GC::cycleMaxTime = 0;

// The start timestamp of the cycle in milliseconds
int GC::cycleStartTime = 0;

// The number of bytes collected in the current cycle
int GC::cycleCollectedBytes = 0;

// The amount of memory taken in KB at the end of the last cycle
int GC::cycleKB = 0;

// The amount of memory taken in KB at the end of the last cycle
double GC::cyclePrevGarbage = 0;

// true if the system is currently hibernating, false otherwise.
// See above for details.
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
