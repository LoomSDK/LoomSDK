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

#include "loom/script/native/lsNativeInterface.h"
#include "loom/script/runtime/lsLuaState.h"
#include "lmPackageSystem.h"

using namespace LS;

void installSystemBaseDelegate();
void installSystemNativeDelegate();
void installSystemBootstrap();
void installSystemConsole();
void installSystemCoroutine();
void installSystemDictionary();
void installSystemFunction();
void installSystemGC();
void installSystemMath();
void installSystemDate();
void installSystemRandom();
void installSystemObject();
void installSystemString();
void installSystemNumber();
void installSystemVector();
void installSystemVM();
void installSystemCommandLine();
void installSystemDebug();
void installSystemProfiler();
void installSystemTelemetry();
void installSystemProcess();
void installSystemByteArray();
void installSystemSocket();
void installSystemIO();

// Sytem.Reflection
void installSystemReflectionAssembly();
void installSystemReflectionType();

// system.xml
void installSystemXML();
void installSystemJSON();

// system.metrics
void installSystemMetrics();

// system.Platform
void installSystemPlatform();

// system.Debugger
void installSystemDebugger();

// system.utils
void installSystemUtils();

void installPackageSystem()
{
    installSystemObject();
    installSystemString();
    installSystemNumber();

    // Sytem.Reflection
    installSystemReflectionAssembly();
    installSystemReflectionType();

    installSystemBaseDelegate();
    installSystemByteArray();
    installSystemNativeDelegate();
    installSystemBootstrap();
    installSystemConsole();
    installSystemCoroutine();
    installSystemDictionary();
    installSystemFunction();
    installSystemGC();
    installSystemMath();
    installSystemDate();
    installSystemRandom();
    installSystemVector();
    installSystemVM();
    installSystemCommandLine();
    installSystemDebug();
    installSystemProfiler();
    installSystemTelemetry();
    installSystemProcess();
    installSystemSocket();
    installSystemIO();

    // system.utils
    installSystemUtils();

    // system.xml
    installSystemXML();

    // system.JSON
    installSystemJSON();

    // system.metrics
    installSystemMetrics();

    // system.Platform
    installSystemPlatform();

    installSystemDebugger();

    //FIXME: move this
    void installPackageTests();
    installPackageTests();

    void installPackageBenchmark();
    installPackageBenchmark();
}
