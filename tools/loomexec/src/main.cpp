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

#include "stdio.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/performance.h"
#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformNetwork.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/script/common/lsLog.h"
#include "loom/script/common/lsFile.h"

using namespace LS;

void installPackageSystem();

static utString   assemblyPath  = "./bin/Main.loom";
static LSLuaState *execState    = NULL;
static Assembly   *execAssembly = NULL;
static utArray<utString> argSwitches;

lmDefineLogGroup(applicationLogGroup, "loom.application", 1, LoomLogInfo);
lmDefineLogGroup(scriptLogGroup, "loom.script", 1, LoomLogInfo);


static void initExecState()
{
    execState = new LSLuaState();
    execState->open();
}


static void executeAssembly()
{
    lmAssert(execState, "null execState");
    execAssembly = execState->loadExecutableAssembly(assemblyPath.c_str(), true);

    // look for a class derived from LoomApplication in the main assembly
    Type *loomAppType = execState->getType("system.application.ConsoleApplication");
    if (loomAppType)
    {
        utArray<Type *> types;
        execAssembly->getTypes(types);
        for (UTsize i = 0; i < types.size(); i++)
        {
            Type *appType = types.at(i);
            if (appType->isDerivedFrom(loomAppType))
            {
                //lmLog(applicationLogGroup, "Instantiating Application: %s", appType->getName());
                int top = lua_gettop(execState->VM());
                lsr_createinstance(execState->VM(), appType);
                lualoom_getmember(execState->VM(), -1, "initialize");
                lua_call(execState->VM(), 0, 0);
                lua_settop(execState->VM(), top);
                break;
            }
        }
    }
}


static void shutdownExecState()
{
    execAssembly = NULL;

    if (!execState)
    {
        return;
    }

    execState->close();
    delete execState;
    execState = NULL;
}


static void handleAssert()
{
    // Try to display the VM stack.
    execState->triggerRuntimeError("Native Assertion - see above for full error text");
}


static void initialize(int argc, const char **argv)
{
    // Were skipping the first argument (current exe)  and the first passed assembly.
    // The rest will be passed on to the script
    utArray<utString> args;

    assemblyPath = "";

    int argStart = 1;

    while (argStart < argc && strncmp(argv[argStart], "--", 2) == 0) {
        argSwitches.push_back(utString(argv[argStart]));
        argStart++;
    }

    if (argSwitches.find("--verbose") != UT_NPOS) LSLogSetLevel(LSLogDebug);
    if (argSwitches.find("--ignore-missing-types") != UT_NPOS) Type::ignoreMissingTypes = true;

    // look for passing a .loom file
    for (int i = argStart; i < argc; i++ )
    {
        if (assemblyPath.size() == 0 && strstr(argv[i], ".loom"))
        {
            assemblyPath = argv[i];
        }
        else
        {
            args.push_back(argv[i]);
        }
    }

#ifdef LOOM_ENABLE_JIT
    //platform_debugOut("Loom - JIT\n");
#else
    //platform_debugOut("Loom - Interpreted\n");
#endif

    // Mark the main thread for NativeDelegates.
    NativeDelegate::markMainThread();

    // Initialize services.
    //platform_debugOut("Initializing services...");

    // Initialize logging.
    loom_log_initialize();

    // Set up assert handling callback.
    //lmLog(applicationLogGroup, "   o asserts");
    loom_setAssertCallback(handleAssert);

    //lmLog(applicationLogGroup, "   o performance");
    performance_initialize();

    //lmLog(applicationLogGroup, "   o time");
    platform_timeInitialize();

    //lmLog(applicationLogGroup, "   o stringtable");
    stringtable_initialize();

    installPackageSystem();

    //lmLog(applicationLogGroup, "   o network");
    loom_net_initialize();

    // Initialize script hooks.
    LS::LSLogInitialize((LS::FunctionLog)loom_log, (void *)&scriptLogGroup, LoomLogDebug, LoomLogInfo, LoomLogWarn, LoomLogError);

    // Shift the arguments, the first one is meant for loomexec
    LSLuaState::initCommandLine(args);
}


int main(int argc, const char **argv)
{
    initialize(argc, argv);

    initExecState();
    executeAssembly();
    shutdownExecState();
}
