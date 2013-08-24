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
 *  Function represents a function primitive in LoomScript.
 *
 *  A function can be passed as a regular object and invoked via the call() method.
 */
final class Function extends Object {

    /**
     *  Invokes the specified function.
     *
     *  @param theArg either the instance for the method to be called on or null in the case of static/anonymous functions
     *  @param ...args Arbitrary list of arguments to pass in the function call.
     *  @return The Object returned by the called function.
     */
     
    public native function call(thisArg:Object = null, ...args):Object;
    
    /**
     *  Invokes the specified function.
     *
     *  @param theArg either the instance for the method to be called on or null in the case of static/anonymous functions
     *  @param args a vector containing the arguments to apply to the function
     *  @return The Object returned by the called function.
     */

    /**
     *  Gets the maximum number of arguments a member or local function can be passed
     *
     *  @return The maximum number of arguments a member or local function can be passed
     */
    public native function get length():Number;
    
    public native function apply(thisArg:Object = null, args:Vector.<Object> = null):Object;
     
    private native static function _call(func:Function, thisArg:Object = null, ...args):Object;
    
    private native static function _apply(func:Function, thisArg:Object = null, args:Vector.<Object> = null):Object;
    
    private native static function _length(func:Function):Number;

}

}