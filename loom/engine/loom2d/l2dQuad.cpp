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

#include "loom/engine/loom2d/l2dQuad.h"
#include "loom/engine/loom2d/l2dImage.h"
#include "loom/engine/loom2d/l2dBlendMode.h"
#include "loom/graphics/gfxGraphics.h"
#include "loom/graphics/gfxColor.h"

namespace Loom2D
{
Type *Quad::typeQuad = NULL;

void Quad::updateNativeVertexData(lua_State *L, int index)
{
    int didx = lua_gettop(L);

    index = lua_absindex(L, index);

    // todo: optimize VertexData in script needs to be moved native

    if (nativeVertexDataInvalid)
    {
        nativeVertexDataInvalid = false;

        const char *vmember = imageOrDerived ? "mVertexDataCache" : "mVertexData";

        lualoom_getmember(L, index, vmember);

        lualoom_getmember(L, -1, "mRawData");
        lua_rawgeti(L, -1, LSINDEXVECTOR);

        int rawDataTable = lua_gettop(L);
        int rcounter     = 0;

        tinted = false;

        for (int i = 0; i < 4; i++)
        {
            GFX::VertexPosColorTex *v = &quadVertices[i];
            lua_rawgeti(L, rawDataTable, rcounter++);
            v->x = (float)lua_tonumber(L, -1);
            lua_rawgeti(L, rawDataTable, rcounter++);
            v->y = (float)lua_tonumber(L, -1);

            //printf("%i %f %f\n", i, v->x, v->y);

            v->z = 0.0f;

            GFX::Color c(0);
            lua_rawgeti(L, rawDataTable, rcounter++);
            c.r = (float)lua_tonumber(L, -1);
            lua_rawgeti(L, rawDataTable, rcounter++);
            c.g = (float)lua_tonumber(L, -1);
            lua_rawgeti(L, rawDataTable, rcounter++);
            c.b = (float)lua_tonumber(L, -1);
            lua_rawgeti(L, rawDataTable, rcounter++);
            c.a = (float)lua_tonumber(L, -1);

            // todo: optimize this too:

            v->abgr = c.getHex();

            if(v->abgr != 0x00FFFFFFFF)
                tinted = true;

            lua_rawgeti(L, rawDataTable, rcounter++);
            v->u = (float)lua_tonumber(L, -1);

            lua_rawgeti(L, rawDataTable, rcounter++);
            v->v = (float)lua_tonumber(L, -1);
        }

        lua_settop(L, didx);
    }
}


void Quad::render(lua_State *L)
{
    if (nativeTextureID == -1)
    {
        return;
    }

    GFX::TextureInfo *tinfo = GFX::Texture::getTextureInfo(nativeTextureID);

    if (!tinfo)
    {
        return;
    }

    // if render state has 0.0 alpha, quad batch is invisible so don't render at all and get out of here now!
    renderState.alpha = parent ? parent->renderState.alpha * alpha : alpha;
    renderState.clampAlpha();
    if(renderState.alpha == 0.0f)
    {
        return;
    }

    updateLocalTransform();

    Matrix mtx;
    getTargetTransformationMatrix(NULL, &mtx);

    renderState.clipRect = parent ? parent->renderState.clipRect : Loom2D::Rectangle(0, 0, -1, -1);
    renderState.blendMode = (blendMode == BlendMode::AUTO && parent) ? parent->renderState.blendMode : blendMode;

    unsigned int blendSrc, blendDst;
    BlendMode::BlendFunction(renderState.blendMode, blendSrc, blendDst);

    if (renderState.isClipping()) GFX::Graphics::setClipRect((int)renderState.clipRect.x, (int)renderState.clipRect.y, (int)renderState.clipRect.width, (int)renderState.clipRect.height);

    GFX::VertexPosColorTex *v = GFX::QuadRenderer::getQuadVertexMemory(4, nativeTextureID, blendEnabled, blendSrc, blendDst, shader);
    GFX::VertexPosColorTex *src = quadVertices;

    if (!v)
    {
        return;
    }
    for (int i = 0; i < 4; i++)
    {
        *v = *src;
        src++;

        lmscalar _x = mtx.a * v->x + mtx.c * v->y + mtx.tx;
        lmscalar _y = mtx.b * v->x + mtx.d * v->y + mtx.ty;

        v->x = (float) _x;
        v->y = (float) _y;

        // modulate vertex alpha by our DisplayObject alpha setting
        if (renderState.alpha != 1.0f)
        {
            lmscalar va = ((float)(v->abgr >> 24)) * renderState.alpha;
            v->abgr = ((uint32_t)va << 24) | (v->abgr & 0x00FFFFFF);
        }

        v++;
    }
}
}
