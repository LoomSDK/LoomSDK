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

#include "l2dQuadBatch.h"
#include "loom/graphics/gfxGraphics.h"

namespace Loom2D
{
Type *QuadBatch::typeQuadBatch = NULL;

void QuadBatch::render(lua_State *L)
{
    // if we have no native texture assigned bail
    if (nativeTextureID == -1)
    {
        return;
    }

    // check the texture info
    GFX::TextureInfo *tinfo = GFX::Texture::getTextureInfo(nativeTextureID);

    if (!tinfo)
    {
        return;
    }

    // update and get our transformation matrix
    updateLocalTransform();

    Matrix mtx;
    getTargetTransformationMatrix(NULL, &mtx);

    GFX::VertexPosColorTex *v   = GFX::QuadRenderer::getQuadVertices(nativeTextureID, 4 * numQuads, true);
    GFX::VertexPosColorTex *src = quadData;

    // apply the parent alpha
    renderState.alpha          = parent ? parent->renderState.alpha * alpha : alpha;
    renderState.cachedClipRect = parent ? parent->renderState.cachedClipRect : (unsigned short)-1;

    GFX::Graphics::setClipRect(renderState.cachedClipRect);

    if (!v)
    {
        return;
    }

    // transform all quads in the batch and submit them to the QuadBatcher
    for (int i = 0; i < numQuads * 4; i++)
    {
        *v = *src;


        float _x = mtx.a * v->x + mtx.c * v->y + mtx.tx;
        float _y = mtx.b * v->x + mtx.d * v->y + mtx.ty;

        v->x = _x;
        v->y = _y;

        // modulate vertex alpha by our DisplayObject alpha setting
        if (renderState.alpha != 1.0f)
        {
            //TODO: LOOM-1624
            float va = ((float)(v->abgr >> 24)) * renderState.alpha;
            v->abgr = ((uint32_t)va << 24) | (v->abgr & 0x00FFFFFF);
        }

        v++;
        src++;
    }
}
}
