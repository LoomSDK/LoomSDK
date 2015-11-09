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
    delegate AxisDelegate(axis:int, value:Number, raw:int);
    
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
        
        /** Name of a connected controller. */
        public native var name:String;
        
        /** Delegate for handling button events. */
        public native var onButtonEvent:ButtonDelegate;
        /** Delegate for handling axis events. */
        public native var onAxisEvent:AxisDelegate;
        
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
         * @return True if game controller is haptic, false if it is not haptic.
         */
        public native function isHaptic():Boolean;
        
        /**
         * Causes a game controller to start vibrating.
         * 
         * @param intensity Intensity of vibration ranging from 0 to 1.
         * @param ms Duration of vibration in miliseconds. Accepts GameController.RUMBLE_INFINITY for infinite duration.
         */
        public native function startRumble(intensity:Number, ms:uint);
        
        /**
         * Causes a game controller to stop vibrating.
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
         * Gets the value of queried axis. The value is converted to a number ranging from -1 to 1 for usability.
         * 
         * @param axis The id of wanted axis
         * @return Returns a range between -1 and 1
         */
        public native function getNormalizedAxis(axis:uint):Number;
        
        /**
         * Gets the id of the controller.
         * 
         * @return Returns id of controller.
         */
        public native function getID():int;
        
        /**
         * Checks if controller object is connected.
         * 
         * @return Returns true if connected, otherwise returns false.
         */
        public native function isConnected():Boolean;
    }

}