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

#include <time.h>
#include "loom/script/loomscript.h"
#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformDisplay.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformThread.h"

static float _forceDPI = -1.f;

class Platform {
public:

    static int getTime(lua_State *L)
    {
        lua_pushnumber(L, platform_getMilliseconds());

        return 1;
    }

    static int getEpochTime()
    {
        return (unsigned int)time(NULL);
    }

    static int getPlatform()
    {
        return LOOM_PLATFORM;
    }

    static int getProfile()
    {
        return display_getProfile();
    }

    static float getDPI()
    {
        if (_forceDPI != -1.f)
        {
            return _forceDPI;
        }

        return display_getDPI();
    }

    static void forceDPI(float value)
    {
        _forceDPI = value;
    }

    static bool isForcingDPI()
    {
        return _forceDPI != -1.f;
    }

    static void sleep(int sleepTime)
    {
        loom_thread_sleep(sleepTime);
    }
};

static int registerSystemPlatform(lua_State *L)
{
    beginPackage(L, "system.platform")

       .beginClass<Platform> ("Platform")

       .addStaticLuaFunction("getTime", &Platform::getTime)
       .addStaticMethod("getEpochTime", &Platform::getEpochTime)
       .addStaticMethod("getPlatform", &Platform::getPlatform)
       .addStaticMethod("getProfile", &Platform::getProfile)
       .addStaticMethod("getDPI", &Platform::getDPI)
       .addStaticMethod("forceDPI", &Platform::forceDPI)
       .addStaticMethod("isForcingDPI", &Platform::isForcingDPI)
       .addStaticMethod("sleep", &Platform::sleep)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemPlatformFile();
void installSystemPlatformGamepad();

void installSystemPlatform()
{
    LOOM_DECLARE_NATIVETYPE(Platform, registerSystemPlatform);
    installSystemPlatformFile();
#ifndef LOOMSCRIPT_STANDALONE    
    installSystemPlatformGamepad();
#endif    
}
