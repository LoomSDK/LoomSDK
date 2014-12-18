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


#include <stdio.h>

#include "loom/script/loomscript.h"
#include "loom/script/native/core/system/lmConsole.h"

using namespace LS;


int Console::print(lua_State *L)
{
    // get the varargs vector length
    int length = lsr_vector_get_length(L, 1);

    // get the varargs table
    lua_rawgeti(L, 1, LSINDEXVECTOR);
    int vidx = lua_gettop(L);

    // the value to print (concating all objects passed)
    utString toprint;

    for (int i = 0; i < length; i++)
    {
        const char *s = NULL;

        // get vararg[i]
        lua_rawgeti(L, vidx, i);

        // coerce to string
        if (lua_isnil(L, -1))
        {
            s = "null";
        }
        else
        {
            s = lsr_objecttostring(L, -1);
        }

        lua_pop(L, 1); /* pop value */

        if (s == NULL)
        {
            return luaL_error(L, LUA_QL("tostring") " must return a string to "
                              LUA_QL("print"));
        }

        // concat
        toprint += s;

        // truncate to 2000 characters
        if (strlen(toprint.c_str()) > 2000)
        {
            break;
        }

        if (i != length - 1)
        {
            toprint += " ";
        }
    }

    /*
    length = strlen(toprint.c_str());
    char buff[2048];
    memset(buff, 0, 2048);
    memcpy(buff, toprint.c_str(), length > 2000 ? 2000 : length);
    */

    // print to log
    LSLog(LSLogError, "%s", toprint.c_str());

    return 0;
}


static int registerSystemConsole(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<Console> ("Console")

       .addStaticLuaFunction("print", &Console::print)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemConsole()
{
    NativeInterface::registerNativeType<Console>(registerSystemConsole);
}
