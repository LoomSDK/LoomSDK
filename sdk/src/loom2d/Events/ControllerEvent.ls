package loom2d.events
{
    /** A ControllerEvent is dispatched in response to user input through a game controller.
     * 
     *  To be notified of game controller events, add an event listener to the stage. Children
     *  of the stage won't be notified of game controller input.
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

        public static const CONTROLLER_ADDED:String = "addedController";
        public static const CONTROLLER_REMOVED:String = "removedController";

        private var mControllerID:uint;
        private var mButtonID:uint;
        private var mAxisID:uint;
        private var mAxisValue:Number;
        
        /** Creates a new KeyboardEvent. */
        public function ControllerEvent(type:String, controllerID:uint=0, buttonID:uint=0, 
                                      axisID:uint=0, axisValue:int=0)
        {
            super(type, false, controllerID);
            mControllerID = controllerID;
            mButtonID = buttonID;
            mAxisID = axisID;
            mAxisValue = axisValue < 0 ? -(axisValue / ( -32767)) : axisValue / 32767;
            mAxisValue = mAxisValue > 1 ? 1 : mAxisValue < -1 ? -1 : mAxisValue;
        }
        
        /** Contains the ID of controller. */
        public function get controllerID():uint { return mControllerID; }
        
        /** The button number. */
        public function get buttonID():uint { return mButtonID; }
        
        /** Contains the number of the axis. */ 
        public function get axisID():uint { return mAxisID; }
        
        /** Contains the value of the axis. */
        public function get axisValue():Number { return mAxisValue; }

        public function toString():String
        {
            return "[ControllerEvent controllerID=" + controllerID + " buttonID=" + buttonID + " axisID=" + axisID + " axisValue=" + axisValue + "]";
        }
    }
}