/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.popups
{
    import feathers.controls.Callout;

    import System.Errors.IllegalOperationError;

    import Loom2D.Display.DisplayObject;
    import Loom2D.Events.Event;
    import Loom2D.Events.EventDispatcher;

    /**
     * @inheritDoc
     */
    [Event(name="close",type="starling.events.Event")]

    /**
     * Displays pop-up content (such as the List in a PickerList) in a Callout.
     *
     * @see feathers.controls.PickerList
     * @see feathers.controls.Callout
     */
    public class CalloutPopUpContentManager extends EventDispatcher implements IPopUpContentManager
    {
        /**
         * Constructor.
         */
        public function CalloutPopUpContentManager()
        {
        }

        /**
         * The factory used to create the `Callout` instance. If
         * `null`, `Callout.calloutFactory()` will be used.
         *
         * Note: If you change this value while a callout is open, the new
         * value will not go into effect until the callout is closed and a new
         * callout is opened.
         *
         * @see feathers.controls.Callout#calloutFactory
         */
        public var calloutFactory:Function;

        /**
         * The direction of the callout.
         *
         * Note: If you change this value while a callout is open, the new
         * value will not go into effect until the callout is closed and a new
         * callout is opened.
         *
         * @see feathers.controls.Callout#DIRECTION_ANY
         * @see feathers.controls.Callout#DIRECTION_UP
         * @see feathers.controls.Callout#DIRECTION_DOWN
         * @see feathers.controls.Callout#DIRECTION_LEFT
         * @see feathers.controls.Callout#DIRECTION_RIGHT
         */
        public var direction:String = Callout.DIRECTION_ANY;

        /**
         * Determines if the callout will be modal or not.
         *
         * Note: If you change this value while a callout is open, the new
         * value will not go into effect until the callout is closed and a new
         * callout is opened.
         */
        public var isModal:Boolean = true;

        /**
         * @private
         */
        protected var content:DisplayObject;

        /**
         * @private
         */
        protected var callout:Callout;

        /**
         * @inheritDoc
         */
        public function open(content:DisplayObject, source:DisplayObject):void
        {
            if(this.content)
            {
                throw new IllegalOperationError("Pop-up content is already defined.");
            }

            this.content = content;
            this.callout = Callout.show(content, source, this.direction, this.isModal, this.calloutFactory);
            this.callout.addEventListener(Event.CLOSE, callout_closeHandler);
        }

        /**
         * @inheritDoc
         */
        public function close():void
        {
            if(!this.callout)
            {
                return;
            }
            this.callout.close();
        }

        /**
         * @inheritDoc
         */
        public function dispose():void
        {
            this.close();
        }

        /**
         * @private
         */
        protected function cleanup():void
        {
            this.content = null;
            this.callout.content = null;
            this.callout.removeEventListener(Event.CLOSE, callout_closeHandler);
            this.callout = null;
        }

        /**
         * @private
         */
        protected function callout_closeHandler(event:Event):void
        {
            this.cleanup();
            this.dispatchEventWith(Event.CLOSE);
        }
    }
}
