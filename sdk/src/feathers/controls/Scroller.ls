/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.controls.supportClasses.IViewPort;
    import feathers.core.FeathersControl;
    import feathers.events.FeathersEventType;
    import feathers.system.DeviceCapabilities;
    import feathers.utils.FeathersMath;

    import loom2d.math.Point;
    import loom2d.math.Rectangle;

    import loom2d.animation.Transitions;
    import loom2d.animation.Tween;
    import loom2d.display.DisplayObject;
    import loom2d.display.Quad;
    import loom2d.display.Sprite;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    import loom2d.Loom2D;

    import loom.platform.Timer;

    /**
     * Dispatched when the scroller scrolls in either direction or when the view
     * port's scrolling bounds have changed. Listen for `FeathersEventType.SCROLL_START`
     * to know when scrolling starts as a result of user interaction or when
     * scrolling is triggered by an animation. Similarly, listen for
     * `FeathersEventType.SCROLL_COMPLETE` to know when the scrolling
     * ends.
     *
     * @eventType loom2d.events.Event.SCROLL
     * @see feathers.events.FeathersEventType.SCROLL_START
     * @see feathers.events.FeathersEventType.SCROLL_COMPLETE
     */
    [Event(name="scroll",type="loom2d.events.Event")]

    /**
     * Dispatched when the scroller starts scrolling in either direction
     * as a result of either user interaction or animation.
     *
     * Note: If `horizontalScrollPosition` or `verticalScrollPosition`
     * is set manually (in other words, the scrolling is not triggered by user
     * interaction or an animated scroll), no `FeathersEventType.SCROLL_START`
     * or `FeathersEventType.SCROLL_COMPLETE` events will be
     * dispatched.
     *
     * @eventType feathers.events.FeathersEventType.SCROLL_START
     * @see feathers.events.FeathersEventType.SCROLL_COMPLETE
     * @see feathers.events.FeathersEventType.SCROLL
     */
    [Event(name="scrollStart",type="loom2d.events.Event")]

    /**
     * Dispatched when the scroller finishes scrolling in either direction
     * as a result of either user interaction or animation. Animations may not
     * end at the same time that user interaction ends, so the event may be
     * delayed if user interaction triggers scrolling again.
     *
     * Note: If `horizontalScrollPosition` or `verticalScrollPosition`
     * is set manually (in other words, the scrolling is not triggered by user
     * interaction or an animated scroll), no `FeathersEventType.SCROLL_START`
     * or `FeathersEventType.SCROLL_COMPLETE` events will be
     * dispatched.
     *
     * @eventType feathers.events.FeathersEventType.SCROLL_COMPLETE
     * @see feathers.events.FeathersEventType.SCROLL_START
     * @see feathers.events.FeathersEventType.SCROLL
     */
    [Event(name="scrollComplete",type="loom2d.events.Event")]

    /**
     * Dispatched when the user starts dragging the scroller when
     * `INTERACTION_MODE_TOUCH` is enabled or when the user starts
     * interacting with the scroll bar.
     *
     * Note: If `horizontalScrollPosition` or `verticalScrollPosition`
     * is set manually (in other words, the scrolling is not triggered by user
     * interaction), no `FeathersEventType.BEGIN_INTERACTION`
     * or `FeathersEventType.END_INTERACTION` events will be
     * dispatched.
     *
     * @eventType feathers.events.FeathersEventType.BEGIN_INTERACTION
     * @see feathers.events.FeathersEventType.END_INTERACTION
     * @see feathers.events.FeathersEventType.SCROLL
     */
    [Event(name="beginInteraction",type="loom2d.events.Event")]

    /**
     * Dispatched when the user stops dragging the scroller when
     * `INTERACTION_MODE_TOUCH` is enabled or when the user stops
     * interacting with the scroll bar. The scroller may continue scrolling
     * after this event is dispatched if the user interaction has also triggered
     * an animation.
     *
     * Note: If `horizontalScrollPosition` or `verticalScrollPosition`
     * is set manually (in other words, the scrolling is not triggered by user
     * interaction), no `FeathersEventType.BEGIN_INTERACTION`
     * or `FeathersEventType.END_INTERACTION` events will be
     * dispatched.
     *
     * @eventType feathers.events.FeathersEventType.END_INTERACTION
     * @see feathers.events.FeathersEventType.BEGIN_INTERACTION
     * @see feathers.events.FeathersEventType.SCROLL
     */
    [Event(name="endInteraction",type="loom2d.events.Event")]

    /**
     * Allows horizontal and vertical scrolling of a _view port_. Not
     * meant to be used as a standalone container or component. Generally meant
     * to be the super class of another component that needs to support
     * scrolling. To put components in a generic scrollable container (with
     * optional layout), see `ScrollContainer`. To scroll long
     * passages of text, see `ScrollText`.
     *
     * @see http://wiki.starling-framework.org/feathers/scroller
     * @see ScrollContainer
     * @see ScrollText
     */
    public class Scroller extends FeathersControl
    {
        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_SCROLL_BAR_RENDERER:String = "scrollBarRenderer";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_PENDING_SCROLL:String = "pendingScroll";

        /**
         * The scroller may scroll if the view port is larger than the
         * scroller's bounds. If the interaction mode is touch, the elastic
         * edges will only be active if the maximum scroll position is greater
         * than zero. If the scroll bar display mode is fixed, the scroll bar
         * will only be visible when the maximum scroll position is greater than
         * zero.
         *
         * @see feathers.controls.Scroller#horizontalScrollPolicy
         * @see feathers.controls.Scroller#verticalScrollPolicy
         */
        public static const SCROLL_POLICY_AUTO:String = "auto";

        /**
         * The scroller will always scroll. If the interaction mode is touch,
         * elastic edges will always be active, even when the maximum scroll
         * position is zero. If the scroll bar display mode is fixed, the scroll
         * bar will always be visible.
         *
         * @see feathers.controls.Scroller#horizontalScrollPolicy
         * @see feathers.controls.Scroller#verticalScrollPolicy
         */
        public static const SCROLL_POLICY_ON:String = "on";
        
        /**
         * The scroller does not scroll at all. If the scroll bar display mode
         * is fixed or float, the scroll bar will never be visible.
         *
         * @see feathers.controls.Scroller#horizontalScrollPolicy
         * @see feathers.controls.Scroller#verticalScrollPolicy
         */
        public static const SCROLL_POLICY_OFF:String = "off";

        /**
         * The scroll bars appear above the scroller's view port, and fade out
         * when not in use.
         *
         * @see feathers.controls.Scroller#scrollBarDisplayMode
         */
        public static const SCROLL_BAR_DISPLAY_MODE_FLOAT:String = "float";

        /**
         * The scroll bars are always visible and appear next to the scroller's
         * view port, making the view port smaller than the scroller.
         *
         * @see feathers.controls.Scroller#scrollBarDisplayMode
         */
        public static const SCROLL_BAR_DISPLAY_MODE_FIXED:String = "fixed";

        /**
         * The scroll bars are never visible.
         *
         * @see feathers.controls.Scroller#scrollBarDisplayMode
         */
        public static const SCROLL_BAR_DISPLAY_MODE_NONE:String = "none";

        /**
         * The user may touch anywhere on the scroller and drag to scroll.
         *
         * @see feathers.controls.Scroller#interactionMode
         */
        public static const INTERACTION_MODE_TOUCH:String = "touch";

        /**
         * The user may interact with the scroll bars to scroll.
         *
         * @see feathers.controls.Scroller#interactionMode
         */
        public static const INTERACTION_MODE_MOUSE:String = "mouse";
        
        /**
         * Flag to indicate that the clipping has changed.
         */
        protected static const INVALIDATION_FLAG_CLIPPING:String = "clipping";
        
        /**
         * @private
         * The minimum physical distance (in inches) that a touch must move
         * before the scroller starts scrolling.
         */
        private static const MINIMUM_DRAG_DISTANCE:Number = 0.04;

        /**
         * @private
         * The minimum physical velocity (in inches per second) that a touch
         * must move before the scroller will "throw" to the next page.
         * Otherwise, it will settle to the nearest page.
         */
        private static const MINIMUM_PAGE_VELOCITY:Number = 5;

        /**
         * @private
         * The point where we stop calculating velocity changes because floating
         * point issues can start to appear.
         */
        private static const MINIMUM_VELOCITY:Number = 0.02;
        
        /**
         * @private
         * The friction applied every frame when the scroller is "thrown".
         */
        private static const FRICTION:Number = 0.998;

        /**
         * @private
         * Extra friction applied when the scroller is beyond its bounds and
         * needs to bounce back.
         */
        private static const EXTRA_FRICTION:Number = 0.95;

        /**
         * @private
         * Older saved velocities are given less importance.
         */
        private static const VELOCITY_WEIGHTS:Vector.<Number> = new <Number>[2, 1.66, 1.33, 1];

        /**
         * @private
         */
        private static const MAXIMUM_SAVED_VELOCITY_COUNT:int = 4;

        /**
         * The default value added to the `nameList` of the
         * horizontal scroll bar.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_HORIZONTAL_SCROLL_BAR:String = "feathers-scroller-horizontal-scroll-bar";

        /**
         * The default value added to the `nameList` of the vertical
         * scroll bar.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_VERTICAL_SCROLL_BAR:String = "feathers-scroller-vertical-scroll-bar";

        /**
         * @private
         */
        protected static function defaultHorizontalScrollBarFactory():IScrollBar
        {
            const scrollBar:SimpleScrollBar = new SimpleScrollBar();
            scrollBar.direction = SimpleScrollBar.DIRECTION_HORIZONTAL;
            return scrollBar;
        }

        /**
         * @private
         */
        protected static function defaultVerticalScrollBarFactory():IScrollBar
        {
            const scrollBar:SimpleScrollBar = new SimpleScrollBar();
            scrollBar.direction = SimpleScrollBar.DIRECTION_VERTICAL;
            return scrollBar;
        }
        
        /**
         * Constructor.
         */
        public function Scroller()
        {
            super();

            this.addEventListener(Event.ADDED_TO_STAGE, scroller_addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, scroller_removedFromStageHandler);
        }

        /**
         * The value added to the `nameList` of the horizontal scroll
         * bar. This variable is `protected` so that sub-classes can
         * customize the horizontal scroll bar name in their constructors
         * instead of using the default name defined by `DEFAULT_CHILD_NAME_HORIZONTAL_SCROLL_BAR`.
         *
         * To customize the horizontal scroll bar name without subclassing, see
         * `customHorizontalScrollBarName`.
         *
         * @see #customHorizontalScrollBarName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var horizontalScrollBarName:String = DEFAULT_CHILD_NAME_HORIZONTAL_SCROLL_BAR;

        /**
         * The value added to the `nameList` of the vertical scroll
         * bar. This variable is `protected` so that sub-classes can
         * customize the horizontal scroll bar name in their constructors
         * instead of using the default name defined by `DEFAULT_CHILD_NAME_HORIZONTAL_SCROLL_BAR`.
         *
         * To customize the vertical scroll bar name without subclassing, see
         * `customVerticalScrollBarName`.
         *
         * @see #customVerticalScrollBarName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var verticalScrollBarName:String = DEFAULT_CHILD_NAME_VERTICAL_SCROLL_BAR;

        /**
         * The horizontal scrollbar instance. May be null.
         */
        protected var horizontalScrollBar:IScrollBar;

        /**
         * The vertical scrollbar instance. May be null.
         */
        protected var verticalScrollBar:IScrollBar;

        /**
         * @private
         */
        protected var _topViewPortOffset:Number;

        /**
         * @private
         */
        protected var _rightViewPortOffset:Number;

        /**
         * @private
         */
        protected var _bottomViewPortOffset:Number;

        /**
         * @private
         */
        protected var _leftViewPortOffset:Number;

        /**
         * @private
         */
        protected var _hasHorizontalScrollBar:Boolean = false;

        /**
         * @private
         */
        protected var _hasVerticalScrollBar:Boolean = false;

        /**
         * @private
         */
        protected var _horizontalScrollBarTouchPointID:int = -1;

        /**
         * @private
         */
        protected var _verticalScrollBarTouchPointID:int = -1;

        /**
         * @private
         */
        protected var _touchPointID:int = -1;

        /**
         * @private
         */
        protected var _startTouchX:Number;

        /**
         * @private
         */
        protected var _startTouchY:Number;

        /**
         * @private
         */
        protected var _startHorizontalScrollPosition:Number;

        /**
         * @private
         */
        protected var _startVerticalScrollPosition:Number;

        /**
         * @private
         */
        protected var _currentTouchX:Number;

        /**
         * @private
         */
        protected var _currentTouchY:Number;

        /**
         * @private
         */
        protected var _previousTouchTime:int;

        /**
         * @private
         */
        protected var _previousTouchX:Number;

        /**
         * @private
         */
        protected var _previousTouchY:Number;

        /**
         * @private
         */
        protected var _velocityX:Number = 0;

        /**
         * @private
         */
        protected var _velocityY:Number = 0;

        /**
         * @private
         */
        protected var _previousVelocityX:Vector.<Number> = new <Number>[];

        /**
         * @private
         */
        protected var _previousVelocityY:Vector.<Number> = new <Number>[];

        /**
         * @private
         */
        protected var _lastViewPortWidth:Number = 0;

        /**
         * @private
         */
        protected var _lastViewPortHeight:Number = 0;

        /**
         * @private
         */
        protected var _hasViewPortBoundsChanged:Boolean = false;

        /**
         * @private
         */
        protected var _horizontalAutoScrollTween:Tween;

        /**
         * @private
         */
        protected var _verticalAutoScrollTween:Tween;

        /**
         * @private
         */
        protected var _isDraggingHorizontally:Boolean = false;

        /**
         * @private
         */
        protected var _isDraggingVertically:Boolean = false;

        /**
         * @private
         */
        protected var ignoreViewPortResizing:Boolean = false;

        /**
         * @private
         */
        protected var _touchBlocker:Quad;
        
        /**
         * @private
         */
        protected var _viewPort:IViewPort;
        
        /**
         * The display object displayed and scrolled within the Scroller.
         */
        public function get viewPort():IViewPort
        {
            return this._viewPort;
        }
        
        /**
         * @private
         */
        public function set viewPort(value:IViewPort):void
        {
            if(this._viewPort == value)
            {
                return;
            }
            if(this._viewPort)
            {
                this._viewPort.removeEventListener(FeathersEventType.RESIZE, viewPort_resizeHandler);
                this.removeChild(DisplayObject(this._viewPort));
            }
            this._viewPort = value;
            if(this._viewPort)
            {
                this._viewPort.addEventListener(FeathersEventType.RESIZE, viewPort_resizeHandler);
                this.addChildAt(DisplayObject(this._viewPort), 0);
            }
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _snapToPages:Boolean = false;

        /**
         * Determines if scrolling will snap to the nearest page.
         */
        public function get snapToPages():Boolean
        {
            return this._snapToPages;
        }

        /**
         * @private
         */
        public function set snapToPages(value:Boolean):void
        {
            if(this._snapToPages == value)
            {
                return;
            }
            this._snapToPages = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
        }

        /**
         * @private
         */
        protected var _horizontalScrollBarFactory:Function = defaultHorizontalScrollBarFactory;

        /**
         * Creates the horizontal scroll bar. The horizontal scroll bar must be
         * an instance of `IScrollBar`. This factory can be used to
         * change properties on the horizontal scroll bar when it is first
         * created. For instance, if you are skinning Feathers components
         * without a theme, you might use this factory to set skins and other
         * styles on the horizontal scroll bar.
         *
         * This function is expected to have the following signature:
         *
         * `function():IScrollBar`
         *
         * @see feathers.controls.IScrollBar
         * @see #horizontalScrollBarProperties
         */
        public function get horizontalScrollBarFactory():Function
        {
            return this._horizontalScrollBarFactory;
        }

        /**
         * @private
         */
        public function set horizontalScrollBarFactory(value:Function):void
        {
            if(this._horizontalScrollBarFactory == value)
            {
                return;
            }
            this._horizontalScrollBarFactory = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
        }

        /**
         * @private
         */
        protected var _customHorizontalScrollBarName:String;

        /**
         * A name to add to the container's horizontal scroll bar sub-component.
         * Typically used by a theme to provide different skins to different
         * containers.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #horizontalScrollBarFactory
         * @see #horizontalScrollBarProperties
         */
        public function get customHorizontalScrollBarName():String
        {
            return this._customHorizontalScrollBarName;
        }

        /**
         * @private
         */
        public function set customHorizontalScrollBarName(value:String):void
        {
            if(this._customHorizontalScrollBarName == value)
            {
                return;
            }
            this._customHorizontalScrollBarName = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
        }

        /**
         * @private
         */
        protected var _horizontalScrollBarProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroller's
         * horizontal scroll bar instance (if it exists). The scroll bar is an
         * `IScrollBar` instance. The available properties depend on
         * which implementation of `IScrollBar` is returned by
         * `horizontalScrollBarFactory`. The most common
         * implementations are `SimpleScrollBar` and `ScrollBar`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `horizontalScrollBarFactory`
         * function instead of using `horizontalScrollBarProperties`
         * will result in better performance.
         *
         * @see #horizontalScrollBarFactory
         * @see feathers.controls.IScrollBar
         * @see feathers.controls.SimpleScrollBar
         * @see feathers.controls.ScrollBar
         */
        public function get horizontalScrollBarProperties():Dictionary.<String, Object>
        {
            if(!this._horizontalScrollBarProperties)
            {
                this._horizontalScrollBarProperties = new Dictionary.<String, Object>;
            }
            return this._horizontalScrollBarProperties;
        }

        /**
         * @private
         */
        public function set horizontalScrollBarProperties(value:Dictionary.<String, Object>):void
        {
            if(this._horizontalScrollBarProperties == value)
            {
                return;
            }
            this._horizontalScrollBarProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _verticalScrollBarFactory:Function = defaultVerticalScrollBarFactory;

        /**
         * Creates the vertical scroll bar. The vertical scroll bar must be an
         * instance of `Button`. This factory can be used to change
         * properties on the vertical scroll bar when it is first created. For
         * instance, if you are skinning Feathers components without a theme,
         * you might use this factory to set skins and other styles on the
         * vertical scroll bar.
         *
         * This function is expected to have the following signature:
         *
         * `function():IScrollBar`
         *
         * @see feathers.controls.IScrollBar
         * @see #verticalScrollBarProperties
         */
        public function get verticalScrollBarFactory():Function
        {
            return this._verticalScrollBarFactory;
        }

        /**
         * @private
         */
        public function set verticalScrollBarFactory(value:Function):void
        {
            if(this._verticalScrollBarFactory == value)
            {
                return;
            }
            this._verticalScrollBarFactory = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
        }

        /**
         * @private
         */
        protected var _customVerticalScrollBarName:String;

        /**
         * A name to add to the container's vertical scroll bar sub-component.
         * Typically used by a theme to provide different skins to different
         * containers.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #verticalScrollBarFactory
         * @see #verticalScrollBarProperties
         */
        public function get customVerticalScrollBarName():String
        {
            return this._customVerticalScrollBarName;
        }

        /**
         * @private
         */
        public function set customVerticalScrollBarName(value:String):void
        {
            if(this._customVerticalScrollBarName == value)
            {
                return;
            }
            this._customVerticalScrollBarName = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
        }

        /**
         * @private
         */
        protected var _verticalScrollBarProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroller's
         * vertical scroll bar instance (if it exists). The scroll bar is an
         * `IScrollBar` instance. The available properties depend on
         * which implementation of `IScrollBar` is returned by
         * `verticalScrollBarFactory`. The most common
         * implementations are `SimpleScrollBar` and `ScrollBar`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `verticalScrollBarFactory`
         * function instead of using `verticalScrollBarProperties`
         * will result in better performance.
         *
         * @see #verticalScrollBarFactory
         * @see feathers.controls.IScrollBar
         * @see feathers.controls.SimpleScrollBar
         * @see feathers.controls.ScrollBar
         */
        public function get verticalScrollBarProperties():Dictionary.<String, Object>
        {
            if(!this._verticalScrollBarProperties)
            {
                this._verticalScrollBarProperties = new Dictionary.<String, Object>;
            }
            return this._verticalScrollBarProperties;
        }

        /**
         * @private
         */
        public function set verticalScrollBarProperties(value:Dictionary.<String, Object>):void
        {
            if(this._verticalScrollBarProperties == value)
            {
                return;
            }
            this._verticalScrollBarProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var actualHorizontalScrollStep:Number = 1;

        /**
         * @private
         */
        protected var explicitHorizontalScrollStep:Number = NaN;

        /**
         * The number of pixels the scroller can be stepped horizontally. Passed
         * to the horizontal scroll bar, if one exists. Touch scrolling is not
         * affected by the step value.
         */
        public function get horizontalScrollStep():Number
        {
            return this.actualHorizontalScrollStep;
        }

        /**
         * @private
         */
        public function set horizontalScrollStep(value:Number):void
        {
            if(this.explicitHorizontalScrollStep == value)
            {
                return;
            }
            if(isNaN(value))
            {
                //nope
                Debug.assert("horizontalScrollStep cannot be NaN.");
            }
            this.explicitHorizontalScrollStep = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
        }

        /**
         * @private
         */
        protected var _targetHorizontalScrollPosition:Number;
        
        /**
         * @private
         */
        protected var _horizontalScrollPosition:Number = 0;
        
        /**
         * The number of pixels the scroller has been scrolled horizontally (on
         * the x-axis).
         */
        public function get horizontalScrollPosition():Number
        {
            return this._horizontalScrollPosition;
        }
        
        /**
         * @private
         */
        public function set horizontalScrollPosition(value:Number):void
        {
            if(this._snapScrollPositionsToPixels)
            {
                value = Math.round(value);
            }
            if(this._horizontalScrollPosition == value)
            {
                return;
            }
            if(isNaN(value))
            {
                //there isn't any recovery from this, so stop it early
                Debug.assert("horizontalScrollPosition cannot be NaN.");
            }
            this._horizontalScrollPosition = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
        }
        
        /**
         * @private
         */
        protected var _maxHorizontalScrollPosition:Number = 0;
        
        /**
         * The maximum number of pixels the scroller may be scrolled
         * horizontally (on the x-axis). This value is automatically calculated
         * based on the width of the viewport. The `horizontalScrollPosition`
         * property may have a higher value than the maximum due to elastic
         * edges. However, once the user stops interacting with the scroller,
         * it will automatically animate back to the maximum (or minimum, if
         * below 0).
         */
        public function get maxHorizontalScrollPosition():Number
        {
            return this._maxHorizontalScrollPosition;
        }

        /**
         * @private
         */
        protected var _horizontalPageIndex:int = 0;

        /**
         * The index of the horizontal page, if snapping is enabled. If snapping
         * is disabled, the index will always be `0`.
         */
        public function get horizontalPageIndex():int
        {
            if(this.pendingHorizontalPageIndex >= 0)
            {
                return this.pendingHorizontalPageIndex;
            }
            return this._horizontalPageIndex;
        }

        /**
         * @private
         */
        protected var _horizontalPageCount:int = 1;

        /**
         * The number of horizontal pages, if snapping is enabled. If snapping
         * is disabled, the page count will always be `1`.
         */
        public function get horizontalPageCount():int
        {
            return this._horizontalPageCount;
        }

        /**
         * @private
         */
        protected var _horizontalScrollPolicy:String = SCROLL_POLICY_AUTO;

        [Inspectable(type="String",enumeration="auto,on,off")]
        /**
         * Determines whether the scroller may scroll horizontally (on the
         * x-axis) or not.
         *
         * @see #SCROLL_POLICY_AUTO
         * @see #SCROLL_POLICY_ON
         * @see #SCROLL_POLICY_OFF
         */
        public function get horizontalScrollPolicy():String
        {
            return this._horizontalScrollPolicy;
        }
        
        /**
         * @private
         */
        public function set horizontalScrollPolicy(value:String):void
        {
            if(this._horizontalScrollPolicy == value)
            {
                return;
            }
            this._horizontalScrollPolicy = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
            this.invalidate(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
        }

        /**
         * @private
         */
        protected var actualVerticalScrollStep:Number = 1;

        /**
         * @private
         */
        protected var explicitVerticalScrollStep:Number = NaN;

        /**
         * The number of pixels the scroller can be stepped vertically. Passed
         * to the vertical scroll bar, if it exists, and used for scrolling with
         * the mouse wheel. Touch scrolling is not affected by the step value.
         */
        public function get verticalScrollStep():Number
        {
            return this.actualVerticalScrollStep;
        }

        /**
         * @private
         */
        public function set verticalScrollStep(value:Number):void
        {
            if(this.explicitVerticalScrollStep == value)
            {
                return;
            }
            if(isNaN(value))
            {
                //nope
                Debug.assert("verticalScrollStep cannot be NaN.");
            }
            this.explicitVerticalScrollStep = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
        }

        /**
         * @private
         */
        protected var _targetVerticalScrollPosition:Number;
        
        /**
         * @private
         */
        protected var _verticalScrollPosition:Number = 0;
        
        /**
         * The number of pixels the scroller has been scrolled vertically (on
         * the y-axis).
         */
        public function get verticalScrollPosition():Number
        {
            return this._verticalScrollPosition;
        }
        
        /**
         * @private
         */
        public function set verticalScrollPosition(value:Number):void
        {
            if(this._snapScrollPositionsToPixels)
            {
                value = Math.round(value);
            }
            if(this._verticalScrollPosition == value)
            {
                return;
            }
            if(isNaN(value))
            {
                //there isn't any recovery from this, so stop it early
                Debug.assert("verticalScrollPosition cannot be NaN.");
            }
            this._verticalScrollPosition = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
        }
        
        /**
         * @private
         */
        protected var _maxVerticalScrollPosition:Number = 0;
        
        /**
         * The maximum number of pixels the scroller may be scrolled vertically
         * (on the y-axis). This value is automatically calculated based on the 
         * height of the viewport. The `verticalScrollPosition`
         * property may have a higher value than the maximum due to elastic
         * edges. However, once the user stops interacting with the scroller,
         * it will automatically animate back to the maximum (or minimum, if
         * below 0).
         */
        public function get maxVerticalScrollPosition():Number
        {
            return this._maxVerticalScrollPosition;
        }

        /**
         * @private
         */
        protected var _verticalPageIndex:int = 0;

        /**
         * The index of the vertical page, if snapping is enabled. If snapping
         * is disabled, the index will always be `0`.
         */
        public function get verticalPageIndex():int
        {
            if(this.pendingVerticalPageIndex >= 0)
            {
                return this.pendingVerticalPageIndex;
            }
            return this._verticalPageIndex;
        }

        /**
         * @private
         */
        protected var _verticalPageCount:int = 1;

        /**
         * The number of vertical pages, if snapping is enabled. If snapping
         * is disabled, the page count will always be `1`.
         */
        public function get verticalPageCount():int
        {
            return this._verticalPageCount;
        }
        
        /**
         * @private
         */
        protected var _verticalScrollPolicy:String = SCROLL_POLICY_AUTO;

        [Inspectable(type="String",enumeration="auto,on,off")]
        /**
         * Determines whether the scroller may scroll vertically (on the
         * y-axis) or not.
         *
         * @see #SCROLL_POLICY_AUTO
         * @see #SCROLL_POLICY_ON
         * @see #SCROLL_POLICY_OFF
         */
        public function get verticalScrollPolicy():String
        {
            return this._verticalScrollPolicy;
        }
        
        /**
         * @private
         */
        public function set verticalScrollPolicy(value:String):void
        {
            if(this._verticalScrollPolicy == value)
            {
                return;
            }
            this._verticalScrollPolicy = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
            this.invalidate(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
        }
        
        /**
         * @private
         */
        protected var _clipContent:Boolean = true;
        
        /**
         * If true, the viewport will be clipped to the scroller's bounds. In
         * other words, anything appearing outside the scroller's bounds will
         * not be visible.
         * 
         * To improve performance, turn off clipping and place other display
         * objects over the edges of the scroller to hide the content that
         * bleeds outside of the scroller's bounds.
         */
        public function get clipContent():Boolean
        {
            return this._clipContent;
        }
        
        /**
         * @private
         */
        public function set clipContent(value:Boolean):void
        {
            if(this._clipContent == value)
            {
                return;
            }
            this._clipContent = value;
            this.invalidate(INVALIDATION_FLAG_CLIPPING);
        }
        
        /**
         * @private
         */
        protected var _hasElasticEdges:Boolean = true;
        
        /**
         * Determines if the scrolling can go beyond the edges of the viewport.
         */
        public function get hasElasticEdges():Boolean
        {
            return this._hasElasticEdges;
        }
        
        /**
         * @private
         */
        public function set hasElasticEdges(value:Boolean):void
        {
            this._hasElasticEdges = value;
        }

        /**
         * @private
         */
        protected var _elasticity:Number = 0.33;

        /**
         * If the scroll position goes outside the minimum or maximum bounds,
         * the scrolling will be constrained using this multiplier.
         */
        public function get elasticity():Number
        {
            return this._elasticity;
        }

        /**
         * @private
         */
        public function set elasticity(value:Number):void
        {
            this._elasticity = value;
        }

        /**
         * @private
         */
        protected var _scrollBarDisplayMode:String = SCROLL_BAR_DISPLAY_MODE_FLOAT;

        [Inspectable(type="String",enumeration="float,fixed,none")]
        /**
         * Determines how the scroll bars are displayed.
         *
         * @see #SCROLL_BAR_DISPLAY_MODE_FLOAT
         * @see #SCROLL_BAR_DISPLAY_MODE_FIXED
         * @see #SCROLL_BAR_DISPLAY_MODE_NONE
         */
        public function get scrollBarDisplayMode():String
        {
            return this._scrollBarDisplayMode;
        }

        /**
         * @private
         */
        public function set scrollBarDisplayMode(value:String):void
        {
            if(this._scrollBarDisplayMode == value)
            {
                return;
            }
            this._scrollBarDisplayMode = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _interactionMode:String = INTERACTION_MODE_TOUCH;

        [Inspectable(type="String",enumeration="touch,mouse")]
        /**
         * Determines how the user may interact with the scroller.
         *
         * @see #INTERACTION_MODE_TOUCH
         * @see #INTERACTION_MODE_MOUSE
         */
        public function get interactionMode():String
        {
            return this._interactionMode;
        }

        /**
         * @private
         */
        public function set interactionMode(value:String):void
        {
            if(this._interactionMode == value)
            {
                return;
            }
            this._interactionMode = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var originalBackgroundWidth:Number = NaN;

        /**
         * @private
         */
        protected var originalBackgroundHeight:Number = NaN;

        /**
         * @private
         */
        protected var currentBackgroundSkin:DisplayObject;

        /**
         * @private
         */
        protected var _backgroundSkin:DisplayObject;

        /**
         * The default background to display.
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

            if(this._backgroundSkin && this._backgroundSkin != this._backgroundDisabledSkin)
            {
                this.removeChild(this._backgroundSkin);
            }
            this._backgroundSkin = value;
            if(this._backgroundSkin && this._backgroundSkin.parent != this)
            {
                this._backgroundSkin.visible = false;
                this.addChild(this._backgroundSkin);
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _backgroundDisabledSkin:DisplayObject;

        /**
         * A background to display when the container is disabled.
         */
        public function get backgroundDisabledSkin():DisplayObject
        {
            return this._backgroundDisabledSkin;
        }

        /**
         * @private
         */
        public function set backgroundDisabledSkin(value:DisplayObject):void
        {
            if(this._backgroundDisabledSkin == value)
            {
                return;
            }

            if(this._backgroundDisabledSkin && this._backgroundDisabledSkin != this._backgroundSkin)
            {
                this.removeChild(this._backgroundDisabledSkin);
            }
            this._backgroundDisabledSkin = value;
            if(this._backgroundDisabledSkin && this._backgroundDisabledSkin.parent != this)
            {
                this._backgroundDisabledSkin.visible = false;
                this.addChild(this._backgroundDisabledSkin);
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * Quickly sets all padding properties to the same value. The
         * `padding` getter always returns the value of
         * `paddingTop`, but the other padding values may be
         * different.
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
         * The minimum space, in pixels, between the container's top edge and the
         * container's content.
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
         * The minimum space, in pixels, between the container's right edge and
         * the container's content.
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
         * The minimum space, in pixels, between the container's bottom edge and
         * the container's content.
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
         * The minimum space, in pixels, between the container's left edge and the
         * container's content.
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
        protected var _horizontalScrollBarHideTween:Tween;

        /**
         * @private
         */
        protected var _verticalScrollBarHideTween:Tween;

        /**
         * @private
         */
        protected var _hideScrollBarAnimationDuration:Number = 0.2;

        /**
         * The duration, in seconds, of the animation when a scroll bar fades
         * out.
         */
        public function get hideScrollBarAnimationDuration():Number
        {
            return this._hideScrollBarAnimationDuration;
        }

        /**
         * @private
         */
        public function set hideScrollBarAnimationDuration(value:Number):void
        {
            this._hideScrollBarAnimationDuration = value;
        }

        /**
         * @private
         */
        protected var _hideScrollBarAnimationEase:Object = Transitions.EASE_OUT;

        /**
         * The easing function used for hiding the scroll bars, if applicable.
         */
        public function get hideScrollBarAnimationEase():Object
        {
            return this._hideScrollBarAnimationEase;
        }

        /**
         * @private
         */
        public function set hideScrollBarAnimationEase(value:Object):void
        {
            this._hideScrollBarAnimationEase = value;
        }

        /**
         * @private
         */
        protected var _elasticSnapDuration:Number = 0.24;

        /**
         * The duration, in seconds, of the animation when a the scroller snaps
         * back to the minimum or maximum position after going out of bounds.
         */
        public function get elasticSnapDuration():Number
        {
            return this._elasticSnapDuration;
        }

        /**
         * @private
         */
        public function set elasticSnapDuration(value:Number):void
        {
            this._elasticSnapDuration = value;
        }

        /**
         * @private
         */
        protected var _pageThrowDuration:Number = 0.5;

        /**
         * The duration, in seconds, of the animation when the scroller is
         * thrown to a page.
         */
        public function get pageThrowDuration():Number
        {
            return this._pageThrowDuration;
        }

        /**
         * @private
         */
        public function set pageThrowDuration(value:Number):void
        {
            this._pageThrowDuration = value;
        }

        /**
         * @private
         */
        protected var _mouseWheelScrollDuration:Number = 0.35;

        /**
         * The duration, in seconds, of the animation when the mouse wheel
         * initiates a scroll action.
         */
        public function get mouseWheelScrollDuration():Number
        {
            return this._mouseWheelScrollDuration;
        }

        /**
         * @private
         */
        public function set mouseWheelScrollDuration(value:Number):void
        {
            this._mouseWheelScrollDuration = value;
        }

        /**
         * @private
         */
        protected var _throwEase:Object = Transitions.EASE_OUT;

        /**
         * The easing function used for "throw" animations.
         */
        public function get throwEase():Object
        {
            return this._throwEase;
        }

        /**
         * @private
         */
        public function set throwEase(value:Object):void
        {
            this._throwEase = value;
        }

        /**
         * @private
         */
        protected var _snapScrollPositionsToPixels:Boolean = false;

        /**
         * If enabled, the scroll position will always be adjusted to whole
         * pixels.
         */
        public function get snapScrollPositionsToPixels():Boolean
        {
            return this._snapScrollPositionsToPixels;
        }

        /**
         * @private
         */
        public function set snapScrollPositionsToPixels(value:Boolean):void
        {
            if(this._snapScrollPositionsToPixels == value)
            {
                return;
            }
            this._snapScrollPositionsToPixels = value;
            if(this._snapScrollPositionsToPixels)
            {
                this.horizontalScrollPosition = Math.round(this._horizontalScrollPosition);
                this.verticalScrollPosition = Math.round(this._verticalScrollPosition);
            }
        }

        /**
         * @private
         */
        protected var _horizontalScrollBarIsScrolling:Boolean = false;

        /**
         * @private
         */
        protected var _verticalScrollBarIsScrolling:Boolean = false;

        /**
         * Determines if the scroller is currently scrolling with touch or with
         * animation.
         */
        public function get isScrolling():Boolean
        {
            return this._touchPointID >= 0 || this._horizontalScrollBarIsScrolling || this._verticalScrollBarIsScrolling ||
                this._horizontalAutoScrollTween || this._verticalAutoScrollTween;
        }

        /**
         * @private
         */
        protected var _isScrollingStopped:Boolean = false;

        /**
         * @private
         */
        protected var _scrollerProperties:Dictionary.<String, Object>;

        /**
         * DEPRECATED: A set of key/value pairs to be passed down to the
         * container's scroller sub-component. As of 1.1, the "scroller" is no
         * longer a sub-component, but the component itself.
         *
         * **DEPRECATION WARNING:** This property is deprecated
         * starting with Feathers 1.1. It will be removed in a future version of
         * Feathers according to the standard
         * [Feathers deprecation policy](http://wiki.starling-framework.org/feathers/deprecation-policy).
         * The properties of `Scroller` are now exposed individually.
         */
        public function get scrollerProperties():Dictionary.<String, Object>
        {
            if(!this._scrollerProperties)
            {
                this._scrollerProperties = new Dictionary.<String, Object>;
            }
            return this._scrollerProperties;
        }

        /**
         * @private
         */
        public function set scrollerProperties(value:Dictionary.<String, Object>):void
        {
            if(this._scrollerProperties == value)
            {
                return;
            }
            this._scrollerProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The pending horizontal scroll position to scroll to after validating.
         * A value of `NaN` means that the scroller won't scroll to a
         * horizontal position after validating.
         */
        protected var pendingHorizontalScrollPosition:Number = NaN;

        /**
         * The pending vertical scroll position to scroll to after validating.
         * A value of `NaN` means that the scroller won't scroll to a
         * vertical position after validating.
         */
        protected var pendingVerticalScrollPosition:Number = NaN;

        /**
         * The pending horizontal page index to scroll to after validating. A
         * value of `-1` means that the scroller won't scroll to a
         * horizontal page after validating.
         */
        protected var pendingHorizontalPageIndex:int = -1;

        /**
         * The pending vertical page index to scroll to after validating. A
         * value of `-1` means that the scroller won't scroll to a
         * vertical page after validating.
         */
        protected var pendingVerticalPageIndex:int = -1;

        /**
         * The duration of the pending scroll action.
         */
        protected var pendingScrollDuration:Number;

        /**
         * @private
         */
        override public function dispose():void
        {
            //Loom2D.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, nativeStage_mouseWheelHandler);
            //Loom2D.current.nativeStage.removeEventListener("orientationChange", nativeStage_orientationChangeHandler);
            super.dispose();
        }
        
        /**
         * If the user is scrolling with touch or if the scrolling is animated,
         * calling stopScrolling() will cause the scroller to ignore the drag
         * and stop animations.
         */
        public function stopScrolling():void
        {
            if(this._horizontalAutoScrollTween)
            {
                Loom2D.juggler.remove(this._horizontalAutoScrollTween);
                Tween.toPool(this._horizontalAutoScrollTween);
                this._horizontalAutoScrollTween = null;
            }
            if(this._verticalAutoScrollTween)
            {
                Loom2D.juggler.remove(this._verticalAutoScrollTween);
                Tween.toPool(this._verticalAutoScrollTween);
                this._verticalAutoScrollTween = null;
            }
            this._isScrollingStopped = true;
            this._velocityX = 0;
            this._velocityY = 0;
            this._previousVelocityX.length = 0;
            this._previousVelocityY.length = 0;
            this.hideHorizontalScrollBar();
            this.hideVerticalScrollBar();
        }

        /**
         * After the next validation, scrolls to a specific position. May scroll
         * in only one direction by passing in a value of `NaN` for
         * either scroll position. If the `animationDuration` argument
         * is greater than zero, the scroll will animate. The duration is in
         * seconds.
         */
        public function scrollToPosition(horizontalScrollPosition:Number, verticalScrollPosition:Number, animationDuration:Number = 0):void
        {
            this.pendingHorizontalPageIndex = -1;
            this.pendingVerticalPageIndex = -1;
            if(this.pendingHorizontalScrollPosition == horizontalScrollPosition &&
                this.pendingVerticalScrollPosition == verticalScrollPosition &&
                this.pendingScrollDuration == animationDuration)
            {
                return;
            }
            this.pendingHorizontalScrollPosition = horizontalScrollPosition;
            this.pendingVerticalScrollPosition = verticalScrollPosition;
            this.pendingScrollDuration = animationDuration;
            this.invalidate(INVALIDATION_FLAG_PENDING_SCROLL);
        }

        /**
         * After the next validation, scrolls to a specific page index. May scroll
         * in only one direction by passing in a value of `-1` for
         * either page index. If the `animationDuration` argument
         * is greater than zero, the scroll will animate. The duration is in
         * seconds.
         */
        public function scrollToPageIndex(horizontalPageIndex:int, verticalPageIndex:int, animationDuration:Number = 0):void
        {
            this.pendingHorizontalScrollPosition = NaN;
            this.pendingVerticalScrollPosition = NaN;
            const horizontalPageHasChanged:Boolean = (this.pendingHorizontalPageIndex >= 0 && this.pendingHorizontalPageIndex != horizontalPageIndex) ||
                (this.pendingHorizontalPageIndex < 0 && this._horizontalPageIndex != horizontalPageIndex);
            const verticalPageHasChanged:Boolean = (this.pendingVerticalPageIndex >= 0 && this.pendingVerticalPageIndex != verticalPageIndex) ||
                (this.pendingVerticalPageIndex < 0 && this._verticalPageIndex != verticalPageIndex);
            const durationHasChanged:Boolean = (this.pendingHorizontalPageIndex >= 0 || this.pendingVerticalPageIndex >= 0) && this.pendingScrollDuration == animationDuration;
            if(!horizontalPageHasChanged && !verticalPageHasChanged &&
                !durationHasChanged)
            {
                return;
            }
            this.pendingHorizontalPageIndex = horizontalPageIndex;
            this.pendingVerticalPageIndex = verticalPageIndex;
            this.pendingScrollDuration = animationDuration;
            this.invalidate(INVALIDATION_FLAG_PENDING_SCROLL);
        }

        /**
         * @private
         */
        override public function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject
        {
            //save localX and localY because localPoint could change after the
            //call to super.hitTest().
            const localX:Number = localPoint.x;
            const localY:Number = localPoint.y;
            //first check the children for touches
            var result:DisplayObject = super.hitTest(localPoint, forTouch);
            if(!result)
            {
                //we want to register touches in our hitArea as a last resort
                if(forTouch && (!this.visible || !this.touchable))
                {
                    return null;
                }
                return this._hitArea.contains(localX, localY) ? this : null;
            }
            return result;
        }
        
        /**
         * @private
         */
        override protected function draw():void
        {
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const scrollInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SCROLL);
            const clippingInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_CLIPPING);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const scrollBarInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SCROLL_BAR_RENDERER);
            const pendingScrollInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_PENDING_SCROLL);

            if(scrollBarInvalid)
            {
                this.createScrollBars();
            }

            if(sizeInvalid || stylesInvalid || stateInvalid)
            {
                this.refreshBackgroundSkin();
            }

            if(scrollBarInvalid || stylesInvalid)
            {
                this.refreshScrollBarStyles();
                this.refreshInteractionModeEvents();
            }

            if(stateInvalid)
            {
                this.refreshEnabled();
            }

            if(this.horizontalScrollBar)
            {
                this.horizontalScrollBar.validate();
            }
            if(this.verticalScrollBar)
            {
                this.verticalScrollBar.validate();
            }

            var loopCount:int = 0;
            do
            {
                this._hasViewPortBoundsChanged = false;
                //even if fixed, we need to measure without them first
                if(scrollInvalid || sizeInvalid || stylesInvalid || scrollBarInvalid)
                {
                    this.calculateViewPortOffsets(true);
                    this.refreshViewPortBoundsWithoutFixedScrollBars();
                    this.calculateViewPortOffsets(false);
                }

                sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

                if(scrollInvalid || sizeInvalid || stylesInvalid || scrollBarInvalid)
                {
                    this.refreshViewPortBoundsWithFixedScrollBars();
                }
                loopCount++;
                if(loopCount >= 10)
                {
                    //if it still fails after ten tries, we've probably entered
                    //an infinite loop due to rounding errors or something
                    break;
                }
            }
            while(this._hasViewPortBoundsChanged)
            this._lastViewPortWidth = viewPort.width;
            this._lastViewPortHeight = viewPort.height;

            this.showOrHideScrollBars();

            if(scrollInvalid || sizeInvalid || stylesInvalid || scrollBarInvalid)
            {
                this.layoutChildren();
            }

            if(scrollInvalid || sizeInvalid || stylesInvalid || scrollBarInvalid)
            {
                this.refreshScrollValues(scrollInvalid);
                this.refreshScrollBarValues();
            }
            
            if(scrollInvalid || sizeInvalid || stylesInvalid || scrollBarInvalid || clippingInvalid)
            {
                this.refreshClipRect();
            }

            if(pendingScrollInvalid)
            {
                this.handlePendingScroll();
            }
        }

        /**
         * Automatically determines the ideal width and height of the control,
         * if required. If an explicit width or height is provided, that value
         * is used instead.
         */
        protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }

            var newWidth:Number = this.explicitWidth;
            var newHeight:Number = this.explicitHeight;
            if(needsWidth)
            {
                newWidth = this._viewPort.width + this._rightViewPortOffset + this._leftViewPortOffset;
                if(!isNaN(this.originalBackgroundWidth))
                {
                    newWidth = Math.max(newWidth, this.originalBackgroundWidth);
                }
            }
            if(needsHeight)
            {
                newHeight = this._viewPort.height + this._bottomViewPortOffset + this._topViewPortOffset;
                if(!isNaN(this.originalBackgroundHeight))
                {
                    newHeight = Math.max(newHeight, this.originalBackgroundHeight);
                }
            }
            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * Creates the scroll bars from the provided factories.
         */
        protected function createScrollBars():void
        {
            if(this.horizontalScrollBar)
            {
                this.horizontalScrollBar.removeEventListener(FeathersEventType.BEGIN_INTERACTION, horizontalScrollBar_beginInteractionHandler);
                this.horizontalScrollBar.removeEventListener(FeathersEventType.END_INTERACTION, horizontalScrollBar_endInteractionHandler);
                this.horizontalScrollBar.removeEventListener(Event.CHANGE, horizontalScrollBar_changeHandler);
                this.removeChild(DisplayObject(this.horizontalScrollBar), true);
                this.horizontalScrollBar = null;
            }
            if(this.verticalScrollBar)
            {
                this.verticalScrollBar.removeEventListener(FeathersEventType.BEGIN_INTERACTION, verticalScrollBar_beginInteractionHandler);
                this.verticalScrollBar.removeEventListener(FeathersEventType.END_INTERACTION, verticalScrollBar_endInteractionHandler);
                this.verticalScrollBar.removeEventListener(Event.CHANGE, verticalScrollBar_changeHandler);
                this.removeChild(DisplayObject(this.verticalScrollBar), true);
                this.verticalScrollBar = null;
            }

            if(this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_NONE &&
                this._horizontalScrollPolicy != SCROLL_POLICY_OFF && this._horizontalScrollBarFactory != null)
            {
                this.horizontalScrollBar = IScrollBar(this._horizontalScrollBarFactory.call());
                const horizontalScrollBarName:String = this._customHorizontalScrollBarName != null ? this._customHorizontalScrollBarName : this.horizontalScrollBarName;
                this.horizontalScrollBar.nameList.add(horizontalScrollBarName);
                this.horizontalScrollBar.addEventListener(Event.CHANGE, horizontalScrollBar_changeHandler);
                this.horizontalScrollBar.addEventListener(FeathersEventType.BEGIN_INTERACTION, horizontalScrollBar_beginInteractionHandler);
                this.horizontalScrollBar.addEventListener(FeathersEventType.END_INTERACTION, horizontalScrollBar_endInteractionHandler);
                this.addChild(DisplayObject(this.horizontalScrollBar));
            }
            if(this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_NONE &&
                this._verticalScrollPolicy != SCROLL_POLICY_OFF && this._verticalScrollBarFactory != null)
            {
                this.verticalScrollBar = IScrollBar(this._verticalScrollBarFactory.call());
                const verticalScrollBarName:String = this._customVerticalScrollBarName != null ? this._customVerticalScrollBarName : this.verticalScrollBarName;
                this.verticalScrollBar.nameList.add(verticalScrollBarName);
                this.verticalScrollBar.addEventListener(Event.CHANGE, verticalScrollBar_changeHandler);
                this.verticalScrollBar.addEventListener(FeathersEventType.BEGIN_INTERACTION, verticalScrollBar_beginInteractionHandler);
                this.verticalScrollBar.addEventListener(FeathersEventType.END_INTERACTION, verticalScrollBar_endInteractionHandler);
                this.addChild(DisplayObject(this.verticalScrollBar));
            }
        }

        /**
         * Choose the appropriate background skin based on the control's current
         * state.
         */
        protected function refreshBackgroundSkin():void
        {
            this.currentBackgroundSkin = this._backgroundSkin;
            if(!this._isEnabled && this._backgroundDisabledSkin)
            {
                if(this._backgroundSkin)
                {
                    this._backgroundSkin.visible = false;
                }
                this.currentBackgroundSkin = this._backgroundDisabledSkin;
            }
            else if(this._backgroundDisabledSkin)
            {
                this._backgroundDisabledSkin.visible = false;
            }
            if(this.currentBackgroundSkin)
            {
                //force it to the bottom
                this.setChildIndex(this.currentBackgroundSkin, 0);
                this.currentBackgroundSkin.visible = true;

                if(isNaN(this.originalBackgroundWidth))
                {
                    this.originalBackgroundWidth = this.currentBackgroundSkin.width;
                }
                if(isNaN(this.originalBackgroundHeight))
                {
                    this.originalBackgroundHeight = this.currentBackgroundSkin.height;
                }
            }
        }

        /**
         * @private
         */
        protected function refreshScrollBarStyles():void
        {
            if(this.horizontalScrollBar)
            {
                Dictionary.mapToObject(this._horizontalScrollBarProperties, this.horizontalScrollBar);
                if(this._horizontalScrollBarHideTween)
                {
                    Loom2D.juggler.remove(this._horizontalScrollBarHideTween);
                    Tween.toPool(this._horizontalScrollBarHideTween);
                    this._horizontalScrollBarHideTween = null;
                }
                this.horizontalScrollBar.alpha = this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FLOAT ? 0 : 1;
                this.horizontalScrollBar.touchable = this._interactionMode == INTERACTION_MODE_MOUSE;
            }
            if(this.verticalScrollBar)
            {
                Dictionary.mapToObject(this._verticalScrollBarProperties, this.verticalScrollBar);
                if(this._verticalScrollBarHideTween)
                {
                    Loom2D.juggler.remove(this._verticalScrollBarHideTween);
                    Tween.toPool(this._verticalScrollBarHideTween);
                    this._verticalScrollBarHideTween = null;
                }
                this.verticalScrollBar.alpha = this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FLOAT ? 0 : 1;
                this.verticalScrollBar.touchable = this._interactionMode == INTERACTION_MODE_MOUSE;
            }
        }

        /**
         * @private
         */
        protected function refreshEnabled():void
        {
            if(this._viewPort)
            {
                this._viewPort.isEnabled = this._isEnabled;
            }
            if(this.horizontalScrollBar)
            {
                this.horizontalScrollBar.isEnabled = this._isEnabled;
            }
            if(this.verticalScrollBar)
            {
                this.verticalScrollBar.isEnabled = this._isEnabled;
            }
        }

        /**
         * @private
         */
        protected function refreshViewPortBoundsWithoutFixedScrollBars():void
        {
            var horizontalWidthOffset:Number = this._leftViewPortOffset + this._rightViewPortOffset;
            var verticalHeightOffset:Number = this._topViewPortOffset + this._bottomViewPortOffset;

            //if scroll bars are fixed, we're going to include the offsets even
            //if they may not be needed in the final pass. if not fixed, the
            //view port fills the entire bounds.
            this._viewPort.visibleWidth = this.explicitWidth - horizontalWidthOffset;
            this._viewPort.visibleHeight = this.explicitHeight - verticalHeightOffset;
            this._viewPort.minVisibleWidth = Math.max(0, this._minWidth - horizontalWidthOffset);
            this._viewPort.maxVisibleWidth = this._maxWidth - horizontalWidthOffset;
            this._viewPort.minVisibleHeight = Math.max(0, this._minHeight - verticalHeightOffset);
            this._viewPort.maxVisibleHeight = this._maxHeight - verticalHeightOffset;
            this._viewPort.horizontalScrollPosition = this._horizontalScrollPosition;
            this._viewPort.verticalScrollPosition = this._verticalScrollPosition;

            const oldIgnoreViewPortResizing:Boolean = this.ignoreViewPortResizing;
            if(this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FIXED)
            {
                this.ignoreViewPortResizing = true;
            }
            this._viewPort.validate();
            this.ignoreViewPortResizing = oldIgnoreViewPortResizing;
        }

        /**
         * @private
         */
        protected function refreshViewPortBoundsWithFixedScrollBars():void
        {
            this._viewPort.visibleWidth = this.actualWidth - (this._leftViewPortOffset + this._rightViewPortOffset);
            this._viewPort.visibleHeight = this.actualHeight - (this._topViewPortOffset + this._bottomViewPortOffset);
            this._viewPort.validate();
        }

        /**
         * @private
         */
        protected function refreshScrollValues(isScrollInvalid:Boolean):void
        {
            if(isNaN(this.explicitHorizontalScrollStep))
            {
                if(this._viewPort)
                {
                    this.actualHorizontalScrollStep = this._viewPort.horizontalScrollStep;
                }
                else
                {
                    this.actualHorizontalScrollStep = 1;
                }
            }
            else
            {
                this.actualHorizontalScrollStep = this.explicitHorizontalScrollStep;
            }
            if(isNaN(this.explicitVerticalScrollStep))
            {
                if(this._viewPort)
                {
                    this.actualVerticalScrollStep = this._viewPort.verticalScrollStep;
                }
                else
                {
                    this.actualVerticalScrollStep = 1;
                }
            }
            else
            {
                this.actualVerticalScrollStep = this.explicitVerticalScrollStep;
            }

            const pageWidth:Number = this.actualWidth - (this._leftViewPortOffset + this._rightViewPortOffset);
            const pageHeight:Number = this.actualHeight - (this._topViewPortOffset + this._bottomViewPortOffset);
            const oldMaxHSP:Number = this._maxHorizontalScrollPosition;
            const oldMaxVSP:Number = this._maxVerticalScrollPosition;
            if(this._viewPort)
            {
                this._maxHorizontalScrollPosition = Math.max(0, this._viewPort.width - pageWidth);
                this._maxVerticalScrollPosition = Math.max(0, this._viewPort.height - pageHeight);
                if(this._snapScrollPositionsToPixels)
                {
                    this._maxHorizontalScrollPosition = Math.round(this._maxHorizontalScrollPosition);
                    this._maxVerticalScrollPosition = Math.round(this._maxVerticalScrollPosition);
                }
            }
            else
            {
                this._maxHorizontalScrollPosition = 0;
                this._maxVerticalScrollPosition = 0;
            }
            if(this._snapToPages)
            {
                this._horizontalPageCount = Math.ceil(this._maxHorizontalScrollPosition / pageWidth) + 1;
                this._verticalPageCount = Math.ceil(this._maxVerticalScrollPosition / pageHeight) + 1;
            }
            else
            {
                this._horizontalPageCount = 1;
                this._verticalPageCount = 1;
            }

            const maximumPositionsChanged:Boolean = this._maxHorizontalScrollPosition != oldMaxHSP || this._maxVerticalScrollPosition != oldMaxVSP;
            if(maximumPositionsChanged)
            {
                if(this._touchPointID < 0 && !this._horizontalAutoScrollTween)
                {
                    if(this._snapToPages)
                    {
                        this._horizontalScrollPosition = Math.max(0, FeathersMath.roundToNearest(this._horizontalScrollPosition, pageWidth));
                    }
                    this.horizontalScrollPosition = FeathersMath.clamp(this._horizontalScrollPosition, 0, this._maxHorizontalScrollPosition);
                }
                if(this._touchPointID < 0 && !this._verticalAutoScrollTween)
                {
                    if(this._snapToPages)
                    {
                        this._verticalScrollPosition = Math.max(0, FeathersMath.roundToNearest(this._verticalScrollPosition, pageHeight));
                    }
                    this.verticalScrollPosition = FeathersMath.clamp(this._verticalScrollPosition, 0, this._maxVerticalScrollPosition);
                }
            }

            if(this._snapToPages)
            {
                if(isScrollInvalid && !this._isDraggingHorizontally && !this._horizontalAutoScrollTween && this.pendingHorizontalPageIndex < 0)
                {
                    if(this._horizontalScrollPosition == this._maxHorizontalScrollPosition)
                    {
                        this._horizontalPageIndex = this._horizontalPageCount - 1;
                    }
                    else
                    {
                        this._horizontalPageIndex = Math.max(0, Math.floor(this._horizontalScrollPosition / pageWidth));
                    }
                }
                if(isScrollInvalid && !this._isDraggingVertically && !this._verticalAutoScrollTween && this.pendingVerticalPageIndex < 0)
                {
                    if(this._verticalScrollPosition == this._maxVerticalScrollPosition)
                    {
                        this._verticalPageIndex = this._verticalPageCount - 1;
                    }
                    else
                    {
                        this._verticalPageIndex = Math.max(0, Math.floor(this._verticalScrollPosition / pageHeight));
                    }
                }
            }
            else
            {
                this._horizontalPageIndex = this._verticalPageIndex = 0;
            }

            if(maximumPositionsChanged)
            {
                if(this._horizontalAutoScrollTween && this._targetHorizontalScrollPosition > this._maxHorizontalScrollPosition &&
                    oldMaxHSP > this._maxHorizontalScrollPosition)
                {
                    this._targetHorizontalScrollPosition -= (oldMaxHSP - this._maxHorizontalScrollPosition);
                    this.throwTo(this._targetHorizontalScrollPosition, NaN, this._horizontalAutoScrollTween.totalTime - this._horizontalAutoScrollTween.currentTime);
                }
                if(this._verticalAutoScrollTween && this._targetVerticalScrollPosition > this._maxVerticalScrollPosition &&
                    oldMaxVSP > this._maxVerticalScrollPosition)
                {
                    this._targetVerticalScrollPosition -= (oldMaxVSP - this._maxVerticalScrollPosition);
                    this.throwTo(NaN, this._targetVerticalScrollPosition, this._verticalAutoScrollTween.totalTime - this._verticalAutoScrollTween.currentTime);
                }
            }
            if(maximumPositionsChanged || isScrollInvalid)
            {
                this.dispatchEventWith(Event.SCROLL);
            }
        }

        /**
         * @private
         */
        protected function refreshScrollBarValues():void
        {
            if(this.horizontalScrollBar)
            {
                const pageWidth:Number = this.actualWidth - (this._leftViewPortOffset + this._rightViewPortOffset);
                this.horizontalScrollBar.minimum = 0;
                this.horizontalScrollBar.maximum = this._maxHorizontalScrollPosition;
                this.horizontalScrollBar.value = this._horizontalScrollPosition;
                this.horizontalScrollBar.page = this._maxHorizontalScrollPosition * pageWidth / this._viewPort.width;
                this.horizontalScrollBar.step = this.actualHorizontalScrollStep;
            }

            if(this.verticalScrollBar)
            {
                const pageHeight:Number = this.actualHeight - (this._topViewPortOffset + this._bottomViewPortOffset);
                this.verticalScrollBar.minimum = 0;
                this.verticalScrollBar.maximum = this._maxVerticalScrollPosition;
                this.verticalScrollBar.value = this._verticalScrollPosition;
                this.verticalScrollBar.page = this._maxVerticalScrollPosition * pageHeight / this._viewPort.height;
                this.verticalScrollBar.step = this.actualVerticalScrollStep;
            }
        }

        /**
         * @private
         */
        protected function showOrHideScrollBars():void
        {
            const isFixed:Boolean = this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FIXED;
            if(this.horizontalScrollBar)
            {
                this.horizontalScrollBar.visible = !isFixed || this._hasHorizontalScrollBar;
                this.setChildIndex(DisplayObject(this.horizontalScrollBar), this.numChildren - 1);
            }
            if(this.verticalScrollBar)
            {
                this.verticalScrollBar.visible = !isFixed || this._hasVerticalScrollBar;
                this.setChildIndex(DisplayObject(this.verticalScrollBar), this.numChildren - 1);
            }
        }

        /**
         * @private
         */
        protected function calculateViewPortOffsets(forceScrollBars:Boolean = false):void
        {
            //in fixed mode, if we determine that scrolling is required, we
            //remember the offsets for later. if scrolling is not needed, then
            //we will ignore the offsets from here forward
            this._topViewPortOffset = this._paddingTop;
            this._rightViewPortOffset = this._paddingRight;
            this._bottomViewPortOffset = this._paddingBottom;
            this._leftViewPortOffset = this._paddingLeft;
            if(this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FIXED)
            {
                if(this.horizontalScrollBar)
                {
                    if(forceScrollBars || this._horizontalScrollPolicy == SCROLL_POLICY_ON ||
                        ((this._viewPort.width > this.explicitWidth || this._viewPort.width > this._maxWidth) &&
                            this._horizontalScrollPolicy != SCROLL_POLICY_OFF))
                    {
                        this._hasHorizontalScrollBar = true;
                        this._bottomViewPortOffset += this.horizontalScrollBar.height;
                    }
                    else
                    {
                        this._hasHorizontalScrollBar = false;
                    }
                }
                else
                {
                    this._hasHorizontalScrollBar = false;
                }
                if(this.verticalScrollBar)
                {
                    if(forceScrollBars || this._verticalScrollPolicy == SCROLL_POLICY_ON ||
                        ((this._viewPort.height > this.explicitHeight || this._viewPort.height > this._maxHeight) &&
                            this._verticalScrollPolicy != SCROLL_POLICY_OFF))
                    {
                        this._hasVerticalScrollBar = true;
                        this._rightViewPortOffset += this.verticalScrollBar.width;
                    }
                    else
                    {
                        this._hasVerticalScrollBar = false;
                    }
                }
                else
                {
                    this._hasVerticalScrollBar = false;
                }
            }
        }

        /**
         * @private
         */
        protected function refreshInteractionModeEvents():void
        {
            if(this._interactionMode == INTERACTION_MODE_TOUCH)
            {
                this.addEventListener(TouchEvent.TOUCH, touchHandler);
                if(!this._touchBlocker)
                {
                    this._touchBlocker = new Quad(100, 100, 0xff00ff);
                    this._touchBlocker.alpha = 0;
                    this._touchBlocker.visible = false;
                    this.addChild(this._touchBlocker);
                }
            }
            else
            {
                this.removeEventListener(TouchEvent.TOUCH, touchHandler);
                if(this._touchBlocker)
                {
                    this.removeChild(this._touchBlocker, true);
                    this._touchBlocker = null;
                }
            }

            if(this._interactionMode == INTERACTION_MODE_MOUSE && this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FLOAT)
            {
                if(this.horizontalScrollBar)
                {
                    this.horizontalScrollBar.addEventListener(TouchEvent.TOUCH, horizontalScrollBar_touchHandler);
                }
                if(this.verticalScrollBar)
                {
                    this.verticalScrollBar.addEventListener(TouchEvent.TOUCH, verticalScrollBar_touchHandler);
                }
            }
            else
            {
                if(this.horizontalScrollBar)
                {
                    this.horizontalScrollBar.removeEventListener(TouchEvent.TOUCH, horizontalScrollBar_touchHandler);
                }
                if(this.verticalScrollBar)
                {
                    this.verticalScrollBar.removeEventListener(TouchEvent.TOUCH, verticalScrollBar_touchHandler);
                }
            }
        }

        /**
         * Positions and sizes children based on the actual width and height
         * values.
         */
        protected function layoutChildren():void
        {
            if(this.currentBackgroundSkin)
            {
                this.currentBackgroundSkin.width = this.actualWidth;
                this.currentBackgroundSkin.height = this.actualHeight;
            }

            if(this.horizontalScrollBar)
            {
                this.horizontalScrollBar.validate();
            }
            if(this.verticalScrollBar)
            {
                this.verticalScrollBar.validate();
            }
            if(this._touchBlocker)
            {
                this._touchBlocker.width = this.actualWidth;
                this._touchBlocker.height = this.actualHeight;
            }

            this._viewPort.x = this._leftViewPortOffset - this._horizontalScrollPosition;
            this._viewPort.y = this._topViewPortOffset - this._verticalScrollPosition;

            if(this.horizontalScrollBar)
            {
                this.horizontalScrollBar.x = this._leftViewPortOffset;
                this.horizontalScrollBar.y = this._topViewPortOffset + this._viewPort.visibleHeight;
                if(this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_FIXED)
                {
                    this.horizontalScrollBar.y -= this.horizontalScrollBar.height;
                }
                this.horizontalScrollBar.width = this._viewPort.visibleWidth;
                if(this._hasVerticalScrollBar && this.verticalScrollBar)
                {
                    this.horizontalScrollBar.width -= this.verticalScrollBar.width;
                }
            }

            if(this.verticalScrollBar)
            {
                this.verticalScrollBar.x = this._leftViewPortOffset + this._viewPort.visibleWidth;
                if(this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_FIXED)
                {
                    this.verticalScrollBar.x -= this.verticalScrollBar.width;
                }
                this.verticalScrollBar.y = this._topViewPortOffset;
                this.verticalScrollBar.height = this._viewPort.visibleHeight;
                if(this._hasHorizontalScrollBar && this.horizontalScrollBar)
                {
                    this.verticalScrollBar.height -= this.horizontalScrollBar.height;
                }
            }
        }
        
        /**
         * @private
         */
        protected function refreshClipRect():void
        {
            if(this._clipContent &&
                ((this._interactionMode == INTERACTION_MODE_TOUCH && this._hasElasticEdges) ||
                    this._maxHorizontalScrollPosition > 0 || this._maxVerticalScrollPosition > 0))
            {
                if(!this._viewPort.clipRect)
                {
                    this._viewPort.clipRect = new Rectangle();
                }
                
                const clipRect:Rectangle = this._viewPort.clipRect;
                clipRect.x = this._horizontalScrollPosition;
                clipRect.y = this._verticalScrollPosition;
                clipRect.width = this.actualWidth - this._leftViewPortOffset - this._rightViewPortOffset;
                clipRect.height = this.actualHeight - this._topViewPortOffset - this._bottomViewPortOffset;
                this._viewPort.clipRect = clipRect;
            }
            else
            {
                this._viewPort.clipRect = null;
            }
        }
        
        /**
         * @private
         */
        protected function updateHorizontalScrollFromTouchPosition(touchX:Number):void
        {
            const offset:Number = this._startTouchX - touchX;
            var position:Number = this._startHorizontalScrollPosition + offset;
            if(position < 0)
            {
                if(this._hasElasticEdges)
                {
                    position *= this._elasticity;
                }
                else
                {
                    position = 0;
                }
            }
            else if(position > this._maxHorizontalScrollPosition)
            {
                if(this._hasElasticEdges)
                {
                    position -= (position - this._maxHorizontalScrollPosition) * (1 - this._elasticity);
                }
                else
                {
                    position = this._maxHorizontalScrollPosition;
                }
            }
            
            this.horizontalScrollPosition = position;
        }
        
        /**
         * @private
         */
        protected function updateVerticalScrollFromTouchPosition(touchY:Number):void
        {
            const offset:Number = this._startTouchY - touchY;
            var position:Number = this._startVerticalScrollPosition + offset;
            if(position < 0)
            {
                if(this._hasElasticEdges)
                {
                    position *= this._elasticity;
                }
                else
                {
                    position = 0;
                }
            }
            else if(position > this._maxVerticalScrollPosition)
            {
                if(this._hasElasticEdges)
                {
                    position -= (position - this._maxVerticalScrollPosition) * (1 - this._elasticity);
                }
                else
                {
                    position = this._maxVerticalScrollPosition;
                }
            }
            
            this.verticalScrollPosition = position;
        }

        /**
         * Immediately throws the scroller to the specified position, with
         * optional animation. If you want to throw in only one direction, pass
         * in `NaN` for the value that you do not want to change. The
         * scroller should be validated before throwing.
         *
         * @see #scrollToPosition()
         */
        protected function throwTo(targetHorizontalScrollPosition:Number = NaN, targetVerticalScrollPosition:Number = NaN, duration:Number = 0.5):void
        {
            if(!isNaN(targetHorizontalScrollPosition))
            {
                if(this._horizontalAutoScrollTween)
                {
                    Loom2D.juggler.remove(this._horizontalAutoScrollTween);
                    Tween.toPool(this._horizontalAutoScrollTween);
                    this._horizontalAutoScrollTween = null;
                }
                if(this._horizontalScrollPosition != targetHorizontalScrollPosition)
                {
                    this._targetHorizontalScrollPosition = targetHorizontalScrollPosition;
                    this._horizontalAutoScrollTween = Tween.fromPool(this, duration, this._throwEase);
                    this._horizontalAutoScrollTween.animate("horizontalScrollPosition", targetHorizontalScrollPosition);
                    this._horizontalAutoScrollTween.onComplete = horizontalAutoScrollTween_onComplete;
                    Loom2D.juggler.add(this._horizontalAutoScrollTween);
                }
                else
                {
                    this.finishScrollingHorizontally();
                }
            }

            if(!isNaN(targetVerticalScrollPosition))
            {
                if(this._verticalAutoScrollTween)
                {
                    Loom2D.juggler.remove(this._verticalAutoScrollTween);
                    Tween.toPool(this._verticalAutoScrollTween);
                    this._verticalAutoScrollTween = null;
                }
                if(this._verticalScrollPosition != targetVerticalScrollPosition)
                {
                    this._targetVerticalScrollPosition = targetVerticalScrollPosition;
                    this._verticalAutoScrollTween = Tween.fromPool(this, duration, this._throwEase);
                    this._verticalAutoScrollTween.animate("verticalScrollPosition", targetVerticalScrollPosition);
                    this._verticalAutoScrollTween.onComplete = verticalAutoScrollTween_onComplete;
                    Loom2D.juggler.add(this._verticalAutoScrollTween);
                }
                else
                {
                    this.finishScrollingVertically();
                }
            }
        }

        /**
         * Immediately throws the scroller to the specified page index, with
         * optional animation. If you want to throw in only one direction, pass
         * in a parameter value of `-1` for the direction that should
         * not change. The scroller should be validated before throwing.
         *
         * @see #scrollToPageIndex()
         */
        protected function throwToPage(targetHorizontalPageIndex:int = -1, targetVerticalPageIndex:int = -1, duration:Number = 0.5):void
        {
            const pageWidth:Number = this.actualWidth - (this._leftViewPortOffset + this._rightViewPortOffset);
            const pageHeight:Number = this.actualHeight - (this._topViewPortOffset + this._bottomViewPortOffset);
            const targetHorizontalScrollPosition:Number = Math.max(0, Math.min(this._maxHorizontalScrollPosition, (targetHorizontalPageIndex >= 0 ? (pageWidth * targetHorizontalPageIndex) : this._horizontalScrollPosition)));
            const targetVerticalScrollPosition:Number = Math.max(0, Math.min(this._maxVerticalScrollPosition, (targetVerticalPageIndex >= 0 ? (pageHeight * targetVerticalPageIndex) : this._verticalScrollPosition)));
            if(duration > 0)
            {
                this.throwTo(targetHorizontalScrollPosition, targetVerticalScrollPosition, duration);
            }
            else
            {
                this.horizontalScrollPosition = targetHorizontalScrollPosition;
                this.verticalScrollPosition = targetVerticalScrollPosition;
            }
            if(targetHorizontalPageIndex >= 0)
            {
                this._horizontalPageIndex = targetHorizontalPageIndex;
            }
            if(targetVerticalPageIndex >= 0)
            {
                this._verticalPageIndex = targetVerticalPageIndex;
            }
        }
        
        /**
         * @private
         */
        protected function finishScrollingHorizontally():void
        {
            var targetHorizontalScrollPosition:Number = NaN;
            if(this._horizontalScrollPosition < 0)
            {
                targetHorizontalScrollPosition = 0;
            }
            else if(this._horizontalScrollPosition > this._maxHorizontalScrollPosition)
            {
                targetHorizontalScrollPosition = this._maxHorizontalScrollPosition;
            }
            
            this._isDraggingHorizontally = false;
            if(isNaN(targetHorizontalScrollPosition) && !this._isDraggingVertically && !this._verticalAutoScrollTween)
            {
                this.hideHorizontalScrollBar();
                this.hideVerticalScrollBar();
                this.validate();
                this.dispatchEventWith(FeathersEventType.SCROLL_COMPLETE);
            }
            else
            {
                this.throwTo(targetHorizontalScrollPosition, NaN, this._elasticSnapDuration);
            }
        }
        
        /**
         * @private
         */
        protected function finishScrollingVertically():void
        {
            var targetVerticalScrollPosition:Number = NaN;
            if(this._verticalScrollPosition < 0)
            {
                targetVerticalScrollPosition = 0;
            }
            else if(this._verticalScrollPosition > this._maxVerticalScrollPosition)
            {
                targetVerticalScrollPosition = this._maxVerticalScrollPosition;
            }
            
            this._isDraggingVertically = false;
            if(isNaN(targetVerticalScrollPosition) && !this._isDraggingHorizontally && !this._horizontalAutoScrollTween)
            {
                this.hideHorizontalScrollBar();
                this.hideVerticalScrollBar();
                this.validate();
                this.dispatchEventWith(FeathersEventType.SCROLL_COMPLETE);
            }
            else
            {
                this.throwTo(NaN, targetVerticalScrollPosition, this._elasticSnapDuration);
            }
        }
        
        /**
         * @private
         */
        protected function throwHorizontally(pixelsPerMS:Number):void
        {
            if(this._snapToPages)
            {
                const pageWidth:Number = this.actualWidth - (this._leftViewPortOffset + this._rightViewPortOffset);
                const inchesPerSecond:Number = 1000 * pixelsPerMS / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
                if(inchesPerSecond > MINIMUM_PAGE_VELOCITY)
                {
                    var snappedPageHorizontalScrollPosition:Number = FeathersMath.roundDownToNearest(this._horizontalScrollPosition, pageWidth);
                }
                else if(inchesPerSecond < -MINIMUM_PAGE_VELOCITY)
                {
                    snappedPageHorizontalScrollPosition = FeathersMath.roundUpToNearest(this._horizontalScrollPosition, pageWidth);
                }
                else
                {
                    const lastPageWidth:Number = this._maxHorizontalScrollPosition % pageWidth;
                    var startOfLastPage:Number = this._maxHorizontalScrollPosition - lastPageWidth;
                    if(lastPageWidth < pageWidth && this._horizontalScrollPosition >= startOfLastPage)
                    {
                        const lastPagePosition:Number = this._horizontalScrollPosition - startOfLastPage;
                        if(inchesPerSecond > MINIMUM_PAGE_VELOCITY)
                        {
                            snappedPageHorizontalScrollPosition = startOfLastPage + FeathersMath.roundDownToNearest(lastPagePosition, lastPageWidth);
                        }
                        else if(inchesPerSecond < -MINIMUM_PAGE_VELOCITY)
                        {
                            snappedPageHorizontalScrollPosition = startOfLastPage + FeathersMath.roundUpToNearest(lastPagePosition, lastPageWidth);
                        }
                        else
                        {
                            snappedPageHorizontalScrollPosition = startOfLastPage + FeathersMath.roundToNearest(lastPagePosition, lastPageWidth);
                        }
                    }
                    else
                    {
                        snappedPageHorizontalScrollPosition = FeathersMath.roundToNearest(this._horizontalScrollPosition, pageWidth);
                    }
                }
                snappedPageHorizontalScrollPosition = Math.max(0, Math.min(this._maxHorizontalScrollPosition, snappedPageHorizontalScrollPosition));
                if(snappedPageHorizontalScrollPosition == this._maxHorizontalScrollPosition)
                {
                    var targetHorizontalPageIndex:int = this._horizontalPageCount - 1;
                }
                else
                {
                    targetHorizontalPageIndex = snappedPageHorizontalScrollPosition / pageWidth;
                }
                this.throwToPage(targetHorizontalPageIndex, -1, this._pageThrowDuration);
                return;
            }

            const absPixelsPerMS:Number = Math.abs(pixelsPerMS);
            if(absPixelsPerMS <= MINIMUM_VELOCITY)
            {
                this.finishScrollingHorizontally();
                return;
            }
            var targetHorizontalScrollPosition:Number = this._horizontalScrollPosition + (pixelsPerMS - MINIMUM_VELOCITY) / Math.log(FRICTION);
            if(targetHorizontalScrollPosition < 0 || targetHorizontalScrollPosition > this._maxHorizontalScrollPosition)
            {
                var duration:Number = 0;
                targetHorizontalScrollPosition = this._horizontalScrollPosition;
                while(Math.abs(pixelsPerMS) > MINIMUM_VELOCITY)
                {
                    targetHorizontalScrollPosition -= pixelsPerMS;
                    if(targetHorizontalScrollPosition < 0 || targetHorizontalScrollPosition > this._maxHorizontalScrollPosition)
                    {
                        if(this._hasElasticEdges)
                        {
                            pixelsPerMS *= FRICTION * EXTRA_FRICTION;
                        }
                        else
                        {
                            targetHorizontalScrollPosition = FeathersMath.clamp(targetHorizontalScrollPosition, 0, this._maxHorizontalScrollPosition);
                            duration++;
                            break;
                        }
                    }
                    else
                    {
                        pixelsPerMS *= FRICTION;
                    }
                    duration++;
                }
            }
            else
            {
                duration = Math.log(MINIMUM_VELOCITY / absPixelsPerMS) / Math.log(FRICTION);
            }
            this.throwTo(targetHorizontalScrollPosition, NaN, duration / 1000);
        }
        
        /**
         * @private
         */
        protected function throwVertically(pixelsPerMS:Number):void
        {
            if(this._snapToPages)
            {
                const pageHeight:Number = this.actualHeight - (this._topViewPortOffset + this._bottomViewPortOffset);
                const inchesPerSecond:Number = 1000 * pixelsPerMS / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
                if(inchesPerSecond > MINIMUM_PAGE_VELOCITY)
                {
                    var snappedPageVerticalScrollPosition:Number = FeathersMath.roundDownToNearest(this._verticalScrollPosition, pageHeight);
                }
                else if(inchesPerSecond < -MINIMUM_PAGE_VELOCITY)
                {
                    snappedPageVerticalScrollPosition = FeathersMath.roundUpToNearest(this._verticalScrollPosition, pageHeight);
                }
                else
                {
                    const lastPageHeight:Number = this._maxVerticalScrollPosition % pageHeight;
                    var startOfLastPage:Number = this._maxVerticalScrollPosition - lastPageHeight;
                    if(lastPageHeight < pageHeight && this._verticalScrollPosition >= startOfLastPage)
                    {
                        const lastPagePosition:Number = this._verticalScrollPosition - startOfLastPage;
                        if(inchesPerSecond > MINIMUM_PAGE_VELOCITY)
                        {
                            snappedPageVerticalScrollPosition = startOfLastPage + FeathersMath.roundDownToNearest(lastPagePosition, lastPageHeight);
                        }
                        else if(inchesPerSecond < -MINIMUM_PAGE_VELOCITY)
                        {
                            snappedPageVerticalScrollPosition = startOfLastPage + FeathersMath.roundUpToNearest(lastPagePosition, lastPageHeight);
                        }
                        else
                        {
                            snappedPageVerticalScrollPosition = startOfLastPage + FeathersMath.roundToNearest(lastPagePosition, lastPageHeight);
                        }
                    }
                    else
                    {
                        snappedPageVerticalScrollPosition = FeathersMath.roundToNearest(this._verticalScrollPosition, pageHeight);
                    }
                }
                snappedPageVerticalScrollPosition = Math.max(0, Math.min(this._maxVerticalScrollPosition, snappedPageVerticalScrollPosition));
                if(snappedPageVerticalScrollPosition == this._maxVerticalScrollPosition)
                {
                    var targetVerticalPageIndex:int = this._verticalPageCount - 1;
                }
                else
                {
                    targetVerticalPageIndex = snappedPageVerticalScrollPosition / pageHeight;
                }
                this.throwToPage(-1, targetVerticalPageIndex, this._pageThrowDuration);
                return;
            }

            const absPixelsPerMS:Number = Math.abs(pixelsPerMS);
            if(absPixelsPerMS <= MINIMUM_VELOCITY)
            {
                this.finishScrollingVertically();
                return;
            }
            var targetVerticalScrollPosition:Number = this._verticalScrollPosition + (pixelsPerMS - MINIMUM_VELOCITY) / Math.log(FRICTION);
            var duration:Number = 0;
            if(targetVerticalScrollPosition < 0 || targetVerticalScrollPosition > this._maxVerticalScrollPosition)
            {
                targetVerticalScrollPosition = this._verticalScrollPosition;
                while(Math.abs(pixelsPerMS) > MINIMUM_VELOCITY)
                {
                    targetVerticalScrollPosition -= pixelsPerMS;
                    if(targetVerticalScrollPosition < 0 || targetVerticalScrollPosition > this._maxVerticalScrollPosition)
                    {
                        if(this._hasElasticEdges)
                        {
                            pixelsPerMS *= FRICTION * EXTRA_FRICTION;
                        }
                        else
                        {
                            targetVerticalScrollPosition = FeathersMath.clamp(targetVerticalScrollPosition, 0, this._maxVerticalScrollPosition);
                            duration++;
                            break;
                        }
                    }
                    else
                    {
                        pixelsPerMS *= FRICTION;
                    }
                    duration++;
                }
            }
            else
            {
                duration = Math.log(MINIMUM_VELOCITY / absPixelsPerMS) / Math.log(FRICTION);
            }
            this.throwTo(NaN, targetVerticalScrollPosition, duration / 1000);
        }

        /**
         * @private
         */
        protected function hideHorizontalScrollBar(delay:Number = 0):void
        {
            if(!this.horizontalScrollBar || this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_FLOAT || this._horizontalScrollBarHideTween)
            {
                return;
            }
            if(this.horizontalScrollBar.alpha == 0)
            {
                return;
            }
            this._horizontalScrollBarHideTween = Tween.fromPool(this.horizontalScrollBar, this._hideScrollBarAnimationDuration, this._hideScrollBarAnimationEase);
            this._horizontalScrollBarHideTween.fadeTo(0);
            this._horizontalScrollBarHideTween.delay = delay;
            this._horizontalScrollBarHideTween.onComplete = horizontalScrollBarHideTween_onComplete;
            Loom2D.juggler.add(this._horizontalScrollBarHideTween);
        }

        /**
         * @private
         */
        protected function hideVerticalScrollBar(delay:Number = 0):void
        {
            if(!this.verticalScrollBar || this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_FLOAT || this._verticalScrollBarHideTween)
            {
                return;
            }
            if(this.verticalScrollBar.alpha == 0)
            {
                return;
            }
            this._verticalScrollBarHideTween = Tween.fromPool(this.verticalScrollBar, this._hideScrollBarAnimationDuration, this._hideScrollBarAnimationEase);
            this._verticalScrollBarHideTween.fadeTo(0);
            this._verticalScrollBarHideTween.delay = delay;
            this._verticalScrollBarHideTween.onComplete = verticalScrollBarHideTween_onComplete;
            Loom2D.juggler.add(this._verticalScrollBarHideTween);
        }

        /**
         * Scrolls to a pending scroll position, if required.
         */
        protected function handlePendingScroll():void
        {
            if(!isNaN(this.pendingHorizontalScrollPosition) || !isNaN(this.pendingVerticalScrollPosition))
            {
                this.throwTo(this.pendingHorizontalScrollPosition, this.pendingVerticalScrollPosition, this.pendingScrollDuration);
                this.pendingHorizontalScrollPosition = NaN;
                this.pendingVerticalScrollPosition = NaN;
            }
            if(this.pendingHorizontalPageIndex >= 0 || this.pendingVerticalPageIndex >= 0)
            {
                this.throwToPage(this.pendingHorizontalPageIndex, this.pendingVerticalPageIndex, this.pendingScrollDuration);
                this.pendingHorizontalPageIndex = -1;
                this.pendingVerticalPageIndex = -1;
            }
        }

        /**
         * @private
         */
        protected function viewPort_resizeHandler(event:Event):void
        {
            if(this.ignoreViewPortResizing ||
                (this._viewPort.width == this._lastViewPortWidth && this._viewPort.height == this._lastViewPortHeight))
            {
                return;
            }
            this._lastViewPortWidth = this._viewPort.width;
            this._lastViewPortHeight = this._viewPort.height;
            if(this._isValidating)
            {
                this._hasViewPortBoundsChanged = true;
            }
            else
            {
                this.invalidate(INVALIDATION_FLAG_SIZE);
            }
        }
        /**
         * @private
         */
        protected function verticalScrollBar_changeHandler(event:Event):void
        {
            this.verticalScrollPosition = this.verticalScrollBar.value;
        }

        /**
         * @private
         */
        protected function horizontalScrollBar_changeHandler(event:Event):void
        {
            this.horizontalScrollPosition = this.horizontalScrollBar.value;
        }

        /**
         * @private
         */
        protected function horizontalScrollBar_beginInteractionHandler(event:Event):void
        {
            this._horizontalScrollBarIsScrolling = true;
            this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
            this.dispatchEventWith(FeathersEventType.SCROLL_START);
        }

        /**
         * @private
         */
        protected function horizontalScrollBar_endInteractionHandler(event:Event):void
        {
            this._horizontalScrollBarIsScrolling = false;
            this.dispatchEventWith(FeathersEventType.END_INTERACTION);
            this.dispatchEventWith(FeathersEventType.SCROLL_COMPLETE);
        }

        /**
         * @private
         */
        protected function verticalScrollBar_beginInteractionHandler(event:Event):void
        {
            this._verticalScrollBarIsScrolling = true;
            this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
            this.dispatchEventWith(FeathersEventType.SCROLL_START);
        }

        /**
         * @private
         */
        protected function verticalScrollBar_endInteractionHandler(event:Event):void
        {
            this._verticalScrollBarIsScrolling = false;
            this.dispatchEventWith(FeathersEventType.END_INTERACTION);
            this.dispatchEventWith(FeathersEventType.SCROLL_COMPLETE);
        }
        
        /**
         * @private
         */
        protected function horizontalAutoScrollTween_onComplete():void
        {
            this._horizontalAutoScrollTween = null;
            this.finishScrollingHorizontally();
        }
        
        /**
         * @private
         */
        protected function verticalAutoScrollTween_onComplete():void
        {
            this._verticalAutoScrollTween = null;
            this.finishScrollingVertically();
        }

        /**
         * @private
         */
        protected function horizontalScrollBarHideTween_onComplete():void
        {
            this._horizontalScrollBarHideTween = null;
        }

        /**
         * @private
         */
        protected function verticalScrollBarHideTween_onComplete():void
        {
            this._verticalScrollBarHideTween = null;
        }
        
        /**
         * @private
         */
        protected function touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled || this._touchPointID >= 0)
            {
                return;
            }

            //any began touch is okay here. we don't need to check all touches.
            const touch:Touch = event.getTouch(this, TouchPhase.BEGAN);
            if(!touch)
            {
                return;
            }

            HELPER_POINT = touch.getLocation(this);

            if(this._horizontalAutoScrollTween)
            {
                Loom2D.juggler.remove(this._horizontalAutoScrollTween);
                Tween.toPool(this._horizontalAutoScrollTween);
                this._horizontalAutoScrollTween = null;
            }
            else
            {
                this._isDraggingHorizontally = false;
            }

            if(this._verticalAutoScrollTween)
            {
                Loom2D.juggler.remove(this._verticalAutoScrollTween);
                Tween.toPool(this._verticalAutoScrollTween);

                this._verticalAutoScrollTween = null;
            }
            else
            {
                this._isDraggingVertically = false;
            }
            
            this._touchPointID = touch.id;
            this._velocityX = 0;
            this._velocityY = 0;
            this._previousVelocityX.length = 0;
            this._previousVelocityY.length = 0;
            this._previousTouchTime = Platform.getTime();
            this._previousTouchX = this._startTouchX = this._currentTouchX = HELPER_POINT.x;
            this._previousTouchY = this._startTouchY = this._currentTouchY = HELPER_POINT.y;
            this._startHorizontalScrollPosition = this._horizontalScrollPosition;
            this._startVerticalScrollPosition = this._verticalScrollPosition;
            this._isScrollingStopped = false;

            stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
            
            //we need to listen on the stage because if we scroll the bottom or
            //right edge past the top of the scroller, it gets stuck and we stop
            //receiving touch events for "this".
            this.stage.addEventListener(TouchEvent.TOUCH, stage_touchHandler);
        }

        /**
         * @private
         */
        protected function enterFrameHandler(event:Event):void
        {
            if(this._isScrollingStopped)
            {
                return;
            }
            const now:int = Platform.getTime();
            const timeOffset:int = now - this._previousTouchTime;
            if(timeOffset > 0)
            {
                //we're keeping previous velocity updates to improve accuracy
                this._previousVelocityX.unshift(this._velocityX);
                if(this._previousVelocityX.length > MAXIMUM_SAVED_VELOCITY_COUNT)
                {
                    this._previousVelocityX.pop();
                }
                this._previousVelocityY.unshift(this._velocityY);
                if(this._previousVelocityY.length > MAXIMUM_SAVED_VELOCITY_COUNT)
                {
                    this._previousVelocityY.pop();
                }
                this._velocityX = (this._currentTouchX - this._previousTouchX) / timeOffset;
                this._velocityY = (this._currentTouchY - this._previousTouchY) / timeOffset;
                this._previousTouchTime = now;
                this._previousTouchX = this._currentTouchX;
                this._previousTouchY = this._currentTouchY;
            }
            const horizontalInchesMoved:Number = Math.abs(this._currentTouchX - this._startTouchX) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
            const verticalInchesMoved:Number = Math.abs(this._currentTouchY - this._startTouchY) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
            if((this._horizontalScrollPolicy == SCROLL_POLICY_ON ||
                (this._horizontalScrollPolicy == SCROLL_POLICY_AUTO && this._maxHorizontalScrollPosition > 0)) &&
                !this._isDraggingHorizontally && horizontalInchesMoved >= MINIMUM_DRAG_DISTANCE)
            {
                if(this.horizontalScrollBar)
                {
                    if(this._horizontalScrollBarHideTween)
                    {
                        Loom2D.juggler.remove(this._horizontalScrollBarHideTween);
                        Tween.toPool(this._horizontalScrollBarHideTween);
                        this._horizontalScrollBarHideTween = null;
                    }
                    if(this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FLOAT)
                    {
                        this.horizontalScrollBar.alpha = 1;
                    }
                }
                //if we haven't already started dragging in the other direction,
                //we need to dispatch the event that says we're starting.
                if(!this._isDraggingVertically)
                {
                    if(this._touchBlocker)
                    {
                        this._touchBlocker.visible = true;
                    }
                    this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                    this.dispatchEventWith(FeathersEventType.SCROLL_START);
                }
                this._startTouchX = this._currentTouchX;
                this._startHorizontalScrollPosition = this._horizontalScrollPosition;
                this._isDraggingHorizontally = true;
            }
            if((this._verticalScrollPolicy == SCROLL_POLICY_ON ||
                (this._verticalScrollPolicy == SCROLL_POLICY_AUTO && this._maxVerticalScrollPosition > 0)) &&
                !this._isDraggingVertically && verticalInchesMoved >= MINIMUM_DRAG_DISTANCE)
            {
                if(this.verticalScrollBar)
                {
                    if(this._verticalScrollBarHideTween)
                    {
                        Loom2D.juggler.remove(this._verticalScrollBarHideTween);
                        Tween.toPool(this._verticalScrollBarHideTween);
                        this._verticalScrollBarHideTween = null;
                    }
                    if(this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FLOAT)
                    {
                        this.verticalScrollBar.alpha = 1;
                    }
                }
                if(!this._isDraggingHorizontally)
                {
                    if(this._touchBlocker)
                    {
                        this._touchBlocker.visible = true;
                    }
                    this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                    this.dispatchEventWith(FeathersEventType.SCROLL_START);
                }
                this._startTouchY = this._currentTouchY;
                this._startVerticalScrollPosition = this._verticalScrollPosition;
                this._isDraggingVertically = true;
            }
            if(this._isDraggingHorizontally && !this._horizontalAutoScrollTween)
            {
                this.updateHorizontalScrollFromTouchPosition(this._currentTouchX);
            }
            if(this._isDraggingVertically && !this._verticalAutoScrollTween)
            {
                this.updateVerticalScrollFromTouchPosition(this._currentTouchY);
            }
        }

        /**
         * @private
         */
        protected function stage_touchHandler(event:TouchEvent):void
        {
            const touches:Vector.<Touch> = event.getTouches(this.stage, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0 || this._touchPointID < 0)
            {
                HELPER_TOUCHES_VECTOR.length = 0;
                return;
            }
            var touch:Touch;
            for each(var currentTouch:Touch in touches)
            {
                if(currentTouch.id == this._touchPointID)
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

            if(touch.phase == TouchPhase.MOVED)
            {
                //we're saving these to use in the enter frame handler because
                //that provides a longer time offset
                HELPER_POINT = touch.getLocation(this);
                this._currentTouchX = HELPER_POINT.x;
                this._currentTouchY = HELPER_POINT.y;
            }
            else if(touch.phase == TouchPhase.ENDED)
            {
                if(this._touchBlocker)
                {
                    this._touchBlocker.visible = false;
                }
                stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
                this.stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
                this._touchPointID = -1;
                this.dispatchEventWith(FeathersEventType.END_INTERACTION);
                var isFinishingHorizontally:Boolean = false;
                var isFinishingVertically:Boolean = false;
                if(this._horizontalScrollPosition < 0 || this._horizontalScrollPosition > this._maxHorizontalScrollPosition)
                {
                    isFinishingHorizontally = true;
                    this.finishScrollingHorizontally();
                }
                if(this._verticalScrollPosition < 0 || this._verticalScrollPosition > this._maxVerticalScrollPosition)
                {
                    isFinishingVertically = true;
                    this.finishScrollingVertically();
                }
                if(isFinishingHorizontally && isFinishingVertically)
                {
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                
                if(!isFinishingHorizontally && this._isDraggingHorizontally)
                {
                    //take the average for more accuracy
                    var sum:Number = this._velocityX * 2.33;
                    var velocityCount:int = this._previousVelocityX.length;
                    var totalWeight:Number = 0;
                    for(var i:int = 0; i < velocityCount; i++)
                    {
                        var weight:Number = VELOCITY_WEIGHTS[i];
                        sum += _previousVelocityX.shift() * weight;
                        totalWeight += weight;
                    }
                    this.throwHorizontally(sum / totalWeight);
                }
                else
                {
                    this.hideHorizontalScrollBar();
                }
                
                if(!isFinishingVertically && this._isDraggingVertically)
                {
                    sum = this._velocityY * 2.33;
                    velocityCount = this._previousVelocityY.length;
                    totalWeight = 0;
                    for(i = 0; i < velocityCount; i++)
                    {
                        weight = VELOCITY_WEIGHTS[i];
                        sum += _previousVelocityY.shift() * weight;
                        totalWeight += weight;
                    }
                    this.throwVertically(sum / totalWeight);
                }
                else
                {
                    this.hideVerticalScrollBar();
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
/*        protected function nativeStage_mouseWheelHandler(event:MouseEvent):void
        {
            if(!this._isEnabled || this._maxVerticalScrollPosition == 0)
            {
                return;
            }
            const starlingViewPort:Rectangle = Loom2D.current.viewPort;
            HELPER_POINT.x = (event.stageX - starlingViewPort.x) / Loom2D.contentScaleFactor;
            HELPER_POINT.y = (event.stageY - starlingViewPort.y) / Loom2D.contentScaleFactor;
            if(this.contains(this.stage.hitTest(HELPER_POINT, true)))
            {
                if(this._verticalScrollBarHideTween)
                {
                    Loom2D.juggler.remove(this._verticalScrollBarHideTween);
                    Tween.toPool(this._verticalScrollBarHideTween);
                    this._verticalScrollBarHideTween = null;
                }
                if(this.verticalScrollBar && this._scrollBarDisplayMode == SCROLL_BAR_DISPLAY_MODE_FLOAT)
                {
                    this.verticalScrollBar.alpha = 1;
                }
                const targetVerticalScrollPosition:Number = Math.min(this._maxVerticalScrollPosition, Math.max(0, this._verticalScrollPosition - event.delta * this.actualVerticalScrollStep));
                this.throwTo(NaN, targetVerticalScrollPosition, this._mouseWheelScrollDuration);
            }
        } */

        /**
         * @private
         */
/*        protected function nativeStage_orientationChangeHandler(event:flash.events.Event):void
        {
            if(this._touchPointID < 0)
            {
                return;
            }
            this._startTouchX = this._previousTouchX = this._currentTouchX;
            this._startTouchY = this._previousTouchY = this._currentTouchY;
            this._startHorizontalScrollPosition = this._horizontalScrollPosition;
            this._startVerticalScrollPosition = this._verticalScrollPosition;
        } */

        /**
         * @private
         */
        protected function horizontalScrollBar_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                this._horizontalScrollBarTouchPointID = -1;
                return;
            }
            const displayHorizontalScrollBar:DisplayObject = DisplayObject(event.currentTarget);
            const touches:Vector.<Touch> = event.getTouches(displayHorizontalScrollBar, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                //end hover
                this.hideHorizontalScrollBar();
                return;
            }
            if(this._horizontalScrollBarTouchPointID >= 0)
            {
                var touch:Touch;
                for each(var currentTouch:Touch in touches)
                {
                    if(currentTouch.id == this._horizontalScrollBarTouchPointID)
                    {
                        touch = currentTouch;
                        break;
                    }
                }
                if(!touch)
                {
                    //end hover
                    this.hideHorizontalScrollBar();
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this._horizontalScrollBarTouchPointID = -1;
                    HELPER_POINT = touch.getLocation(displayHorizontalScrollBar);
                    const isInBounds:Boolean = this.horizontalScrollBar.hitTest(HELPER_POINT, true) != null;
                    if(!isInBounds)
                    {
                        this.hideHorizontalScrollBar();
                    }
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.HOVER)
                    {
                        if(this._horizontalScrollBarHideTween)
                        {
                            Loom2D.juggler.remove(this._horizontalScrollBarHideTween);
                            Tween.toPool(this._horizontalScrollBarHideTween);
                            this._horizontalScrollBarHideTween = null;
                        }
                        this.horizontalScrollBar.alpha = 1;
                        break;
                    }
                    else if(touch.phase == TouchPhase.BEGAN)
                    {
                        this._horizontalScrollBarTouchPointID = touch.id;
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function verticalScrollBar_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                this._verticalScrollBarTouchPointID = -1;
                return;
            }
            const displayVerticalScrollBar:DisplayObject = DisplayObject(event.currentTarget);
            const touches:Vector.<Touch> = event.getTouches(displayVerticalScrollBar, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                //end hover
                this.hideVerticalScrollBar();
                return;
            }
            if(this._verticalScrollBarTouchPointID >= 0)
            {
                var touch:Touch;
                for each(var currentTouch:Touch in touches)
                {
                    if(currentTouch.id == this._verticalScrollBarTouchPointID)
                    {
                        touch = currentTouch;
                        break;
                    }
                }
                if(!touch)
                {
                    //end hover
                    this.hideVerticalScrollBar();
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this._verticalScrollBarTouchPointID = -1;
                    HELPER_POINT = touch.getLocation(displayVerticalScrollBar);
                    const isInBounds:Boolean = this.verticalScrollBar.hitTest(HELPER_POINT, true) != null;
                    if(!isInBounds)
                    {
                        this.hideVerticalScrollBar();
                    }
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.HOVER)
                    {
                        if(this._verticalScrollBarHideTween)
                        {
                            Loom2D.juggler.remove(this._verticalScrollBarHideTween);
                            Tween.toPool(this._verticalScrollBarHideTween);
                            this._verticalScrollBarHideTween = null;
                        }
                        this.verticalScrollBar.alpha = 1;
                        break;
                    }
                    else if(touch.phase == TouchPhase.BEGAN)
                    {
                        this._verticalScrollBarTouchPointID = touch.id;
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function scroller_addedToStageHandler(event:Event):void
        {
            //Loom2D.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, nativeStage_mouseWheelHandler, false, 0, true);
            //Loom2D.current.nativeStage.addEventListener("orientationChange", nativeStage_orientationChangeHandler, false, 0, true);
        }
        
        /**
         * @private
         */
        protected function scroller_removedFromStageHandler(event:Event):void
        {
            //Loom2D.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, nativeStage_mouseWheelHandler);
            //Loom2D.current.nativeStage.removeEventListener("orientationChange", nativeStage_orientationChangeHandler);
            this._touchPointID = -1;
            this._horizontalScrollBarTouchPointID = -1;
            this._verticalScrollBarTouchPointID = -1;
            this._velocityX = 0;
            this._velocityY = 0;
            this._previousVelocityX.length = 0;
            this._previousVelocityY.length = 0;
            this._horizontalScrollBarIsScrolling = false;
            this._verticalScrollBarIsScrolling = false;
            this.stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
            this.stage.removeEventListener(TouchEvent.TOUCH, stage_touchHandler);
            if(this._verticalAutoScrollTween)
            {
                Loom2D.juggler.remove(this._verticalAutoScrollTween);
                Tween.toPool(this._verticalAutoScrollTween);
                this._verticalAutoScrollTween = null;
            }
            if(this._horizontalAutoScrollTween)
            {
                Loom2D.juggler.remove(this._horizontalAutoScrollTween);
                Tween.toPool(this._horizontalAutoScrollTween);
                this._horizontalAutoScrollTween = null;
            }
            
            //if we stopped the animation while the list was outside the scroll
            //bounds, then let's account for that
            const oldHorizontalScrollPosition:Number = this._horizontalScrollPosition;
            const oldVerticalScrollPosition:Number = this._verticalScrollPosition;
            this._horizontalScrollPosition = FeathersMath.clamp(this._horizontalScrollPosition, 0, this._maxHorizontalScrollPosition);
            this._verticalScrollPosition = FeathersMath.clamp(this._verticalScrollPosition, 0, this._maxVerticalScrollPosition);
            if(oldHorizontalScrollPosition != this._horizontalScrollPosition ||
                oldVerticalScrollPosition != this._verticalScrollPosition)
            {
                this.dispatchEventWith(Event.SCROLL);
            }
        }
    }
}