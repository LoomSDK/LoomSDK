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

#include "loom/common/utils/utTypes.h"
#include "loom/engine/loom2d/l2dDisplayObject.h"

namespace Loom2D
{
struct DisplayObjectSort
{
    DisplayObject *displayObject;
    int           index;
};

class DisplayObjectContainer : public DisplayObject
{
    static utArray<DisplayObjectSort> sSortBucket;

public:

    DisplayObjectContainer()
    {
        type       = typeDisplayObjectContainer;
        _depthSort = false;
        _view      = 0;
        clipX      = clipY = 0;
        clipWidth  = clipHeight = -1;
    }

    bool _depthSort;

    inline bool getDepthSort() const
    {
        return _depthSort;
    }

    inline void setDepthSort(bool value)
    {
        _depthSort = value;
    }

    // DisplayObjectContainers may specify a view which their children
    // will render into
    int _view;

/*    inline int getView() const
    {
        return _view;
    }

    inline void setView(int value)
    {
        _view = value;
    } */

    int clipX, clipY, clipWidth, clipHeight;

    void setClipRect(int _clipX, int _clipY, int _clipWidth, int _clipHeight)
    {
        clipX      = _clipX;
        clipY      = _clipY;
        clipWidth  = _clipWidth;
        clipHeight = _clipHeight;
    }

    static Type       *typeDisplayObjectContainer;
    static lua_Number childrenOrdinal;

    void renderChildren(lua_State *L);

    void render(lua_State *L)
    {
        updateLocalTransform();

        lualoom_pushnative<DisplayObjectContainer>(L, this);
        renderChildren(L);
        lua_pop(L, 1);
    }

    static void initialize(lua_State *L)
    {
        typeDisplayObjectContainer = LSLuaState::getLuaState(L)->getType("loom2d.display.DisplayObjectContainer");
        lmAssert(typeDisplayObjectContainer, "unable to get loom2d.display.DisplayObjectContainer type");
        childrenOrdinal = typeDisplayObjectContainer->getMemberOrdinal("mChildren");
    }
};
}
