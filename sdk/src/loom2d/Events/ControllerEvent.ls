// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.events
{
    /** A KeyboardEvent is dispatched in response to user input through a keyboard.
     * 
     *  This is Starling's version of the Flash KeyboardEvent class. It contains the same 
     *  properties as the Flash equivalent. 
     * 
     *  To be notified of keyboard events, add an event listener to the Starling stage. Children
     *  of the stage won't be notified of keybaord input. Starling has no concept of a "Focus"
     *  like native Flash.
     *  
     *  @see loom2d.display.Stage
     */  
    public class ControllerEvent extends Event
    {
        /** Event type for a button that was released. */
        public static const BUTTON_UP:String = "buttonUp";
        
        /** Event type for a button that was pressed. */
        public static const BUTTON_DOWN:String = "buttonDown";

        /** Event type for an axis being moved. */
        public static const AXIS_MOTION:String = "axisMoved";

        /** Event type for hat switch being moved. */
        public static const HAT_MOTION:String = "hatMoved";
        
        private var mControllerID:uint;
        private var mButtonID:uint;
        private var mAxisID:uint;
        private var mAxisValue:Number;
        private var mHatID:uint;
		private var mHatValue:uint;
        
        /** Creates a new KeyboardEvent. */
        public function ControllerEvent(type:String, controllerID:uint=0, buttonID:uint=0, 
                                      axisID:uint=0, axisValue:Number=0, 
                                      hatID:uint=0, hatValue:uint=0)
        {
            super(type, false, controllerID);
            mControllerID = controllerID;
            mButtonID = buttonID;
            mAxisID = axisID;
            mAxisValue = axisValue;
            mHatID = hatID;
            mHatValue = hatValue;
        }
        
        /** Contains the ID of controller. */
        public function get controllerID():uint { return mControllerID; }
        
        /** The button number. */
        public function get buttonID():uint { return mButtonID; }
        
        /** Contains the number of the axis. */ 
        public function get axisID():uint { return mAxisID; }
        
        /** Contains the value of the axis. */
        public function get axisValue():Number { return mAxisValue; }
        
        /** Contains the id of the Hat switch. */
        public function get hatID():int { return mHatID; }
        
        /** Contains the value of the Hat switch. */
        public function get hatValue():uint { return mHatValue; }

        public function toString():String
        {
            return "[ControllerEvent controllerID=" + controllerID + " buttonID=" + buttonID + " axisID=" + axisID + " axisValue=" + axisValue + " hatID=" + hatID + " hatValue=" + hatValue +"]";
        }
    }
}