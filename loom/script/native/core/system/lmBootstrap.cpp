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

#include "loom/script/native/lsNative.h"

class Bootstrap {
public:

    static int initialize(lua_State *L)
    {
        return 0;
    }
};

static int registerSystemBootstrap(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<Bootstrap> ("Bootstrap")

       .addStaticLuaFunction("initialize", &Bootstrap::initialize)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemBootstrap()
{
    NativeInterface::registerNativeType<Bootstrap>(registerSystemBootstrap);
}
