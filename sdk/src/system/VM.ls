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

import system.reflection.Assembly;

/**
 * Callback when ticks occur in the VM.
 */
delegate TickDelegate();

/**
 *  The VM class represents a virtual machine in LoomScript.
 */
[Native(managed)]
native class VM {
    
    // will tick the actual VM, this may happen outside of the VM this method
    // is called from (ie. the owning VM)
    ///@cond PRIVATE
    private  native function tick();

    private static function _tick() {
        ticks();
    }
    ///@endcond
    
    /**
     *  Delegate that is called whenever the main VM ticks.
     */
    public static var ticks:TickDelegate;
    
    /**
     *  Delegate that is called whenever the VM has reloaded.
     */
    public native var onReload:NativeDelegate;

    /**
     * Open the VM (internal).
     */
    public native function open():void;
    
    /**
     * Close the VM (internal).
     */
    public native function close():void;
    
    /**
     * Return a reference to the currently executing VM.
     */
    public static native function getExecutingVM():VM;
    
    /**
     * Return the depth of the underlying Lua stack (internal).
     */
    public native function getStackSize():Number;
    
    /**
     * Print a report showing information about all allocated native structures.
     */
    public native function dumpManagedNatives():void;    
    
    /**
     * True when we are executing under the JIT.
     */
    static public native function isJIT():Boolean;
    
    
}

}