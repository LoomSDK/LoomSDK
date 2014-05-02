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

#include "loom/graphics/gfxQuadRenderer.h"
#include "loom/engine/loom2d/l2dDisplayObject.h"
#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"
#include "loom/engine/loom2d/l2dQuad.h"
#include "loom/engine/loom2d/l2dImage.h"
#include "loom/engine/loom2d/l2dRectangle.h"

namespace Loom2D
{
#define DEFAULT_QUADS    32

// Native side of the QuadBatch script class
class QuadBatch : public DisplayObject
{
public:

    // static type cache
    static Type *typeQuadBatch;

    // initialize type information
    static void initialize(lua_State *L)
    {
        typeQuadBatch = LSLuaState::getLuaState(L)->getType("loom2d.display.QuadBatch");
        lmAssert(typeQuadBatch, "unable to get loom2d.display.QuadBatch type");
    }

    // allocated quad vertex data, up to 4 * maxQuads
    GFX::VertexPosColorTex *quadData;

    // total number of quads allocated
    int maxQuads;

    // the current Quad insertion point
    int numQuads;

    // the native texture id used by this batch
    int nativeTextureID;

    // renders the QuadBatch
    void render(lua_State *L);

    // retrieves the number of quads currently rendered by the batch
    inline int getNumQuads() const
    {
        return numQuads;
    }

    QuadBatch()
    {
        type            = typeQuadBatch;
        quadData        = NULL;
        maxQuads        = 0;
        numQuads        = 0;
        nativeTextureID = -1;
    }

    ~QuadBatch()
    {
        if (quadData)
        {
            lmFree(NULL, quadData);
        }
    }

    // property accessors for native texture id
    int getNativeTextureID() const
    {
        return (int)nativeTextureID;
    }

    void setNativeTextureID(int value)
    {
        nativeTextureID = value;
    }

    // resets the quad count (but does not free memory)
    int reset(lua_State *L)
    {
        numQuads = 0;
        return 0;
    }

    // gets the bounding rectangle of the quadbatch
    int _getBounds(lua_State *L)
    {
        DisplayObject *targetSpace = NULL;

        // check if we're given a DisplayObject to use as target space
        if (!lua_isnil(L, 2))
        {
            targetSpace = (DisplayObject *)lualoom_getnativepointer(L, 2);
        }

        // get the Rectangle to store the bounds into
        Rectangle *resultRect = (Rectangle *)lualoom_getnativepointer(L, 3);

        // transform to target space
        Matrix mtx;
        getTargetTransformationMatrix(targetSpace, &mtx);

        float minx = 1000000;
        float maxx = -1000000;

        float miny = 1000000;
        float maxy = -1000000;


        // calculate bounding rect
        for (int i = 0; i < numQuads; i++)
        {
            GFX::VertexPosColorTex *v = &quadData[i * 4];

            for (int j = 0; j < 4; j++)
            {
                float x = mtx.a * v->x + mtx.c * v->y + mtx.tx;
                float y = mtx.b * v->x + mtx.d * v->y + mtx.ty;

                if (x < minx)
                {
                    minx = x;
                }

                if (x > maxx)
                {
                    maxx = x;
                }

                if (y < miny)
                {
                    miny = y;
                }

                if (y > maxy)
                {
                    maxy = y;
                }

                v++;
            }
        }

        resultRect->x      = minx;
        resultRect->y      = miny;
        resultRect->width  = maxx - minx;
        resultRect->height = maxy - miny;

        return 0;
    }

    // adds a quad to the QuadBatch
    int _addQuad(lua_State *L)
    {
        // get the infos off the stack
        Quad *quad = (Quad *)lualoom_getnativepointer(L, 2);

        Matrix *modelViewMatrix = (Matrix *)lualoom_getnativepointer(L, 3);

        nativeTextureID = quad->nativeTextureID;

        quad->validate(L, 2);

        // check whether we need to allocate more quad storage
        if (numQuads == maxQuads)
        {
            if (maxQuads == 0)
            {
                maxQuads = DEFAULT_QUADS;
            }
            else
            {
                maxQuads *= 2;
            }

            GFX::VertexPosColorTex *newData = (GFX::VertexPosColorTex *)lmAlloc(NULL, sizeof(GFX::VertexPosColorTex) * 4 * maxQuads);

            if (quadData)
            {
                memcpy(newData, quadData, (numQuads) * (sizeof(GFX::VertexPosColorTex) * 4));
                lmFree(NULL, quadData);
            }

            quadData = newData;
        }

        // ... and add the (transformed) quad data to the batch
        GFX::VertexPosColorTex *dst = &quadData[numQuads * 4];
        GFX::VertexPosColorTex *src = quad->quadVertices;
        bool isIdentity = modelViewMatrix->isIdentity();
        for (int i = 0; i < 4; i++)
        {
            *dst = *src;

            //only do transform if matrix is not identity matrix
            if(!isIdentity)
            {
                float _x = modelViewMatrix->a * dst->x + modelViewMatrix->c * dst->y + modelViewMatrix->tx;
                float _y = modelViewMatrix->b * dst->x + modelViewMatrix->d * dst->y + modelViewMatrix->ty;

                dst->x = _x;
                dst->y = _y;
            }

            dst++;
            src++;
        }

        numQuads++;

        return 0;
    }
};
}
