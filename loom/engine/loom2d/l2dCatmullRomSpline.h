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

#include "math.h"
#include "stdio.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/utils/utTypes.h"
#include "loom/engine/loom2d/l2dPoint.h"



namespace Loom2D
{

// Class for evaluating a CMR Tuple (x & y)
class CatmullRomTuple
{
public:
    float _x;
    float _y;


    // CatmullRomTuple( const CatmullRomTuple& other ) {}
    CatmullRomTuple()
    {
        _x = 0.0f;
        _y = 0.0f;
    }
    CatmullRomTuple(float x, float y)
    {
        _x = x;
        _y = y;
    }
    float getMagnitude()
    {
        return sqrtf(_x*_x + _y*_y);
    }
    CatmullRomTuple & operator=(const CatmullRomTuple &rhs)
    {
        _x = rhs._x;
        _y = rhs._y;
        return *this;
    }
    CatmullRomTuple  operator+(const CatmullRomTuple &rhs) const
    {
        CatmullRomTuple ret = *this;
        ret._x += rhs._x;
        ret._y += rhs._y;
        return ret;
    }
    CatmullRomTuple  operator-(const CatmullRomTuple &rhs) const
    {
        CatmullRomTuple ret = *this;
        ret._x -= rhs._x;
        ret._y -= rhs._y;
        return ret;
    }
    CatmullRomTuple  operator*(const float s) const
    {
        CatmullRomTuple ret = *this;
        ret._x *= s;
        ret._y *= s;
        return ret;
    }
    friend CatmullRomTuple operator*(const float s, const CatmullRomTuple& point)
    {
        return point * s;
    }
};






//------------------------------------------------------------------------------
// Catmull Rom Spline.
// This spline is interpolating not approximmating.  Which means the spline goes
// through all of its control points.
//
// It needs 4 control points to be valid.  Evaluate SecondDeriv
// expect a value between 0 and 1.0. You can create either an arb float tuple, triple, or quadruple 
// 
// You can use SecondDeriv (removed Deriv as it wasn't being used) for curvature evaluation at a point.
// 
// CANDO: We can expand this class to allow CMR evaluations of Triples and Quadruples if necessary
//------------------------------------------------------------------------------

class CatmullRomSpline
{
public:
   // constructor/destructor
   CatmullRomSpline(int _elements = 2) :
      _totalLength( 0.0f ),
      _count( 0 )
   {
        //CANDO: _tripleElement / _quadrupleElement support
        lmAssert((_elements == 2), "Unsupported element size for CatmullRomSpline. Only 2 (tuple) is supported at the moment, not %d.", _elements);
        _elementSize = _elements;
   }   
   
   virtual ~CatmullRomSpline()
   {
      clear();
   }  


   static void initialize(lua_State *L)
   {
      typeCatmullRomSpline = LSLuaState::getLuaState(L)->getType("loom2d.math.CatmullRomSpline");
      lmAssert(typeCatmullRomSpline, "unable to get loom2d.math.CatmullRomSpline type");
      sHelperPointOrdinal = typeCatmullRomSpline->getMemberOrdinal("sHelperPoint");
   }
 
   void clear()
   {
      _tupleElement.clear(); 
      //CANDO: _tripleElement / _quadrupleElement determination
      _times.clear();
      _lengths.clear();
      _totalLength = 0.0f;
      _count = 0;
   } 


   template<typename T>
   void addElement(T& element, bool replaceLast, utArray<T>& elements)
   {
        if(replaceLast && (elements.size() > 0))
        {
            elements[elements.size() - 1] = element;
        }
        else
        {
            elements.push_back(element);
        }
   }



   // finalizes the line for calculations
   template<typename T>
   bool finalize(utArray<T>& elements)
   {
      // make sure not already initialized
      if (_count != 0)
         return false;
      
      // make sure data is valid
      if ( elements.size() < 4 )
         return false;
      
      _times.clear();
      _lengths.clear();
      _count = elements.size();  
      
      // set up curve segment lengths
      unsigned int i;
      _times.reserve(_count);
      _lengths.reserve(_count);
      _totalLength = 0.0f;
      for ( i = 0; i < _count-1; ++i )
      {
         _lengths[i] = segmentArcLength(elements, i, 0.0f, 1.0f);
         _totalLength += _lengths[i];
         _times[i] = i / (float)(_count - 1);
      }
      _times[i] = i/(float)(_count - 1);

      return true;
   }


   template<typename T>
   T evaluate( float t, utArray<T>& elements )
   {
      // make sure data is valid
      lmAssert( _count >= 2, "CatmullRom - Too Few Data Points");
      if ( _count < 2 )
      {
         T defaultValue;
         return defaultValue;
      }
      
      // handle boundary conditions
      if ( t <= _times[0] )
         return elements[0];
      else if ( t >= _times[_count-1] )
         return elements[_count-1];
      
      // find segment and parameter
      unsigned int i;  // segment #
      for ( i = 0; i < _count-1; ++i )
      {
         if ( t <= _times[i+1] )
         {
            break;
         }
      }
      lmAssert( i >= 0 && i < _count,"CatmullRom - Couldn't find valid segment number" );
      
      float t0 = _times[i];
      float t1 = _times[i+1];
      float u = (t - t0)/(t1 - t0);
      
      // quadratic Catmull-Rom for Q_0
      if (i == 0)
      {
         T A = elements[0] - 2.0f*elements[1] + elements[2];
         T B = 4.0f*elements[1] - 3.0f*elements[0] - elements[2];
         
         return elements[0] + (0.5f*u)*(B + u*A);
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         T A = elements[i-1] - 2.0f*elements[i] + elements[i+1];
         T B = elements[i+1] - elements[i-1];
         
         return elements[i] + (0.5f*u)*(B + u*A);
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         // evaluate
         T A = 3.0f*elements[i]
         - elements[i-1]
         - 3.0f*elements[i+1]
         + elements[i+2];
         T B = 2.0f*elements[i-1]
         - 5.0f*elements[i]
         + 4.0f*elements[i+1]
         - elements[i+2];
         T C = elements[i+1] - elements[i-1];
         
         return elements[i] + (0.5f*u)*(C + u*(B + u*A));
      }
   }


   template<typename T>
   T secondDeriv( float t, utArray<T>& elements )
   {
      // make sure data is valid
      lmAssert( _count >= 2,"CatmullRom - Too Few Data Points" );
      if ( _count < 2 )
      {
         T defaultValue;
         return defaultValue;
      }
      
      // handle boundary conditions
      if ( t <= _times[0] )
         t = 0.0f;
      else if ( t > _times[_count-1] )
         t = _times[_count-1];
      
      // find segment and parameter
      unsigned int i;
      for ( i = 0; i < _count-1; ++i )
      {
         if ( t <= _times[i+1] )
         {
            break;
         }
      }
      float t0 = _times[i];
      float t1 = _times[i+1];
      float u = (t - t0)/(t1 - t0);
      
      // evaluate
      // quadratic Catmull-Rom for Q_0
      if (i == 0)
      {
         return elements[0] - 2.0f*elements[1] + elements[2];
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         return elements[i-1] - 2.0f*elements[i] + elements[i+1];
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         // evaluate
         T A = 3.0f*elements[i]
         - elements[i-1]
         - 3.0f*elements[i+1]
         + elements[i+2];
         T B = 2.0f*elements[i-1]
         - 5.0f*elements[i]
         + 4.0f*elements[i+1]
         - elements[i+2];
         
         return B + (3.0f*u)*A;
      } 
   } 

   inline float getSplineLength() { return _totalLength; }
   inline float getElementSize() { return _elementSize; }
    


   
   // lua accessor for addElement
   int _addElement(lua_State *L)
   {
       bool replaceLast = lua_toboolean(L, 3);
       switch(_elementSize)
       {
         case 2:
            {
                // parse Point class for the Tuple
                lua_rawgeti(L, 2, (int)Point::xOrdinal);
                lua_rawgeti(L, 2, (int)Point::yOrdinal);
                float px = (float)lua_tonumber(L, -2);
                float py = (float)lua_tonumber(L, -1);

                CatmullRomTuple *tuple = new CatmullRomTuple(px, py);
                addElement(*tuple, replaceLast, _tupleElement);
                break;
            }
          //CANDO: _tripleElement / _quadrupleElement support
          default:
                lmAssert(false, "Unsupported element size for CatmullRomSpline. Only 2 (tuple) is supported at the moment.");
      }
      return 0;
  }

   // lua accessor for finalize
   int _finalize(lua_State *L)
   {
      switch(_elementSize)
      {
         case 2:
            finalize(_tupleElement);
            break;
            //CANDO: _tripleElement / _quadrupleElement support
          default:
            lmAssert(false, "Unsupported element size for CatmullRomSpline. Only 2 (tuple) is supported at the moment.");
      }
      return 0;
   }

   // lua accessor for evaluate
   int _evaluate(lua_State *L)
   {
      float t = (float)lua_tonumber(L, 2);
      switch(_elementSize)
      {
         case 2:
            {
                CatmullRomTuple tuple = evaluate(t, _tupleElement);
                pushLuaTuple(L, 3, tuple);
                break;
            }
         //CANDO: _tripleElement / _quadrupleElement support
         default:
            lmAssert(false, "Unsupported element size for CatmullRomSpline. Only 2 (tuple) is supported at the moment.");
            lua_pushnil(L);
      }
      return 1;
   }

   // lua accessor for secondDeriv
   int _secondDeriv(lua_State *L)
   {
      float t = (float)lua_tonumber(L, 2);
      switch(_elementSize)
      {
         case 2:
            {
                CatmullRomTuple tuple = secondDeriv(t, _tupleElement);
                pushLuaTuple(L, 3, tuple);
                break;
            }
         //CANDO: _tripleElement / _quadrupleElement support
         default:
                lmAssert(false, "Unsupported element size for CatmullRomSpline. Only 2 (tuple) is supported at the moment.");
                lua_pushnil(L);
      }
      return 1;
   }

protected:

   // return length of curve between u1 and u2
   template<typename T>
   float segmentArcLength(utArray<T>& elements, unsigned int i, float u1, float u2 )
   {
      static const float x[] =
      {
         0.0000000000f, 0.5384693101f, -0.5384693101f, 0.9061798459f, -0.9061798459f 
      };
      
      static const float c[] =
      {
         0.5688888889f, 0.4786286705f, 0.4786286705f, 0.2369268850f, 0.2369268850f
      };
      
      assert(i >= 0 && i < _count-1);
      
      if ( u2 <= u1 )
         return 0.0f;
      
      if ( u1 < 0.0f )
         u1 = 0.0f;
      
      if ( u2 > 1.0f )
         u2 = 1.0f;
      
      // use Gaussian quadrature
      float sum = 0.0f;
      T A, B, C;
      if (i == 0)
      {
         A = elements[0] - 2.0f*elements[1] + elements[2];
         B = 4.0f*elements[1] - 3.0f*elements[0] - elements[2];
         
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         A = elements[i-1] - 2.0f*elements[i] + elements[i+1];
         B = elements[i+1] - elements[i-1];
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         A = 3.0f*elements[i]
         - elements[i-1]
         - 3.0f*elements[i+1]
         + elements[i+2];
         B = 2.0f*elements[i-1]
         - 5.0f*elements[i]
         + 4.0f*elements[i+1]
         - elements[i+2];
         C = elements[i+1] - elements[i-1];
      }
      
      for ( unsigned int j = 0; j < 5; ++j )
      {
         float u = 0.5f*((u2 - u1)*x[j] + u2 + u1);
         T derivative;
         if ( i == 0 || i >= _count-2)
            derivative = 0.5f*B + u*A;
         else
            derivative = 0.5f*C + u*(B + 1.5f*u*A);
         sum += c[j]*derivative.getMagnitude();
      }
      sum *= 0.5f*(u2-u1);
      
      return sum;
   } 



   utArray<CatmullRomTuple>     _tupleElement;     // sample elemements (position, etc.) in Tuble (x, y) form
   //CANDO: _tripleElement / _quadrupleElement support
   utArray<float>               _times;         // time to arrive at each point
   utArray<float>               _lengths;       // length of each curve segment
   float                        _totalLength;   // total length of curve
   unsigned int                 _count;         // number of points and times
   unsigned int                 _elementSize;   // number of elements that make up a point
                                                // NOTE: '2' is the only valid value for now, but should be able to add '3'(triple) and '4'(quadruple) easily
   
private:
   static Type       *typeCatmullRomSpline;
   static lua_Number sHelperPointOrdinal;

   // copy operations
   // made private so they can't be used
   CatmullRomSpline( const CatmullRomSpline& other );
   CatmullRomSpline& operator=( const CatmullRomSpline& other );


   void pushLuaTuple(lua_State *L, int luaPushIndex, CatmullRomTuple& tuple)
   {
        // get the helper point
        lua_pushnumber(L, sHelperPointOrdinal);
        lua_gettable(L, 1);

        lua_pushnumber(L, tuple._x);
        lua_rawseti(L, luaPushIndex, (int)Point::xOrdinal);
        lua_pushnumber(L, tuple._y);
        lua_rawseti(L, luaPushIndex, (int)Point::yOrdinal);      
   }
};

}
