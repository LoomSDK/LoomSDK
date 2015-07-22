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

    tfloat x;
    tfloat y;
    tfloat width;
    tfloat height;

    Rectangle(tfloat _x = 0, tfloat _y = 0, tfloat _width = 0, tfloat _height = 0)
    {
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;
    }

    inline tfloat getX() const
    {
        return x;
    }

    inline void setX(tfloat _x)
    {
        x = _x;
    }

    inline tfloat getY() const
    {
        return y;
    }

    inline void setY(tfloat _y)
    {
        y = _y;
    }

    inline tfloat getWidth() const
    {
        return width;
    }

    inline void setWidth(tfloat _width)
    {
        width = _width;
    }

    inline tfloat getHeight() const
    {
        return height;
    }

    inline void setHeight(tfloat _height)
    {
        height = _height;
    }

    inline tfloat getMinX() const
    {
        return x;
    }

    inline tfloat getMaxX() const
    {
        return x + width;
    }

    inline tfloat getMinY() const
    {
        return y;
    }

    inline tfloat getMaxY() const
    {
        return y + height;
    }

    inline tfloat getTop() const
    {
        return y;
    }

    inline void setTop(tfloat top)
    {
        height += y - top;
        y = top;
    }

    inline tfloat getBottom() const
    {
        return y + height;
    }

    inline void setBottom(tfloat bottom)
    {
        height = bottom - y;
    }

    inline tfloat getLeft() const
    {
        return x;
    }

    inline void setLeft(tfloat left)
    {
        width += x - left;
        x = left;
    }

    inline tfloat getRight() const
    {
        return x + width;
    }

    inline void setRight(tfloat right)
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

        tfloat px = (tfloat)lua_tonumber(L, -2);
        tfloat py = (tfloat)lua_tonumber(L, -1);

        lua_pop(L, 2);

        tfloat minX = x;
        tfloat maxX = x + width;
        tfloat minY = y;
        tfloat maxY = y + height;

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

        tfloat px = (tfloat)lua_tonumber(L, -2);
        tfloat py = (tfloat)lua_tonumber(L, -1);

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
        tfloat px = (tfloat)lua_tonumber(L, 2);
        tfloat py = (tfloat)lua_tonumber(L, 3);

        bool result = true;

        if ((px > (x + width)) || (px < x)) { result = false; }
        else if ((py > (y + height)) || (py < y)) { result = false; }

        lua_pushboolean(L, result ? 1 : 0);

        return 1;
    }

    void clip(tfloat cx, tfloat cy, tfloat cwidth, tfloat cheight)
    {
        width  = fmax((tfloat) 0., fmin(cwidth,  fmin(width,  fmin(x + width  - cx, cx + cwidth  - x))));
        height = fmax((tfloat) 0., fmin(cheight, fmin(height, fmin(y + height - cy, cy + cheight - y))));
        x = fmax(x, cx);
        y = fmax(y, cy);
    }

    /**
     * Assign the x,y,width,height of this rectangle.
     */
    void setTo(tfloat _x, tfloat _y, tfloat _width, tfloat _height)
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
                 (tfloat)x, (tfloat)y, (tfloat)width, (tfloat)height);

        return toStringBuffer;
    }

    /**
     * Make a copy of this Rectangle.
     */
    Rectangle *clone()
    {
        Rectangle *copy = lmNew(NULL) Rectangle();

        copy->x      = x;
        copy->y      = y;
        copy->width  = width;
        copy->height = height;
        return copy;
    }

    static void initialize(lua_State *L)
    {
    }
};
}
