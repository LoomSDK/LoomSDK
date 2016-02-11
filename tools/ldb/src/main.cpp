/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

#include <stdio.h>
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platform.h"

#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"

// LoomScript Debugger

using namespace LS;

extern "C" {
void stringtable_initialize();
}

static loom_logGroup_t ldbLogGroup = { "LDB", 1 };

int main(int argc, const char** argv) {

    stringtable_initialize();
    loom_log_initialize();

    NativeDelegate::markMainThread();

    void installPackageSystem();
    installPackageSystem();

    LSLuaState::initCommandLine(argc, argv);

    LSLuaState* debuggerVM = NULL;

    debuggerVM = new LSLuaState();
    debuggerVM->open();

    lmLog(ldbLogGroup,"o executing LDB");
    Assembly* ldbAssembly = debuggerVM->loadExecutableAssembly("../../../libs/LDB.loom");
    ldbAssembly->execute();

    debuggerVM->close();

    return EXIT_SUCCESS;

}
