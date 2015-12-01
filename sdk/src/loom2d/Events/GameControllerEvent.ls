package loom2d.events
{
    /** A GameControllerEvent is dispatched in response to connecting or disconnecting a game controller.
     * 
     *  To be notified of game controller events, add an event listener to the stage. Children
     *  of the stage won't be notified of game controller input.
     *  
     *  @see loom2d.display.Stage
     */  
    public class GameControllerEvent extends Event
    {
        /** Event type for a game controller being connected. */
        public static const CONTROLLER_ADDED:String = "addedController";

        /** Event type for a game controller being disconnected. */
        public static const CONTROLLER_REMOVED:String = "removedController";

        private var mControllerID:uint;

        /** Creates a new GameControllerEvent. */
        public function GameControllerEvent(type:String, controllerID:uint=0)
        {
            super(type, false, controllerID);
            mControllerID = controllerID;
        }

        /** Contains the ID of controller. */
        public function get controllerID():uint { return mControllerID; }

        public function toString():String
        {
            return "[GameControllerEvent controllerID=" + controllerID + "]";
        }
    }
}