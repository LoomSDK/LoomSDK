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
 * A data type representing an IEEE-754 double-precision floating-point number. You can manipulate primitive numeric values by using the methods and properties associated with the Number class. This class is identical to the JavaScript Number class.
 * The properties of the Number class are static, which means you do not need an object to use them, so you do not need to use the constructor.
 */
final class Number extends Object 
{
    /**
     *
     *  Gets a string representation of the number truncated to the specificed decimal point     
     *
     *  @param fractionDigits the number of digits to the right of the decimal point to include
     *  @return String representation of the number truncated to the specified decimal digits
     */
    public native function toFixed(fractionDigits:int = 0):String;

    public static native function get MAX_VALUE():Number;
    public static native function get MIN_VALUE():Number;
    public static native function get NEGATIVE_INFINITY():Number;
    public static native function get POSITIVE_INFINITY():Number;

    /**
     * Parse a string into a Number.
     */
    public static native function fromString(value:String):Number;

    /// @cond PRIVATE

    private static native function _toFixed(value:Number, fractionDigits:int):String;

    /// @endcond

}

}