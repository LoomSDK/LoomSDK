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

package loom.graphics
{
    /**
     * Control global graphics subsystem behavior.
     */
    public native class Graphics
    {
        /**
         * Private API; simulates graphics context loss.
         */
        public static native function handleContextLoss():void;

        /**
         * Take a screenshot and save it to the specified path (in TGA format).
         */
        public static native function screenshot(path:String):void;

        /// No debug features enabled.
        public static var DEBUG_NONE 		= 0;

        /// Draw everything in wireframe.
        public static var DEBUG_WIREFRAME 	= 1;

        /// Simulate infinitely fast hardware - all draws do nothing. Useful
        /// for determining CPU/GPU bottleneck.
        public static var DEBUG_IFH 		= 2;

        /// Show internal statistics.
        public static var DEBUG_STATS 		= 4;

        /// Show debug text.
        public static var DEBUG_TEXT 		= 8;
        
        /**
         * Control debug mode behavior; see the DEBUG_* flags for details.
         */
        public static native function setDebug(flags:int):void;

        /** 
         * Set the background color for the graphics viewport, in RGBA.
         */
        public static native function setFillColor(color:int):void;

    }

}