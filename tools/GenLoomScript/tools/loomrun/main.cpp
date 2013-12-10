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

#include "loom/script/loomscript.h"

using namespace LS;

static utString   assemblyPath  = "./bin/Main.loom";
static Assembly   *execAssembly = NULL;

static void executeAssembly()
{
    LSLuaState* execState = lsr_getexecstate();
    lmAssert(execState, "null execState");

    execAssembly = execState->loadExecutableAssembly(assemblyPath.c_str(), true);

    // first see if we have a static main
    MethodInfo *smain = execAssembly->getStaticMethodInfo("main");
    if (smain)
    {
        //GO!
        smain->invoke(NULL, 0);
    }

}

int main(int argc, const char **argv)
{
    // look for passing a .loom file
    for (int i = 1; i < argc; i++ )
    {
        if (strstr(argv[i], ".loom"))
        {
            assemblyPath = argv[i];
            break;
        }
    }

    lsr_loomscript_open(argc, argv);
    executeAssembly();
    lsr_loomscript_close();
}
