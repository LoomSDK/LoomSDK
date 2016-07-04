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

#include "loom/graphics/gfxMath.h"
#include "loom/engine/loom2d/l2dPoint.h"

namespace Loom2D
{
/**
 * A basic Rectangle class.
 */
class Rectangle
{
public:

    lmscalar x;
    lmscalar y;
    lmscalar width;
    lmscalar height;

    Rectangle(lmscalar _x = 0, lmscalar _y = 0, lmscalar _width = 0, lmscalar _height = 0)
    {
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;
    }

    inline lmscalar getX() const
    {
        return x;
    }

    inline void setX(lmscalar _x)
    {
        x = _x;
    }

    inline lmscalar getY() const
    {
        return y;
    }

    inline void setY(lmscalar _y)
    {
        y = _y;
    }

    inline lmscalar getWidth() const
    {
        return width;
    }

    inline void setWidth(lmscalar _width)
    {
        width = _width;
    }

    inline lmscalar getHeight() const
    {
        return height;
    }

    inline void setHeight(lmscalar _height)
    {
        height = _height;
    }

    inline lmscalar getMinX() const
    {
        return x;
    }

    inline lmscalar getMaxX() const
    {
        return x + width;
    }

    inline lmscalar getMinY() const
    {
        return y;
    }

    inline lmscalar getMaxY() const
    {
        return y + height;
    }

    inline lmscalar getTop() const
    {
        return y;
    }

    inline void setTop(lmscalar top)
    {
        height += y - top;
        y = top;
    }

    inline lmscalar getBottom() const
    {
        return y + height;
    }

    inline void setBottom(lmscalar bottom)
    {
        height = bottom - y;
    }

    inline lmscalar getLeft() const
    {
        return x;
    }

    inline void setLeft(lmscalar left)
    {
        width += x - left;
        x = left;
    }

    inline lmscalar getRight() const
    {
        return x + width;
    }

    inline void setRight(lmscalar right)
    {
        width = right - x;
    }

    /**
     * If p is outside of the rectangle's current bounds, expand it to include p.
     */
    int expandByPoint(lua_State *L)
    {
        lua_rawgeti(L, 2, (int)Point::xOrdinal);
        lua_rawgeti(L, 2, (int)Point::yOrdinal);

        lmscalar px = (lmscalar)lua_tonumber(L, -2);
        lmscalar py = (lmscalar)lua_tonumber(L, -1);

        lua_pop(L, 2);

        lmscalar minX = x;
        lmscalar maxX = x + width;
        lmscalar minY = y;
        lmscalar maxY = y + height;

        if (px < minX) { minX = px; }
        if (px > maxX) { maxX = px; }
        if (py < minY) { minY = py; }
        if (py > maxY) { maxY = py; }

        x      = minX;
        width  = maxX - minX;
        y      = minY;
        height = maxY - minY;

        return 0;
    }

    /**
     * Returns true if p is inside the bounds of this rectangle.
     */
    int containsPoint(lua_State *L)
    {
        lua_rawgeti(L, 2, (int)Point::xOrdinal);
        lua_rawgeti(L, 2, (int)Point::yOrdinal);

        lmscalar px = (lmscalar)lua_tonumber(L, -2);
        lmscalar py = (lmscalar)lua_tonumber(L, -1);

        bool result = true;
        if ((px > (x + width)) || (px < x)) { result = false; }
        else if ((py > (y + height)) || (py < y)) { result = false; }

        lua_pushboolean(L, result ? 1 : 0);

        return 1;
    }

    /**
     * Returns true if both the top/left and bottom/right points are inside the bounds of this rectangle.
     */
    inline bool containsRect(Rectangle rect)
    {
        if ((rect.x > (x + width)) || (rect.x < x)) { return false; }
        else if ((rect.y > (y + height)) || (rect.y < y)) { return false; }
        else if (((rect.x + rect.width) > (x + width)) || ((rect.x + rect.width) < x)) { return false; }
        else if (((rect.y + rect.height) > (y + height)) || ((rect.y + rect.height) < y)) { return false; }
        return true;
    }

    /**
     * Returns true if x, y is inside the bounds of this rectangle.
     */
    int contains(lua_State *L)
    {
        lmscalar px = (lmscalar)lua_tonumber(L, 2);
        lmscalar py = (lmscalar)lua_tonumber(L, 3);

        bool result = true;

        if ((px > (x + width)) || (px < x)) { result = false; }
        else if ((py > (y + height)) || (py < y)) { result = false; }

        lua_pushboolean(L, result ? 1 : 0);

        return 1;
    }

    void clip(lmscalar cx, lmscalar cy, lmscalar cwidth, lmscalar cheight)
    {
        width  = lmClamp(lmMin(width,  lmMin(x + width  - cx, cx + cwidth  - x)), 0, cwidth);
        height = lmClamp(lmMin(height, lmMin(y + height - cy, cy + cheight - y)), 0, cheight);
        x = lmMax(x, cx);
        y = lmMax(y, cy);
    }

    /**
     * Assign the x,y,width,height of this rectangle.
     */
    void setTo(lmscalar _x, lmscalar _y, lmscalar _width, lmscalar _height)
    {
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;
    }

    const char *toString()
    {
        static char toStringBuffer[256];

        snprintf(toStringBuffer, 255, "x= %.2f, y= %.2f, width= %.2f, height= %.2f",
                 (lmscalar)x, (lmscalar)y, (lmscalar)width, (lmscalar)height);

        return toStringBuffer;
    }

    /**
     * Make a copy of this Rectangle.
     */
    int clone(lua_State *L)
    {
        static Type* type = LSLuaState::getLuaState(L)->getType("loom2d.math.Rectangle");

        // Create the instance on top of the stack
        lsr_createinstance(L, type);

        // Gets a pointer from the top of the stack and keep it there
        Rectangle* copy = (Rectangle *)lualoom_getnativepointer(L, -1);
        copy->x      = x;
        copy->y      = y;
        copy->width  = width;
        copy->height = height;

        return 1;
    }

    static void initialize(lua_State *L)
    {
    }
};
}
