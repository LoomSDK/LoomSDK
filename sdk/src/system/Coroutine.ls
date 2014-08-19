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
 *  The Coroutine class is an interface to the powerful bidirectional coroutine implementation in the Lua runtime.
 */
final class Coroutine {

    public var alive = true;
    
    public function cancel() {
        
        alive = false;
        _this = null;
        thread = null;
        
    }

    
    /**
     *  Create a Coroutine with a function that the coroutine will run.
     *
     *  Coroutines start in a suspended state, you must call resume to start them.
     *
     *  @param f The function that the coroutine will run.
     */
    public static function create(f:Function):Coroutine
    {
        var c:Coroutine = new Coroutine();
        c.thread = _create(f, c);
        return c;   
    }
    
    /**
     *  Resume the coroutine, with the provided arguments (these will be used as function parameters on the first invoke of resume
     *  or on subsequent resume a single return value to the last yield statement in the coroutine.
     */
    public function resume(...args):Object {
    
    
        // do not attempt to resume dead coroutines, it is bad for you
        Debug.assert(alive);        
    
        // if we're initializing a method, prime it 
        if (_initMethod) {
        
            _initMethod = false;

            // we have a this arg, we need to prepend            
            if (_this) {
            
                var thisArgs:Vector.<Object> = [_this];
                args = thisArgs.concat(args);
            }
            
            // prime the method call
            _resume(thread, args, this);
            
            // we don't need the args for next call
            args.clear();
            
        }
        
        // resume the thread
        var retValue = _resume(thread, args, this);
        
        // did we terminate?
        if (!alive) {
        
            _this = null;
            thread = null;
        }

        // return the value of the yield(x);
        return retValue;
        
    }
    
    /// @cond PRIVATE    
    /** @private */
    public var thread:Object;
    
    public static native function _create(f:Function, c:Coroutine):Object;

    public static native function _resume(thread:Object, args:Vector, c:Coroutine):Object;
    
    // If we belong to an instance method, the instance will be held here
    private var _this:Object = null;
    
    // methods start in a suspected state and require a resume with arguments to set their state
    // this flag is set in this case to tell the runtime, it is transparent to the user
    private var _initMethod:Boolean = false; 
    
    /// @endcond
    

}

}