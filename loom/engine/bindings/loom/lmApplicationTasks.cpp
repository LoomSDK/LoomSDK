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
#include "loom/common/assets/assets.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "lmApplication.h"
#include "loom/common/config/applicationConfig.h"
#include "loom/engine/loom2d/l2dStage.h"
#include "loom/graphics/gfxTexture.h"
#include "loom/common/assets/telemetry.h"

lmDefineLogGroup(gTickLogGroup, "tick", true, LoomLogInfo)

extern "C"
{

void loom_tick()
{
    Telemetry::beginTick();
    //Telemetry::beginTickTimer("tickNano");
        
    LOOM_PROFILE_START(loom_tick);

    LSLuaState *vm = NULL;

    vm = LoomApplication::getReloadQueued() ? NULL : LoomApplication::getRootVM();

    // Mark the main thread for NativeDelegates. On some platforms this
    // may change so we remark every frame.
    NativeDelegate::markMainThread();
    if (vm) NativeDelegate::executeDeferredCalls(vm->VM());

    performance_tick();

    profilerBlock_t p = { "loom_tick", platform_getMilliseconds(), 8 };
    
    if (LoomApplication::getReloadQueued())
    {
        LoomApplication::reloadMainAssembly();
    }
    else
    {
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

    //Telemetry::beginTickTimer("http");
    platform_HTTPUpdate();
    //Telemetry::endTickTimer("http");

    //Telemetry::beginTickTimer("tex");
    GFX::Texture::tick();
    //Telemetry::endTickTimer("tex");

    LOOM_PROFILE_START(render);
    if (Loom2D::Stage::smMainStage) Loom2D::Stage::smMainStage->invokeRenderStage();
    LOOM_PROFILE_END(render);

    //Telemetry::endTickTimer("render");

    finishProfilerBlock(&p);

    LOOM_PROFILE_END(loom_tick);

    LOOM_PROFILE_ZERO_CHECK()

    //Telemetry::endTickTimer("tickNano");
    Telemetry::endTick();

}
}

