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

#include <math.h>

#include "loom/script/loomscript.h"
#include "loom/engine/loom2d/l2dPoint.h"

namespace Loom2D
{
class Matrix
{
private:

    static Type       *typeMatrix;
    static lua_Number sHelperPointOrdinal;

public:

    float a;
    float b;
    float c;
    float d;

    float tx;
    float ty;

    Matrix(float _a = 1.0f, float _b = 0.0f, float _c = 0.0f, float _d = 1.0f, float _tx = 0.0f, float _ty = 0.0f)
    {
        //printf("New Matrix: %f %f %f %f %f %f\n", _a, _b, _c, _d, _tx, _ty);
        setTo(_a, _b, _c, _d, _tx, _ty);
    }

    inline float get_a() const
    {
        return a;
    }

    inline void set_a(float _a)
    {
        a = _a;
    }

    inline float get_b() const
    {
        return b;
    }

    inline void set_b(float _b)
    {
        b = _b;
    }

    inline float get_c() const
    {
        return c;
    }

    inline void set_c(float _c)
    {
        c = _c;
    }

    inline float get_d() const
    {
        return d;
    }

    inline void set_d(float _d)
    {
        d = _d;
    }

    inline float get_tx() const
    {
        return tx;
    }

    inline void set_tx(float _tx)
    {
        tx = _tx;
    }

    inline float get_ty() const
    {
        return ty;
    }

    inline void set_ty(float _ty)
    {
        ty = _ty;
    }

    inline float determinant()
    {
        return a * d - b * c;
    }

    inline void setTo(float _a, float _b, float _c, float _d, float _tx, float _ty)
    {
        a  = _a;
        b  = _b;
        c  = _c;
        d  = _d;
        tx = _tx;
        ty = _ty;
    }

    inline void concat(const Matrix *m)
    {
        float ta  = a;
        float tb  = b;
        float tc  = c;
        float td  = d;
        float ttx = tx;
        float tty = ty;

        a  = m->a * ta + m->c * tb;
        b  = m->b * ta + m->d * tb;
        c  = m->a * tc + m->c * td;
        d  = m->b * tc + m->d * td;
        tx = m->a * ttx + m->c * tty + m->tx;
        ty = m->b * ttx + m->d * tty + m->ty;
    }

    inline void skew(float xSkew, float ySkew)
    {
        float sinX = sin(xSkew);
        float cosX = cos(xSkew);
        float sinY = sin(ySkew);
        float cosY = cos(ySkew);

        setTo(a * cosY - b * sinX,
              a * sinY + b * cosX,
              c * cosY - d * sinX,
              c * sinY + d * cosX,
              tx * cosY - ty * sinX,
              tx * sinY + ty * cosX);
    }

    inline void rotate(float angle)
    {
        if (angle == 0.0f)
        {
            return;
        }

        float _cos = cos(angle);
        float _sin = sin(angle);

        float ta  = a;
        float tb  = b;
        float tc  = c;
        float td  = d;
        float ttx = tx;
        float tty = ty;

        a  = ta * _cos - tb * _sin;
        b  = ta * _sin + tb * _cos;
        c  = tc * _cos - td * _sin;
        d  = tc * _sin + td * _cos;
        tx = ttx * _cos - tty * _sin;
        ty = ttx * _sin + tty * _cos;
    }

    inline void translate(float dx, float dy)
    {
        tx += dx;
        ty += dy;
    }

    inline void scale(float sx, float sy)
    {
        if (sx != 1.0f)
        {
            a  *= sx;
            c  *= sx;
            tx *= sx;
        }

        if (sy != 1.0f)
        {
            b  *= sy;
            d  *= sy;
            ty *= sy;
        }
    }

    inline void identity()
    {
        a  = 1;
        b  = 0;
        tx = 0;
        c  = 0;
        d  = 1;
        ty = 0;
    }

    inline bool isIdentity()
    {
        return ((tx != 0.0f) || (ty != 0.0f) || (a != 1.0f) || (d != 1.0f) || (b != 0.0f) || (c != 0.0f)) ? false : true;
    }

    inline void invert()
    {
        invertOther(this);
    }

    inline void invertOther(const Matrix *other)
    {
        float a  = other->a;
        float b  = other->b;
        float c  = other->c;
        float d  = other->d;
        float tx = other->tx;
        float ty = other->ty;

        // Cremer's rule: inverse = adjugate / determinant
        // A-1 = adj(A) / det(A)
        float invDet = 1.0f / (a * d - c * b);

        //     [a11 a12 a13]
        // A = [a21 a22 a23]
        //     [a31 a32 a33]
        // according to http://de.wikipedia.org/wiki/Inverse_Matrix#Formel_f.C3.BCr_3x3-Matrizen (sorry, German):
        //          [a22*a33-a32*a23 a13*a32-a12*a33 a12*a23-a13*a22]
        // adj(A) = [a23*a31-a21*a33 a11*a33-a13*a31 a13*a21-a11*a23]
        //          [a21*a32-a22*a31 a12*a31-a11*a32 a11*a22-a12*a21]
        // with a11 = a, a12 = c, a13 = tx,
        //      a21 = b, a22 = d, a23 = ty,
        //      a31 = 0, a32 = 0, a33 = 1:
        //          [d *1-0*ty  tx*0-c *1  c *ty-tx*d ]
        // adj(A) = [ty*0-b* 1  a *1-tx*0  tx* b-a *ty]
        //          [b *0-d* 0  c *0-a *0  a * d-c *b ]
        //          [ d -c  c*ty-tx*d]
        //        = [-b  a  tx*b-a*ty]
        //          [ 0  0  a*d -c*b ]
        this->a = d * invDet;
        this->b = -b * invDet;
        this->c = -c * invDet;
        this->d = a * invDet;

        // Dart version:
        this->tx = -(this->a * tx + this->c * ty);
        this->ty = -(this->b * tx + this->d * ty);
    }

    int transformCoord(lua_State *L)
    {
        float x = (float)lua_tonumber(L, 2);
        float y = (float)lua_tonumber(L, 3);

        // get the helper point
        lua_pushnumber(L, sHelperPointOrdinal);
        lua_gettable(L, 1);

        lua_pushnumber(L, a * x + c * y + tx);
        lua_rawseti(L, 4, (int)Point::xOrdinal);
        lua_pushnumber(L, b * x + d * y + ty);
        lua_rawseti(L, 4, (int)Point::yOrdinal);

        return 1;
    }

    void transformCoordInternal(float x, float y, float *rx, float *ry)
    {
        *rx = a*x + c*y + tx;
        *ry = b*x + d*y + ty;
    }

    int deltaTransformCoord(lua_State *L)
    {
        float x = (float)lua_tonumber(L, 2);
        float y = (float)lua_tonumber(L, 3);

        // get the helper point
        lua_pushnumber(L, sHelperPointOrdinal);
        lua_gettable(L, 1);

        lua_pushnumber(L, a * x + c * y);
        lua_rawseti(L, 4, (int)Point::xOrdinal);
        lua_pushnumber(L, b * x + d * y);
        lua_rawseti(L, 4, (int)Point::yOrdinal);

        return 1;
    }

    inline void copyFrom(const Matrix *other)
    {
        a  = other->a;
        b  = other->b;
        c  = other->c;
        d  = other->d;
        tx = other->tx;
        ty = other->ty;
    }

    // fast marshaling version
    int setTo(lua_State *L)
    {
        a  = (float)lua_tonumber(L, 2);
        b  = (float)lua_tonumber(L, 3);
        c  = (float)lua_tonumber(L, 4);
        d  = (float)lua_tonumber(L, 5);
        tx = (float)lua_tonumber(L, 6);
        ty = (float)lua_tonumber(L, 7);
        return 0;
    }

    // fast marshaling version
    int copyFrom(lua_State *L)
    {
        const Matrix *other = (const Matrix *)lualoom_getnativepointer(L, 2);

        a = other->a;
        b = other->b;
        c = other->c;
        d = other->d;

        tx = other->tx;
        ty = other->ty;
        return 0;
	}

	void copyToMatrix3(float* values)
	{
		values[0] = a;
		values[1] = b;
		values[2] = 0;
		values[3] = c;
		values[4] = d;
		values[5] = 0;
		values[6] = tx;
		values[7] = ty;
		values[8] = 1;
	}

	void copyToMatrix4(float* values)
	{
		values[0] = a;
		values[1] = b;
		values[2] = 0;
		values[3] = 0;
		values[4] = c;
		values[5] = d;
		values[6] = 0;
		values[7] = 0;
		values[8] = 0;
		values[9] = 0;
		values[10] = 0;
		values[11] = 0;
		values[12] = tx;
		values[13] = ty;
		values[14] = 0;
		values[15] = 1;
	}

    const char *toString()
    {
        static char toStringBuffer[256];

        snprintf(toStringBuffer, 255, "a= %.2f, b= %.2f, c= %.2f, d= %.2f, tx= %.2f, ty= %.2f",
                 (float)a, (float)b, (float)c, (float)d, (float)tx, (float)ty);

        return toStringBuffer;
    }

    static void initialize(lua_State *L)
    {
        typeMatrix = LSLuaState::getLuaState(L)->getType("loom2d.math.Matrix");
        lmAssert(typeMatrix, "unable to get loom2d.math.Matrix type");
        sHelperPointOrdinal = typeMatrix->getMemberOrdinal("sHelperPoint");
    }
};
}
