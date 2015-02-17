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

#include "lmProcess.h"

#include "loom/script/native/lsLuaBridge.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
#include <Windows.h>
#endif

extern "C" {
    void loom_appShutdown();
}

bool LS::Process::consoleAttached = false;
void LS::Process::cleanupConsole()
{
#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32
    if (consoleAttached) {
        LRESULT res;
        HWND hConsole = GetConsoleWindow();
        res = PostMessage(hConsole, WM_KEYDOWN, VK_RETURN, 1);
        res = PostMessage(hConsole, WM_KEYUP, VK_RETURN, 0xC0000001);
    }
#endif
}
void LS::Process::_exit(int exitCode)
{
    cleanupConsole();
    exit(exitCode);
}

namespace LS {
    static int registerSystemProcess(lua_State *L)
    {
        beginPackage(L, "system")

            .beginClass<Process>("Process")

            .addStaticMethod("exit", &Process::_exit)


            .endClass()

            .endPackage();

        return 0;
    }
}

void installSystemProcess()
{
    LS::NativeInterface::registerNativeType<LS::Process>(LS::registerSystemProcess);
}