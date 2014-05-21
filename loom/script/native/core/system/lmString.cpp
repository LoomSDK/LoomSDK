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

#include <ctype.h>
#include <string.h>
#include <cstring>
#include "loom/common/utils/md5.h"
#include "loom/common/core/allocator.h"
#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"

class LSString {
public:


    static int format(lua_State *L)
    {
        // unwind the input args
        int nargs = lsr_vector_get_length(L, 2);

        lua_rawgeti(L, 2, LSINDEXVECTOR);
        lua_replace(L, 2);

        for (int i = 0; i < nargs; i++)
        {
            lua_rawgeti(L, 2, i);
        }

        // remove the vector
        lua_remove(L, 2);

        // setup string.format call
        lua_getglobal(L, "string");
        lua_getfield(L, -1, "format");
        lua_insert(L, 1);
        lua_pop(L, 1);

        // call leaving formatted string on stack
        lua_call(L, nargs + 1, 1);

        return 1;
    }

    static int _charAt(lua_State *L)
    {
        lmAssert(lua_isstring(L, 1), "Non-string passed to String._charAt");

        const char *svalue = lua_tostring(L, 1);
        int        index   = (int)lua_tonumber(L, 2);

        if (!svalue || !svalue[0] || (index < 0) || (index >= (int)strlen(svalue)))
        {
            lua_pushstring(L, "");
            return 1;
        }

        char returnValue[2];
        returnValue[0] = svalue[index];
        returnValue[1] = 0;

        lua_pushstring(L, returnValue);

        return 1;
    }

    static int _charCodeAt(lua_State *L)
    {
        lmAssert(lua_isstring(L, 1), "Non-string passed to String._charCodeAt");

        const char *svalue = lua_tostring(L, 1);
        int        index   = (int)lua_tonumber(L, 2);

        if (!svalue || !svalue[0] || (index < 0) || (index >= (int)strlen(svalue)))
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        lua_pushnumber(L, (double)svalue[index]);

        return 1;
    }

    static int fromCharCode(lua_State *L)
    {
        lmAssert(lua_isnumber(L, 1), "Non-number passed to String.fromCharCode");

        char svalue[2];
        svalue[0] = (char)lua_tonumber(L, 1);
        svalue[1] = 0;

        lua_pushstring(L, svalue);

        return 1;
    }

    static int _length(lua_State *L)
    {
        const char *svalue = lua_tostring(L, 1);

        if (!svalue)
        {
            lua_pushnumber(L, 0);
        }
        else
        {
            lua_pushnumber(L, strlen(svalue));
        }
        return 1;
    }

    static int _toUpperCase(lua_State *L)
    {
        const char *svalue = lua_tostring(L, 1);

        if (!svalue || (strlen(svalue) <= 0))
        {
            lua_pushstring(L, "");
        }
        else
        {
            int  length = strlen(svalue);
            char *upper = new char[length + 1];
            upper[length] = 0;
            for (int i = 0; i < length; i++)
            {
                upper[i] = toupper(svalue[i]);
            }

            lua_pushstring(L, upper);

            delete [] upper;
        }

        return 1;
    }

    static int _toLowerCase(lua_State *L)
    {
        const char *svalue = lua_tostring(L, 1);

        if (!svalue || (strlen(svalue) <= 0))
        {
            lua_pushstring(L, "");
        }
        else
        {
            int  length = strlen(svalue);
            char *lower = new char[length + 1];
            lower[length] = 0;
            for (int i = 0; i < length; i++)
            {
                lower[i] = tolower(svalue[i]);
            }

            lua_pushstring(L, lower);

            delete [] lower;
        }

        return 1;
    }

    static int _indexOf(lua_State *L)
    {
        const char *svalue    = lua_tostring(L, 1);
        const char *search    = lua_tostring(L, 2);
        int        startIndex = (int)lua_tonumber(L, 3);

        if (!svalue || !svalue[0] || !search || !search[0])
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        const char *start = &svalue[startIndex];

        if (start - svalue >= (int)strlen(svalue))
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        const char *found = strstr(start, search);

        if (!found)
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        lua_pushnumber(L, found - svalue);
        return 1;
    }

    static int _lastIndexOf(lua_State *L)
    {
        const char *svalue    = lua_tostring(L, 1);
        const char *search    = lua_tostring(L, 2);
        int        startIndex = (int)lua_tonumber(L, 3);

        if (!svalue || !svalue[0] || !search || !search[0])
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        if (startIndex < 0)
        {
            startIndex = strlen(svalue);
        }

        int searchLength = strlen(search);

        while (startIndex >= 0)
        {
            if (!strncmp(&svalue[startIndex], search, searchLength))
            {
                lua_pushnumber(L, startIndex);
                return 1;
            }

            startIndex--;
        }

        lua_pushnumber(L, -1);
        return 1;
    }

    static int _concat(lua_State *L)
    {
        utString value = lua_tostring(L, 1);

        lua_rawgeti(L, 2, LSINDEXVECTOR);
        int length = lsr_vector_get_length(L, 2);

        for (int i = 0; i < length; i++)
        {
            lua_pushnumber(L, i);
            lua_rawget(L, -2);
            value += lsr_objecttostring(L, -1);
            lua_pop(L, 1);
        }

        lua_pushstring(L, value.c_str());

        return 1;
    }

    static int _substr(lua_State *L)
    {
        const char *svalue    = lua_tostring(L, 1);
        int        startIndex = (int)lua_tonumber(L, 2);
        int        len        = (int)lua_tonumber(L, 3);

        if (!svalue || !svalue[0])
        {
            lua_pushstring(L, "");
            return 1;
        }

        int slength = (int)strlen(svalue);

        char *nvalue = new char[slength + 1];
        memset(nvalue, 0, slength + 1);

        if ((len < 0) || (len > slength))
        {
            len = slength;
        }

        for (int i = 0; i < len; i++)
        {
            if ((startIndex + i >= slength) || !svalue[startIndex + i])
            {
                break;
            }

            nvalue[i] = svalue[startIndex + i];
        }

        lua_pushstring(L, nvalue);

        delete [] nvalue;

        return 1;
    }

    static int _substring(lua_State *L)
    {
        const char *svalue    = lua_tostring(L, 1);
        int        startIndex = (int)lua_tonumber(L, 2);
        int        endIndex   = (int)lua_tonumber(L, 3);

        if (!svalue || !svalue[0])
        {
            lua_pushstring(L, "");
            return 1;
        }

        int len = strlen(svalue);

        char *nbuffer = new char[len + 1];

        if (startIndex < 0)
        {
            startIndex = 0;
        }
        else if (startIndex > len)
        {
            startIndex = len;
        }

        if (endIndex < 0)
        {
            endIndex = len;
        }

        if (endIndex > len)
        {
            endIndex = len;
        }

        memcpy(nbuffer, &svalue[startIndex], endIndex - startIndex);
        nbuffer[endIndex - startIndex] = 0;

        lua_pushstring(L, nbuffer);

        delete [] nbuffer;

        return 1;
    }

    static int _slice(lua_State *L)
    {
        const char *svalue    = lua_tostring(L, 1);
        int        startIndex = (int)lua_tonumber(L, 2);
        int        endIndex   = (int)lua_tonumber(L, 3);

        if (!svalue || !svalue[0])
        {
            lua_pushstring(L, "");
            return 1;
        }

        int svalueLength = strlen(svalue);

        if (endIndex >= svalueLength)
        {
            endIndex = svalueLength;
        }

        else if (endIndex == -1)
        {
            endIndex = svalueLength - (-(endIndex + 1));
        }

        if (startIndex >= svalueLength)
        {
            lua_pushstring(L, "");
            return 1;
        }

        char *nvalue = new char[svalueLength + 1];
        memset(nvalue, 0, svalueLength + 1);

        for (int i = startIndex; i < endIndex; i++)
        {
            nvalue[i - startIndex] = svalue[i];
        }

        lua_pushstring(L, nvalue);

        delete [] nvalue;

        return 1;
    }

    static int _toNumber(lua_State *L)
    {
        lmAssert(lua_isstring(L, 1), "Non-string passed to String._toNumber");

        const char *svalue = lua_tostring(L, 1);

        // if it is null or empty return -1
        if (!svalue || !svalue[0])
        {
            lua_pushnumber(L, -1);
            return 1;
        }

        float f;
        if (sscanf(svalue, "%f", &f) == 1)
        {
            lua_pushnumber(L, f);
        }
        else
        {
            lua_pushnumber(L, -1);
        }

        return 1;
    }

    static int _toBoolean(lua_State *L)
    {
        lmAssert(lua_isstring(L, 1), "Non-string passed to String._toBoolean");

        const char *svalue = lua_tostring(L, 1);

        if (!svalue || !svalue[0])
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        if (strcasecmp(svalue, "true") == 0)
        {
            lua_pushboolean(L, 1);
        }
        else
        {
            lua_pushboolean(L, 0);
        }

        return 1;
    }

    static int _toMD5(lua_State *L)
    {
        lmAssert(lua_isstring(L, 1), "Non-string passed to String._toMD5");

        const char *svalue = lua_tostring(L, 1);

        if (!svalue || !svalue[0])
        {
            lua_pushstring(L, "");
            return 1;
        }

        lua_pushstring(L, mdfive(svalue).c_str());
        return 1;
    }    

    static int _find(lua_State *L)
    {
        lua_getglobal(L, "string");
        lua_getfield(L, -1, "find");

        int top = lua_gettop(L);
        lua_pushvalue(L, 1);
        lua_pushvalue(L, 2);
        lua_call(L, 2, LUA_MULTRET);

        int retIdx = lua_gettop(L);
        int nret   = (retIdx - top) + 1;

        // skip the found number indexes
        retIdx = top + 2;
        nret  -= 2;

        // not found
        if ((nret == 1) && lua_isnil(L, -1))
        {
            return 1;
        }

        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");
        lsr_createinstance(L, vectorType);
        int newVectorIdx = lua_gettop(L);
        lua_rawgeti(L, newVectorIdx, LSINDEXVECTOR);

        int newVectorTbl = lua_gettop(L);

        int scount = 0;
        for (int i = 0; i < nret; i++)
        {
            if (!lua_isstring(L, retIdx + i))
            {
                continue;
            }

            lua_pushnumber(L, scount++);
            lua_pushvalue(L, retIdx + i);
            lua_rawset(L, newVectorTbl);
        }

        lsr_vector_set_length(L, newVectorIdx, scount);

        lua_pushvalue(L, newVectorIdx);

        return 1;
    }

    static int _split(lua_State *L)
    {
        char       *str   = (char *)lua_tostring(L, 1);
        const char *delim = lua_tostring(L, 2);

        if (!str || !str[0])
        {
            str = "";
        }

        if (!delim || !delim[0])
        {
            delim = "";
        }


        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");
        lsr_createinstance(L, vectorType);
        int newVectorIdx = lua_gettop(L);

        lua_rawgeti(L, newVectorIdx, LSINDEXVECTOR);

        int count = 0;
        int dlen  = strlen(delim);
        int slen  = strlen(str);

        // handle the case of "", delim, ...
        if (!strncmp(str, delim, dlen))
        {
            lua_pushnumber(L, count++);
            lua_pushstring(L, "");
            lua_rawset(L, -3);
        }

        char *start = str;
        char *found;
        char *temp = (char*) lmAlloc(NULL, slen + 1);
        do {
            found = strstr(start, delim);

            if (found)
            {
                if (found - start > 0)
                {
                    memcpy(temp, start, found - start);
                    temp[found - start] = 0;
                    lua_pushnumber(L, count++);
                    lua_pushstring(L, temp);
                    lua_rawset(L, -3);
                }

                start = found + dlen;
            }
            
        } while (found);        

        if (start - str < slen)
        {
            strncpy(temp, start, slen + 1);
            lua_pushnumber(L, count++);
            lua_pushstring(L, temp);
            lua_rawset(L, -3);            
        }

        lmFree(NULL, temp);

        // handle the case of ..., delta, ""
        if (slen >= dlen)
        {
            if (!strncmp(&str[slen - dlen], delim, dlen))
            {
                lua_pushnumber(L, count++);
                lua_pushstring(L, "");
                lua_rawset(L, -3);
            }
        }

        lsr_vector_set_length(L, newVectorIdx, count);

        lua_settop(L, newVectorIdx);
        return 1;
    }
};


static int registerSystemString(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<LSString> ("String")

       .addStaticLuaFunction("fromCharCode", &LSString::fromCharCode)

    // transforms static calls
       .addStaticLuaFunction("_charAt", &LSString::_charAt)
       .addStaticLuaFunction("_charCodeAt", &LSString::_charCodeAt)
       .addStaticLuaFunction("_length", &LSString::_length)
       .addStaticLuaFunction("_toUpperCase", &LSString::_toUpperCase)
       .addStaticLuaFunction("_toLowerCase", &LSString::_toLowerCase)
       .addStaticLuaFunction("_toLocaleUpperCase", &LSString::_toUpperCase)
       .addStaticLuaFunction("_toLocaleLowerCase", &LSString::_toLowerCase)
       .addStaticLuaFunction("_indexOf", &LSString::_indexOf)
       .addStaticLuaFunction("_lastIndexOf", &LSString::_lastIndexOf)
       .addStaticLuaFunction("_concat", &LSString::_concat)
       .addStaticLuaFunction("_slice", &LSString::_slice)
       .addStaticLuaFunction("_substr", &LSString::_substr)
       .addStaticLuaFunction("_substring", &LSString::_substring)
       .addStaticLuaFunction("_toNumber", &LSString::_toNumber)
       .addStaticLuaFunction("_toBoolean", &LSString::_toBoolean)
       .addStaticLuaFunction("_toMD5", &LSString::_toMD5)
       .addStaticLuaFunction("_find", &LSString::_find)
       .addStaticLuaFunction("_split", &LSString::_split)
       .addStaticLuaFunction("format", &LSString::format)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemString()
{
    NativeInterface::registerNativeType<LSString>(registerSystemString);
}
