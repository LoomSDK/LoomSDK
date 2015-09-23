package loom2d.events
{
    /** A GameControllerEvent is dispatched in response to user input through a game controller.
     * 
     *  To be notified of game controller events, add an event listener to the stage. Children
     *  of the stage won't be notified of game controller input.
     *  
     *  @see loom2d.display.Stage
     */  
    public class GameControllerEvent extends Event
    {
        /** Event type for a button that was released. */
        public static const BUTTON_UP:String = "buttonUp";
        
        /** Event type for a button that was pressed. */
        public static const BUTTON_DOWN:String = "buttonDown";

        /** Event type for an axis being moved.
         * WARNING: Clone axis event data if you want to keep it. Otherwise it will be overwritten on next event update. */
        public static const AXIS_MOTION:String = "axisMoved";

        /** Event type for a game controller being connected. */
        public static const CONTROLLER_ADDED:String = "addedController";

        /** Event type for a game controller being disconnected. */
        public static const CONTROLLER_REMOVED:String = "removedController";

        private var mControllerID:uint;
        private var mButtonID:uint;
        private var mAxisID:uint;
        private var mAxisValue:Number;

        /** Creates a new GameControllerEvent. */
        public function GameControllerEvent(type:String, controllerID:uint=0, buttonID:uint=0, 
                                      axisID:uint=0, axisValue:int=0)
        {
            super(type, false, controllerID);
            mControllerID = controllerID;
            mButtonID = buttonID;
            mAxisID = axisID;
            mAxisValue = axisValue < 0 ? -(axisValue / ( -32767)) : axisValue / 32767;
            mAxisValue = mAxisValue > 1 ? 1 : mAxisValue < -1 ? -1 : mAxisValue;
        }

        /** @private */
        public function reconstruct(type:String, bubbles:Boolean=false, data:Object=null, controllerID:uint = 0,buttonID:uint = 0, 
                                      axisID:uint = 0, axisValue:int = 0):GameControllerEvent {
            mControllerID = controllerID;
            mButtonID = buttonID;
            mAxisID = axisID;
            mAxisValue = axisValue < 0 ? -(axisValue / ( -32767)) : axisValue / 32767;
            mAxisValue = mAxisValue > 1 ? 1 : mAxisValue < -1 ? -1 : mAxisValue;
            return this;
        }

        /** Contains the ID of controller. */
        public function get controllerID():uint { return mControllerID; }
        
        /** The button number. */
        public function get buttonID():uint { return mButtonID; }
        
        /** Contains the id of the axis. */ 
        public function get axisID():uint { return mAxisID; }
        
        /** Contains the value of the axis. */
        public function get axisValue():Number { return mAxisValue; }

        public function toString():String
        {
            return "[GameControllerEvent controllerID=" + controllerID + " buttonID=" + buttonID + " axisID=" + axisID + " axisValue=" + axisValue + "]";
        }
    }
}