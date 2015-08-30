/*
* ===========================================================================
* Loom SDK
* Copyright 2011, 2012, 2013, 2015
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
#include <ctime>

using namespace LS;

class Date {
private:
    // The buffer size when returning string data
    static const int BUFFER_SIZE = 1024;

public:
    static const char *formatTime(const char *format)
    {
        time_t rawtime;
        struct tm *timeinfo;
        char buffer[BUFFER_SIZE];

        time(&rawtime);
        timeinfo = localtime(&rawtime);

        strftime(buffer, BUFFER_SIZE, format, timeinfo);
        
        // The buffer must be converted into a const char* before returning
        const char *retString = buffer;

        return retString;
    }
};

static int registerSystemDate(lua_State *L)
{
    beginPackage(L, "system")

        .beginClass<Date>("Date")

        .addStaticMethod("formatTime", &Date::formatTime)

        .endClass()

        .endPackage();

    return 0;
}

void installSystemDate()
{
    NativeInterface::registerNativeType<Date>(registerSystemDate);
}
