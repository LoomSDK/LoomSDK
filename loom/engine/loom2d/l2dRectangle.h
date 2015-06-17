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

    float x;
    float y;
    float width;
    float height;

    Rectangle(float _x = 0, float _y = 0, float _width = 0, float _height = 0)
    {
        x      = _x;
        y      = _y;
        width  = _width;
        height = _height;
    }

    inline float getX() const
    {
        return x;
    }

    inline void setX(float _x)
    {
        x = _x;
    }

    inline float getY() const
    {
        return y;
    }

    inline void setY(float _y)
    {
        y = _y;
    }

    inline float getWidth() const
    {
        return width;
    }

    inline void setWidth(float _width)
    {
        width = _width;
    }

    inline float getHeight() const
    {
        return height;
    }

    inline void setHeight(float _height)
    {
        height = _height;
    }

    inline float getMinX() const
    {
        return x;
    }

    inline float getMaxX() const
    {
        return x + width;
    }

    inline float getMinY() const
    {
        return y;
    }

    inline float getMaxY() const
    {
        return y + height;
    }

    inline float getTop() const
    {
        return y;
    }

    inline void setTop(float top)
    {
        height += y - top;
        y = top;
    }

    inline float getBottom() const
    {
        return y + height;
    }

    inline void setBottom(float bottom)
    {
        height = bottom - y;
    }

    inline float getLeft() const
    {
        return x;
    }

    inline void setLeft(float left)
    {
        width += x - left;
        x = left;
    }

    inline float getRight() const
    {
        return x + width;
    }

    inline void setRight(float right)
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

        float px = (float)lua_tonumber(L, -2);
        float py = (float)lua_tonumber(L, -1);

        lua_pop(L, 2);

        float minX = x;
        float maxX = x + width;
        float minY = y;
        float maxY = y + height;

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

        float px = (float)lua_tonumber(L, -2);
        float py = (float)lua_tonumber(L, -1);

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
        float px = (float)lua_tonumber(L, 2);
        float py = (float)lua_tonumber(L, 3);

        bool result = true;

        if ((px > (x + width)) || (px < x)) { result = false; }
        else if ((py > (y + height)) || (py < y)) { result = false; }

        lua_pushboolean(L, result ? 1 : 0);

        return 1;
    }

    void clip(float cx, float cy, float cwidth, float cheight)
    {
        width  = fmaxf(0.f, fminf(cwidth,  fminf(width,  fminf(x + width  - cx, cx + cwidth  - x))));
        height = fmaxf(0.f, fminf(cheight, fminf(height, fminf(y + height - cy, cy + cheight - y))));
        x = fmaxf(x, cx);
        y = fmaxf(y, cy);
    }

    /**
     * Assign the x,y,width,height of this rectangle.
     */
    void setTo(float _x, float _y, float _width, float _height)
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
                 (float)x, (float)y, (float)width, (float)height);

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
