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


#include "loom/script/native/lsLuaBridge.h"

using namespace LS;

class GC {
public:
    static int collect(lua_State *L)
    {
        lua_gc(L, (int)lua_tonumber(L, 1), (int)lua_tonumber(L, 2));

        return 0;
    }
};

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


       .endClass()

       .endPackage();

    return 0;
}


void installSystemGC()
{
    NativeInterface::registerNativeType<GC>(registerSystemGC);
}
