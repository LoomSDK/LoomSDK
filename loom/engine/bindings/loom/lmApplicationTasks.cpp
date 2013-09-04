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

#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformHttp.h"
#include "loom/common/core/performance.h"
#include "loom/engine/tasks/tasks.h"
#include "loom/common/assets/assets.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "lmApplication.h"
#include "loom/common/config/applicationConfig.h"

static int gLastTickTime;

extern "C"
{

void loom_tick()
{
    // Mark the main thread for NativeDelegates. On some platforms this
    // may change so we remark every frame.
    NativeDelegate::markMainThread();

    profilerBlock_t p = { "loom_tick", platform_getMilliseconds(), 8 };

    if (LoomApplication::getReloadQueued())
    {
        LoomApplication::reloadMainAssembly();
    }
    else
    {
        LSLuaState *vm = LoomApplication::getRootVM();
        if (vm)
        {
            // https://theengineco.atlassian.net/browse/LOOM-468
            // decouple debugger enabled from connection time
            // as the debugger matures this may change a bit
            if (LoomApplicationConfig::waitForDebugger() > 0)
            {
                vm->invokeStaticMethod("system.debugger.DebuggerClient", "update");
            }

            LoomApplication::ticks.invoke();
        }
    }

    loom_asset_pump();
    platform_HTTPUpdate();

    lualoom_gc_update(LoomApplication::getRootVM()->VM());

    finishProfilerBlock(&p);
}
}


LOOM_IMPLEMENT_TASK(PreTick)
{
    return NULL;
}

LOOM_IMPLEMENT_TASK(PostTick)
{
    return NULL;
}

LOOM_IMPLEMENT_TASK(Network)
{
    loom_asset_pump();
    return NULL;
}

LOOM_IMPLEMENT_TASK(Frame)
{
    performance_tick();

    // Check that it's been at least tickms from last tick.

    int msToRunTasks = 32 - (platform_getMilliseconds() - gLastTickTime);
    if (msToRunTasks < 0)
    {
        msToRunTasks = 0;
    }
    if (msToRunTasks > 32)
    {
        msToRunTasks = 32;
    }
    tasks_runAnyTaskForDuration(msToRunTasks);

    // Pre-tick
    task_t *prett = task_initialize(task_PreTickTask, NULL);
    task_setThreadAffinity(prett, 1);

    // Post-tick
    task_t *posttt = task_initialize(task_PostTickTask, NULL);
    task_setFinishes(posttt, task);

    // Network
    task_t *nt = task_initialize(task_NetworkTask, NULL);
    task_setFinishes(nt, task);

    // Set up next frame.
    task_t *ft = task_initialize(task_FrameTask, NULL);
    task_setThreadAffinity(ft, 1);
    task_setStarts(task, ft);

    // Fire it all off!
    tasks_schedule(prett);
    tasks_schedule(nt);

    gLastTickTime = platform_getMilliseconds();

    return NULL;
}
