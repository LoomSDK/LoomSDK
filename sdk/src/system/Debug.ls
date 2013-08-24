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

    import system.reflection.MethodBase;

    /// @cond PRIVATE
    /**
     *  Represents an frame in a loom callstack. Instances of this class can be retreived by calling Debug.getCallStack()
     *
     *  @see Debug.getCallStack()
     */
    class CallStackInfo {
        
        /**
         *  The LoomScript source file.
         */ 
        public var source:String;
        
        /**
         *  The line of source that was executed in this callstack frame. 
         */
        public var line:Number;
        
        // 
        /**
         *  Represents either a method, a contstructor, a propery getter/setter etc
         *  The callstack has full reflection information.
         */
        public var method:MethodBase;
        
        
    }
    /// @endcond
    
    class Breakpoint {
            
        public var source:String;
        public var line:Number;
        
    }

    
    /**
     *  The Debug class provides methods that aid in debugging a %Loom %Application.
     */
    class Debug {
        
        // TODO: We now have debug/release builds, we need to add Debug metatags or some light preprocessor 
        // stuff for debug/release builds, this should be a NOP basically
        /// @cond PRIVATE
        public static function print(message:String) 
        {
        
            trace(message);
            
        }
        /// @endcond
                
        /**
         *  Perform an assertion check on a loomscript expression or Object.
         *
         *  @param expression The object to be asserted.
         *  @param message The message to print if the assertion fails.
         */
        public static native function assert(expression:Object, message:String = "");

        /**
         * Internally called to handle a throw keyword.
         */
        public static function assertException(e:Error)
        {
            Debug.assert(false, e.toString());
        }
        
        /**
         *  Perform an debugber break if supplied expression fails
         *
         *  @param expression The object to be tested.
         */
        public static function debug(expression:Object = false) {
        
            if (expression)
                return;
                
            debugBreak = true;    
            
        }
        
        /*
         * Initializes the Lua VM debug hook. At this point,
         * we are  running under the debugger.
         */
        public static native function setDebugHook();
        
        /*
         * Retrieves the locals of the given stack index.
         */
        public static native function getLocals(snapshot:Vector.<CallStackInfo>, stackLevel:Number):Dictionary.<String, Object>;
        
        /*
         * Adds a breakpoint at the given source and line number.
         */
        public static native function addBreakpoint(source:String, line:Number);

        /*
         * Removes a breakpoint at the given source and line number.
         */
        public static native function removeBreakpoint(source:String, line:Number);

        /*
         * Removes a breakpoint at the given index.
         */
        public static native function removeBreakpointAtIndex(index:Number);

        /*
         * Removes all breakpoints.
         */
        public static native function removeAllBreakpoints();

        /*
         * Retrieves current breakpoints.
         */
        public static native function getBreakpoints():Vector.<Breakpoint>;

        /*
         * Checks if there is a breakpoint at the given source and line.
         */
        public static native function hasBreakpoint(source:String, line:Number):Boolean;
        
        
        // If true, we have hit a Debug.debug() break.
        public static native var debugBreak:Boolean;        
        
        // If set, this is the current method we are stepping over or finishing before
        // continuing to step under the debugger.
        public static native var finishMethod:MethodBase;

        /**
         *  When this is true, the debugger coroutine will block the main application code (for hitting breakpoints, stepping code, etc).
         */
        public static native var blocking:Boolean;
 
        /**
         *  When true, we are stepping over code.
         */
        public static native var stepOver:Boolean = false;
        
        /**
         *  When true, we are stepping code.
         */
        public static static native var stepping:Boolean = false;

        /**
         * When set, we have hit a fatal assertion and while we can inspect the 
         * program state under the debugger we cannot continue execution.
         */ 
        public static native var assertion:Boolean;        
        
        /*
         * Delegates for line, return, call, and assert events.
         */
        public static native var lineEventDelegate:NativeDelegate;
        public static native var returnEventDelegate:NativeDelegate;
        public static native var callEventDelegate:NativeDelegate;
        public static native var assertEventDelegate:NativeDelegate;
        
    }
    
}