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

#include "loom/common/core/assert.h"
#include "loom/engine/loom2d/l2dDisplayObject.h"
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"
#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/graphics/gfxShader.h"

namespace Loom2D
{
class Quad : public DisplayObject
{
public:

    GFX::VertexPosColorTex quadVertices[4];
    GFX::Shader* shader;

    bool nativeVertexDataInvalid;
    bool tinted;

    int nativeTextureID;

    Quad()
    {
        type = typeQuad;
        tinted = false;
        shader = GFX::Shader::getDefaultShader();
    }

    int getNativeTextureID() const
    {
        return (int)nativeTextureID;
    }

    void setNativeTextureID(int value)
    {
        nativeTextureID = value;
    }

    inline bool getNativeVertexDataInvalid() const
    {
        return nativeVertexDataInvalid;
    }

    inline void setNativeVertexDataInvalid(bool value)
    {
        nativeVertexDataInvalid = value;
    }

    void setShader(GFX::Shader* sh)
    {
        shader = sh;
    }

    GFX::Shader* getShader() const
    {
        return shader;
    }

    virtual void validate(lua_State *L, int index)
    {
        int top = lua_gettop(L);

        index = lua_absindex(L, index);

        if (!valid)
        {
            // call script validate method

            // OPTIMIZE ORDINAL!
            lualoom_getmember(L, index, "validate");
            lua_call(L, 0, 0);
            valid = true;
        }

        if (nativeVertexDataInvalid)
        {
            updateNativeVertexData(L, index);
        }

        lmAssert(top == lua_gettop(L), "misaligned stack");
    }

    void updateNativeVertexData(lua_State *L, int index);

    static Type *typeQuad;

    static void initialize(lua_State *L)
    {
        typeQuad = LSLuaState::getLuaState(L)->getType("loom2d.display.Quad");
        lmAssert(typeQuad, "unable to get loom2d.display.Quad type");
    }

    void render(lua_State *L);
};
}
