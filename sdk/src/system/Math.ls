/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package system {

/**
 *  The Math class is a utility for common mathematical functions in LoomScript.
 */
final class Math {

    /// @cond PRIVATE
    /**
     * @private
     */
    public static native function get RAND_MAX():Number;
    /// @endcond

    /**
     *  A mathematical constant for the ratio of the circumference of a circle to its diameter, expressed as pi, with a value of 3.141592653589793.
     */
    public static const PI:Number = 3.14159265358979323846;

    /**
     *  PI * 2
     */
    public static const TWOPI:Number = 3.14159265358979323846 * 2.0;

    /**
     *  A mathematical constant for the base of natural logarithms, expressed as e.
     */    
    public static const E : Number = 2.71828182845905;

    /**
     *   A mathematical constant for the natural logarithm of 10, expressed as loge10.
     */    
    public static const LN10 : Number = 2.302585092994046;

    /**
     *   A mathematical constant for the natural logarithm of 2, expressed as loge2.
     */    
    public static const LN2 : Number = 0.6931471805599453;

    /**
     *   A mathematical constant for the base-10 logarithm of the constant e (Math.E), expressed as log10e.
     */    
    public static const LOG10E : Number = 0.4342944819032518;

    /**
     *   A mathematical constant for the base-2 logarithm of the constant e, expressed as log2e.
     */    
    public static const LOG2E : Number = 1.442695040888963387;
        
    /**
     *    A mathematical constant for the square root of one-half.
     */    
    public static const SQRT1_2 : Number = 0.7071067811865476;

    /**
     *    A mathematical constant for the square root of 2.
     */    
    public static const SQRT2 : Number = 1.4142135623730951;    

    /**
     *  Returns a pseudo-random number n, where 0 <= n <= 1.
     */
    public static native function random():Number;
    
    /**
     *  Returns a pseudo-random number n, where min <= n <= max.
     */
    public static native function randomRange(min:Number, max:Number):Number;
    
    /**
     *  Returns a pseudo-random integer value n, where min <= n <= max.
     */
    public static native function randomRangeInt(min:int, max:int):int;
    
    /**
     *  Returns the absolute value for the number specified by the parameter value.
     */
    public static native function abs(value:Number):Number;

    /**
     *  Returns base to the power of exponent.
     */
    public static native function pow(base:Number, exponent:Number):Number;
	
    /**
     *  Returns the sine of the specified angle in radians.
     */
    public static native function sin(value:Number):Number;

    /**
     *  Returns the cosine of the specified angle in radians.
     */
    public static native function cos(value:Number):Number;

    /**
     *  Returns the tangent of the specified angle.
     */
    public static native function tan(value:Number):Number;

    /**
     *  Returns the square root of the specified number.
     */
    public static native function sqrt(value:Number):Number;

    /**
     *  Returns the angle of the point y/x in radians, when measured counterclockwise from a circle's x axis (where 0,0 represents the center of the circle).
     */
    public static native function atan2(y:Number, x:Number):Number;
    
    /**
     *  Returns the arc cosine of the number specified in the parameter val, in radians.
     */
    public static native function acos(val:Number):Number;

    /**
     *  Returns the arc sine for the number specified in the parameter val, in radians.
     */
    public static native function asin(val:Number):Number;
    
    /**
     *  Returns the value, in radians, of the angle whose tangent is specified in the parameter val.
     */
    public static native function atan(val:Number):Number;
    
    /**
     *  Returns the value of the base of the natural logarithm (e), to the power of the exponent specified in the parameter x.
     */
    public static native function exp(val:Number):Number;

    /**
     *  Returns the natural logarithm of the parameter val.
     */
    public static native function log(val:Number):Number;
    
    /**
     *  Evaluates val1 and val2 (or more values) and returns the largest value.
     */
    public static native function max(val1:Number, val2:Number, ...rest):Number;

    /**
     *  Fast path for max of just 2 values.
     */
    public static function max2(val1:Number, val2:Number):Number
    {
        return (val1 > val2) ? val1 : val2;
    }
    
    /**
     *  Evaluates val1 and val2 (or more values) and returns the smallest value.
     */
    public static native function min(val1:Number, val2:Number, ...rest):Number;
    
    /**
     *  Fast path for min of just 2 values.
     */
    public static function min2(val1:Number, val2:Number):Number
    {
        return (val1 > val2) ? val2 : val1;
    }

    /**
     *  Returns the floor of the number or expression specified in the parameter val.
     */
    public static native function floor(value:Number):Number;

    /**
     *  Returns the ceiling of the specified number or expression.
     */
    public static native function ceil(value:Number):Number;

    /**
     *  Rounds the value of the parameter value up or down to the nearest integer and returns the value.
     */
    public static native function round(value:Number):Number;

    /**
     *  Clamps the value to the specified minimum and maximum values.
     */
    public static function clamp(value:Number, minimum:Number = 0, maximum:Number = 1):Number
    {
        if(value < minimum) return minimum;
        if(value > maximum) return maximum;
        return value;
    }

    /**
     *  Checks if the value provided is equal to a Power of 2 Number (ie. 4, 8, 256, etc.)
     */
    public static function isPowerOf2(value:int):Boolean
    {
        return ((value != 0) && ((value & (value - 1)) == 0)) ? true : false;
    }

    /**
     *  Converts the angle provided, in degrees, to its radian representation.
     */
    static public function degToRad(deg:Number):Number
    {
        return deg * (Math.PI / 180.0);
    }

    /**
     *  Converts the angle provided, in radians, to its degree representation.
     */
    static public function radToDeg(rad:Number):Number
    {
        return rad * (180.0 / Math.PI);
    }
}

}
