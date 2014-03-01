/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.popups
{
    import feathers.core.IFeathersControl;
    import feathers.core.PopUpManager;
    import feathers.events.FeathersEventType;

    import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
    import loom2d.events.ResizeEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    /**
     * @inheritDoc
     */
    [Event(name="close",type="starling.events.Event")]

    /**
     * Displays a pop-up at the center of the stage, filling the vertical space.
     * The content will be sized horizontally so that it is no larger than the
     * the width or height of the stage (whichever is smaller).
     */
    public class VerticalCenteredPopUpContentManager extends EventDispatcher implements IPopUpContentManager
    {
        /**
         * @private
         */
        private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

        /**
         * Constructor.
         */
        public function VerticalCenteredPopUpContentManager()
        {
        }

        /**
         * The minimum space, in pixels, between the top edge of the content and
         * the top edge of the stage.
         */
        public var marginTop:Number = 0;

        /**
         * The minimum space, in pixels, between the right edge of the content
         * and the right edge of the stage.
         */
        public var marginRight:Number = 0;

        /**
         * The minimum space, in pixels, between the bottom edge of the content
         * and the bottom edge of the stage.
         */
        public var marginBottom:Number = 0;

        /**
         * The minimum space, in pixels, between the left edge of the content
         * and the left edge of the stage.
         */
        public var marginLeft:Number = 0;

        /**
         * @private
         */
        protected var content:DisplayObject;

        /**
         * @private
         */
        protected var touchPointID:int = -1;

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
            PopUpManager.addPopUp(this.content, true, false);
            if(this.content is IFeathersControl)
            {
                const uiContent:IFeathersControl = IFeathersControl(this.content);
                this.content.addEventListener(FeathersEventType.RESIZE, content_resizeHandler);
            }
            this.layout();
            Loom2D.stage.addEventListener(TouchEvent.TOUCH, stage_touchHandler);
            Loom2D.stage.addEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
            Loom2D.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
        }

        /**
         * @inheritDoc
         */
        public function close():void
        {
            if(!this.content)
            {
                return;
            }
            Loom2D.stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
            Loom2D.stage.removeEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
            Loom2D.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
            if(this.content is IFeathersControl)
            {
                this.content.removeEventListener(FeathersEventType.RESIZE, content_resizeHandler);
            }
            PopUpManager.removePopUp(this.content);
            this.content = null;
            this.dispatchEventWith(Event.CLOSE);
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
        protected function layout():void
        {
            const maxWidth:Number = Math.min(Loom2D.stage.stageWidth, Loom2D.stage.stageHeight) - this.marginLeft - this.marginRight;
            const maxHeight:Number = Loom2D.stage.stageHeight - this.marginTop - this.marginBottom;
            if(this.content is IFeathersControl)
            {
                const uiContent:IFeathersControl = IFeathersControl(this.content);
                uiContent.minWidth = uiContent.maxWidth = maxWidth;
                uiContent.maxHeight = maxHeight;
                uiContent.validate();
            }

            //if it's a ui control that is able to auto-size, the above
            //section will ensure that the control stays within the required
            //bounds.
            //if it's not a ui control, or if the control's explicit width
            //and height values are greater than our maximum bounds, then we
            //will enforce the maximum bounds the hard way.
            if(this.content.width > maxWidth)
            {
                this.content.width = maxWidth;
            }
            if(this.content.height > maxHeight)
            {
                this.content.height = maxHeight;
            }
            this.content.x = (Loom2D.stage.stageWidth - this.content.width) / 2;
            this.content.y = (Loom2D.stage.stageHeight - this.content.height) / 2;
        }

        /**
         * @private
         */
        protected function content_resizeHandler(event:Event):void
        {
            this.layout();
        }

        /**
         * @private
         */
        protected function stage_keyDownHandler(event:KeyboardEvent):void
        {
            if(event.keyCode != LoomKey.BUTTON_BACK && event.keyCode != LoomKey.ESCAPE)
            {
                return;
            }

            //don't let other event handlers handle the event
            event.stopImmediatePropagation();
            this.close();
        }

        /**
         * @private
         */
        protected function stage_resizeHandler(event:ResizeEvent):void
        {
            this.layout();
        }

        /**
         * @private
         */
        protected function stage_touchHandler(event:TouchEvent):void
        {
            if(event.interactsWith(this.content) || !PopUpManager.isTopLevelPopUp(this.content))
            {
                return;
            }
            const touches:Vector.<Touch> = event.getTouches(Loom2D.stage, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                return;
            }
            if(this.touchPointID >= 0)
            {
                var touch:Touch;
                for each(var currentTouch:Touch in touches)
                {
                    if(currentTouch.id == this.touchPointID)
                    {
                        touch = currentTouch;
                        break;
                    }
                }
                if(!touch)
                {
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this.touchPointID = -1;
                    this.close();
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this.touchPointID = touch.id;
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }


    }
}
