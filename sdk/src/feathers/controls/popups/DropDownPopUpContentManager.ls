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
    import loom2d.math.Rectangle;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
    import loom2d.events.ResizeEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    
    import loom.platform.LoomKey;

    /**
     * @inheritDoc
     */
    [Event(name="close",type="starling.events.Event")]

    /**
     * Displays pop-up content as a desktop-style drop-down.
     */
    public class DropDownPopUpContentManager extends EventDispatcher implements IPopUpContentManager
    {
        /**
         * Constructor.
         */
        public function DropDownPopUpContentManager()
        {
        }

        /**
         * @private
         */
        protected var content:DisplayObject;

        /**
         * @private
         */
        protected var source:DisplayObject;

        /**
         * @inheritDoc
         */
        public function open(content:DisplayObject, source:DisplayObject):void
        {
            Debug.assert( content == null, "Pop-up content is already defined." );

            this.content = content;
            this.source = source;
            PopUpManager.addPopUp(this.content, false, false);
            if(this.content is IFeathersControl)
            {
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
            this.source = null;
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
            const globalOrigin:Rectangle = this.source.getBounds(Loom2D.stage);

            if(this.source is IFeathersControl)
            {
                IFeathersControl(this.source).validate();
            }
            if(this.content is IFeathersControl)
            {
                const uiContent:IFeathersControl = IFeathersControl(this.content);
                uiContent.minWidth = Math.max(uiContent.minWidth, this.source.width);
                uiContent.validate();
            }
            else
            {
                this.content.width = Math.max(this.content.width, this.source.width);
            }

            const downSpace:Number = (Loom2D.stage.stageHeight - this.content.height) - (globalOrigin.y + globalOrigin.height);
            if(downSpace >= 0)
            {
                layoutBelow(globalOrigin);
                return;
            }

            const upSpace:Number = globalOrigin.y - this.content.height;
            if(upSpace >= 0)
            {
                layoutAbove(globalOrigin);
                return;
            }

            //worst case: pick the side that has the most available space
            if(upSpace >= downSpace)
            {
                layoutAbove(globalOrigin);
            }
            else
            {
                layoutBelow(globalOrigin);
            }

        }

        /**
         * @private
         */
        protected function layoutAbove(globalOrigin:Rectangle):void
        {
            const idealXPosition:Number = globalOrigin.x + (globalOrigin.width - this.content.width) / 2;
            const xPosition:Number = Math.max(0, Math.min(Loom2D.stage.stageWidth - this.content.width, idealXPosition));
            this.content.x = xPosition;
            this.content.y = globalOrigin.y - this.content.height;
        }

        /**
         * @private
         */
        protected function layoutBelow(globalOrigin:Rectangle):void
        {
            const idealXPosition:Number = globalOrigin.x;
            const xPosition:Number = Math.max(0, Math.min(Loom2D.stage.stageWidth - this.content.width, idealXPosition));
            this.content.x = xPosition;
            this.content.y = globalOrigin.y + globalOrigin.height;
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
            const target:DisplayObject = DisplayObject(event.target);
            if(this.content == target || (this.content is DisplayObjectContainer && DisplayObjectContainer(this.content).contains(target)))
            {
                return;
            }
            if(this.source == target || (this.source is DisplayObjectContainer && DisplayObjectContainer(this.source).contains(target)))
            {
                return;
            }
            if(!PopUpManager.isTopLevelPopUp(this.content))
            {
                return;
            }
            //any began touch is okay here. we don't need to check all touches
            const touch:Touch = event.getTouch(Loom2D.stage, TouchPhase.BEGAN);
            if(!touch)
            {
                return;
            }
            this.close();
        }
    }
}
