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
#include "loom/script/runtime/lsRuntime.h"

#include "loom/engine/loom2d/l2dDisplayObjectContainer.h"
#include "loom/engine/loom2d/l2dSprite.h"
#include "loom/engine/loom2d/l2dImage.h"
#include "loom/engine/loom2d/l2dQuadBatch.h"
#include "loom/engine/loom2d/l2dBlendMode.h"
#include "loom/graphics/gfxGraphics.h"


namespace Loom2D
{
Type       *DisplayObjectContainer::typeDisplayObjectContainer = NULL;
lua_Number DisplayObjectContainer::childrenOrdinal             = -1;

utArray<DisplayObjectSort> DisplayObjectContainer::sSortBucket;

static int DisplayObjectSortFunction(const void *pidx1, const void *pidx2)
{
    DisplayObjectSort *first  = (DisplayObjectSort *)pidx1;
    DisplayObjectSort *second = (DisplayObjectSort *)pidx2;

    if (first->displayObject->depth == second->displayObject->depth)
    {
        return 0;
    }

    return first->displayObject->depth > second->displayObject->depth ? 1 : -1;
}


static inline void renderType(lua_State *L, Type *type, DisplayObject *dobj)
{
    if (!dobj->visible)
    {
        return;
    }

    // direct descendants of DisplayObject can specifiy a custom render method
    if ((type->getBaseType() == DisplayObject::typeDisplayObject) && dobj->getCustomRenderDelegate()->getCount())
    {
        dobj->getCustomRenderDelegate()->invoke();
    }
    else
    {
        //invoke an onRender method in script if specified, that can do work before the default rendering
        if (dobj->getOnRenderDelegate()->getCount())
        {
            dobj->getOnRenderDelegate()->invoke();
        }
        dobj->render(L);
    }
}


void DisplayObjectContainer::renderChildren(lua_State *L)
{
    if (!visible)
    {
        return;
    }

    // containers can set a new view to render into, but we must restore the
    // current view after, so take a snapshot
/*    int viewRestore = GFX::Graphics::getView();

    // set the current view we will be rendering into.
    if (viewRestore != _view)
    {
        GFX::Graphics::setView(_view);
    } */

    renderState.alpha          = parent ? parent->renderState.alpha * alpha : alpha;
    renderState.clampAlpha();
    renderState.clipRect = parent ? parent->renderState.clipRect : Loom2D::Rectangle(0, 0, -1, -1);
    renderState.blendMode = (parent && blendMode == BlendMode::AUTO) ? parent->renderState.blendMode : blendMode;

    int docidx = lua_gettop(L);

    lua_rawgeti(L, docidx, (int)childrenOrdinal);

    lua_rawgeti(L, -1, LSINDEXVECTOR);
    int childrenVectorIdx = lua_gettop(L);

    int numChildren = lsr_vector_get_length(L, -2);


    if (_depthSort && ((int)sSortBucket.size() < numChildren))
    {
        sSortBucket.resize(numChildren);
    }

    // Is there a cliprect? If so, set it.
    if (clipWidth != -1 && clipHeight != -1)
    {
        GFX::QuadRenderer::submit();

        Matrix    res;
        Rectangle clipBounds = Rectangle((float)clipX, (float)clipY, (float)clipWidth, (float)clipHeight);
        Rectangle clipResult;
        getTargetTransformationMatrix(NULL, &res);
        transformBounds(&res, &clipBounds, &clipResult);

        if (!renderState.isClipping()) {
            renderState.clipRect = Rectangle(clipResult);
        }
        else
        {
            renderState.clipRect.clip(clipResult.x, clipResult.y, clipResult.width, clipResult.height);
        }
    }

    if (renderState.isClipping()) GFX::Graphics::setClipRect((int)renderState.clipRect.x, (int)renderState.clipRect.y, (int)renderState.clipRect.width, (int)renderState.clipRect.height);

    for (int i = 0; i < numChildren; i++)
    {
        lua_rawgeti(L, childrenVectorIdx, i);

        DisplayObject *dobj = (DisplayObject *)lualoom_getnativepointer(L, -1);

        lua_rawgeti(L, -1, LSINDEXTYPE);
        dobj->type = (Type *)lua_topointer(L, -1);
        lua_pop(L, 1);

        dobj->validate(L, lua_gettop(L));

        if (!_depthSort)
        {
            renderType(L, dobj->type, dobj);
        }
        else
        {
            sSortBucket[i].index         = i;
            sSortBucket[i].displayObject = dobj;
        }

        // pop instance
        lua_pop(L, 1);
    }

    if (_depthSort)
    {
        qsort(sSortBucket.ptr(), numChildren, sizeof(DisplayObjectSort), DisplayObjectSortFunction);

        for (int i = 0; i < numChildren; i++)
        {
            DisplayObjectSort *ds = &sSortBucket[i];

            lua_rawgeti(L, childrenVectorIdx, ds->index);

            renderType(L, ds->displayObject->type, ds->displayObject);

            // pop instance
            lua_pop(L, 1);
        }
    }

    lua_settop(L, docidx);

    // Restore clip state.
    if (renderState.isClipping() && (!parent || !parent->renderState.isClipping()))
    {
        GFX::QuadRenderer::submit();
        GFX::Graphics::clearClipRect();
    }

    // restore view
/*    if (viewRestore != _view)
    {
        GFX::Graphics::setView(viewRestore);
    }*/
}
}
