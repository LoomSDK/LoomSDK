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

#pragma once

#include "loom/engine/loom2d/l2dQuad.h"

namespace Loom2D
{
class Image : public Quad
{
public:

    static Type       *typeImage;
    static lua_Number mVertexDataCacheInvalidOrdinal;

    static void initialize(lua_State *L)
    {
        typeImage = LSLuaState::getLuaState(L)->getType("loom2d.display.Image");
        lmAssert(typeImage, "unable to get loom2d.display.Image type");
        mVertexDataCacheInvalidOrdinal = typeImage->getMemberOrdinal("mVertexDataCacheInvalid");
    }

    Image()
    {
        type           = typeImage;
        imageOrDerived = true;
    }

    virtual void validate(lua_State *L, int index)
    {
        int top = lua_gettop(L);

        index = lua_absindex(L, index);

        // note: doesn't call Quad::validate as we need to possibly call updateVertexData
        // before updating the native vertex data

        if (!valid)
        {
            // call script validate method

            // OPTIMIZE ORDINAL!
            lualoom_getmember(L, index, "validate");
            lua_call(L, 0, 0);
            valid = true;
        }

        lua_rawgeti(L, index, (int)Image::mVertexDataCacheInvalidOrdinal);

        if (lua_toboolean(L, -1))
        {
            lualoom_getmember(L, index, "updateVertexData");
            lua_call(L, 0, 0);
        }

        lua_pop(L, 1);


        if (nativeVertexDataInvalid)
        {
            updateNativeVertexData(L, index);
        }

        lmAssert(top == lua_gettop(L), "misaligned stack");
    }

    inline void render(lua_State *L)
    {
        if (nativeTextureID == -1)
        {
            return;
        }

        Quad::render(L);
    }
};
}
