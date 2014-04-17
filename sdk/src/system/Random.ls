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
 *  The Random class is an alternative to Math.random() functionality based off of the MersenneTwister random number generation method.
 */
final class Random {

    /**
     *  Sets the seeding for the random number generation to follow. 
     *  If not set to something unique for the current execution, your 
     *  application will always generate the same sequence of values.
     */
    public static native function setSeed(seed:int):void;
    
    /**
     *  Returns a pseudo-random number n, where 0.0 <= n <= 1.0
     */
    public static native function rand():Number;
    
    /**
     *  Returns a pseudo-random number n, where min <= n <= max.
     */
    public static native function randRange(min:Number, max:Number):Number;
    
    /**
     *  Returns a pseudo-random integer value n, where min <= n <= max.
     */
    public static native function randRangeInt(min:int, max:int):int;
   
    /**
     *  Returns a pseudo-random number n, between -1.0 and 1.0, using the given mean and deviation.
     */
    public static native function randNormal(mean:Number, deviation:Number):Number;
   
    /**
     *  Returns a pseudo-random negative exponential number with given curve halfLife.
     */
    public static native function randNegativeExponential(halfLife:Number):Number;
   
    /**
     *  Returns a pseudo-random integer value using Poisson Distrubution and the given mean.
     */
    public static native function randPoisson(mean:Number):int;
}
}
