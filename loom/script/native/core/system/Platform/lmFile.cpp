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

#include "loom/common/core/allocator.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/platform/platformFile.h"

#include "loom/script/loomscript.h"

#include <string.h>

class File
{
protected:


public:


    static int fileExists(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        lua_pushboolean(L, platform_mapFileExists(lua_tostring(L, 1)));

        return 1;
    }

    static int writeTextFile(lua_State *L)
    {
        if (!lua_isstring(L, 1) || !lua_isstring(L, 2))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        const char *path = lua_tostring(L, 1);
        const char *data = lua_tostring(L, 2);

        int sz = (int)strlen(data);

        lua_pushboolean(L, !platform_writeFile(path, (void *)data, sz));

        return 1;
    }

    static int removeFile(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        lua_pushboolean(L, !platform_removeFile(lua_tostring(L, 1)));

        return 1;
    }

    static int moveFile(lua_State *L)
    {
        if (!lua_isstring(L, 1) || !lua_isstring(L, 2))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        lua_pushboolean(L, !platform_moveFile(lua_tostring(L, 1), lua_tostring(L, 2)));

        return 1;
    }

    static int writeBinaryFile(lua_State *L)
    {
        if (!lua_isstring(L, 1) || !lualoom_checkinstancetype(L, 2, "system.ByteArray"))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        utByteArray *byteArray = (utByteArray *)lualoom_getnativepointer(L, 2);

        const char *path = lua_tostring(L, 1);

        lua_pushboolean(L, !platform_writeFile(path, (void *)byteArray->getDataPtr(), (int)byteArray->getSize()));

        return 1;
    }

    static int loadTextFile(lua_State *L)
    {
        void *ptr;
        void *dataBuffer;
        long size;

        if (!lua_isstring(L, 1))
        {
            lua_pushnil(L);
            return 1;
        }

        const char *path = lua_tostring(L, 1);

        if (!platform_mapFile(path, &ptr, &size))
        {
            lua_pushnil(L);
            return 1;
        }

        dataBuffer = lmAlloc(NULL, size + 1);
        memcpy(dataBuffer, ptr, size);
        ((char *)dataBuffer)[size] = 0;

        platform_unmapFile(ptr);

        lua_pushstring(L, (const char *)dataBuffer);

        lmFree(NULL, dataBuffer);

        return 1;
    }

    static int loadBinaryFile(lua_State *L)
    {
        void *ptr;
        long size;

        if (!lua_isstring(L, 1))
        {
            lua_pushnil(L);
            return 1;
        }

        const char *path = lua_tostring(L, 1);

        if (!platform_mapFile(path, &ptr, &size))
        {
            lua_pushnil(L);
            return 1;
        }

        utByteArray *ba = lmNew(NULL) utByteArray();

        ba->allocateAndCopy(ptr, size);

        platform_unmapFile(ptr);

        lualoom_pushnative<utByteArray>(L, ba);

        return 1;
    }
};

class Path {
public:

    static int getWritablePath(lua_State *L)
    {
        lua_pushstring(L, platform_getWritablePath());
        return 1;
    }

    static int normalizePath(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushstring(L, "");
            return 1;
        }

        static char normalized[4096];
        strncpy(normalized, lua_tostring(L, 1), sizeof(normalized));
        platform_normalizePath(normalized);
        lua_pushstring(L, normalized);

        return 1;
    }

    static int makeDir(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        lua_pushboolean(L, !platform_makeDir(lua_tostring(L, 1)));

        return 1;
    }

    static int dirExists(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        lua_pushboolean(L, !platform_dirExists(lua_tostring(L, 1)));

        return 1;
    }

    static int removeDir(lua_State *L)
    {
        if (!lua_isstring(L, 1))
        {
            lua_pushboolean(L, 0);
            return 1;
        }

        lua_pushboolean(L, !platform_removeDir(lua_tostring(L, 1)));

        return 1;
    }

    static void walkFilesCB(const char *filename, void *payload)
    {
        utArray<utString> *files = (utArray<utString> *)payload;
        files->push_back(filename);
    }

    static int walkFiles(lua_State *L)
    {
        if (!lua_isstring(L, 1) || !(lua_isfunction(L, 2) || lua_iscfunction(L, 2)))
        {
            return 0;
        }

        utArray<utString> files;

        platform_walkFiles(lua_tostring(L, 1), walkFilesCB, (void *)&files);

        for (UTsize i = 0; i < files.size(); i++)
        {
            int top = lua_gettop(L);

            // push function
            lua_pushvalue(L, 2);
            lua_pushstring(L, files.at(i).c_str());
            lua_pushvalue(L, 3);
            lua_call(L, 2, 0);

            lua_settop(L, top);
        }

        return 0;
    }

    static int getFolderDelimiter(lua_State *L)
    {
        lua_pushstring(L, platform_getFolderDelimiter());
        return 1;
    }
};


static int _registerSystemPlatform(lua_State *L)
{
    beginPackage(L, "system.platform")

       .beginClass<File>("File")
       .addConstructor<void (*)(void)>()
       .addStaticLuaFunction("_loadTextFile", &File::loadTextFile)
       .addStaticLuaFunction("_loadBinaryFile", &File::loadBinaryFile)
       .addStaticLuaFunction("_writeTextFile", &File::writeTextFile)
       .addStaticLuaFunction("_writeBinaryFile", &File::writeBinaryFile)
       .addStaticLuaFunction("_fileExists", &File::fileExists)
       .addStaticLuaFunction("_removeFile", &File::removeFile)
       .addStaticLuaFunction("_moveFile", &File::moveFile)
       .endClass()

       .beginClass<Path>("Path")
       .addStaticLuaFunction("getWritablePath", &Path::getWritablePath)
       .addStaticLuaFunction("getFolderDelimiter", &Path::getFolderDelimiter)
       .addStaticLuaFunction("_makeDir", &Path::makeDir)
       .addStaticLuaFunction("normalizePath", &Path::normalizePath)
       .addStaticLuaFunction("_dirExists", &Path::dirExists)
       .addStaticLuaFunction("_removeDir", &Path::removeDir)
       .addStaticLuaFunction("_walkFiles", &Path::walkFiles)
       .endClass()

       .endPackage();

    return 0;
}


void installSystemPlatformFile()
{
    LOOM_DECLARE_NATIVETYPE(File, _registerSystemPlatform);
    LOOM_DECLARE_NATIVETYPE(Path, _registerSystemPlatform);
}
