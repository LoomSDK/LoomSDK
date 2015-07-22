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

package system 
{

    /**
     *  Profiler class for runtime timing metrics of execution.
     */
    public static class Profiler 
    {  

        /**
        *  Returns true if profiling is enabled.
        */
        public static native function isEnabled():Boolean;

        /**
        *  Enable profiling.
        */
        public static native function enable();

        /**
        *  Disable profiling.
        */
        public static native function disable();

        /**
        *  Reset the profiling data and potentially dump the current data 
        *  to the console (if dump has been called).
        */        
        public static native function reset();

        /**
        *  Dumps the current profiler data to the console immediately and resets the profiler.
        */
        public static native function dump();

    }

}