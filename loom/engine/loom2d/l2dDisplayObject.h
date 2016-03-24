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
    lmscalar alpha;
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
    // true if caching is in progress, used for avoiding rendering to texture while rendering to texture 
    static bool cacheAsBitmapInProgress;

public:

    bool transformDirty;

    /** The x coordinate of the object relative to the local coordinates of the parent. */
    lmscalar x;

    /** The y coordinate of the object relative to the local coordinates of the parent. */
    lmscalar y;

    /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
    lmscalar pivotX;

    /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
    lmscalar pivotY;

    /** The horizontal scale factor. '1' means no scale, negative values flip the object. */
    lmscalar scaleX;

    /** The vertical scale factor. '1' means no scale, negative values flip the object. */
    lmscalar scaleY;

    /** The horizontal skew angle in radians. */
    lmscalar skewX;

    /** The vertical skew angle in radians. */
    lmscalar skewY;

    /** The rotation of the object in radians. (In Starling, all angles are measured
     *  in radians.) */
    lmscalar rotation;

    /** The opacity of the object. 0 = transparent, 1 = opaque. */
    lmscalar alpha;

    /** The blend mode for the object. Default is BlendMode.AUTO (will inherit parent's blendMode) */
    int blendMode;

    /** Toggle blending of object. If false, blendMode will be ignored and there may be perfomance gains */
    bool blendEnabled;

    /** If depth sorting is enabled on parent this will be used to establish draw order. */
    lmscalar depth;

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

    // true if the contents are or are pending to be cached as an image
    bool cacheAsBitmap;
    // true if cachedImage represents a valid cache of the contents
    // if false, the contents are re-cached at render time
    bool cacheAsBitmapValid;
    // pointer to the cached image, details depend on implementation
    void* cachedImage;
    // X offset the cached image has to be rendered at
    lmscalar cacheAsBitmapOffsetX;
    // Y offset the cached image has to be rendered at
    lmscalar cacheAsBitmapOffsetY;

    // should not set this directly
    DisplayObjectContainer *parent;

    Matrix transformMatrix;

    bool isEquivalent(lmscalar a, lmscalar b, lmscalar epsilon = 0.0001f)
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
        x                  = y = 0;
        pivotX             = pivotY = 0;
        scaleX             = scaleY = 1;
        skewX              = skewY = 0;
        depth              = 0;
        rotation           = 0;
        alpha              = 1;
        blendMode          = BlendMode::AUTO;
        blendEnabled       = true;
        visible            = touchable = true;
        name               = stringtable_insert("");
        parent             = NULL;
        valid              = false;
        type               = NULL;
        imageOrDerived     = false;
        transformDirty     = false;
        cacheAsBitmap      = false;
        cacheAsBitmapValid = false;
        cachedImage        = NULL;
    }

    DisplayObject()
    {
        init();
        type = typeDisplayObject;
    }

    ~DisplayObject()
    {
        lualoom_managedpointerreleased(this);
    }

    virtual void render(lua_State *L);

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
                lmscalar _cos = cos(rotation);
                lmscalar _sin = sin(rotation);
                lmscalar a    = scaleX * _cos;
                lmscalar b    = scaleX * _sin;
                lmscalar c    = scaleY * -_sin;
                lmscalar d    = scaleY * _cos;
                lmscalar tx   = x - pivotX * a - pivotY * c;
                lmscalar ty   = y - pivotX * b - pivotY * d;

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

        lmscalar rx, ry;
        lmscalar minx, miny, maxx, maxy;

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

    inline lmscalar getX() const
    {
        return x;
    }

    inline void setX(lmscalar _x)
    {
        transformDirty = true;
        x = _x;
    }

    inline lmscalar getY() const
    {
        return y;
    }

    inline void setY(lmscalar _y)
    {
        transformDirty = true;
        y = _y;
    }

    inline lmscalar getPivotX() const
    {
        return pivotX;
    }

    inline void setPivotX(lmscalar _pivotX)
    {
        transformDirty = true;
        pivotX         = _pivotX;
    }

    inline lmscalar getPivotY() const
    {
        return pivotY;
    }

    inline void setPivotY(lmscalar _pivotY)
    {
        transformDirty = true;
        pivotY         = _pivotY;
    }

    inline lmscalar getScaleX() const
    {
        return scaleX;
    }

    inline void setScaleX(lmscalar _scaleX)
    {
        transformDirty = true;
        scaleX         = _scaleX;
    }

    inline lmscalar getScaleY() const
    {
        return scaleY;
    }

    inline void setScaleY(lmscalar _scaleY)
    {
        transformDirty = true;
        scaleY         = _scaleY;
    }

    inline void setScale(lmscalar _scale)
    {
        transformDirty = true;
        scaleX         = scaleY = _scale;
    }

    inline lmscalar getScale() const
    {
        return (scaleX + scaleY) * .5f;
    }

    inline lmscalar getSkewX() const
    {
        return skewX;
    }

    inline void setSkewX(lmscalar _skewX)
    {
        transformDirty = true;
        skewX          = _skewX;
    }

    inline lmscalar getSkewY() const
    {
        return skewY;
    }

    inline void setSkewY(lmscalar _skewY)
    {
        transformDirty = true;
        skewY          = _skewY;
    }

    inline lmscalar getRotation() const
    {
        return rotation;
    }

    inline void setRotation(lmscalar _rotation)
    {
        transformDirty = true;
        rotation       = _rotation;
    }

    inline lmscalar getAlpha() const
    {
        return alpha;
    }

    inline void setAlpha(lmscalar _alpha)
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

    inline bool getBlendEnabled() const
    {
        return blendEnabled;
    }

    inline void setBlendEnabled(bool _enabled)
    {
        blendEnabled = _enabled;
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

    bool getCacheAsBitmap() const
    {
        return cacheAsBitmap;
    }

    void setCacheAsBitmap(bool _cacheAsBitmap)
    {
        if (!_cacheAsBitmap && cacheAsBitmap) invalidateBitmapCache();
        cacheAsBitmap = _cacheAsBitmap;
    }

    void invalidateBitmapCache()
    {
        cacheAsBitmapValid = false;
    }

    bool renderCached(lua_State *L);
    
    inline bool getValid() const
    {
        return valid;
    }

    inline void setValid(bool _valid)
    {
        valid = _valid;
    }

    inline lmscalar getDepth() const
    {
        return depth;
    }

    inline void setDepth(lmscalar _depth)
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
