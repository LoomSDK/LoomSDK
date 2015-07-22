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

#include "loom/engine/loom2d/l2dRectangle.h"
#include "loom/engine/loom2d/l2dMatrix.h"
#include "loom/engine/loom2d/l2dEventDispatcher.h"
#include "loom/engine/loom2d/l2dBlendMode.h"
#include "loom/script/native/lsNativeDelegate.h"
#include <math.h>

namespace Loom2D
{
class DisplayObjectContainer;

// small structure to handle renderstate as
// traverses down the DisplayObject hierarchy
struct RenderState
{
    tfloat alpha;
    // Clipping is disabled when width equals -1
    Loom2D::Rectangle clipRect;
    int   blendMode;
    void clampAlpha()
    {
        if(alpha < 0.f) alpha = 0.f;
        if(alpha > 1.f) alpha = 1.f;
    }
    inline bool isClipping()
    {
        return clipRect.width != -1.f;
    }
};

class DisplayObject : public EventDispatcher
{
public:

    bool transformDirty;

    /** The x coordinate of the object relative to the local coordinates of the parent. */
    tfloat x;

    /** The y coordinate of the object relative to the local coordinates of the parent. */
    tfloat y;

    /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
    tfloat pivotX;

    /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
    tfloat pivotY;

    /** The horizontal scale factor. '1' means no scale, negative values flip the object. */
    tfloat scaleX;

    /** The vertical scale factor. '1' means no scale, negative values flip the object. */
    tfloat scaleY;

    /** The horizontal skew angle in radians. */
    tfloat skewX;

    /** The vertical skew angle in radians. */
    tfloat skewY;

    /** The rotation of the object in radians. (In Starling, all angles are measured
     *  in radians.) */
    tfloat rotation;

    /** The opacity of the object. 0 = transparent, 1 = opaque. */
    tfloat alpha;

    /** The blend mode for the object. Default is BlendMode.AUTO (will inherit parent's blendMode) */
    int blendMode;

    /** If depth sorting is enabled on parent this will be used to establish draw order. */
    tfloat depth;

    /** The visibility of the object. An invisible object will be untouchable. */
    bool visible;

    /** Indicates if this object (and its children) will receive touch events. */
    bool touchable;

    bool valid;

    /** The name of the display object (default: null). Used by 'getChildByName()' of
     *  display object containers. */
    const char *name;

    Type *type;

    // true if Image or derived from Image type
    bool imageOrDerived;

    // should not set this directly
    DisplayObjectContainer *parent;

    Matrix transformMatrix;

    bool isEquivalent(tfloat a, tfloat b, tfloat epsilon = 0.0001f)
    {
        return (a - epsilon < b) && (a + epsilon > b);
    }

    RenderState renderState;

public:

    static Type       *typeDisplayObject;
    static lua_Number _transformationMatrixOrdinal;

    static void initialize(lua_State *L)
    {
        typeDisplayObject = LSLuaState::getLuaState(L)->getType("loom2d.display.DisplayObject");
        lmAssert(typeDisplayObject, "unable to get loom2d.display.DisplayObject type");

        _transformationMatrixOrdinal = typeDisplayObject->getMemberOrdinal("_transformationMatrix");
    }

    inline void init()
    {
        x              = y = 0;
        pivotX         = pivotY = 0;
        scaleX         = scaleY = 1;
        skewX          = skewY = 0;
        depth          = 0;
        rotation       = 0;
        alpha          = 1;
        blendMode      = BlendMode::AUTO;
        visible        = touchable = true;
        name           = stringtable_insert("");
        parent         = NULL;
        valid          = false;
        type           = NULL;
        imageOrDerived = false;
        transformDirty = false;
    }

    DisplayObject()
    {
        init();
        type = typeDisplayObject;
    }

    virtual void render(lua_State *L)
    {
    }

    virtual void validate(lua_State *L, int index)
    {
        if (!valid)
        {
            // call script validate method

            // OPTIMIZE ORDINAL!
            lualoom_getmember(L, index, "validate");
            lua_call(L, 0, 0);
            valid = true;
        }
    }

    inline DisplayObjectContainer *getParent()
    {
        return parent;
    }

    inline void setParent(DisplayObjectContainer *_parent)
    {
        parent = _parent;
    }

    inline void updateLocalTransform()
    {
        if (!transformDirty)
        {
            return;
        }

        Matrix *m = &transformMatrix;

        transformDirty = false;

        if ((skewX == 0.0) && (skewY == 0.0))
        {
            // optimization: no skewing / rotation simplifies the matrix math

            if (rotation == 0.0)
            {
                m->setTo(scaleX, 0.0, 0.0, scaleY,
                         x - pivotX * scaleX, y - pivotY * scaleY);
            }
            else
            {
                tfloat _cos = cos(rotation);
                tfloat _sin = sin(rotation);
                tfloat a    = scaleX * _cos;
                tfloat b    = scaleX * _sin;
                tfloat c    = scaleY * -_sin;
                tfloat d    = scaleY * _cos;
                tfloat tx   = x - pivotX * a - pivotY * c;
                tfloat ty   = y - pivotX * b - pivotY * d;

                m->setTo(a, b, c, d, tx, ty);
            }
        }
        else
        {
            m->identity();
            m->scale(scaleX, scaleY);
            m->skew(skewX, skewY);
            m->rotate(rotation);
            m->translate(x, y);

            if ((pivotX != 0.0) || (pivotY != 0.0))
            {
                // prepend pivot transformation
                m->tx = x - m->a * pivotX - m->c * pivotY;

                m->ty = y - m->b * pivotX - m->d * pivotY;
            }
        }
    }

    int getTransformationMatrix(lua_State *L)
    {
        // get the instance transformation matrix
        lua_rawgeti(L, 1, (int)_transformationMatrixOrdinal);

        if (!transformDirty)
        {
            return 1;
        }

        updateLocalTransform();

        Matrix *m = (Matrix *)lualoom_getnativepointer(L, -1, true);

        m->copyFrom(&transformMatrix);

        return 1;
    }

    int setTransformationMatrix(lua_State *L)
    {
        if (lua_isnil(L, 2))
        {
            return 0;
        }

        // get the instance transformation matrix
        lua_rawgeti(L, 1, (int)_transformationMatrixOrdinal);

        Matrix *m = (Matrix *)lualoom_getnativepointer(L, -1);

        const Matrix *newM = (const Matrix *)lualoom_getnativepointer(L, 2);

        transformDirty = false;

        m->copyFrom(newM);
        transformMatrix.copyFrom(newM);

        pivotX = pivotY = 0;

        x      = m->tx;
        y      = m->ty;
        scaleX = sqrt(m->a * m->a + m->b * m->b);
        skewY  = acos(m->a / scaleX);

        if (!isEquivalent(m->b, scaleX * sin(skewY)))
        {
            scaleX *= -1;
            skewY   = acos(m->a / scaleX);
        }

        scaleY = sqrt(m->c * m->c + m->d * m->d);
        skewX  = acos(m->d / scaleY);

        if (!isEquivalent(m->c, -scaleY * sin(skewX)))
        {
            scaleY *= -1;
            skewX   = acos(m->d / scaleY);
        }

        if (isEquivalent(skewX, skewY))
        {
            rotation = skewX;
            skewX    = skewY = 0;
        }
        else
        {
            rotation = 0;
        }

        return 0;
    }

    /** Creates a matrix that represents the transformation from the local coordinate system
     *  to another. If you pass a 'resultMatrix', the result will be stored in this matrix
     *  instead of creating a new object. */
    void getTargetTransformationMatrix(DisplayObject *targetSpace, Matrix *resultMatrix);


    static void transformBounds(Matrix *transform, Rectangle *bounds, Rectangle *resultRect) {
        lmAssert(transform != NULL, "Transform is null");
        lmAssert(bounds != NULL, "Bounds are null");
        lmAssert(resultRect != NULL, "Result rect is null");

        tfloat rx, ry;
        tfloat minx, miny, maxx, maxy;

        transform->transformCoordInternal(bounds->getLeft(), bounds->getTop(), &rx, &ry);
        minx = rx;
        maxx = rx;
        miny = ry;
        maxy = ry;

        transform->transformCoordInternal(bounds->getLeft(), bounds->getBottom(), &rx, &ry);
        if (minx > rx) minx = rx;
        if (maxx < rx) maxx = rx;
        if (miny > ry) miny = ry;
        if (maxy < ry) maxy = ry;

        transform->transformCoordInternal(bounds->getRight(), bounds->getTop(), &rx, &ry);
        if (minx > rx) minx = rx;
        if (maxx < rx) maxx = rx;
        if (miny > ry) miny = ry;
        if (maxy < ry) maxy = ry;

        transform->transformCoordInternal(bounds->getRight(), bounds->getBottom(), &rx, &ry);
        if (minx > rx) minx = rx;
        if (maxx < rx) maxx = rx;
        if (miny > ry) miny = ry;
        if (maxy < ry) maxy = ry;

        resultRect->x = minx;
        resultRect->y = miny;
        resultRect->width = maxx-minx;
        resultRect->height = maxy-miny;
    }


    // fast path accessors for DisplayObject properties

    inline tfloat getX() const
    {
        return x;
    }

    inline void setX(tfloat _x)
    {
        transformDirty = true;
        x = _x;
    }

    inline tfloat getY() const
    {
        return y;
    }

    inline void setY(tfloat _y)
    {
        transformDirty = true;
        y = _y;
    }

    inline tfloat getPivotX() const
    {
        return pivotX;
    }

    inline void setPivotX(tfloat _pivotX)
    {
        transformDirty = true;
        pivotX         = _pivotX;
    }

    inline tfloat getPivotY() const
    {
        return pivotY;
    }

    inline void setPivotY(tfloat _pivotY)
    {
        transformDirty = true;
        pivotY         = _pivotY;
    }

    inline tfloat getScaleX() const
    {
        return scaleX;
    }

    inline void setScaleX(tfloat _scaleX)
    {
        transformDirty = true;
        scaleX         = _scaleX;
    }

    inline tfloat getScaleY() const
    {
        return scaleY;
    }

    inline void setScaleY(tfloat _scaleY)
    {
        transformDirty = true;
        scaleY         = _scaleY;
    }

    inline void setScale(tfloat _scale)
    {
        transformDirty = true;
        scaleX         = scaleY = _scale;
    }

    inline tfloat getScale() const
    {
        return (scaleX + scaleY) * .5f;
    }

    inline tfloat getSkewX() const
    {
        return skewX;
    }

    inline void setSkewX(tfloat _skewX)
    {
        transformDirty = true;
        skewX          = _skewX;
    }

    inline tfloat getSkewY() const
    {
        return skewY;
    }

    inline void setSkewY(tfloat _skewY)
    {
        transformDirty = true;
        skewY          = _skewY;
    }

    inline tfloat getRotation() const
    {
        return rotation;
    }

    inline void setRotation(tfloat _rotation)
    {
        transformDirty = true;
        rotation       = _rotation;
    }

    inline tfloat getAlpha() const
    {
        return alpha;
    }

    inline void setAlpha(tfloat _alpha)
    {
        alpha = _alpha;
    }

    inline int getBlendMode() const
    {
        return blendMode;
    }

    inline void setBlendMode(int _mode)
    {
        blendMode = _mode;
    }

    inline bool getVisible() const
    {
        return visible;
    }

    inline void setVisible(bool _visible)
    {
        visible = _visible;
    }

    inline bool getTouchable() const
    {
        return touchable;
    }

    inline void setTouchable(bool _touchable)
    {
        touchable = _touchable;
    }

    inline bool getValid() const
    {
        return valid;
    }

    inline void setValid(bool _valid)
    {
        valid = _valid;
    }

    inline tfloat getDepth() const
    {
        return depth;
    }

    inline void setDepth(tfloat _depth)
    {
        depth = _depth;
    }

    inline const char *getName() const
    {
        return name;
    }

    inline void setName(const char *_name)
    {
        if (!_name)
        {
            _name = "";
        }

        name = stringtable_insert(_name);
    }

    // a delegate which can be used for custom rendering
    LOOM_DELEGATE(CustomRender);

    // a delegate which is called prior to normal rendering
    LOOM_DELEGATE(OnRender);
};
}
