/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.core.PopUpManager;

    import loom2d.math.Point;
    import loom2d.math.Rectangle;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.events.EnterFrameEvent;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.events.KeyboardEvent;

    import loom.platform.LoomKey;

    /**
     * Dispatched when the callout is closed.
     *
     * @eventType starling.events.Event.CLOSE
     */
    [Event(name="close",type="starling.events.Event")]

    /**
     * A pop-up container that points at (or calls out) a specific region of
     * the application (typically a specific control that triggered it).
     *
     * In general, a `Callout` isn't instantiated directly.
     * Instead, you will typically call the static function
     * `Callout.show()`. This is not required, but it result in less
     * code and no need to manually manage calls to the `PopUpManager`.
     *
     * In the following example, a callout displaying a `Label` is
     * shown when a `Button` is triggered:
     *
     * ~~~as3
     * button.addEventListener( Event.TRIGGERED, button_triggeredHandler );
     *
     * function button_triggeredHandler( event:Event ):void {
     *    ⇥var label:Label = new Label();
     *    ⇥label.text = "Hello World!";
     *    ⇥var button:Button = Button( event.currentTarget );
     *    ⇥Callout.show( label, button );
     * }
     * ~~~
     *
     * @see http://wiki.starling-framework.org/feathers/callout
     */
    public class Callout extends FeathersControl
    {
        /**
         * The callout may be positioned on any side of the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_ANY:String = "any";

        /**
         * The callout may be positioned on top or bottom of the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_VERTICAL:String = "vertical";

        /**
         * The callout may be positioned on top or bottom of the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_HORIZONTAL:String = "horizontal";

        /**
         * The callout must be positioned above the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_UP:String = "up";

        /**
         * The callout must be positioned below the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_DOWN:String = "down";

        /**
         * The callout must be positioned to the left side of the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_LEFT:String = "left";

        /**
         * The callout must be positioned to the right side of the origin region.
         *
         * @see #supportedDirections
         */
        public static const DIRECTION_RIGHT:String = "right";

        /**
         * The arrow will appear on the top side of the callout.
         *
         * @see #arrowPosition
         */
        public static const ARROW_POSITION_TOP:String = "top";

        /**
         * The arrow will appear on the right side of the callout.
         *
         * @see #arrowPosition
         */
        public static const ARROW_POSITION_RIGHT:String = "right";

        /**
         * The arrow will appear on the bottom side of the callout.
         *
         * @see #arrowPosition
         */
        public static const ARROW_POSITION_BOTTOM:String = "bottom";

        /**
         * The arrow will appear on the left side of the callout.
         *
         * @see #arrowPosition
         */
        public static const ARROW_POSITION_LEFT:String = "left";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_ORIGIN:String = "origin";

        /**
         * @private
         */
        private static const HELPER_RECT:Rectangle = new Rectangle();

        /**
         * @private
         */
        private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        protected static const DIRECTION_TO_FUNCTION:Dictionary.<String, Function> = {};

        /**
         * The padding between a callout and the top edge of the stage when the
         * callout is positioned automatically. May be ignored if the callout
         * is too big for the stage.
         *
         * In the following example, the top stage padding will be set to
         * 20 pixels:
         *
         * ~~~as3
         * Callout.stagePaddingTop = 20;
         * ~~~
         */
        public static var stagePaddingTop:Number = 0;

        /**
         * The padding between a callout and the right edge of the stage when the
         * callout is positioned automatically. May be ignored if the callout
         * is too big for the stage.
         *
         * In the following example, the right stage padding will be set to
         * 20 pixels:
         *
         * ~~~as3
         * Callout.stagePaddingRight = 20;
         * ~~~
         */
        public static var stagePaddingRight:Number = 0;

        /**
         * The padding between a callout and the bottom edge of the stage when the
         * callout is positioned automatically. May be ignored if the callout
         * is too big for the stage.
         *
         * In the following example, the bottom stage padding will be set to
         * 20 pixels:
         *
         * ~~~as3
         * Callout.stagePaddingBottom = 20;
         * ~~~
         */
        public static var stagePaddingBottom:Number = 0;

        /**
         * The margin between a callout and the top edge of the stage when the
         * callout is positioned automatically. May be ignored if the callout
         * is too big for the stage.
         *
         * In the following example, the left stage padding will be set to
         * 20 pixels:
         *
         * ~~~as3
         * Callout.stagePaddingLeft = 20;
         * ~~~
         */
        public static var stagePaddingLeft:Number = 0;

        /**
         * Returns a new `Callout` instance when `Callout.show()`
         * is called with isModal set to true. If one wishes to skin the callout
         * manually, a custom factory may be provided.
         *
         * This function is expected to have the following signature:
         *
         * `function():Callout`
         *
         * The following example shows how to create a custom callout factory:
         *
         * ~~~as3
         * Callout.calloutFactory = function():Callout {
         *    ⇥var callout:Callout = new Callout();
         *    ⇥//set properties here!
         *    ⇥return callout;
         * };
         * ~~~
         *
         * @see #show()
         */
        public static var calloutFactory:Function = defaultCalloutFactory;

        /**
         * Returns an overlay to display with a callout that is modal. Uses the
         * standard `overlayFactory` of the `PopUpManager`
         * by default, but you can use this property to provide your own custom
         * overlay, if you prefer.
         *
         * This function is expected to have the following signature:

         * `function():DisplayObject`

         *
         * The following example uses a semi-transparent `Quad` as
         * a custom overlay:
         *
         * ~~~as3
         * Callout.calloutOverlayFactory = function():Quad {
         *    ⇥var quad:Quad = new Quad(10, 10, 0x000000);
         *    ⇥quad.alpha = 0.75;
         *    ⇥return quad;
         * };
         * ~~~
         *
         * @see feathers.core.PopUpManager#overlayFactory
         *
         * @see #show()
         */
        public static var calloutOverlayFactory:Function = PopUpManager.defaultOverlayFactory;

        /**
         * Creates a callout, and then positions and sizes it automatically
         * based on an origin rectangle and the specified direction relative to
         * the original. The provided width and height values are optional, and
         * these values may be ignored if the callout cannot be drawn at the
         * specified dimensions.
         *
         * In the following example, a callout displaying a `Label` is
         * shown when a `Button` is triggered:
         *
         * ~~~as3
         * button.addEventListener( Event.TRIGGERED, button_triggeredHandler );
         *
         * function button_triggeredHandler( event:Event ):void {
         *    ⇥var label:Label = new Label();
         *    ⇥label.text = "Hello World!";
         *    ⇥var button:Button = Button( event.currentTarget );
         *    ⇥Callout.show( label, button );
         * }
         * ~~~
         */
        public static function show(content:DisplayObject, origin:DisplayObject, supportedDirections:String = DIRECTION_ANY,
            isModal:Boolean = true, customCalloutFactory:Function = null):Callout
        {
            if(!origin.stage)
            {
                throw new ArgumentError("Callout origin must be added to the stage.");
            }
            var factory:Function = customCalloutFactory;
            if(factory == null)
            {
                factory = calloutFactory != null ? calloutFactory : defaultCalloutFactory;
            }
            const callout:Callout = Callout(factory());
            callout.content = content;
            callout.supportedDirections = supportedDirections;
            callout.origin = origin;
            const overlayFactory:Function = calloutOverlayFactory != null ? calloutOverlayFactory : PopUpManager.defaultOverlayFactory;
            PopUpManager.addPopUp(callout, isModal, false, overlayFactory);
            return callout;
        }

        /**
         * The default factory that creates callouts when `Callout.show()`
         * is called. To use a different factory, you need to set
         * `Callout.calloutFactory` to a `Function`
         * instance.
         */
        public static function defaultCalloutFactory():Callout
        {
            const callout:Callout = new Callout();
            callout.closeOnTouchBeganOutside = true;
            callout.closeOnTouchEndedOutside = true;
            callout.closeOnKeys = [ LoomKey.BUTTON_BACK, LoomKey.ESCAPE ];
            return callout;
        }

        /**
         * @private
         */
        protected static function positionWithSupportedDirections(callout:Callout, globalOrigin:Rectangle, direction:String):void
        {
            if(DIRECTION_TO_FUNCTION[direction] != null)
            {
                const calloutPositionFunction:Function = DIRECTION_TO_FUNCTION[direction];
                calloutPositionFunction(callout, globalOrigin);
            }
            else
            {
                positionBestSideOfOrigin(callout, globalOrigin);
            }
        }

        /**
         * @private
         */
        protected static function positionBestSideOfOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_TOP);
            const downSpace:Number = (Loom2D.stage.stageHeight - helperPoint.y) - (globalOrigin.y + globalOrigin.height);
            if(downSpace >= stagePaddingBottom)
            {
                positionBelowOrigin(callout, globalOrigin);
                return;
            }

            helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_BOTTOM);
            const upSpace:Number = globalOrigin.y - helperPoint.y;
            if(upSpace >= stagePaddingTop)
            {
                positionAboveOrigin(callout, globalOrigin);
                return;
            }

            helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_LEFT);
            const rightSpace:Number = (Loom2D.stage.stageWidth - helperPoint.x) - (globalOrigin.x + globalOrigin.width);
            if(rightSpace >= stagePaddingRight)
            {
                positionToRightOfOrigin(callout, globalOrigin);
                return;
            }

            helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_RIGHT);
            const leftSpace:Number = globalOrigin.x - helperPoint.x;
            if(leftSpace >= stagePaddingLeft)
            {
                positionToLeftOfOrigin(callout, globalOrigin);
                return;
            }

            //worst case: pick the side that has the most available space
            if(downSpace >= upSpace && downSpace >= rightSpace && downSpace >= leftSpace)
            {
                positionBelowOrigin(callout, globalOrigin);
            }
            else if(upSpace >= rightSpace && upSpace >= leftSpace)
            {
                positionAboveOrigin(callout, globalOrigin);
            }
            else if(rightSpace >= leftSpace)
            {
                positionToRightOfOrigin(callout, globalOrigin);
            }
            else
            {
                positionToLeftOfOrigin(callout, globalOrigin);
            }
        }

        /**
         * @private
         */
        protected static function positionAboveOrBelowOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_TOP);
            const downSpace:Number = (Loom2D.stage.stageHeight - helperPoint.y) - (globalOrigin.y + globalOrigin.height);
            if(downSpace >= stagePaddingBottom)
            {
                positionBelowOrigin(callout, globalOrigin);
                return;
            }

            helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_BOTTOM);
            const upSpace:Number = globalOrigin.y - helperPoint.y;
            if(upSpace >= stagePaddingTop)
            {
                positionAboveOrigin(callout, globalOrigin);
                return;
            }

            //worst case: pick the side that has the most available space
            if(downSpace >= upSpace)
            {
                positionBelowOrigin(callout, globalOrigin);
            }
            else
            {
                positionAboveOrigin(callout, globalOrigin);
            }
        }

        /**
         * @private
         */
        protected static function positionToLeftOrRightOfOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_LEFT);
            const rightSpace:Number = (Loom2D.stage.stageWidth - helperPoint.x) - (globalOrigin.x + globalOrigin.width);
            if(rightSpace >= stagePaddingRight)
            {
                positionToRightOfOrigin(callout, globalOrigin);
                return;
            }

            helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_RIGHT);
            const leftSpace:Number = globalOrigin.x - helperPoint.x;
            if(leftSpace >= stagePaddingLeft)
            {
                positionToLeftOfOrigin(callout, globalOrigin);
                return;
            }

            //worst case: pick the side that has the most available space
            if(rightSpace >= leftSpace)
            {
                positionToRightOfOrigin(callout, globalOrigin);
            }
            else
            {
                positionToLeftOfOrigin(callout, globalOrigin);
            }
        }

        /**
         * @private
         */
        protected static function positionBelowOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_TOP);
            const idealXPosition:Number = globalOrigin.x + (globalOrigin.width - helperPoint.x) / 2;
            const xPosition:Number = Math.max(stagePaddingLeft, Math.min(Loom2D.stage.stageWidth - helperPoint.x - stagePaddingRight, idealXPosition));
            callout.x = xPosition;
            callout.y = globalOrigin.y + globalOrigin.height;
            if(callout._isValidating)
            {
                //no need to invalidate and need to validate again next frame
                callout._arrowOffset = idealXPosition - xPosition;
                callout._arrowPosition = ARROW_POSITION_TOP;
            }
            else
            {
                callout.arrowOffset = idealXPosition - xPosition;
                callout.arrowPosition = ARROW_POSITION_TOP;
            }
        }

        /**
         * @private
         */
        protected static function positionAboveOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_BOTTOM);
            const idealXPosition:Number = globalOrigin.x + (globalOrigin.width - helperPoint.x) / 2;
            const xPosition:Number = Math.max(stagePaddingLeft, Math.min(Loom2D.stage.stageWidth - helperPoint.x - stagePaddingRight, idealXPosition));
            callout.x = xPosition;
            callout.y = globalOrigin.y - helperPoint.y;
            if(callout._isValidating)
            {
                //no need to invalidate and need to validate again next frame
                callout._arrowOffset = idealXPosition - xPosition;
                callout._arrowPosition = ARROW_POSITION_BOTTOM;
            }
            else
            {
                callout.arrowOffset = idealXPosition - xPosition;
                callout.arrowPosition = ARROW_POSITION_BOTTOM;
            }
        }

        /**
         * @private
         */
        protected static function positionToRightOfOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_LEFT);
            callout.x = globalOrigin.x + globalOrigin.width;
            const idealYPosition:Number = globalOrigin.y + (globalOrigin.height - helperPoint.y) / 2;
            const yPosition:Number = Math.max(stagePaddingTop, Math.min(Loom2D.stage.stageHeight - helperPoint.y - stagePaddingBottom, idealYPosition));
            callout.y = yPosition;
            if(callout._isValidating)
            {
                //no need to invalidate and need to validate again next frame
                callout._arrowOffset = idealYPosition - yPosition;
                callout._arrowPosition = ARROW_POSITION_LEFT;
            }
            else
            {
                callout.arrowOffset = idealYPosition - yPosition;
                callout.arrowPosition = ARROW_POSITION_LEFT;
            }
        }

        /**
         * @private
         */
        protected static function positionToLeftOfOrigin(callout:Callout, globalOrigin:Rectangle):void
        {
            var helperPoint = callout.measureWithArrowPosition(ARROW_POSITION_RIGHT);
            callout.x = globalOrigin.x - helperPoint.x;
            const idealYPosition:Number = globalOrigin.y + (globalOrigin.height - helperPoint.y) / 2;
            const yPosition:Number = Math.max(stagePaddingLeft, Math.min(Loom2D.stage.stageHeight - helperPoint.y - stagePaddingBottom, idealYPosition));
            callout.y = yPosition;
            if(callout._isValidating)
            {
                //no need to invalidate and need to validate again next frame
                callout._arrowOffset = idealYPosition - yPosition;
                callout._arrowPosition = ARROW_POSITION_RIGHT;
            }
            else
            {
                callout.arrowOffset = idealYPosition - yPosition;
                callout.arrowPosition = ARROW_POSITION_RIGHT;
            }
        }

        /**
         * Constructor.
         */
        public function Callout()
        {
            if ( DIRECTION_TO_FUNCTION.length == 0 )
            {
                DIRECTION_TO_FUNCTION[DIRECTION_ANY] = positionBestSideOfOrigin;
                DIRECTION_TO_FUNCTION[DIRECTION_UP] = positionAboveOrigin;
                DIRECTION_TO_FUNCTION[DIRECTION_DOWN] = positionBelowOrigin;
                DIRECTION_TO_FUNCTION[DIRECTION_LEFT] = positionToLeftOfOrigin;
                DIRECTION_TO_FUNCTION[DIRECTION_RIGHT] = positionToRightOfOrigin;
                DIRECTION_TO_FUNCTION[DIRECTION_VERTICAL] = positionAboveOrBelowOrigin;
                DIRECTION_TO_FUNCTION[DIRECTION_HORIZONTAL] = positionToLeftOrRightOfOrigin;
            }

            this.addEventListener(Event.ADDED_TO_STAGE, callout_addedToStageHandler);
        }

        /**
         * Determines if the callout is automatically closed if a touch in the
         * `TouchPhase.BEGAN` phase happens outside of the callout's
         * bounds.
         *
         * In the following example, the callout will not close when a touch
         * event with `TouchPhase.BEGAN` is detected outside the
         * callout's (or its origin's) bounds:
         *
         * ~~~as3
         * callout.closeOnTouchBeganOutside = false;
         * ~~~
         *
         * @see #closeOnTouchEndedOutside
         * @see #closeOnKeys
         */
        public var closeOnTouchBeganOutside:Boolean = false;

        /**
         * Determines if the callout is automatically closed if a touch in the
         * `TouchPhase.ENDED` phase happens outside of the callout's
         * bounds.
         *
         * In the following example, the callout will not close when a touch
         * event with `TouchPhase.ENDED` is detected outside the
         * callout's (or its origin's) bounds:
         *
         * ~~~as3
         * callout.closeOnTouchEndedOutside = false;
         * ~~~
         *
         * @see #closeOnTouchBeganOutside
         * @see #closeOnKeys
         */
        public var closeOnTouchEndedOutside:Boolean = false;

        /**
         * The callout will be closed if any of these keys are pressed.
         *
         * In the following example, the callout close when the Escape key
         * is pressed:
         *
         * ~~~as3
         * callout.closeOnKeys = new &lt;uint&gt;[Keyboard.ESCAPE];
         * ~~~
         *
         * @see #closeOnTouchBeganOutside
         * @see #closeOnTouchEndedOutside
         */
        public var closeOnKeys:Vector.<uint>;

        /**
         * Determines if the callout will be disposed when `close()`
         * is called internally. Close may be called internally in a variety of
         * cases, depending on values such as `closeOnTouchBeganOutside`,
         * `closeOnTouchEndedOutside`, and `closeOnKeys`.
         * If set to `false`, you may reuse the callout later by
         * giving it a new `origin` and adding it to the
         * `PopUpManager` again.
         *
         * In the following example, the callout will not be disposed when it
         * closes itself:
         *
         * ~~~as3
         * callout.disposeOnSelfClose = false;
         * ~~~
         *
         * @see #closeOnTouchBeganOutside
         * @see #closeOnTouchEndedOutside
         * @see #closeOnKeys
         * @see #close()
         */
        public var disposeOnSelfClose:Boolean = true;

        /**
         * Determines if the callout's content will be disposed when the callout
         * is disposed. If set to `false`, the callout's content may
         * be added to the display list again later.
         *
         * In the following example, the callout's content will not be
         * disposed when the callout is disposed:
         *
         * ~~~as3
         * callout.disposeContent = false;
         * ~~~
         */
        public var disposeContent:Boolean = true;

        /**
         * @private
         */
        protected var _isReadyToClose:Boolean = false;

        /**
         * @private
         */
        protected var _originalContentWidth:Number = NaN;

        /**
         * @private
         */
        protected var _originalContentHeight:Number = NaN;

        /**
         * @private
         */
        protected var _content:DisplayObject;

        /**
         * The display object that will be presented by the callout. This object
         * may be resized to fit the callout's bounds. If the content needs to
         * be scrolled if placed into a smaller region than its ideal size, it
         * must provide its own scrolling capabilities because the callout does
         * not offer scrolling.
         *
         * In the following example, the callout's content is an image:
         *
         * ~~~as3
         * callout.content = new Image( texture );
         * ~~~
         */
        public function get content():DisplayObject
        {
            return this._content;
        }

        /**
         * @private
         */
        public function set content(value:DisplayObject):void
        {
            if(this._content == value)
            {
                return;
            }
            if(this._content)
            {
                this._content.removeFromParent(false);
            }
            this._content = value;
            if(this._content)
            {
                this.addChild(this._content);
            }
            this._originalContentWidth = NaN;
            this._originalContentHeight = NaN;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _origin:DisplayObject;

        /**
         * A callout may be positioned relative to another display object, known
         * as the callout's origin. Even if the position of the origin changes,
         * the callout will reposition itself to always point at the origin.
         *
         * When an origin is set, the `arrowPosition` and
         * `arrowOffset` properties will be managed automatically by
         * the callout. Setting either of these values manually with either have
         * no effect or unexpected behavior, so it is recommended that you
         * avoid modifying those properties.
         *
         * In general, if you use `Callout.show()`, you will
         * rarely need to manually manage the origin.
         *
         * In the following example, the callout's origin is set to a button:
         *
         * ~~~as3
         * callout.origin = button;
         * ~~~
         *
         * @see #supportedDirections
         * @see #arrowPosition
         * @see #arrowOffset
         */
        public function get origin():DisplayObject
        {
            return this._origin;
        }

        public function set origin(value:DisplayObject):void
        {
            if(this._origin == value)
            {
                return;
            }
            if(value && !value.stage)
            {
                throw new ArgumentError("Callout origin must have access to the stage.");
            }
            if(this._origin)
            {
                Loom2D.stage.removeEventListener(EnterFrameEvent.ENTER_FRAME, callout_enterFrameHandler);
                this._origin.removeEventListener(Event.REMOVED_FROM_STAGE, origin_removedFromStageHandler);
            }
            this._origin = value;
            this._lastGlobalBoundsOfOrigin = null;
            if(this._origin)
            {
                this._origin.addEventListener(Event.REMOVED_FROM_STAGE, origin_removedFromStageHandler);
                Loom2D.stage.addEventListener(EnterFrameEvent.ENTER_FRAME, callout_enterFrameHandler);
            }
            this.invalidate(INVALIDATION_FLAG_ORIGIN);
        }

        /**
         * @private
         */
        protected var _supportedDirections:String = DIRECTION_ANY;

        /**
         * The directions that the callout may be positioned, relative to its
         * origin. If the callout's origin is not set, this value will be
         * ignored.
         *
         * The `arrowPosition` property is related to this one,
         * but they have different meanings and are usually opposites. For
         * example, a callout on the right side of its origin will generally
         * display its left arrow.
         *
         * In the following example, the callout's supported directions are
         * restricted to up and down:
         *
         * ~~~as3
         * callout.supportedDirections = Callout.DIRECTION_VERTICAL;
         * ~~~
         *
         * @see #origin
         * @see #DIRECTION_ANY
         * @see #DIRECTION_VERTICAL
         * @see #DIRECTION_HORIZONTAL
         * @see #DIRECTION_UP
         * @see #DIRECTION_DOWN
         * @see #DIRECTION_LEFT
         * @see #DIRECTION_RIGHT
         * @see #arrowPosition
         */
        public function get supportedDirections():String
        {
            return this._supportedDirections;
        }

        public function set supportedDirections(value:String):void
        {
            this._supportedDirections = value;
        }

        /**
         * Quickly sets all padding properties to the same value. The
         * `padding` getter always returns the value of
         * `paddingTop`, but the other padding values may be
         * different.
         *
         * In the following example, the padding of all sides of the callout
         * is set to 20 pixels:
         *
         * ~~~as3
         * callout.padding = 20;
         * ~~~
         */
        public function get padding():Number
        {
            return this._paddingTop;
        }

        /**
         * @private
         */
        public function set padding(value:Number):void
        {
            this.paddingTop = value;
            this.paddingRight = value;
            this.paddingBottom = value;
            this.paddingLeft = value;
        }

        /**
         * @private
         */
        protected var _paddingTop:Number = 0;

        /**
         * The minimum space, in pixels, between the callout's top edge and the
         * callout's content.
         *
         * In the following example, the padding on the top edge of the
         * callout is set to 20 pixels:
         *
         * ~~~as3
         * callout.paddingTop = 20;
         * ~~~
         */
        public function get paddingTop():Number
        {
            return this._paddingTop;
        }

        /**
         * @private
         */
        public function set paddingTop(value:Number):void
        {
            if(this._paddingTop == value)
            {
                return;
            }
            this._paddingTop = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingRight:Number = 0;

        /**
         * The minimum space, in pixels, between the callout's right edge and
         * the callout's content.
         *
         * In the following example, the padding on the right edge of the
         * callout is set to 20 pixels:
         *
         * ~~~as3
         * callout.paddingRight = 20;
         * ~~~
         */
        public function get paddingRight():Number
        {
            return this._paddingRight;
        }

        /**
         * @private
         */
        public function set paddingRight(value:Number):void
        {
            if(this._paddingRight == value)
            {
                return;
            }
            this._paddingRight = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingBottom:Number = 0;

        /**
         * The minimum space, in pixels, between the callout's bottom edge and
         * the callout's content.
         *
         * In the following example, the padding on the bottom edge of the
         * callout is set to 20 pixels:
         *
         * ~~~as3
         * callout.paddingBottom = 20;
         * ~~~
         */
        public function get paddingBottom():Number
        {
            return this._paddingBottom;
        }

        /**
         * @private
         */
        public function set paddingBottom(value:Number):void
        {
            if(this._paddingBottom == value)
            {
                return;
            }
            this._paddingBottom = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingLeft:Number = 0;

        /**
         * The minimum space, in pixels, between the callout's left edge and the
         * callout's content.
         *
         * In the following example, the padding on the left edge of the
         * callout is set to 20 pixels:
         *
         * ~~~as3
         * callout.paddingLeft = 20;
         * ~~~
         */
        public function get paddingLeft():Number
        {
            return this._paddingLeft;
        }

        /**
         * @private
         */
        public function set paddingLeft(value:Number):void
        {
            if(this._paddingLeft == value)
            {
                return;
            }
            this._paddingLeft = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _arrowPosition:String = ARROW_POSITION_TOP;

        [Inspectable(type="String",enumeration="top,right,bottom,left")]
        /**
         * The position of the callout's arrow relative to the callout's
         * background. If the callout's `origin` is set, this value
         * will be managed by the callout and may change automatically if the
         * origin moves to a new position or if the stage resizes.
         *
         * The `supportedDirections` property is related to this
         * one, but they have different meanings and are usually opposites. For
         * example, a callout on the right side of its origin will generally
         * display its left arrow.
         *
         * If you use `Callout.show()` or set the `origin`
         * property manually, you should avoid manually modifying the
         * `arrowPosition` and `arrowOffset` properties.
         *
         * In the following example, the callout's arrow is positioned on the
         * left side:
         *
         * ~~~as3
         * callout.arrowPosition = Callout.ARROW_POSITION_LEFT;
         * ~~~
         *
         * @see #origin
         * @see #supportedDirections
         * @see #arrowOffset
         */
        public function get arrowPosition():String
        {
            return this._arrowPosition;
        }

        /**
         * @private
         */
        public function set arrowPosition(value:String):void
        {
            if(this._arrowPosition == value)
            {
                return;
            }
            this._arrowPosition = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _originalBackgroundWidth:Number = NaN;

        /**
         * @private
         */
        protected var _originalBackgroundHeight:Number = NaN;

        /**
         * @private
         */
        protected var _backgroundSkin:DisplayObject;

        /**
         * The primary background to display.
         *
         * In the following example, the callout's background is set to an image:
         *
         * ~~~as3
         * callout.backgroundSkin = new Image( texture );
         * ~~~
         */
        public function get backgroundSkin():DisplayObject
        {
            return this._backgroundSkin;
        }

        /**
         * @private
         */
        public function set backgroundSkin(value:DisplayObject):void
        {
            if(this._backgroundSkin == value)
            {
                return;
            }

            if(this._backgroundSkin)
            {
                this.removeChild(this._backgroundSkin);
            }
            this._backgroundSkin = value;
            if(this._backgroundSkin)
            {
                this._originalBackgroundWidth = this._backgroundSkin.width;
                this._originalBackgroundHeight = this._backgroundSkin.height;
                this.addChildAt(this._backgroundSkin, 0);
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var currentArrowSkin:DisplayObject;

        /**
         * @private
         */
        protected var _bottomArrowSkin:DisplayObject;

        /**
         * The arrow skin to display on the bottom edge of the callout. This
         * arrow is displayed when the callout is displayed above the region it
         * points at.
         *
         * In the following example, the callout's bottom arrow skin is set
         * to an image:
         *
         * ~~~as3
         * callout.bottomArrowSkin = new Image( texture );
         * ~~~
         */
        public function get bottomArrowSkin():DisplayObject
        {
            return this._bottomArrowSkin;
        }

        /**
         * @private
         */
        public function set bottomArrowSkin(value:DisplayObject):void
        {
            if(this._bottomArrowSkin == value)
            {
                return;
            }

            if(this._bottomArrowSkin)
            {
                this.removeChild(this._bottomArrowSkin);
            }
            this._bottomArrowSkin = value;
            if(this._bottomArrowSkin)
            {
                this._bottomArrowSkin.visible = false;
                const index:int = this.getChildIndex(this._content);
                if(index < 0)
                {
                    this.addChild(this._bottomArrowSkin);
                }
                else
                {
                    this.addChildAt(this._bottomArrowSkin, index);
                }
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _topArrowSkin:DisplayObject;

        /**
         * The arrow skin to display on the top edge of the callout. This arrow
         * is displayed when the callout is displayed below the region it points
         * at.
         *
         * In the following example, the callout's top arrow skin is set
         * to an image:
         *
         * ~~~as3
         * callout.topArrowSkin = new Image( texture );
         * ~~~
         */
        public function get topArrowSkin():DisplayObject
        {
            return this._topArrowSkin;
        }

        /**
         * @private
         */
        public function set topArrowSkin(value:DisplayObject):void
        {
            if(this._topArrowSkin == value)
            {
                return;
            }

            if(this._topArrowSkin)
            {
                this.removeChild(this._topArrowSkin);
            }
            this._topArrowSkin = value;
            if(this._topArrowSkin)
            {
                this._topArrowSkin.visible = false;
                const index:int = this.getChildIndex(this._content);
                if(index < 0)
                {
                    this.addChild(this._topArrowSkin);
                }
                else
                {
                    this.addChildAt(this._topArrowSkin, index);
                }
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _leftArrowSkin:DisplayObject;

        /**
         * The arrow skin to display on the left edge of the callout. This arrow
         * is displayed when the callout is displayed to the right of the region
         * it points at.
         *
         * In the following example, the callout's left arrow skin is set
         * to an image:
         *
         * ~~~as3
         * callout.leftArrowSkin = new Image( texture );
         * ~~~
         */
        public function get leftArrowSkin():DisplayObject
        {
            return this._leftArrowSkin;
        }

        /**
         * @private
         */
        public function set leftArrowSkin(value:DisplayObject):void
        {
            if(this._leftArrowSkin == value)
            {
                return;
            }

            if(this._leftArrowSkin)
            {
                this.removeChild(this._leftArrowSkin);
            }
            this._leftArrowSkin = value;
            if(this._leftArrowSkin)
            {
                this._leftArrowSkin.visible = false;
                const index:int = this.getChildIndex(this._content);
                if(index < 0)
                {
                    this.addChild(this._leftArrowSkin);
                }
                else
                {
                    this.addChildAt(this._leftArrowSkin, index);
                }
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _rightArrowSkin:DisplayObject;

        /**
         * The arrow skin to display on the right edge of the callout. This
         * arrow is displayed when the callout is displayed to the left of the
         * region it points at.
         *
         * In the following example, the callout's right arrow skin is set
         * to an image:
         *
         * ~~~as3
         * callout.rightArrowSkin = new Image( texture );
         * ~~~
         */
        public function get rightArrowSkin():DisplayObject
        {
            return this._rightArrowSkin;
        }

        /**
         * @private
         */
        public function set rightArrowSkin(value:DisplayObject):void
        {
            if(this._rightArrowSkin == value)
            {
                return;
            }

            if(this._rightArrowSkin)
            {
                this.removeChild(this._rightArrowSkin);
            }
            this._rightArrowSkin = value;
            if(this._rightArrowSkin)
            {
                this._rightArrowSkin.visible = false;
                const index:int = this.getChildIndex(this._content);
                if(index < 0)
                {
                    this.addChild(this._rightArrowSkin);
                }
                else
                {
                    this.addChildAt(this._rightArrowSkin, index);
                }
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _topArrowGap:Number = 0;

        /**
         * The space, in pixels, between the top arrow skin and the background
         * skin. To have the arrow overlap the background, you may use a
         * negative gap value.
         *
         * In the following example, the gap between the callout and its
         * top arrow is set to -4 pixels (perhaps to hide a border on the
         * callout's background):
         *
         * ~~~as3
         * callout.topArrowGap = -4;
         * ~~~
         */
        public function get topArrowGap():Number
        {
            return this._topArrowGap;
        }

        /**
         * @private
         */
        public function set topArrowGap(value:Number):void
        {
            if(this._topArrowGap == value)
            {
                return;
            }
            this._topArrowGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _bottomArrowGap:Number = 0;

        /**
         * The space, in pixels, between the bottom arrow skin and the
         * background skin. To have the arrow overlap the background, you may
         * use a negative gap value.
         *
         * In the following example, the gap between the callout and its
         * bottom arrow is set to -4 pixels (perhaps to hide a border on the
         * callout's background):
         *
         * ~~~as3
         * callout.bottomArrowGap = -4;
         * ~~~
         */
        public function get bottomArrowGap():Number
        {
            return this._bottomArrowGap;
        }

        /**
         * @private
         */
        public function set bottomArrowGap(value:Number):void
        {
            if(this._bottomArrowGap == value)
            {
                return;
            }
            this._bottomArrowGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _rightArrowGap:Number = 0;

        /**
         * The space, in pixels, between the right arrow skin and the background
         * skin. To have the arrow overlap the background, you may use a
         * negative gap value.
         *
         * In the following example, the gap between the callout and its
         * right arrow is set to -4 pixels (perhaps to hide a border on the
         * callout's background):
         *
         * ~~~as3
         * callout.rightArrowGap = -4;
         * ~~~
         */
        public function get rightArrowGap():Number
        {
            return this._rightArrowGap;
        }

        /**
         * @private
         */
        public function set rightArrowGap(value:Number):void
        {
            if(this._rightArrowGap == value)
            {
                return;
            }
            this._rightArrowGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _leftArrowGap:Number = 0;

        /**
         * The space, in pixels, between the right arrow skin and the background
         * skin. To have the arrow overlap the background, you may use a
         * negative gap value.
         *
         * In the following example, the gap between the callout and its
         * left arrow is set to -4 pixels (perhaps to hide a border on the
         * callout's background):
         *
         * ~~~as3
         * callout.leftArrowGap = -4;
         * ~~~
         */
        public function get leftArrowGap():Number
        {
            return this._leftArrowGap;
        }

        /**
         * @private
         */
        public function set leftArrowGap(value:Number):void
        {
            if(this._leftArrowGap == value)
            {
                return;
            }
            this._leftArrowGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _arrowOffset:Number = 0;

        /**
         * The offset, in pixels, of the arrow skin from the horizontal center
         * or vertical middle of the background skin, depending on the position
         * of the arrow (which side it is on). This value is used to point at
         * the callout's origin when the callout is not perfectly centered
         * relative to the origin.
         *
         * On the top and bottom edges, the arrow will move left for negative
         * values of `arrowOffset` and right for positive values. On
         * the left and right edges, the arrow will move up for negative values
         * and down for positive values.
         *
         * If you use `Callout.show()` or set the `origin`
         * property manually, you should avoid manually modifying the
         * `arrowPosition` and `arrowOffset` properties.
         *
         * In the following example, the arrow offset is set to 20 pixels:
         *
         * ~~~as3
         * callout.arrowOffset = 20;
         * ~~~
         *
         * @see #arrowPosition
         * @see #origin
         */
        public function get arrowOffset():Number
        {
            return this._arrowOffset;
        }

        /**
         * @private
         */
        public function set arrowOffset(value:Number):void
        {
            if(this._arrowOffset == value)
            {
                return;
            }
            this._arrowOffset = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _lastGlobalBoundsOfOrigin:Rectangle;

        /**
         * @private
         */
        override public function dispose():void
        {
            this.origin = null;
            //remove the content safely if it should not be disposed
            if(!this.disposeContent && this._content && this._content.parent == this)
            {
                this.removeChild(this._content, false);
            }
            super.dispose();
        }

        /**
         * Closes the callout.
         */
        public function close(dispose:Boolean = false):void
        {
            if(this.parent)
            {
                //don't dispose here because we need to keep the event listeners
                //when dispatching Event.CLOSE. we'll dispose after that.
                this.removeFromParent(false);
                this.dispatchEventWith(Event.CLOSE);
            }
            if(dispose)
            {
                this.dispose();
            }
        }

        /**
         * @private
         */
        override protected function initialize():void
        {
            this.stage.addEventListener(TouchEvent.TOUCH, stage_touchHandler);
            Loom2D.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, callout_removedFromStageHandler);
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const originInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_ORIGIN);

            if(originInvalid)
            {
                this.positionToOrigin();
            }

            if(stylesInvalid || stateInvalid)
            {
                this.refreshArrowSkin();
            }

            if(stateInvalid)
            {
                if(this._content is FeathersControl)
                {
                    FeathersControl(this._content).isEnabled = this._isEnabled;
                }
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(sizeInvalid || stylesInvalid || dataInvalid || stateInvalid)
            {
                this.layoutChildren();
            }
        }

        /**
         * @private
         */
        protected function autoSizeIfNeeded():Boolean
        {
            var helperPoint = this.measureWithArrowPosition(this._arrowPosition);
            return this.setSizeInternal(helperPoint.x, helperPoint.y, false);
        }

        /**
         * @private
         */
        protected function measureWithArrowPosition(arrowPosition:String):Point
        {
            var result = new Point();

            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                result.x = this.explicitWidth;
                result.y = this.explicitHeight;
                return result;
            }

            const needsContentWidth:Boolean = isNaN(this._originalContentWidth);
            const needsContentHeight:Boolean = isNaN(this._originalContentHeight);
            if(this._content && (needsContentWidth || needsContentHeight))
            {
                if(this._content is FeathersControl)
                {
                    FeathersControl(this._content).validate();
                }
                if(needsContentWidth)
                {
                    this._originalContentWidth = this._content.width;
                }
                if(needsContentHeight)
                {
                    this._originalContentHeight = this._content.height;
                }
            }

            var newWidth:Number = this.explicitWidth;
            var newHeight:Number = this.explicitHeight;
            if(needsWidth)
            {
                newWidth = this._originalContentWidth + this._paddingLeft + this._paddingRight;
                if(!isNaN(this._originalBackgroundWidth))
                {
                    newWidth = Math.max(this._originalBackgroundWidth, newWidth);
                }
                if(arrowPosition == ARROW_POSITION_LEFT && this._leftArrowSkin)
                {
                    newWidth += this._leftArrowSkin.width + this._leftArrowGap;
                }
                if(arrowPosition == ARROW_POSITION_RIGHT && this._rightArrowSkin)
                {
                    newWidth += this._rightArrowSkin.width + this._rightArrowGap;
                }
                if(arrowPosition == ARROW_POSITION_TOP && this._topArrowSkin)
                {
                    newWidth = Math.max(newWidth, this._topArrowSkin.width + this._paddingLeft + this._paddingRight);
                }
                if(arrowPosition == ARROW_POSITION_BOTTOM && this._bottomArrowSkin)
                {
                    newWidth = Math.max(newWidth, this._bottomArrowSkin.width + this._paddingLeft + this._paddingRight);
                }
                newWidth = Math.min(newWidth, this.stage.stageWidth - stagePaddingLeft - stagePaddingRight);
            }
            if(needsHeight)
            {
                newHeight = this._originalContentHeight + this._paddingTop + this._paddingBottom;
                if(!isNaN(this._originalBackgroundHeight))
                {
                    newHeight = Math.max(this._originalBackgroundHeight, newHeight);
                }
                if(arrowPosition == ARROW_POSITION_TOP && this._topArrowSkin)
                {
                    newHeight += this._topArrowSkin.height + this._topArrowGap;
                }
                if(arrowPosition == ARROW_POSITION_BOTTOM && this._bottomArrowSkin)
                {
                    newHeight += this._bottomArrowSkin.height + this._bottomArrowGap;
                }
                if(arrowPosition == ARROW_POSITION_LEFT && this._leftArrowSkin)
                {
                    newHeight = Math.max(newHeight, this._leftArrowSkin.height + this._paddingTop + this._paddingBottom);
                }
                if(arrowPosition == ARROW_POSITION_RIGHT && this._rightArrowSkin)
                {
                    newHeight = Math.max(newHeight, this._rightArrowSkin.height + this._paddingTop + this._paddingBottom);
                }
                newHeight = Math.min(newHeight, this.stage.stageHeight - stagePaddingTop - stagePaddingBottom);
            }
            result.x = Math.max(this._minWidth, Math.min(this._maxWidth, newWidth));
            result.y = Math.max(this._minHeight,  Math.min(this._maxHeight, newHeight));
            return result;
        }

        /**
         * @private
         */
        protected function refreshArrowSkin():void
        {
            this.currentArrowSkin = null;
            if(this._arrowPosition == ARROW_POSITION_BOTTOM)
            {
                this.currentArrowSkin = this._bottomArrowSkin;
            }
            else if(this._bottomArrowSkin)
            {
                this._bottomArrowSkin.visible = false;
            }
            if(this._arrowPosition == ARROW_POSITION_TOP)
            {
                this.currentArrowSkin = this._topArrowSkin;
            }
            else if(this._topArrowSkin)
            {
                this._topArrowSkin.visible = false;
            }
            if(this._arrowPosition == ARROW_POSITION_LEFT)
            {
                this.currentArrowSkin = this._leftArrowSkin;
            }
            else if(this._leftArrowSkin)
            {
                this._leftArrowSkin.visible = false;
            }
            if(this._arrowPosition == ARROW_POSITION_RIGHT)
            {
                this.currentArrowSkin = this._rightArrowSkin;
            }
            else if(this._rightArrowSkin)
            {
                this._rightArrowSkin.visible = false;
            }
            if(this.currentArrowSkin)
            {
                this.currentArrowSkin.visible = true;
            }
        }

        /**
         * @private
         */
        protected function layoutChildren():void
        {
            const xPosition:Number = (this._leftArrowSkin && this._arrowPosition == ARROW_POSITION_LEFT) ? this._leftArrowSkin.width + this._leftArrowGap : 0;
            const yPosition:Number = (this._topArrowSkin &&  this._arrowPosition == ARROW_POSITION_TOP) ? this._topArrowSkin.height + this._topArrowGap : 0;
            const widthOffset:Number = (this._rightArrowSkin && this._arrowPosition == ARROW_POSITION_RIGHT) ? this._rightArrowSkin.width + this._rightArrowGap : 0;
            const heightOffset:Number = (this._bottomArrowSkin && this._arrowPosition == ARROW_POSITION_BOTTOM) ? this._bottomArrowSkin.height + this._bottomArrowGap : 0;

            this._backgroundSkin.x = xPosition;
            this._backgroundSkin.y = yPosition;
            this._backgroundSkin.width = this.actualWidth - xPosition - widthOffset;
            this._backgroundSkin.height = this.actualHeight - yPosition - heightOffset;

            if(this.currentArrowSkin)
            {
                if(this._arrowPosition == ARROW_POSITION_LEFT)
                {
                    this._leftArrowSkin.x = this._backgroundSkin.x - this._leftArrowSkin.width - this._leftArrowGap;
                    this._leftArrowSkin.y = this._arrowOffset + this._backgroundSkin.y + (this._backgroundSkin.height - this._leftArrowSkin.height) / 2;
                    this._leftArrowSkin.y = Math.min(this._backgroundSkin.y + this._backgroundSkin.height - this._paddingBottom - this._leftArrowSkin.height, Math.max(this._backgroundSkin.y + this._paddingTop, this._leftArrowSkin.y));
                }
                else if(this._arrowPosition == ARROW_POSITION_RIGHT)
                {
                    this._rightArrowSkin.x = this._backgroundSkin.x + this._backgroundSkin.width + this._rightArrowGap;
                    this._rightArrowSkin.y = this._arrowOffset + this._backgroundSkin.y + (this._backgroundSkin.height - this._rightArrowSkin.height) / 2;
                    this._rightArrowSkin.y = Math.min(this._backgroundSkin.y + this._backgroundSkin.height - this._paddingBottom - this._rightArrowSkin.height, Math.max(this._backgroundSkin.y + this._paddingTop, this._rightArrowSkin.y));
                }
                else if(this._arrowPosition == ARROW_POSITION_BOTTOM)
                {
                    this._bottomArrowSkin.x = this._arrowOffset + this._backgroundSkin.x + (this._backgroundSkin.width - this._bottomArrowSkin.width) / 2;
                    this._bottomArrowSkin.x = Math.min(this._backgroundSkin.x + this._backgroundSkin.width - this._paddingRight - this._bottomArrowSkin.width, Math.max(this._backgroundSkin.x + this._paddingLeft, this._bottomArrowSkin.x));
                    this._bottomArrowSkin.y = this._backgroundSkin.y + this._backgroundSkin.height + this._bottomArrowGap;
                }
                else //top
                {
                    this._topArrowSkin.x = this._arrowOffset + this._backgroundSkin.x + (this._backgroundSkin.width - this._topArrowSkin.width) / 2;
                    this._topArrowSkin.x = Math.min(this._backgroundSkin.x + this._backgroundSkin.width - this._paddingRight - this._topArrowSkin.width, Math.max(this._backgroundSkin.x + this._paddingLeft, this._topArrowSkin.x));
                    this._topArrowSkin.y = this._backgroundSkin.y - this._topArrowSkin.height - this._topArrowGap;
                }
            }

            if(this._content)
            {
                this._content.x = this._backgroundSkin.x + this._paddingLeft;
                this._content.y = this._backgroundSkin.y + this._paddingTop;
                this._content.width = this._backgroundSkin.width - this._paddingLeft - this._paddingRight;
                this._content.height = this._backgroundSkin.height - this._paddingTop - this._paddingBottom;
            }
        }

        /**
         * @private
         */
        protected function positionToOrigin():void
        {
            if(!this._origin)
            {
                return;
            }
            this._origin.getBounds(Loom2D.stage, HELPER_RECT);
            const hasGlobalBounds:Boolean = this._lastGlobalBoundsOfOrigin != null;

            var lastBoundsEqualsHelper:Boolean = hasGlobalBounds && _lastGlobalBoundsOfOrigin.x == HELPER_RECT.x && _lastGlobalBoundsOfOrigin.y == HELPER_RECT.y &&
                _lastGlobalBoundsOfOrigin.width == HELPER_RECT.width && _lastGlobalBoundsOfOrigin.height == HELPER_RECT.height;

            if(!hasGlobalBounds || !lastBoundsEqualsHelper)
            {
                if(!hasGlobalBounds)
                {
                    this._lastGlobalBoundsOfOrigin = new Rectangle();
                }
                this._lastGlobalBoundsOfOrigin.x = HELPER_RECT.x;
                this._lastGlobalBoundsOfOrigin.y = HELPER_RECT.y;
                this._lastGlobalBoundsOfOrigin.width = HELPER_RECT.width;
                this._lastGlobalBoundsOfOrigin.height = HELPER_RECT.height;
                positionWithSupportedDirections(this, this._lastGlobalBoundsOfOrigin, this._supportedDirections);
            }
        }

        /**
         * @private
         */
        protected function callout_addedToStageHandler(event:Event):void
        {
            //to avoid touch events bubbling up to the callout and causing it to
            //close immediately, we wait one frame before allowing it to close
            //based on touches.
            this._isReadyToClose = false;
            this.stage.addEventListener(EnterFrameEvent.ENTER_FRAME, callout_oneEnterFrameHandler);
        }

        /**
         * @private
         */
        protected function callout_removedFromStageHandler(event:Event):void
        {
            this.stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
            Loom2D.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
        }

        /**
         * @private
         */
        protected function callout_oneEnterFrameHandler(event:Event):void
        {
            this.stage.removeEventListener(EnterFrameEvent.ENTER_FRAME, callout_oneEnterFrameHandler);
            this._isReadyToClose = true;
        }

        /**
         * @private
         */
        protected function callout_enterFrameHandler(event:EnterFrameEvent):void
        {
            this.positionToOrigin();
        }

        /**
         * @private
         */
        protected function stage_touchHandler(event:TouchEvent):void
        {
            const target:DisplayObject = DisplayObject(event.target);
            if(!this._isReadyToClose ||
                (!this.closeOnTouchEndedOutside && !this.closeOnTouchBeganOutside) || this.contains(target) ||
                (PopUpManager.isPopUp(this) && !PopUpManager.isTopLevelPopUp(this)))
            {
                return;
            }

            if(this._origin == target || (this._origin is DisplayObjectContainer && DisplayObjectContainer(this._origin).contains(target)))
            {
                return;
            }

            const touches:Vector.<Touch> = event.getTouches(this.stage, null, HELPER_TOUCHES_VECTOR);
            const touchCount:int = touches.length;
            for(var i:int = 0; i < touchCount; i++)
            {
                var touch:Touch = touches[i];
                var phase:String = touch.phase;
                if((this.closeOnTouchBeganOutside && phase == TouchPhase.BEGAN) ||
                    (this.closeOnTouchEndedOutside && phase == TouchPhase.ENDED))
                {
                    this.close(this.disposeOnSelfClose);
                    break;
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function stage_keyDownHandler(event:KeyboardEvent):void
        {
            if(!this.closeOnKeys || this.closeOnKeys.indexOf(event.keyCode) < 0)
            {
                return;
            }

            //don't let other event handlers handle the event
            event.stopImmediatePropagation();
            this.close(this.disposeOnSelfClose);
        }

        /**
         * @private
         */
        protected function origin_removedFromStageHandler(event:Event):void
        {
            this.close(this.disposeOnSelfClose);
        }
    }
}
