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

package loom.platform
{
    public static class GameController
    {
        /**
         * Used in startRumble method for infinite rumble duration.
         */
        public static var RUMBLE_INFINITY:uint = 4294967295;
        
        /**
         * Returns number of connected game controllers.
         * 
         * @return An integer that represents the number of connected game controllers.
         */
        public static native function numDevices():int;
        
        /**
         * Checks if game controller is haptic.
         * 
         * @param device The id of game controller.
         * @return True if game controller is haptic, false if it is not haptic.
         */
        public static native function isHaptic(device:int):Boolean;
        
        /**
         * Causes a game controller to start vibrating.
         * 
         * @param device The id of game controller.
         * @param intensity Intensity of vibration ranging from 0 to 1.
         * @param ms Duration of vibration in miliseconds. Accepts GameController.RUMBLE_INFINITY for infinite duration.
         */
        public static native function startRumble(device:int, intensity:Number, ms:uint);
        
        /**
         * Causes a game controller to stop vibrating.
         * 
         * @param device The id of game controller.
         */
        public static native function stopRumble(device:int);
    }

}