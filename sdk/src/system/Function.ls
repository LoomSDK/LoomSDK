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
 *  A Function is a closure primitive. It captures statements, arguments, and a referencing environment for execution.
 *
 *  Functions are typically invoked with parenthesis operators `()`:
 *
 *  ```as3
 *  var f:Function = function(x:Number):Number { return x + 1; };
 *  f(1); // -> 2
 *  ```
 *
 *  The `call()` and `apply()` methods can also be used when the calling object needs to be specified.
 *
 *  As a first-class data type, a function can be assigned to variables and returned from functions:
 *
 *  ```as3
 *  var f1:Function = function(x:Number, y:Number):Number { return x + y; };
 *  var f2:Function = f1;
 *  f1(3,4); // -> 7
 *  f2(5,6); // -> 11
 *  ```
 *
 *  ```as3
 *  var g:Function = function(n:Number):Function {
 *     ⇥return function(x:Number) { return x + n; }
 *  };
 *  var skipTwo:Function = g(2);
 *  skipTwo(7); // -> 9
 *  skipTwo(8); // -> 10
 *  ```
 *
 *  @see #call()
 *  @see #apply()
 */
final class Function extends Object {

    /**
     *  Invokes the function with a context and comma-delimited set of arguments.
     *
     *  `call()` is very similar to `apply()`; the difference is how they accept arguments. `call()` expects them individually:
     *
     *  ```as3
     *  myFunc.call(null, arg1, arg2, arg3);
     *  ```
     *
     *  @param thisArg Value to use as the calling object, i.e. an instance for the method to be called on or null in the case of static/anonymous functions
     *  @param rest Zero or more arguments to pass into the function.
     *  @return The Object returned by the called function.
     */
    public native function call(thisArg:Object = null, ...rest):Object;

    /**
     *  Invokes the function with a context and vector of arguments.
     *
     *  `apply()` is very similar to `call()`; the difference is how they accept arguments. `apply()` expects them bundled in a Vector:
     *
     *  ```as3
     *  var args:Vector.<Object> = [arg1, arg2, arg3];
     *  myFunc.apply(null, args);
     *  ```
     *
     *  @param thisArg Value to use as the calling object, i.e. an instance for the method to be called on or null in the case of static/anonymous functions
     *  @param args Vector of arguments to pass into the function.
     *  @return The Object returned by the called function.
     */
    public native function apply(thisArg:Object = null, args:Vector.<Object> = null):Object;

    /**
     *  The number of formal arguments expected by the function. This does not include use of the `...rest` parameter.
     *
     *  Examples:
     *
     *  ```as3
     *  trace((function()        {}).length); // -> 0
     *  trace((function(a)       {}).length); // -> 1
     *  trace((function(a, b)    {}).length); // -> 2
     *  trace((function(...args) {}).length); // -> 0, rest param not counted
     *  ```
     *
     *  @return The number of formal arguments expected by the function
     */
    public native function get length():Number;

    private native static function _call(func:Function, thisArg:Object = null, ...args):Object;

    private native static function _apply(func:Function, thisArg:Object = null, args:Vector.<Object> = null):Object;

    private native static function _length(func:Function):Number;

}

}
