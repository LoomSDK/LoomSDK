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
    import loom2d.events.GameControllerEvent;
    
    delegate ButtonDelegate(button:int, pressed:Boolean);
    delegate AxisDelegate(axis:int, value:Number);
    
    public final native class GameController
    {
        /**
         * Used in startRumble method for infinite rumble duration.
         */
        public static var RUMBLE_INFINITY:uint = 4294967295;
        
        /**
         * Helper variables for identifying buttons
         */
        public static var BUTTON_A:uint             =  0;
        public static var BUTTON_B:uint             =  1;
        public static var BUTTON_X:uint             =  2;
        public static var BUTTON_Y:uint             =  3;
        public static var BUTTON_BACK:uint          =  4;
        public static var BUTTON_GUIDE:uint         =  5;
        public static var BUTTON_START:uint         =  6;
        public static var BUTTON_LEFTSTICK:uint     =  7;
        public static var BUTTON_RIGHTSTICK:uint    =  8;
        public static var BUTTON_LEFTSHOULDER:uint  =  9;
        public static var BUTTON_RIGHTSHOULDER:uint = 10;
        public static var BUTTON_DPAD_UP:uint       = 11;
        public static var BUTTON_DPAD_DOWN:uint     = 12;
        public static var BUTTON_DPAD_LEFT:uint     = 13;
        public static var BUTTON_DPAD_RIGHT:uint    = 14;
        /**
         * BUTTON_COUNT is not a valid button by itself
         * It is used to help iterating through buttons
         */
        public static var BUTTON_MAX:uint = 15;
        
        /**
         * Helper variables for identifying axes
         */
        public static var AXIS_LEFTX:uint        = 0;
        public static var AXIS_LEFTY:uint        = 1;
        public static var AXIS_RIGHTX:uint       = 2;
        public static var AXIS_RIGHTY:uint       = 3;
        public static var AXIS_TRIGGERLEFT:uint  = 4;
        public static var AXIS_TRIGGERRIGHT:uint = 5;
        /**
         * AXIS_COUNT is not a valid axis by itself
         * It is used to help iterating through axes
         */
        public static var AXIS_MAX:uint = 6;
        
        /** Specifies the number of connected game controllers. */
        public static native var numControllers:int;
        
        public native var onButtonEvent:ButtonDelegate;
        public native var onAxisMoved:AxisDelegate;
        
        /**
         * Returns a GameController object.
         * 
         * @param index The index of the controller
         * @return Returns a GameController if it is connected
         */
        public static native function getGameController(index:int = -1):GameController;
        
        /**
         * Checks if game controller is haptic.
         * 
         * @param device The id of game controller.
         * @return True if game controller is haptic, false if it is not haptic.
         */
        public native function isHaptic():Boolean;
        
        /**
         * Causes a game controller to start vibrating.
         * 
         * @param device The id of game controller.
         * @param intensity Intensity of vibration ranging from 0 to 1.
         * @param ms Duration of vibration in miliseconds. Accepts GameController.RUMBLE_INFINITY for infinite duration.
         */
        public native function startRumble(intensity:Number, ms:uint);
        
        /**
         * Causes a game controller to stop vibrating.
         * 
         * @param device The id of game controller.
         */
        public native function stopRumble();
        
        /**
         * Gets the state of a specific button.
         * 
         * @param button The id of wanted button
         * @return Returns true if button is pressed, otherwise returns false.
         */
        public native function getButton(button:uint):Boolean;
        
        /**
         * Gets the value of queried axis.
         * 
         * @param axis The id of wanted axis
         * @return Returns a number between -32768 and 32767
         */
        public native function getAxis(axis:uint):int;
        
        /**
         * Helper function to convert axis value into a value between 0 and 1.
         * 
         * @param value Value of axis that you need normalized.
         * @return Returns a value between 0 and 1
         */
        public static function convertAxis(value:int):Number
        {
            return value < 0 ? -(value / ( -32768)) : value / 32767;
        }
    }

}