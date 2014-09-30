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
    
    import loom2d.display.Cocos2D;
    import loom2d.display.CCLayer;
    
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
        private var mWidth:int, mCocosWidth:int;
        private var mHeight:int, mCocosHeight:int;
        private var mColor:uint;
        private var mEnterFrameEvent:EnterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.0);
        private var mScaleMode:StageScaleMode = StageScaleMode.NONE;

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
        public function Stage(layer:CCLayer, width:int, height:int, color:uint=0)
        {
            mWidth = width;
            mHeight = height;
            mColor = color;
            
            // Handle key event dispatch.
            layer.onKeyDown += onKeyDown;
            layer.onKeyUp += onKeyUp;
            layer.onKeyBackClicked += onKeyBackClicked;

            layer.onScrollWheelYMoved += onScrollWheel;

            // Note the stage.
            Loom2D.stage = this;

            // Show stats specified in config file
            if ( Cocos2D.configStats == Cocos2D.STATS_REPORT_FPS )
                reportFps = true;
            else if ( Cocos2D.configStats == Cocos2D.STATS_SHOW_DEBUG_OVERLAY )
                loom.graphics.Graphics.setDebug( loom.graphics.Graphics.DEBUG_STATS );
        }

        protected function onKeyDown(key:int):void
        {
            broadcastEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, 0, key));
        }

        protected function onKeyUp(key:int):void
        {
            broadcastEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, 0, key));
        }

        protected function onScrollWheel(delta:Number)
        {
            broadcastEvent(new ScrollWheelEvent(ScrollWheelEvent.SCROLLWHEEL, delta));   
        }

        protected function onKeyBackClicked()
        {
            broadcastEvent(new KeyboardEvent(KeyboardEvent.BACK_PRESSED, 0, LoomKey.BUTTON_BACK));
        }

        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            // Check to see if we are resizing.
            if(mCocosWidth != Cocos2D.getDisplayWidth() || mCocosHeight != Cocos2D.getDisplayHeight())
            {
                mCocosWidth = Cocos2D.getDisplayWidth();
                mCocosHeight = Cocos2D.getDisplayHeight();
                
                invalidateScale();
                
                dispatchEvent(new ResizeEvent(Event.RESIZE, mWidth, mHeight, false));
            }

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
        
        /** Height of the native display in pixels. */
        public function get nativeStageHeight():int
        {
            return Cocos2D.getDisplayHeight();
        }

        /** Width of the native display in pixels. */
        public function get nativeStageWidth():int
        {
            return Cocos2D.getDisplayWidth();
        }

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
            trace(indent + obj.toString() + " (visible=" + obj.visible + " " + obj.x.toFixed(2) + "," + obj.y.toFixed(2) + " " + obj.width.toFixed(2) + "x" + obj.height.toFixed(2) + ")");
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
            var scaledWidth = Cocos2D.getDisplayWidth()/stageWidth;
            var scaledHeight = Cocos2D.getDisplayHeight()/stageHeight;

            switch(scaleMode)
            {
                case StageScaleMode.NONE:

                    scaleX = scaleY = 1;
                    x = 0;
                    y = 0;
                    mWidth = Cocos2D.getDisplayWidth();
                    mHeight = Cocos2D.getDisplayHeight();

                    break;

                case StageScaleMode.LETTERBOX:

                    if (scaledWidth < scaledHeight) 
                    {
                        scaleX = scaledWidth;
                        scaleY = scaledWidth;
                        x = 0;
                        y = (Cocos2D.getDisplayHeight()/2) - (stageHeight/2)*scaledWidth;
                    }
                    else 
                    {
                        scaleX = scaledHeight;
                        scaleY = scaledHeight;
                        x = (Cocos2D.getDisplayWidth()/2) - (stageWidth/2)*scaledHeight;
                        y = 0;
                    }

                    break;

                case StageScaleMode.FILL:

                    if (scaledWidth > scaledHeight) 
                    {
                        scaleX = scaleY = scaledWidth;
                        x = 0;
                        y = (Cocos2D.getDisplayHeight()/2) - (stageHeight/2)*scaledWidth;
                    }
                    else 
                    {
                        scaleX = scaleY = scaledHeight;
                        x = (Cocos2D.getDisplayWidth()/2) - (stageWidth/2)*scaledHeight;
                        y = 0;
                    }

                    break;
            }
        }    
    }



    [Deprecated(msg="Consider using loom2d.Stage instead.")]
    /**
     * Internal bindings left over from Cocos2D X days. 
     *
     * @private
     */
    public class Cocos2D
    {
        public static const ORIENTATION_PORTRAIT:String = "portrait";
        public static const ORIENTATION_LANDSCAPE:String = "landscape";
        public static const ORIENTATION_AUTO:String = "auto";

        public static const STATS_REPORT_FPS:int = 1;
        public static const STATS_SHOW_DEBUG_OVERLAY:int = 2;

        public static function initializeFromConfig()
        {
            //trace("initializing config");

            var json = new JSON(); 
            Debug.assert(json.loadString(Application.loomConfigJSON));
            var display = json.getObject("display");
            var width = display.getInteger("width");
            var height = display.getInteger("height");
            var title = display.getString("title");
            configStats = display.getInteger("stats");
            var orientation = display.getString("orientation");

            // set the orientation to landscape by default
            if(orientation != ORIENTATION_PORTRAIT &&
            orientation != ORIENTATION_LANDSCAPE &&
            orientation != ORIENTATION_AUTO)
            {
                orientation = ORIENTATION_LANDSCAPE;
            }

            // store off the configs width/height as we 
            // use this to set the initial dimensions when
            // using scaling mode
            configDisplayWidth = width;
            configDisplayHeight = height;

            initialize();

            setDisplayInfo(width, height, title);
            setDisplayOrientation(orientation);
        }

        public static function initialize()
        {
            // register to be told about VM reload 
            VM.getExecutingVM().onReload += onReload;
        }

        private static function onReload() 
        {
            cleanup();
        }

        /**
        * Gets the loom.config display width
        */
        public static function getConfigDisplayWidth():int
        {
            return configDisplayWidth;
        }

        /**
        * Gets the loom.config display height
        */
        public static function getConfigDisplayHeight():int
        {
            return configDisplayHeight;
        }         

        public static native function shutdown():void;

        /**
        * Returns the current orientation of the device.
        * 
        * The orientation is either ORIENTATION_PORTRAIT or ORIENTATION_LANDSCAPE.
        * To read the value set in the loom.config file, use getDisplayOrientation()
        */
        public static native function getOrientation():String;

        /**
        * Call to toggle fullscreen mode.
        */
        public static native function toggleFullscreen():void;

        public static native function getDisplayWidth():int;
        public static native function getDisplayCaption():String;
        public static native function getDisplayHeight():int;
        public static native function getDisplayOrientation():String;
        public static native function addLayer(layer:CCLayer);
        public static native function removeLayer(layer:CCLayer, cleanup:Boolean=true);

        // whether or not to render stats, such as fps
        public static native function setDisplayStats(enabled:Boolean);
        public static native function getDisplayStats():Boolean;

        public static native var onDisplayStatsChanged:NativeDelegate;
        public static native var onOrientationChanged:NativeDelegate;

        /**
        * Called when the display size changes.
        *
        * Two parameters, width and height in pixels as integers.
        */
        public static native var onDisplaySizeChanged:NativeDelegate;

        /** 
        * Display height and width as specified in the loom.config
        */
        public static var configDisplayWidth:int;
        public static var configDisplayHeight:int;

        public static var configStats:int;

        private static native function setDisplayOrientation(orientation:String);
        private static native function setDisplayCaption(caption:String);
        private static native function setDisplayWidth(width:int);
        private static native function setDisplayHeight(height:int); 
        private static native function cleanup();

        private static function setDisplayInfo(width:int, height:int, caption:String) 
        {
            setDisplayCaption(caption);

            setDisplayWidth(width);
            setDisplayHeight(height);
            //trace("SIZE " + width + "x" + height);

            // On some platforms, setting width/height has no effect. For 
            // instance, Mac and Windows may resize the window but this is
            // meaningless on mobile. So we check the actual resolution
            // and re-set it after we tried setting to the new values in 
            // order to properly propagate the actual surface size everywhere.
            var readbackWidth = getDisplayWidth();
            var readbackHeight = getDisplayHeight();

            if(readbackWidth != 0 && readbackHeight != 0)
            {
                setDisplayWidth(readbackWidth);
                setDisplayHeight(readbackHeight);
            }
        }
    }    

   [Native(managed)]
   /**
   * Remnant of bindings to Cocos2DX - propagates touch/keyboard events.
   * @private
   */
   public native class CCLayer
   {
      public native function autorelease():void;

      public native function init():Boolean;

      /** create one layer */
      public native static function create():CCLayer;
      public native static function rootLayer():CCLayer;

      /** If isTouchEnabled, this method is called onEnter. Override it to change the
      way CCLayer receives touch events.
      ( Default: CCTouchDispatcher::sharedDispatcher()->addStandardDelegate(this,0); )
      Example:
      void CCLayer::registerWithTouchDispatcher()
      {
      CCTouchDispatcher::sharedDispatcher()->addTargetedDelegate(this,INT_MIN+1,true);
      }
      @since v0.8.0
      */
      public native function registerWithTouchDispatcher():void;
      /** Register script touch events handler */
      //public native function registerScriptTouchHandler(nHandler:int, bIsMultiTouches:Boolean, nPriority:int, bSwallowsTouches:Boolean):void;
      
      /** Unregister script touch events handler */
      //public native function unregisterScriptTouchHandler():void;

      /** whether or not it will receive Touch events.
      You can enable / disable touch events with this property.
      Only the touches of this node will be affected. This "method" is not propagated to it's children.
      @since v0.8.1
      */
      public native function isTouchEnabled():Boolean;
      public native function setTouchEnabled(value:Boolean):void;

      /** whether or not it will receive Accelerometer events
      You can enable / disable accelerometer events with this property.
      @since v0.8.1
      */
      public native function isAccelerometerEnabled():Boolean;
      public native function setAccelerometerEnabled(value:Boolean):void;

      /** whether or not it will receive keypad events
      You can enable / disable accelerometer events with this property.
      it's new in cocos2d-x
      */
      public native function isKeypadEnabled():Boolean;
      public native function setKeypadEnabled(value:Boolean):void;

      public native function isScrollWheelEnabled():Boolean;
      public native function setScrollWheelEnabled(value:Boolean):void;

      public native var onTouchBegan:NativeDelegate;
      public native var onTouchMoved:NativeDelegate;
      public native var onTouchEnded:NativeDelegate;
      public native var onTouchCancelled:NativeDelegate;
      public native var onKeyBackClicked:NativeDelegate;
      public native var onKeyMenuClicked:NativeDelegate;
      public native var onScrollWheelYMoved:NativeDelegate;
      public native var onAccelerate:NativeDelegate;

      /**
       * Called when a key is depressed; if isKeypadEnabled is true.
       *
       * One parameter, the key code being considered.
       */
      public native var onKeyDown:NativeDelegate;

      /**
       * Called when a key is released; if isKeypadEnabled is true.
       *
       * One parameter, the key code being considered.
       */
      public native var onKeyUp:NativeDelegate;
   }    
}