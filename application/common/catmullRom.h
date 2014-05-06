#ifndef _GRAPHICS_CATMULLROM_H_
#define _GRAPHICS_CATMULLROM_H_


#include <float.h>
#include "loom/common/utils/utTypes.h"


//------------------------------------------------------------------------------
// Catmull Rom Spline.
// This spline is interpolating not approximmating.  Which means the spline goes
// through all of its control points.
//
// It needs 4 control points to be valid.  Evaluate, Deriv and SecondDeriv
// expect a value between 0 and 1.0.  It currently works with Point2F and ColorF
// 
// You can use Deriv and SecondDeriv for curvature evaluation at a point.
//------------------------------------------------------------------------------


template <typename T>
class CatmullRom
{
public:
   // constructor/destructor
   CatmullRom() :
      _totalLength( 0.0f ),
      _count( 0 )
   {
   }   
   
   virtual ~CatmullRom()
   {
      clear();
   }  

   
   // set up
   bool init( const utArray<T>& positions, const utArray<float>& times)
   
   {
      // make sure not already initialized
      if (_count != 0)
         return false;
      
      unsigned int count = positions.size();
      
      // make sure data is valid
      if ( count < 4  )
         return false;
      
      _positions.reserve(count);
      _times.reserve(count);
      _count = count;
      
      // copy data
      unsigned int i;
      for ( i = 0; i < count; ++i )
      {
         _positions[i] = positions[i];
         _times[i] = times[i];
      }
      
      // set up curve segment lengths
      _lengths = new float[count-1];
      _totalLength = 0.0f;
      for ( i = 0; i < count-1; ++i )
      {
         _lengths[i] = segmentArcLength(i, 0.0f, 1.0f);
         _totalLength += _lengths[i];
      }
      
      return true;
      
   }
   
   bool setup(const utArray<T>& positions)
   {
      clear();
      
      // make sure not already initialized
      if (_count != 0)
         return false;
      
      // make sure data is valid
      if ( positions.size() < 4 )
         return false;
      
      _count = positions.size();
      _positions.reserve(_count);
      _times.reserve(_count);
            
      
      // copy data
      unsigned int i;
      for ( i = 0; i < _count; ++i )
      {
         _positions[i] = positions[i];
         _times[i] = i/(float)(_count - 1);
      }
      
      // set up curve segment lengths
      _lengths.reserve(_count);
      _totalLength = 0.0f;
      for ( i = 0; i < _count-1; ++i )
      {
         _lengths[i] = segmentArcLength(i, 0.0f, 1.0f);
         _totalLength += _lengths[i];
      }

      return true;
   }
   
   void clear()
   {
      _positions.clear(); 
      _times.clear();
      _lengths.clear();
      _totalLength = 0.0f;
      _count = 0;
      
   } 

   T evaluate( float t )
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
         return _positions[0];
      else if ( t >= _times[_count-1] )
         return _positions[_count-1];
      
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
         T A = _positions[0] - 2.0f*_positions[1] + _positions[2];
         T B = 4.0f*_positions[1] - 3.0f*_positions[0] - _positions[2];
         
         return _positions[0] + (0.5f*u)*(B + u*A);
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         T A = _positions[i-1] - 2.0f*_positions[i] + _positions[i+1];
         T B = _positions[i+1] - _positions[i-1];
         
         return _positions[i] + (0.5f*u)*(B + u*A);
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         // evaluate
         T A = 3.0f*_positions[i]
         - _positions[i-1]
         - 3.0f*_positions[i+1]
         + _positions[i+2];
         T B = 2.0f*_positions[i-1]
         - 5.0f*_positions[i]
         + 4.0f*_positions[i+1]
         - _positions[i+2];
         T C = _positions[i+1] - _positions[i-1];
         
         return _positions[i] + (0.5f*u)*(C + u*(B + u*A));
      }
      
   }

   
   T deriv( float t )
   {
      // make sure data is valid
      lmAssert( _count >= 2, "CatmullRom - Too Few Data Points" );
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
         T A = _positions[0] - 2.0f*_positions[1] + _positions[2];
         T B = 4.0f*_positions[1] - 3.0f*_positions[0] - _positions[2];
         
         return 0.5f*B + u*A;
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         T A = _positions[i-1] - 2.0f*_positions[i] + _positions[i+1];
         T B = _positions[i+1] - _positions[i-1];
         
         return 0.5f*B + u*A;
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         // evaluate
         T A = 3.0f*_positions[i]
         - _positions[i-1]
         - 3.0f*_positions[i+1]
         + _positions[i+2];
         T B = 2.0f*_positions[i-1]
         - 5.0f*_positions[i]
         + 4.0f*_positions[i+1]
         - _positions[i+2];
         T C = _positions[i+1] - _positions[i-1];
         
         return 0.5f*C + u*(B + 1.5f*u*A);
      }
      
   }

   T secondDeriv( float t )
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
         return _positions[0] - 2.0f*_positions[1] + _positions[2];
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         return _positions[i-1] - 2.0f*_positions[i] + _positions[i+1];
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         // evaluate
         T A = 3.0f*_positions[i]
         - _positions[i-1]
         - 3.0f*_positions[i+1]
         + _positions[i+2];
         T B = 2.0f*_positions[i-1]
         - 5.0f*_positions[i]
         + 4.0f*_positions[i+1]
         - _positions[i+2];
         
         return B + (3.0f*u)*A;
      }
      
   } 
   
   //-------------------------------------------------------------------------------
   // Find parameter s distance in arc length from Q(t1)
   // Returns max float if can't find it
   //-------------------------------------------------------------------------------
   float findParameterByDistance( float t1, float s )
   {
      // ensure that we remain within valid parameter space
      if ( s > arcLength(t1, _times[_count-1]) )
         return _times[_count-1];
      
      // make first guess
      float p = t1 + s*(_times[_count-1]-_times[0])/_totalLength;
      for ( unsigned int i = 0; i < 32; ++i )
      {
         // compute function value and test against zero
         float func = arcLength(t1, p) - s;
         if ( fabs(func) < 1.0e-3f )
         {
            return p;
         }
         // perform Newton-Raphson iteration step
         float speed = deriv(p).getMagnitude();
         lmAssert( !( speed < 1.0e-4f), "Catmull Rom - Newton Rhapson step failed" );
         p -= func/speed;
      }
      
      // done iterating, return failure case
      return FLT_MAX;
      
   }   
   
   
   float arcLength( float t1, float t2 )
   {
      if ( t2 <= t1 )
         return 0.0f;
      
      if ( t1 < _times[0] )
         t1 = _times[0];
      
      if ( t2 > _times[_count-1] )
         t2 = _times[_count-1];
      
      // find segment and parameter
      unsigned int seg1;
      for ( seg1 = 0; seg1 < _count-1; ++seg1 )
      {
         if ( t1 <= _times[seg1+1] )
         {
            break;
         }
      }
      float u1 = (t1 - _times[seg1])/(_times[seg1+1] - _times[seg1]);
      
      // find segment and parameter
      unsigned int seg2;
      for ( seg2 = 0; seg2 < _count-1; ++seg2 )
      {
         if ( t2 <= _times[seg2+1] )
         {
            break;
         }
      }
      float u2 = (t2 - _times[seg2])/(_times[seg2+1] - _times[seg2]);
      
      float result;
      // both parameters lie in one segment
      if ( seg1 == seg2 )
      {
         result = segmentArcLength( seg1, u1, u2 );
      }
      // parameters cross segments
      else
      {
         result = segmentArcLength( seg1, u1, 1.0f );
         for ( unsigned int i = seg1+1; i < seg2; ++i )
            result += _lengths[i];
         result += segmentArcLength( seg2, 0.0f, u2 );
      }
      
      return result;
      
   }   
   

   inline float getLength() { return _totalLength; }
   
protected:
   // return length of curve between u1 and u2
   float segmentArcLength(unsigned int i, float u1, float u2 )
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
         A = _positions[0] - 2.0f*_positions[1] + _positions[2];
         B = 4.0f*_positions[1] - 3.0f*_positions[0] - _positions[2];
         
      }
      // quadratic Catmull-Rom for Q_n-1
      else if (i >= _count-2)
      {
         i = _count-2;
         A = _positions[i-1] - 2.0f*_positions[i] + _positions[i+1];
         B = _positions[i+1] - _positions[i-1];
      }
      // cubic Catmull-Rom for interior segments
      else
      {
         A = 3.0f*_positions[i]
         - _positions[i-1]
         - 3.0f*_positions[i+1]
         + _positions[i+2];
         B = 2.0f*_positions[i-1]
         - 5.0f*_positions[i]
         + 4.0f*_positions[i+1]
         - _positions[i+2];
         C = _positions[i+1] - _positions[i-1];
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
   
   utArray<T>        _positions;     // sample positions
   utArray<float>    _times;         // time to arrive at each point
   utArray<float>   _lengths;       // length of each curve segment
   float           _totalLength;   // total length of curve
   unsigned int    _count;         // number of points and times
   
private:
   // copy operations
   // made private so they can't be used
   CatmullRom( const CatmullRom& other );
   CatmullRom& operator=( const CatmullRom& other );
};

#endif
