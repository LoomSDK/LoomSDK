// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.display
{    
    
    import loom.platform.LoomKeyModifier;

    import loom2d.events.EnterFrameEvent;
    import loom2d.events.ResizeEvent;
    import loom2d.events.Event;
    import loom2d.events.KeyboardEvent;
    import loom2d.events.TouchEvent;
    import loom2d.events.ScrollWheelEvent;
    import loom2d.events.EventDispatcher;
    
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.math.Matrix;

    import loom2d.Loom2D;
    import system.platform.Platform;
    import loom.platform.LoomKey;
    
    import loom.graphics.Graphics;

    import loom.Application;
    
    /**
     * Set the scaling behavior for Stage.
     *
     * @see Stage
     */
    public enum StageScaleMode 
    {
        NONE,
        LETTERBOX,
        FILL
    }

    delegate KeyDelegate(scancode:int, virtualKey:int, modifiers:int);
    delegate HardwareKeyDelegate();
    delegate TouchDelegate(touchId:int, x:int, y:int);
    delegate ScrollWheelDelegate(yDelta:int);
    delegate AccelerationDelegate(x:Number, y:Number, z:Number);

    delegate OrientationChangeDelegate(newOrientation:int);
    delegate SizeChangeDelegate(newWidth:int, newHeight:int);

    /** A Stage represents the root of the display tree.  
     *  Only objects that are direct or indirect children of the stage will be rendered.
     * 
     *  A stage object is created automatically by the `Application` class. Don't
     *  create a Stage instance manually.
     * 
     *  **Keyboard Events**
     * 
     *  In Loom, keyboard events are only dispatched at the stage. Add an event listener
     *  directly to the stage to be notified of keyboard events.
     * 
     *  **Resize Events**
     * 
     *  When a Loom application is resized, the stage dispatches a `ResizeEvent`. The 
     *  event contains properties containing the updated width and height of game.
     *
     *  @see Loom.Events.KeyboardEvent
     *  @see Loom.Events.ResizeEvent
     */
    [Native(managed)]      
    public native class Stage extends DisplayObjectContainer
    {
        /**
         * `Stage.vectorQuality` constant representing no flags (0).
         */
        public static const VECTOR_QUALITY_NONE              = 0;
        
        /**
         * `Stage.vectorQuality` constant defining the vector antialiasing status.
         * 
         * Vector antialiasing adjusts the geometry to include antialiasing.
         */
        public static const VECTOR_QUALITY_ANTIALIAS         = 1 << 0;
        
        /**
         * Uses the stencil buffer to render strokes. This provides better quality rendering for overlapping strokes
         * and overlapping shapes. If you aren't relying on specific overlapping behavior, you can omit this flag for better performance.
         */
        public static const VECTOR_QUALITY_STENCIL_STROKES   = 1 << 1;
        
        private var mWidth:int;
        private var mHeight:int;
        private var mColor:uint;
        private var mEnterFrameEvent:EnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.0);
        private var mScaleMode:StageScaleMode = StageScaleMode.NONE;

        public native var onTouchBegan:TouchDelegate;
        public native var onTouchMoved:TouchDelegate;
        public native var onTouchEnded:TouchDelegate;
        public native var onTouchCancelled:TouchDelegate;

        public native var onKeyUp:KeyDelegate;
        public native var onKeyDown:KeyDelegate;

        public native var onMenuKey:HardwareKeyDelegate;
        public native var onBackKey:HardwareKeyDelegate;

        public native var onScrollWheelYMoved:ScrollWheelDelegate;

        public native var onAccelerate:AccelerationDelegate;

        public native var onOrientationChange:OrientationChangeDelegate;
        public native var onSizeChange:SizeChangeDelegate;

        /**
         * When true, dump the current FPS via trace() every second.
         *
         * Displaying an FPS counter can be expensive enough to affect performance. This
         * is much cheaper, and thus more reliable, especially in performance sensitive
         * situations.
         */
        public var reportFps:Boolean = false;

        /**
         * Called when the stage is about to render.
         */
        public static native var onRenderStage:NativeDelegate;

        private static var fpsCount = 0;
        private static var lastFpsTime = -1;
        
        /** @private */
        public function Stage(width:int, height:int, color:uint=0)
        {
            // Note the stage.
            Loom2D.stage = this;

            // Note down useful information.
            mWidth = width;
            mHeight = height;
            this.color = color;
            
            // Handle key event dispatch.
            onKeyDown += onKeyDownHandler;
            onKeyUp += onKeyUpHandler;

            onSizeChange += onSizeChangeHandler;

            // Application's TouchProcessor handles touch/mouse input.
            onScrollWheelYMoved += onScrollWheelHandler;

            //layer.onKeyBackClicked += onKeyBackClicked;

            // Show stats specified in config file
            /*if ( Cocos2D.configStats == Cocos2D.STATS_REPORT_FPS )
                reportFps = true;
            else if ( Cocos2D.configStats == Cocos2D.STATS_SHOW_DEBUG_OVERLAY )
                Graphics.setDebug( Graphics.DEBUG_STATS );*/
        }

        protected function onKeyDownHandler(scancode:int, virtualKey:int, modifiers:int):void
        {
            broadcastEvent(
                new KeyboardEvent(
                    KeyboardEvent.KEY_DOWN, virtualKey, scancode, 0, 
                    (modifiers | LoomKeyModifier.CTRL) != 0,
                    (modifiers | LoomKeyModifier.ALT) != 0,
                    (modifiers | LoomKeyModifier.SHIFT) != 0));
        }

        protected function onKeyUpHandler(scancode:int, virtualKey:int, modifiers:int):void
        {
            broadcastEvent(
                new KeyboardEvent(
                    KeyboardEvent.KEY_UP, virtualKey, scancode, 0, 
                    (modifiers | LoomKeyModifier.CTRL) != 0,
                    (modifiers | LoomKeyModifier.ALT) != 0,
                    (modifiers | LoomKeyModifier.SHIFT) != 0 ));
        }

        protected function onScrollWheelHandler(delta:Number)
        {
            broadcastEvent(new ScrollWheelEvent(ScrollWheelEvent.SCROLLWHEEL, delta));   
        }

        protected function onKeyBackClickedHandler()
        {
            broadcastEvent(new KeyboardEvent(KeyboardEvent.BACK_PRESSED, 0, LoomKey.BUTTON_BACK));
        }

        protected function onSizeChangeHandler(newWidth:int, newHeight:int)
        {            
            invalidateScale();
            
            dispatchEvent(new ResizeEvent(Event.RESIZE, mWidth, mHeight, false));            
        }

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            // TODO: LOOM-1364
            // disabling frame enter event, until it can be optimized
            // it is currently taking 12-15ms/frame on iPad2

            // Fire the frame enter event.
            mEnterFrameEvent.reset(Event.ENTER_FRAME, false, passedTime);
            dispatchEvent(mEnterFrameEvent);
            // broadcastEvent(mEnterFrameEvent);

            var t = Platform.getTime() - lastFpsTime;
            if (lastFpsTime == -1 || t > 1000)
            {
                lastFpsTime = Platform.getTime();
                if(reportFps) trace("Current FPS: ", fpsCount, "  (period was ", t, "ms)");
                fpsCount = 0;
            }

            fpsCount++;
        }

        /** @inheritDoc */
        public override native function render();

        public native function firePendingResizeEvent();

        /** Returns the object that is found topmost beneath a point in stage coordinates, or  
         *  the stage itself if nothing else is found. */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            // locations outside of the stage area shouldn't be accepted
            if (localPoint.x < 0 || localPoint.x > mWidth ||
                localPoint.y < 0 || localPoint.y > mHeight)
                return null;
                            
            // if nothing else is hit, the stage returns itself as target
            var target:DisplayObject = super.hitTest(localPoint, forTouch);
            if (target == null) target = this;
            return target;
        }
        
        /** @private */
        public override function set width(value:Number):void 
        { 
            Debug.assert(false, "Cannot set width of stage");
        }
        
        /** @private */
        public override function set height(value:Number):void
        {
            Debug.assert(false, "Cannot set height of stage");
        }
                
        /** The background color of the stage. */
        public function get color():uint { return mColor; }
        public function set color(value:uint):void 
        {
            mColor = value; 

            // Update the background. Add alpha to the color.
            var swizzleColor = (value << 8) | 0xFF;

            loom.graphics.Graphics.setFillColor(swizzleColor);
        }
        
        /** The width of the stage coordinate system. Change it to scale its contents relative
         *  to the application viewport. */ 
        public function get stageWidth():int { return mWidth; }
        public function set stageWidth(value:int):void { mWidth = value; invalidateScale(); }
        
        /** The height of the stage coordinate system. Change it to scale its contents relative
         *  to the application viewport. */
        public function get stageHeight():int { return mHeight; }
        public function set stageHeight(value:int):void { mHeight = value; invalidateScale(); }
        
        /**
         * The quality of vector rendering.
         * 
         * @see Stage.VECTOR_QUALITY_ANTIALIAS
         * @see Stage.VECTOR_QUALITY_STENCIL
         * @return Returns the bitfield of flags. Test with the & (bitwise AND) operator,
         *         e.g. `if (Stage.vectorQuality & VECTOR_QUALITY_ANTIALIAS) { trace("Vector antialiasing enabled!"); }`
         */
        public native function get vectorQuality():int;
        public native function set vectorQuality(flags:int):void;
        
        /**
         * The maximum recursion level of tessellation. Bigger values result in greater quality.
         * Valid values are from 1 to 10 while 6 is the default. Values lower than 6 area
         * known to cause visual errors in the rendering.
         */
        public native function set tessellationQuality(value:int);
        public native function get tessellationQuality():int;

        /** Height of the native display in pixels. */
        public native function get nativeStageHeight():int;

        /** Width of the native display in pixels. */
        public native function get nativeStageWidth():int;

        /** Set the scaling behavior of the stage as the application is resized. */
        public function set scaleMode(value:StageScaleMode):void
        {
            mScaleMode = value;
            invalidateScale();
        }

        public function get scaleMode():StageScaleMode
        {
            return mScaleMode;
        }

        /**
         * Print debug information about the display list hiererchy to the 
         * console via trace().
         */
        public function dump():void
        {
            // Walk all the children.
            dump_r("", this);
        }

        protected function dump_r(indent:String, obj:DisplayObject):void
        {
            trace(indent + obj.toString() + " (visible=" + obj.visible + " " + obj.x.toFixed(2) + "," + obj.y.toFixed(2) + " " + obj.width.toFixed(2) + "x" + obj.height.toFixed(2) + ") - " + obj.name);
            if(obj as DisplayObjectContainer)
            {
                var objDOC:DisplayObjectContainer = obj as DisplayObjectContainer;
                for(var i:int=0; i<objDOC.numChildren; i++)
                {
                    dump_r(indent + "   ", objDOC.getChildAt(i));
                }
            }
        }
        
        protected function invalidateScale():void
        {
            var scaledWidth = nativeStageWidth / stageWidth;
            var scaledHeight = nativeStageHeight / stageHeight;

            switch(scaleMode)
            {
                case StageScaleMode.NONE:

                    scaleX = scaleY = 1;
                    x = 0;
                    y = 0;
                    mWidth = nativeStageWidth;
                    mHeight = nativeStageHeight;

                    break;

                case StageScaleMode.LETTERBOX:

                    if (scaledWidth < scaledHeight) 
                    {
                        scaleX = scaledWidth;
                        scaleY = scaledWidth;
                        x = 0;
                        y = (nativeStageHeight/2) - (stageHeight/2)*scaledWidth;
                    }
                    else 
                    {
                        scaleX = scaledHeight;
                        scaleY = scaledHeight;
                        x = (nativeStageWidth/2) - (stageWidth/2)*scaledHeight;
                        y = 0;
                    }

                    break;

                case StageScaleMode.FILL:

                    if (scaledWidth > scaledHeight) 
                    {
                        scaleX = scaleY = scaledWidth;
                        x = 0;
                        y = (nativeStageHeight/2) - (stageHeight/2)*scaledWidth;
                    }
                    else 
                    {
                        scaleX = scaleY = scaledHeight;
                        x = (nativeStageWidth/2) - (stageWidth/2)*scaledHeight;
                        y = 0;
                    }

                    break;
            }
        }    
    }
}