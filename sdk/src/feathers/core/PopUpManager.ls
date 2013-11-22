/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
    import feathers.core.IFocusManager;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Quad;
    import loom2d.display.Stage;
    import loom2d.events.EnterFrameEvent;
    import loom2d.events.Event;
    import loom2d.events.ResizeEvent;

    /**
     * Adds a display object as a pop-up above all content.
     */
    public class PopUpManager
    {
        /**
         * @private
         */
        private static const POPUP_TO_OVERLAY:Dictionary.<String, Object> = new Dictionary.<String, Object>(true);

        /**
         * @private
         */
        private static const POPUP_TO_FOCUS_MANAGER:Dictionary.<String, Object> = new Dictionary.<String, Object>(true);
        
        /**
         * A function that returns a display object to use as an overlay for
         * modal pop-ups.
         *
         * This function is expected to have the following signature: `function():DisplayObject`.
         * 
         */
        public static var overlayFactory:Function = defaultOverlayFactory;

        /**
         * The default factory that creates overlays for modal pop-ups.
         */
        public static function defaultOverlayFactory():DisplayObject
        {
            const quad:Quad = new Quad(100, 100, 0x000000);
            quad.alpha = 0;
            return quad;
        }

        /**
         * @private
         */
        protected static var ignoreRemoval:Boolean = false;

        /**
         * @private
         */
        protected static var _root:DisplayObjectContainer;

        /**
         * The container where pop-ups are added. If not set manually, defaults
         * to the Starling stage.
         */
        public static function get root():DisplayObjectContainer
        {
            return _root;
        }

        /**
         * @private
         */
        public static function set root(value:DisplayObjectContainer):void
        {
            if(_root == value)
            {
                return;
            }
            const popUpCount:int = popUps.length;
            const oldIgnoreRemoval:Boolean = ignoreRemoval; //just in case
            ignoreRemoval = true;
            for(var i:int = 0; i < popUpCount; i++)
            {
                var popUp:DisplayObject = popUps[i];
                var overlay:DisplayObject = DisplayObject(POPUP_TO_OVERLAY[i]);
                popUp.removeFromParent(false);
                if(overlay)
                {
                    overlay.removeFromParent(false);
                }
            }
            ignoreRemoval = oldIgnoreRemoval;
            _root = value;
            const calculatedRoot:DisplayObjectContainer = _root ? _root : Loom2D.stage;
            for(i = 0; i < popUpCount; i++)
            {
                popUp = popUps[i];
                overlay = DisplayObject(POPUP_TO_OVERLAY[i]);
                if(overlay)
                {
                    calculatedRoot.addChild(overlay);
                }
                calculatedRoot.addChild(popUp);
            }
        }

        /**
         * @private
         */
        protected static var popUps:Vector.<DisplayObject> = new <DisplayObject>[];
        
        /**
         * Adds a pop-up to the stage.
         */
        public static function addPopUp(popUp:DisplayObject, isModal:Boolean = true, isCentered:Boolean = true, customOverlayFactory:Function = null):void
        {
            const calculatedRoot:DisplayObjectContainer = _root ? _root : Loom2D.stage;
            if(isModal)
            {
                if(customOverlayFactory == null)
                {
                    customOverlayFactory = overlayFactory;
                }
                if(customOverlayFactory == null)
                {
                    customOverlayFactory = defaultOverlayFactory;
                }
                const overlay:DisplayObject = customOverlayFactory.call() as DisplayObject;
                overlay.width = calculatedRoot.stage.stageWidth;
                overlay.height = calculatedRoot.stage.stageHeight;
                calculatedRoot.addChild(overlay);
                POPUP_TO_OVERLAY[popUp] = overlay;
            }

            popUps.push(popUp);
            calculatedRoot.addChild(popUp);
            popUp.addEventListener(Event.REMOVED_FROM_STAGE, popUp_removedFromStageHandler);

            if(popUps.length == 1)
            {
                calculatedRoot.stage.addEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
            }

            if(FocusManager.isEnabled && popUp is DisplayObjectContainer)
            {
                POPUP_TO_FOCUS_MANAGER[popUp] = new FocusManager(DisplayObjectContainer(popUp));
            }

            if(isCentered)
            {
                centerPopUp(popUp);
            }
        }
        
        /**
         * Removes a pop-up from the stage.
         */
        public static function removePopUp(popUp:DisplayObject, dispose:Boolean = false):void
        {
            const index:int = popUps.indexOf(popUp);
            if(index < 0)
            {
                throw new ArgumentError("Display object is not a pop-up.");
            }
            popUp.removeFromParent(dispose);
        }

        /**
         * Determines if a display object is a pop-up.
         */
        public static function isPopUp(popUp:DisplayObject):Boolean
        {
            return popUps.indexOf(popUp) >= 0;
        }

        /**
         * Determines if a display object is the top-most pop-up.
         */
        public static function isTopLevelPopUp(popUp:DisplayObject):Boolean
        {
            return popUps.indexOf(popUp) == (popUps.length - 1);
        }
        
        /**
         * Centers a pop-up on the stage.
         */
        public static function centerPopUp(popUp:DisplayObject):void
        {
            const stage:Stage = Loom2D.stage;
            if(popUp is IFeathersControl)
            {
                IFeathersControl(popUp).validate();
            }
            popUp.x = (stage.stageWidth - popUp.width) / 2;
            popUp.y = (stage.stageHeight - popUp.height) / 2;
        }

        /**
         * @private
         */
        protected static function popUp_removedFromStageHandler(event:Event):void
        {
            if(ignoreRemoval)
            {
                return;
            }
            const popUp:DisplayObject = DisplayObject(event.currentTarget);
            popUp.removeEventListener(Event.REMOVED_FROM_STAGE, popUp_removedFromStageHandler);
            const index:int = popUps.indexOf(popUp);
            popUps.splice(index, 1);
            const overlay:DisplayObject = DisplayObject(POPUP_TO_OVERLAY[popUp]);
            if(overlay)
            {
                //this is a temporary workaround for Starling issue #131
                Loom2D.stage.addEventListener(EnterFrameEvent.ENTER_FRAME, function(event:EnterFrameEvent):void
                {
                    trace("WARNING - Not Yet Implemented - PopUpManager ENTER_FRAME hack.");
                    //event.currentTarget.removeEventListener(event.type, arguments.callee);
                    overlay.removeFromParent(true);
                    //delete POPUP_TO_OVERLAY[popUp];
                    POPUP_TO_FOCUS_MANAGER[popUp] = null;
                });
            }
            const focusManager:IFocusManager = POPUP_TO_FOCUS_MANAGER[popUp] as IFocusManager;
            if(focusManager)
            {
                //delete POPUP_TO_FOCUS_MANAGER[popUp];
                POPUP_TO_FOCUS_MANAGER[popUp] = null;
                FocusManager.removeFocusManager(focusManager);
            }

            if(popUps.length == 0)
            {
                Loom2D.stage.removeEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
            }
        }

        /**
         * @private
         */
        protected static function stage_resizeHandler(event:ResizeEvent):void
        {
            const stage:Stage = Loom2D.stage;
            const popUpCount:int = popUps.length;
            for(var i:int = 0; i < popUpCount; i++)
            {
                var popUp:DisplayObject = popUps[i];
                var overlay:DisplayObject = DisplayObject(POPUP_TO_OVERLAY[popUp]);
                if(overlay)
                {
                    overlay.width = stage.stageWidth;
                    overlay.height = stage.stageHeight;
                }
            }
        }
    }
}