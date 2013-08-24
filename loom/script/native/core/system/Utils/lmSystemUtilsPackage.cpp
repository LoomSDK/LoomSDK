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
#include "loom/common/utils/utBase64.h"
#include "loom/common/utils/utByteArray.h"

class LoomBase64 {
public:

    static int encode(lua_State *L)
    {
        if (lua_gettop(L) != 1)
        {
            lua_pushstring(L, "");
            return 1;
        }

        utByteArray *byteArray = (utByteArray *)lualoom_getnativepointer(L, 1, true, "system.ByteArray");

        if (!byteArray || !byteArray->getSize())
        {
            lua_pushstring(L, "");
            return 1;
        }

        utBase64 encoded = utBase64::encode64(*(byteArray->getInternalArray()));

        lua_pushstring(L, encoded.getBase64().c_str());

        return 1;
    }

    static void decode(const char *base64, utByteArray *outArray)
    {
        if (!outArray)
        {
            return;
        }

        outArray->clear();

        if (!base64)
        {
            return;
        }

        utBase64 decoded = utBase64::decode64(base64);

        if (!decoded.getData().size())
        {
            return;
        }

        outArray->allocateAndCopy((void *)decoded.getData().ptr(), decoded.getData().size());
    }
};

static int registerSystemUtils(lua_State *L)
{
    beginPackage(L, "system.utils")

       .beginClass<LoomBase64> ("Base64")

       .addStaticLuaFunction("encode", &LoomBase64::encode)
       .addStaticMethod("decode", &LoomBase64::decode)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemUtils()
{
    LOOM_DECLARE_NATIVETYPE(LoomBase64, registerSystemUtils);
}
