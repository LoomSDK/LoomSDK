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
    
    /// @cond PRIVATE    
    // Loom IO is a class for reading/writing from stdin/stdout 
    // it is very simple and may be superceded at some point
    class IO {
        
        public static native function read(format:String):String;
        public static native function write(value:String);
        
    }

    /// @endcond
    
}