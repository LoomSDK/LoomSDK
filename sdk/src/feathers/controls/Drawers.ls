/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.core.IFeathersControl;
    import feathers.events.ExclusiveTouch;
    import feathers.events.FeathersEventType;
    import feathers.system.DeviceCapabilities;
    import feathers.utils.FeathersDisplayUtils;
    import feathers.utils.FeathersMath;

    import loom2d.events.KeyboardEvent;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom.platform.LoomKey;

    import loom2d.animation.Transitions;
    import loom2d.animation.Tween;
    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Sprite;
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
    import loom2d.events.ResizeEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    /**
     * Dispatched when the user starts dragging the content to open or close a
     * drawer.
     *
     * @eventType feathers.events.FeathersEventType.BEGIN_INTERACTION
     * @see feathers.events.FeathersEventType.END_INTERACTION
     */
    [Event(name="beginInteraction",type="starling.events.Event")]

    /**
     * Dispatched when the user stops dragging the content to open or close a
     * drawer. The drawer may continue opening or closing after this event is
     * dispatched if the user interaction has also triggered an animation.
     *
     * @eventType feathers.events.FeathersEventType.END_INTERACTION
     * @see feathers.events.FeathersEventType.BEGIN_INTERACTION
     */
    [Event(name="endInteraction",type="starling.events.Event")]

    /**
     * A container that displays primary content in the center surrounded by
     * optional "drawers" that can open and close on the edges. Useful for
     * mobile-style app menus that slide open from the side of the screen.
     *
     * <p>Additionally, each drawer may be individually "docked" in an
     * always-open state, making this a useful application-level layout
     * container even if the drawers never need to be hidden. Docking behavior
     * may be limited to either portrait or landscape, or a drawer may be docked
     * in both orientations. By default, a drawer is not docked.</p>
     *
     * <p>The following example creates an app with a slide out menu to the
     * left of the main content:</p>
     *
     * <listing version="3.0">
     * var navigator:ScreenNavigator = new ScreenNavigator();
     * var list:List = new List();
     * // the navigator's screens, the list's data provider, and additional
     * // properties should be set here.
     * var drawers:Drawers = new Drawers();
     * drawers.content = navigator;
     * drawers.leftDrawer = menu;
     * drawers.leftDrawerToggleEventType = Event.OPEN;
     * this.addChild( drawers );</listing>
     *
     * <p>In the example above, a screen in the <code>ScreenNavigator</code>
     * component dispatches an event of type <code>Event.OPEN</code> when it
     * wants to display the slide out the <code>List</code> that is used as
     * the left drawer.</p>
     *
     * <p><strong>Beta Component:</strong> This is a new component, and its APIs
     * may need some changes between now and the next version of Feathers to
     * account for overlooked requirements or other issues. Upgrading to future
     * versions of Feathers may involve manual changes to your code that uses
     * this component. The
     * <a href="http://wiki.starling-framework.org/feathers/deprecation-policy">Feathers deprecation policy</a>
     * will not go into effect until this component's status is upgraded from
     * beta to stable.</p>
     *
     * @see http://wiki.starling-framework.org/feathers/drawers
     */
    public class Drawers extends FeathersControl
    {
        /**
         * The drawer will be docked in portrait orientation, but it must be
         * opened and closed explicitly in landscape orientation.
         *
         * @see #topDrawerDockMode
         * @see #rightDrawerDockMode
         * @see #bottomDrawerDockMode
         * @see #leftDrawerDockMode
         * @see #isTopDrawerDocked
         * @see #isRightDrawerDocked
         * @see #isBottomDrawerDocked
         * @see #isLeftDrawerDocked
         */
        public static const DOCK_MODE_PORTRAIT:String = "portrait";

        /**
         * The drawer will be docked in landscape orientation, but it must be
         * opened and closed explicitly in portrait orientation.
         *
         * @see #topDrawerDockMode
         * @see #rightDrawerDockMode
         * @see #bottomDrawerDockMode
         * @see #leftDrawerDockMode
         * @see #isTopDrawerDocked
         * @see #isRightDrawerDocked
         * @see #isBottomDrawerDocked
         * @see #isLeftDrawerDocked
         */
        public static const DOCK_MODE_LANDSCAPE:String = "landscape";

        /**
         * The drawer will be docked in all orientations.
         *
         * @see #topDrawerDockMode
         * @see #rightDrawerDockMode
         * @see #bottomDrawerDockMode
         * @see #leftDrawerDockMode
         * @see #isTopDrawerDocked
         * @see #isRightDrawerDocked
         * @see #isBottomDrawerDocked
         * @see #isLeftDrawerDocked
         */
        public static const DOCK_MODE_BOTH:String = "both";

        /**
         * The drawer won't be docked in any orientation. It must be opened and
         * closed explicitly in all orientations.
         *
         * @see #topDrawerDockMode
         * @see #rightDrawerDockMode
         * @see #bottomDrawerDockMode
         * @see #leftDrawerDockMode
         * @see #isTopDrawerDocked
         * @see #isRightDrawerDocked
         * @see #isBottomDrawerDocked
         * @see #isLeftDrawerDocked
         */
        public static const DOCK_MODE_NONE:String = "none";

        /**
         * The drawers container  will auto size itself to fill the entire stage.
         *
         * @see #autoSizeMode
         */
        public static const AUTO_SIZE_MODE_STAGE:String = "stage";

        /**
         * The drawers container will auto size itself to fit its content.
         *
         * @see #autoSizeMode
         */
        public static const AUTO_SIZE_MODE_CONTENT:String = "content";

        /**
         * A drawer will open by dragging the content starting from a certain
         * physical distance (in inches) from the nearest edge of the content.
         * To customize this distance, use the <code>openGestureDragContentEdgeDistance</code>
         * property.
         *
         * @see #openGesture
         * @see openGestureEdgeSize
         */
        public static const OPEN_GESTURE_DRAG_CONTENT_EDGE:String = "dragContentEdge";

        /**
         * A drawer will open by dragging the content from any location in the
         * appropriate direction.
         *
         * @see #openGesture
         */
        public static const OPEN_GESTURE_DRAG_CONTENT:String = "dragContent";

        /**
         * The drawers container will only open using the toggle event types
         * dispatched by the content. No gesture can be used to open a drawer.
         *
         * @see #openGesture
         * @see #topDrawerToggleEventType
         * @see #rightDrawerToggleEventType
         * @see #bottomDrawerToggleEventType
         * @see #leftDrawerToggleEventType
         */
        public static const OPEN_GESTURE_NONE:String = "none";

        /**
         * The field used to access the "content event dispatcher" of a
         * <code>ScreenNavigator</code> component, which happens to be the
         * currently active screen.
         *
         * @see #contentEventDispatcherField
         * @see feathers.controls.ScreenNavigator
         */
        protected static const SCREEN_NAVIGATOR_CONTENT_EVENT_DISPATCHER_FIELD:String = "activeScreen";

        /**
         * @private
         * The current velocity is given high importance.
         */
        private static const CURRENT_VELOCITY_WEIGHT:Number = 2.33;

        /**
         * @private
         * Older saved velocities are given less importance.
         */
        private static const VELOCITY_WEIGHTS:Vector.<Number> = new <Number>[1, 1.33, 1.66, 2];

        /**
         * @private
         */
        private static const MAXIMUM_SAVED_VELOCITY_COUNT:int = 4;

        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * Constructor.
         */
        public function Drawers(content:DisplayObject = null)
        {
            this.content = content;
            this.addEventListener(Event.ADDED_TO_STAGE, drawers_addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, drawers_removedFromStageHandler);
            this.addEventListener(TouchEvent.TOUCH, drawers_touchHandler);
        }

        /**
         * The event dispatcher that controls opening and closing drawers with
         * events. Often, the event dispatcher is the content itself, but you
         * may specify a <code>contentEventDispatcherField</code> to access a
         * property of the content instead, or you may specify a
         * <code>contentEventDispatcherFunction</code> to run some more complex
         * code to access the event dispatcher.
         *
         * @see #contentEventDispatcherField
         * @see #contentEventDispatcherFunction
         */
        protected var contentEventDispatcher:EventDispatcher;

        /**
         * @private
         */
        protected var _content:DisplayObject;

        /**
         * The primary content displayed in the center of the container.
         *
         * <p>If the primary content is a container where you'd prefer to listen
         * to events from its children, you may need to use properties like
         * <code>contentEventDispatcherField</code>, <code>contentEventDispatcherFunction</code>,
         * and <code>contentEventDispatcherChangeEventType</code> to ensure that
         * open and close events for drawers are correctly mapped to the correct
         * event dispatcher. If the content is dispatching the events, then those
         * properties should be set to <code>null</code>.</p>
         *
         * <p>In the following example, a <code>ScreenNavigator</code> is added
         * as the content:</p>
         *
         * <listing version="3.0">
         * var navigator:ScreenNavigator = new ScreenNavigator();
         * // additional code to add the screens can go here
         * drawers.content = navigator;</listing>
         *
         * @default null
         *
         * @see #contentEventDispatcherField
         * @see #contentEventDispatcherFunction
         * @see #contentEventDispatcherChangeEventType
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
                if(this._contentEventDispatcherChangeEventType)
                {
                    this._content.removeEventListener(this._contentEventDispatcherChangeEventType, content_eventDispatcherChangeHandler);
                }
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    this._content.removeEventListener(FeathersEventType.RESIZE, content_resizeHandler);
                }
                if(this._content.parent == this)
                {
                    this.removeChild(this._content, false);
                }
            }
            this._content = value;
            if(this._content)
            {
                if(this._content is ScreenNavigator)
                {
                    this.contentEventDispatcherField = SCREEN_NAVIGATOR_CONTENT_EVENT_DISPATCHER_FIELD;
                    this.contentEventDispatcherChangeEventType = Event.CHANGE;
                }
                if(this._contentEventDispatcherChangeEventType)
                {
                    this._content.addEventListener(this._contentEventDispatcherChangeEventType, content_eventDispatcherChangeHandler);
                }
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    this._content.addEventListener(FeathersEventType.RESIZE, content_resizeHandler);
                }
                this.addChild(this._content);
            }
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _topDrawer:DisplayObject;

        /**
         * The drawer that appears above the primary content.
         *
         * <p>In the following example, a <code>List</code> is added as the
         * top drawer:</p>
         *
         * <listing version="3.0">
         * var list:List = new List();
         * // set data provider and other properties here
         * drawers.topDrawer = list;</listing>
         *
         * @default null
         *
         * @see #topDrawerDockMode
         * @see #topDrawerToggleEventType
         */
        public function get topDrawer():DisplayObject
        {
            return this._topDrawer;
        }

        /**
         * @private
         */
        public function set topDrawer(value:DisplayObject):void
        {
            if(this._topDrawer == value)
            {
                return;
            }
            if(this._topDrawer && this._topDrawer.parent == this)
            {
                this.removeChild(this._topDrawer, false);
            }
            this._topDrawer = value;
            if(this._topDrawer)
            {
                this._topDrawer.visible = false;
                this.addChildAt(this._topDrawer, 0);
            }
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _topDrawerDockMode:String = DOCK_MODE_NONE;

        /**
         * Determines if the top drawer is docked in all, some, or no stage
         * orientations. The current stage orientation is determined by
         * calculating the aspect ratio of the stage.
         *
         * <p>In the following example, the top drawer is docked in the
         * landscape stage orientation:</p>
         *
         * <listing version="3.0">
         * drawers.topDrawerDockMode = Drawers.DOCK_MODE_LANDSCAPE;</listing>
         *
         * @default Drawers.DOCK_MODE_NONE
         *
         * @see #topDrawer
         */
        public function get topDrawerDockMode():String
        {
            return this._topDrawerDockMode;
        }

        /**
         * @private
         */
        public function set topDrawerDockMode(value:String):void
        {
            if(this._topDrawerDockMode == value)
            {
                return;
            }
            this._topDrawerDockMode = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _topDrawerToggleEventType:String;

        /**
         * When this event is dispatched by the content event dispatcher, the
         * top drawer will toggle open and closed.
         *
         * <p>In the following example, the top drawer is toggled when the
         * content dispatches an event of type <code>Event.OPEN</code>:</p>
         *
         * <listing version="3.0">
         * drawers.topDrawerToggleEventType = Event.OPEN;</listing>
         *
         * @default null
         *
         * @see #content
         * @see #topDrawer
         */
        public function get topDrawerToggleEventType():String
        {
            return this._topDrawerToggleEventType;
        }

        /**
         * @private
         */
        public function set topDrawerToggleEventType(value:String):void
        {
            if(this._topDrawerToggleEventType == value)
            {
                return;
            }
            this._topDrawerToggleEventType = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _isTopDrawerOpen:Boolean = false;

        /**
         * Indicates if the top drawer is currently open. If you want to check
         * if the top drawer is docked, check <code>isTopDrawerDocked</code>
         * instead.
         *
         * <p>To animate the top drawer open or closed, call
         * <code>toggleTopDrawer()</code>. Setting <code>isTopDrawerOpen</code>
         * will open or close the top drawer without animation.</p>
         *
         * <p>In the following example, we check if the top drawer is open:</p>
         *
         * <listing version="3.0">
         * if( drawers.isTopDrawerOpen )
         * {
         *     // do something
         * }</listing>
         *
         * @default false
         *
         * @see #isTopDrawerDocked
         * @see #topDrawer
         * @see #toggleTopDrawer()
         */
        public function get isTopDrawerOpen():Boolean
        {
            return this._topDrawer && this._isTopDrawerOpen;
        }

        /**
         * @private
         */
        public function set isTopDrawerOpen(value:Boolean):void
        {
            if(this.isTopDrawerDocked || this._isTopDrawerOpen == value)
            {
                return;
            }
            this._isTopDrawerOpen = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Indicates if the top drawer is currently docked. Docking behavior of
         * the top drawer is controlled with the <code>topDrawerDockMode</code>
         * property. To check if the top drawer is open, but not docked, use
         * the <code>isTopDrawerOpen</code> property.
         *
         * @see #topDrawer
         * @see #topDrawerDockMode
         * @see #isTopDrawerOpen
         */
        public function get isTopDrawerDocked():Boolean
        {
            if(!this._topDrawer || !this.stage)
            {
                return false;
            }
            if(this._topDrawerDockMode == DOCK_MODE_BOTH)
            {
                return true;
            }
            if(this._topDrawerDockMode == DOCK_MODE_NONE)
            {
                return false;
            }
            if(this.stage.stageWidth > this.stage.stageHeight)
            {
                return this._topDrawerDockMode == DOCK_MODE_LANDSCAPE;
            }
            return this._topDrawerDockMode == DOCK_MODE_PORTRAIT;
        }

        /**
         * @private
         */
        protected var _rightDrawer:DisplayObject;

        /**
         * The drawer that appears to the right of the primary content.
         *
         * <p>In the following example, a <code>List</code> is added as the
         * right drawer:</p>
         *
         * <listing version="3.0">
         * var list:List = new List();
         * // set data provider and other properties here
         * drawers.rightDrawer = list;</listing>
         *
         * @default null
         *
         * @see #rightDrawerDockMode
         * @see #rightDrawerToggleEventType
         */
        public function get rightDrawer():DisplayObject
        {
            return this._rightDrawer;
        }

        /**
         * @private
         */
        public function set rightDrawer(value:DisplayObject):void
        {
            if(this._rightDrawer == value)
            {
                return;
            }
            if(this._rightDrawer && this._rightDrawer.parent == this)
            {
                this.removeChild(this._rightDrawer, false);
            }
            this._rightDrawer = value;
            if(this._rightDrawer)
            {
                this._rightDrawer.visible = false;
                this.addChildAt(this._rightDrawer, 0);
            }
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _rightDrawerDockMode:String = DOCK_MODE_NONE;

        /**
         * Determines if the right drawer is docked in all, some, or no stage
         * orientations. The current stage orientation is determined by
         * calculating the aspect ratio of the stage.
         *
         * <p>In the following example, the right drawer is docked in the
         * landscape stage orientation:</p>
         *
         * <listing version="3.0">
         * drawers.rightDrawerDockMode = Drawers.DOCK_MODE_LANDSCAPE;</listing>
         *
         * @default Drawers.DOCK_MODE_NONE
         *
         * @see #rightDrawer
         */
        public function get rightDrawerDockMode():String
        {
            return this._rightDrawerDockMode;
        }

        /**
         * @private
         */
        public function set rightDrawerDockMode(value:String):void
        {
            if(this._rightDrawerDockMode == value)
            {
                return;
            }
            this._rightDrawerDockMode = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _rightDrawerToggleEventType:String;

        /**
         * When this event is dispatched by the content event dispatcher, the
         * right drawer will toggle open and closed.
         *
         * <p>In the following example, the right drawer is toggled when the
         * content dispatches an event of type <code>Event.OPEN</code>:</p>
         *
         * <listing version="3.0">
         * drawers.rightDrawerToggleEventType = Event.OPEN;</listing>
         *
         * @default null
         *
         * @see #content
         * @see #rightDrawer
         */
        public function get rightDrawerToggleEventType():String
        {
            return this._rightDrawerToggleEventType;
        }

        /**
         * @private
         */
        public function set rightDrawerToggleEventType(value:String):void
        {
            if(this._rightDrawerToggleEventType == value)
            {
                return;
            }
            this._rightDrawerToggleEventType = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _isRightDrawerOpen:Boolean = false;

        /**
         * Indicates if the right drawer is currently open. If you want to check
         * if the right drawer is docked, check <code>isRightDrawerDocked</code>
         * instead.
         *
         * <p>To animate the right drawer open or closed, call
         * <code>toggleRightDrawer()</code>. Setting <code>isRightDrawerOpen</code>
         * will open or close the right drawer without animation.</p>
         *
         * <p>In the following example, we check if the right drawer is open:</p>
         *
         * <listing version="3.0">
         * if( drawers.isRightDrawerOpen )
         * {
         *     // do something
         * }</listing>
         *
         * @default false
         *
         * @see #rightDrawer
         * @see #rightDrawerDockMode
         * @see #toggleRightDrawer()
         */
        public function get isRightDrawerOpen():Boolean
        {
            return this._rightDrawer && this._isRightDrawerOpen;
        }

        /**
         * @private
         */
        public function set isRightDrawerOpen(value:Boolean):void
        {
            if(this.isRightDrawerDocked || this._isRightDrawerOpen == value)
            {
                return;
            }
            this._isRightDrawerOpen = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Indicates if the right drawer is currently docked. Docking behavior of
         * the right drawer is controlled with the <code>rightDrawerDockMode</code>
         * property. To check if the right drawer is open, but not docked, use
         * the <code>isRightDrawerOpen</code> property.
         *
         * @see #rightDrawer
         * @see #rightDrawerDockMode
         * @see #isRightDrawerOpen
         */
        public function get isRightDrawerDocked():Boolean
        {
            if(!this._rightDrawer || !this.stage)
            {
                return false;
            }
            if(this._rightDrawerDockMode == DOCK_MODE_BOTH)
            {
                return true;
            }
            if(this._rightDrawerDockMode == DOCK_MODE_NONE)
            {
                return false;
            }
            if(this.stage.stageWidth > this.stage.stageHeight)
            {
                return this._rightDrawerDockMode == DOCK_MODE_LANDSCAPE;
            }
            return this._rightDrawerDockMode == DOCK_MODE_PORTRAIT;
        }

        /**
         * @private
         */
        protected var _bottomDrawer:DisplayObject;

        /**
         * The drawer that appears below the primary content.
         *
         * <p>In the following example, a <code>List</code> is added as the
         * bottom drawer:</p>
         *
         * <listing version="3.0">
         * var list:List = new List();
         * // set data provider and other properties here
         * drawers.bottomDrawer = list;</listing>
         *
         * @default null
         *
         * @see #bottomDrawerDockMode
         * @see #bottomDrawerToggleEventType
         */
        public function get bottomDrawer():DisplayObject
        {
            return this._bottomDrawer;
        }

        /**
         * @private
         */
        public function set bottomDrawer(value:DisplayObject):void
        {
            if(this._bottomDrawer == value)
            {
                return;
            }
            if(this._bottomDrawer && this._bottomDrawer.parent == this)
            {
                this.removeChild(this._bottomDrawer, false);
            }
            this._bottomDrawer = value;
            if(this._bottomDrawer)
            {
                this._bottomDrawer.visible = false;
                this.addChildAt(this._bottomDrawer, 0);
            }
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _bottomDrawerDockMode:String = DOCK_MODE_NONE;

        /**
         * Determines if the bottom drawer is docked in all, some, or no stage
         * orientations. The current stage orientation is determined by
         * calculating the aspect ratio of the stage.
         *
         * <p>In the following example, the bottom drawer is docked in the
         * landscape stage orientation:</p>
         *
         * <listing version="3.0">
         * drawers.bottomDrawerDockMode = Drawers.DOCK_MODE_LANDSCAPE;</listing>
         *
         * @default Drawers.DOCK_MODE_NONE
         *
         * @see #bottomDrawer
         */
        public function get bottomDrawerDockMode():String
        {
            return this._bottomDrawerDockMode;
        }

        /**
         * @private
         */
        public function set bottomDrawerDockMode(value:String):void
        {
            if(this._bottomDrawerDockMode == value)
            {
                return;
            }
            this._bottomDrawerDockMode = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _bottomDrawerToggleEventType:String;

        /**
         * When this event is dispatched by the content event dispatcher, the
         * bottom drawer will toggle open and closed.
         *
         * <p>In the following example, the bottom drawer is toggled when the
         * content dispatches an event of type <code>Event.OPEN</code>:</p>
         *
         * <listing version="3.0">
         * drawers.bottomDrawerToggleEventType = Event.OPEN;</listing>
         *
         * @default null
         *
         * @see #content
         * @see #bottomDrawer
         */
        public function get bottomDrawerToggleEventType():String
        {
            return this._bottomDrawerToggleEventType;
        }

        /**
         * @private
         */
        public function set bottomDrawerToggleEventType(value:String):void
        {
            if(this._bottomDrawerToggleEventType == value)
            {
                return;
            }
            this._bottomDrawerToggleEventType = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _isBottomDrawerOpen:Boolean = false;

        /**
         * Indicates if the bottom drawer is currently open. If you want to check
         * if the bottom drawer is docked, check <code>isBottomDrawerDocked</code>
         * instead.
         *
         * <p>To animate the bottom drawer open or closed, call
         * <code>toggleBottomDrawer()</code>. Setting <code>isBottomDrawerOpen</code>
         * will open or close the bottom drawer without animation.</p>
         *
         * <p>In the following example, we check if the bottom drawer is open:</p>
         *
         * <listing version="3.0">
         * if( drawers.isBottomDrawerOpen )
         * {
         *     // do something
         * }</listing>
         *
         * @default false
         *
         * @see #bottomDrawer
         * @see #isBottomDrawerOpen
         * @see #toggleBottomDrawer()
         */
        public function get isBottomDrawerOpen():Boolean
        {
            return this._bottomDrawer && this._isBottomDrawerOpen;
        }

        /**
         * @private
         */
        public function set isBottomDrawerOpen(value:Boolean):void
        {
            if(this.isBottomDrawerDocked || this._isBottomDrawerOpen == value)
            {
                return;
            }
            this._isBottomDrawerOpen = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Indicates if the bottom drawer is currently docked. Docking behavior of
         * the bottom drawer is controlled with the <code>bottomDrawerDockMode</code>
         * property. To check if the bottom drawer is open, but not docked, use
         * the <code>isBottomDrawerOpen</code> property.
         *
         * @see #bottomDrawer
         * @see #bottomDrawerDockMode
         * @see #isBottomDrawerOpen
         */
        public function get isBottomDrawerDocked():Boolean
        {
            if(!this._bottomDrawer || !this.stage)
            {
                return false;
            }
            if(this._bottomDrawerDockMode == DOCK_MODE_BOTH)
            {
                return true;
            }
            if(this._bottomDrawerDockMode == DOCK_MODE_NONE)
            {
                return false;
            }
            if(this.stage.stageWidth > this.stage.stageHeight)
            {
                return this._bottomDrawerDockMode == DOCK_MODE_LANDSCAPE;
            }
            return this._bottomDrawerDockMode == DOCK_MODE_PORTRAIT;
        }

        /**
         * @private
         */
        protected var _leftDrawer:DisplayObject;

        /**
         * The drawer that appears below the primary content.
         *
         * <p>In the following example, a <code>List</code> is added as the
         * left drawer:</p>
         *
         * <listing version="3.0">
         * var list:List = new List();
         * // set data provider and other properties here
         * drawers.leftDrawer = list;</listing>
         *
         * @default null
         *
         * @see #leftDrawerDockMode
         * @see #leftDrawerToggleEventType
         */
        public function get leftDrawer():DisplayObject
        {
            return this._leftDrawer;
        }

        /**
         * @private
         */
        public function set leftDrawer(value:DisplayObject):void
        {
            if(this._leftDrawer == value)
            {
                return;
            }
            if(this._leftDrawer && this._leftDrawer.parent == this)
            {
                this.removeChild(this._leftDrawer, false);
            }
            this._leftDrawer = value;
            if(this._leftDrawer)
            {
                this._leftDrawer.visible = false;
                this.addChildAt(this._leftDrawer, 0);
            }
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _leftDrawerDockMode:String = DOCK_MODE_NONE;

        /**
         * Determines if the left drawer is docked in all, some, or no stage
         * orientations. The current stage orientation is determined by
         * calculating the aspect ratio of the stage.
         *
         * <p>In the following example, the left drawer is docked in the
         * landscape stage orientation:</p>
         *
         * <listing version="3.0">
         * drawers.leftDrawerDockMode = Drawers.DOCK_MODE_LANDSCAPE;</listing>
         *
         * @default Drawers.DOCK_MODE_NONE
         *
         * @see #leftDrawer
         */
        public function get leftDrawerDockMode():String
        {
            return this._leftDrawerDockMode;
        }

        /**
         * @private
         */
        public function set leftDrawerDockMode(value:String):void
        {
            if(this._leftDrawerDockMode == value)
            {
                return;
            }
            this._leftDrawerDockMode = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _leftDrawerToggleEventType:String;

        /**
         * When this event is dispatched by the content event dispatcher, the
         * left drawer will toggle open and closed.
         *
         * <p>In the following example, the left drawer is toggled when the
         * content dispatches and event of type <code>Event.OPEN</code>:</p>
         *
         * <listing version="3.0">
         * drawers.leftDrawerToggleEventType = Event.OPEN;</listing>
         *
         * @default null
         *
         * @see #content
         * @see #leftDrawer
         */
        public function get leftDrawerToggleEventType():String
        {
            return this._leftDrawerToggleEventType;
        }

        /**
         * @private
         */
        public function set leftDrawerToggleEventType(value:String):void
        {
            if(this._leftDrawerToggleEventType == value)
            {
                return;
            }
            this._leftDrawerToggleEventType = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _isLeftDrawerOpen:Boolean = false;

        /**
         * Indicates if the left drawer is currently open. If you want to check
         * if the left drawer is docked, check <code>isLeftDrawerDocked</code>
         * instead.
         *
         * <p>To animate the left drawer open or closed, call
         * <code>toggleLeftDrawer()</code>. Setting <code>isLeftDrawerOpen</code>
         * will open or close the left drawer without animation.</p>
         *
         * <p>In the following example, we check if the left drawer is open:</p>
         *
         * <listing version="3.0">
         * if( drawers.isLeftDrawerOpen )
         * {
         *     // do something
         * }</listing>
         *
         * @default false
         *
         * @see #leftDrawer
         * @see #isLeftDrawerDocked
         * @see #toggleLeftDrawer()
         */
        public function get isLeftDrawerOpen():Boolean
        {
            return this._leftDrawer && this._isLeftDrawerOpen;
        }

        /**
         * @private
         */
        public function set isLeftDrawerOpen(value:Boolean):void
        {
            if(this.isLeftDrawerDocked || this._isLeftDrawerOpen == value)
            {
                return;
            }
            this._isLeftDrawerOpen = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Indicates if the left drawer is currently docked. Docking behavior of
         * the left drawer is controlled with the <code>leftDrawerDockMode</code>
         * property. To check if the left drawer is open, but not docked, use
         * the <code>isLeftDrawerOpen</code> property.
         *
         * @see #leftDrawer
         * @see #leftDrawerDockMode
         * @see #isLeftDrawerOpen
         */
        public function get isLeftDrawerDocked():Boolean
        {
            if(!this._leftDrawer || !this.stage)
            {
                return false;
            }
            if(this._leftDrawerDockMode == DOCK_MODE_BOTH)
            {
                return true;
            }
            if(this._leftDrawerDockMode == DOCK_MODE_NONE)
            {
                return false;
            }
            if(this.stage.stageWidth > this.stage.stageHeight)
            {
                return this._leftDrawerDockMode == DOCK_MODE_LANDSCAPE;
            }
            return this._leftDrawerDockMode == DOCK_MODE_PORTRAIT;
        }

        /**
         * @private
         */
        protected var _autoSizeMode:String = AUTO_SIZE_MODE_STAGE;

        [Inspectable(type="String",enumeration="stage,content")]
        /**
         * Determines how the drawers container will set its own size when its
         * dimensions (width and height) aren't set explicitly.
         *
         * <p>In the following example, the drawers container will be sized to
         * match its content:</p>
         *
         * <listing version="3.0">
         * drawers.autoSizeMode = Drawers.AUTO_SIZE_MODE_CONTENT;</listing>
         *
         * @default Drawers.AUTO_SIZE_MODE_STAGE
         *
         * @see #AUTO_SIZE_MODE_STAGE
         * @see #AUTO_SIZE_MODE_CONTENT
         */
        public function get autoSizeMode():String
        {
            return this._autoSizeMode;
        }

        /**
         * @private
         */
        public function set autoSizeMode(value:String):void
        {
            if(this._autoSizeMode == value)
            {
                return;
            }
            this._autoSizeMode = value;
            if(this._content)
            {
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    this._content.addEventListener(FeathersEventType.RESIZE, content_resizeHandler);
                }
                else
                {
                    this._content.removeEventListener(FeathersEventType.RESIZE, content_resizeHandler);
                }
            }
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _clipDrawers:Boolean = true;

        /**
         * Determines if the drawers are clipped while opening or closing. If
         * the content does not have a background, the drawers should
         * generally be clipped so that the drawer does not show under the
         * content. If the content has a fully opaque background that will
         * conceal the drawers, then clipping may be disabled to potentially
         * improve performance.
         *
         * <p>In the following example, clipping will be disabled:</p>
         *
         * <listing version="3.0">
         * navigator.clipDrawers = false;</listing>
         *
         * @default true
         *
         * @see #topDrawer
         * @see #rightDrawer
         * @see #bottomDrawer
         * @see #leftDrawer
         */
        public function get clipDrawers():Boolean
        {
            return this._clipDrawers;
        }

        /**
         * @private
         */
        public function set clipDrawers(value:Boolean):void
        {
            if(this._clipDrawers == value)
            {
                return;
            }
            this._clipDrawers = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _openGesture:String = OPEN_GESTURE_DRAG_CONTENT_EDGE;

        /**
         * An optional touch gesture used to open a drawer.
         *
         * <p>In the following example, the drawers are opened by dragging
         * anywhere inside the content:</p>
         *
         * <listing version="3.0">
         * drawers.openGesture = Drawers.OPEN_GESTURE_DRAG_CONTENT;</listing>
         *
         * @default Drawers.OPEN_GESTURE_DRAG_CONTENT_EDGE
         *
         * @see #OPEN_GESTURE_NONE
         * @see #OPEN_GESTURE_DRAG_CONTENT
         * @see #OPEN_GESTURE_DRAG_CONTENT_EDGE
         */
        public function get openGesture():String
        {
            return this._openGesture;
        }

        /**
         * @private
         */
        public function set openGesture(value:String):void
        {
            this._openGesture = value;
        }

        /**
         * @private
         */
        protected var _minimumDragDistance:Number = 0.04;

        /**
         * The minimum physical distance (in inches) that a touch must move
         * before a drag gesture begins.
         *
         * <p>In the following example, the minimum drag distance is customized:</p>
         *
         * <listing version="3.0">
         * scroller.minimumDragDistance = 0.1;</listing>
         *
         * @default 0.04
         */
        public function get minimumDragDistance():Number
        {
            return this._minimumDragDistance;
        }

        /**
         * @private
         */
        public function set minimumDragDistance(value:Number):void
        {
            this._minimumDragDistance = value;
        }

        /**
         * @private
         */
        protected var _minimumDrawerThrowVelocity:Number = 5;

        /**
         * The minimum physical velocity (in inches per second) that a touch
         * must move before the a drawern can be "thrown" to open or close it.
         * Otherwise, it will settle open or closed based on which state is
         * closer when the touch ends.
         *
         * <p>In the following example, the minimum drawer throw velocity is customized:</p>
         *
         * <listing version="3.0">
         * scroller.minimumDrawerThrowVelocity = 2;</listing>
         *
         * @default 5
         */
        public function get minimumDrawerThrowVelocity():Number
        {
            return this._minimumDrawerThrowVelocity;
        }

        /**
         * @private
         */
        public function set minimumDrawerThrowVelocity(value:Number):void
        {
            this._minimumDrawerThrowVelocity = value;
        }

        /**
         * @private
         */
        protected var _openGestureEdgeSize:Number = 0.1;

        /**
         * The minimum physical distance (in inches) that a touch must move
         * before a drag gesture begins.
         *
         * <p>In the following example, the open gesture edge size customized:</p>
         *
         * <listing version="3.0">
         * scroller.openGestureEdgeSize = 0.25;</listing>
         *
         * @default 0.1
         */
        public function get openGestureEdgeSize():Number
        {
            return this._openGestureEdgeSize;
        }

        /**
         * @private
         */
        public function set openGestureEdgeSize(value:Number):void
        {
            this._openGestureEdgeSize = value;
        }

        /**
         * @private
         */
        protected var _contentEventDispatcherChangeEventType:String;

        /**
         * The event dispatched by the content to indicate that the content
         * event dispatcher has changed. When this event is dispatched by the
         * content, the drawers container will listen for the drawer toggle
         * events from the new dispatcher that discovered using
         * <code>contentEventDispatcherField</code> or
         * <code>contentEventDispatcherFunction</code>.
         *
         * <p>For a <code>ScreenNavigator</code> component, this value is
         * automatically set to <code>Event.CHANGE</code>.</p>
         *
         * <p>In the following example, the drawers container will update its
         * content event dispatcher when the content dispatches an event of type
         * <code>Event.CHANGE</code>:</p>
         *
         * <listing version="3.0">
         * drawers.contentEventDispatcherChangeEventType = Event.CHANGE;</listing>
         *
         * @default null
         *
         * @see #contentEventDispatcherField
         * @see #contentEventDispatcherFunction
         */
        public function get contentEventDispatcherChangeEventType():String
        {
            return this._contentEventDispatcherChangeEventType;
        }

        /**
         * @private
         */
        public function set contentEventDispatcherChangeEventType(value:String):void
        {
            if(this._contentEventDispatcherChangeEventType == value)
            {
                return;
            }
            if(this._content && this._contentEventDispatcherChangeEventType)
            {
                this._content.removeEventListener(this._contentEventDispatcherChangeEventType, content_eventDispatcherChangeHandler);
            }
            this._contentEventDispatcherChangeEventType = value;
            if(this._content && this._contentEventDispatcherChangeEventType)
            {
                this._content.addEventListener(this._contentEventDispatcherChangeEventType, content_eventDispatcherChangeHandler);
            }
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _contentEventDispatcherField:String;

        /**
         * A property of the <code>content</code> that references an event
         * dispatcher that dispatches events to toggle drawers open and closed.
         *
         * <p>For a <code>ScreenNavigator</code> component, this value is
         * automatically set to <code>"activeScreen"</code> to listen for events
         * from the currently active/visible screen.</p>
         *
         * <p>In the following example, the content event dispatcher field is
         * customized:</p>
         *
         * <listing version="3.0">
         * drawers.contentEventDispatcherField = "selectedChild";</listing>
         *
         * @default null
         *
         * @see #contentEventDispatcherFunction
         * @see #contentEventDispatcherChangeEventType
         * @see #topDrawerToggleEventType
         * @see #rightDrawerToggleEventType
         * @see #bottomDrawerToggleEventType
         * @see #leftDrawerToggleEventType
         */
        public function get contentEventDispatcherField():String
        {
            return this._contentEventDispatcherField;
        }

        /**
         * @private
         */
        public function set contentEventDispatcherField(value:String):void
        {
            if(this._contentEventDispatcherField == value)
            {
                return;
            }
            this._contentEventDispatcherField = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _contentEventDispatcherFunction:Function;

        /**
         * A function that returns an event dispatcher that dispatches events to
         * toggle drawers open and closed.
         *
         * <p>The function is expected to have the following signature:</p>
         *
         * <pre>function( content:DisplayObject ):EventDispatcher</pre>
         *
         * <p>In the following example, the content event dispatcher function is
         * customized:</p>
         *
         * <listing version="3.0">
         * drawers.contentEventDispatcherField = function( content:CustomView ):void
         * {
         *     return content.selectedChild;
         * };</listing>
         *
         * @default null
         *
         * @see #contentEventDispatcherField
         * @see #contentEventDispatcherChangeEventType
         * @see #topDrawerToggleEventType
         * @see #rightDrawerToggleEventType
         * @see #bottomDrawerToggleEventType
         * @see #leftDrawerToggleEventType
         */
        public function get contentEventDispatcherFunction():Function
        {
            return this._contentEventDispatcherFunction;
        }

        /**
         * @private
         */
        public function set contentEventDispatcherFunction(value:Function):void
        {
            if(this._contentEventDispatcherFunction == value)
            {
                return;
            }
            this._contentEventDispatcherFunction = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _openOrCloseTween:Tween;

        /**
         * @private
         */
        protected var _openOrCloseDuration:Number = 0.25;

        /**
         * The duration, in seconds, of the animation when a drawer opens or
         * closes.
         *
         * <p>In the following example, the duration of the animation that opens
         * or closes a drawer is set to 500 milliseconds:</p>
         *
         * <listing version="3.0">
         * scroller.openOrCloseDuration = 0.5;</listing>
         *
         * @default 0.25
         *
         * @see #openOrCloseEase
         */
        public function get openOrCloseDuration():Number
        {
            return this._openOrCloseDuration;
        }

        /**
         * @private
         */
        public function set openOrCloseDuration(value:Number):void
        {
            this._openOrCloseDuration = value;
        }

        /**
         * @private
         */
        protected var _openOrCloseEase:Object = Transitions.EASE_OUT;

        /**
         * The easing function used for opening or closing the drawers.
         *
         * <p>In the following example, the ease of the animation that opens and
         * closes a drawer is customized:</p>
         *
         * <listing version="3.0">
         * drawrs.openOrCloseEase = Transitions.EASE_IN_OUT;</listing>
         *
         * @default starling.animation.Transitions.EASE_OUT
         *
         * @see starling.animation.Transitions
         * @see #openOrCloseDuration
         */
        public function get openOrCloseEase():Object
        {
            return this._openOrCloseEase;
        }

        /**
         * @private
         */
        public function set openOrCloseEase(value:Object):void
        {
            this._openOrCloseEase = value;
        }

        /**
         * @private
         */
        protected var isToggleTopDrawerPending:Boolean = false;

        /**
         * @private
         */
        protected var isToggleRightDrawerPending:Boolean = false;

        /**
         * @private
         */
        protected var isToggleBottomDrawerPending:Boolean = false;

        /**
         * @private
         */
        protected var isToggleLeftDrawerPending:Boolean = false;

        /**
         * @private
         */
        protected var pendingToggleDuration:Number;

        /**
         * @private
         */
        protected var touchPointID:int = -1;

        /**
         * @private
         */
        protected var _isDragging:Boolean = false;

        /**
         * @private
         */
        protected var _isDraggingTopDrawer:Boolean = false;

        /**
         * @private
         */
        protected var _isDraggingRightDrawer:Boolean = false;

        /**
         * @private
         */
        protected var _isDraggingBottomDrawer:Boolean = false;

        /**
         * @private
         */
        protected var _isDraggingLeftDrawer:Boolean = false;

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
        override public function hitTest(localPoint:Point, forTouch:Boolean = false):DisplayObject
        {
            var result:DisplayObject = super.hitTest(localPoint, forTouch);
            if(result)
            {
                if(!forTouch)
                {
                    return result;
                }
                if(this._isDragging)
                {
                    return this;
                }
                if(this.isTopDrawerOpen && result != this._topDrawer && !(this._topDrawer is DisplayObjectContainer && DisplayObjectContainer(this._topDrawer).contains(result)))
                {
                    return this;
                }
                else if(this.isRightDrawerOpen && result != this._rightDrawer && !(this._rightDrawer is DisplayObjectContainer && DisplayObjectContainer(this._rightDrawer).contains(result)))
                {
                    return this;
                }
                else if(this.isBottomDrawerOpen && result != this._bottomDrawer && !(this._bottomDrawer is DisplayObjectContainer && DisplayObjectContainer(this._bottomDrawer).contains(result)))
                {
                    return this;
                }
                else if(this.isLeftDrawerOpen && result != this._leftDrawer && !(this._leftDrawer is DisplayObjectContainer && DisplayObjectContainer(this._leftDrawer).contains(result)))
                {
                    return this;
                }
                return result;
            }
            //we want to register touches in our hitArea as a last resort
            if(forTouch && (!this.visible || !this.touchable))
            {
                return null;
            }
            return this._hitArea.contains(localPoint.x, localPoint.y) ? this : null;
        }

        /**
         * Opens or closes the top drawer. If the <code>duration</code> argument
         * is <code>NaN</code>, the default <code>openOrCloseDuration</code> is
         * used. The default value of the <code>duration</code> argument is
         * <code>NaN</code>. Otherwise, this value is the duration of the
         * animation, in seconds.
         *
         * <p>To open or close the top drawer without animation, set the
         * <code>isTopDrawerOpen</code> property.</p>
         *
         * @see #isTopDrawerOpen
         * @see #openOrCloseDuration
         * @see #openOrCloseEase
         */
        public function toggleTopDrawer(duration:Number = NaN):void
        {
            if(!this._topDrawer || this.isToggleTopDrawerPending || this.isTopDrawerDocked)
            {
                return;
            }
            this.isToggleTopDrawerPending = true;
            this.isToggleRightDrawerPending = false;
            this.isToggleBottomDrawerPending = false;
            this.isToggleLeftDrawerPending = false;
            this.pendingToggleDuration = duration;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Opens or closes the right drawer. If the <code>duration</code> argument
         * is <code>NaN</code>, the default <code>openOrCloseDuration</code> is
         * used. The default value of the <code>duration</code> argument is
         * <code>NaN</code>. Otherwise, this value is the duration of the
         * animation, in seconds.
         *
         * <p>To open or close the right drawer without animation, set the
         * <code>isRightDrawerOpen</code> property.</p>
         *
         * @see #isRightDrawerOpen
         * @see #openOrCloseDuration
         * @see #openOrCloseEase
         */
        public function toggleRightDrawer(duration:Number = NaN):void
        {
            if(!this._rightDrawer || this.isToggleRightDrawerPending || this.isRightDrawerDocked)
            {
                return;
            }
            this.isToggleTopDrawerPending = false;
            this.isToggleRightDrawerPending = true;
            this.isToggleBottomDrawerPending = false;
            this.isToggleLeftDrawerPending = false;
            this.pendingToggleDuration = duration;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Opens or closes the bottom drawer. If the <code>duration</code> argument
         * is <code>NaN</code>, the default <code>openOrCloseDuration</code> is
         * used. The default value of the <code>duration</code> argument is
         * <code>NaN</code>. Otherwise, this value is the duration of the
         * animation, in seconds.
         *
         * <p>To open or close the bottom drawer without animation, set the
         * <code>isBottomDrawerOpen</code> property.</p>
         *
         * @see #isBottomDrawerOpen
         * @see #openOrCloseDuration
         * @see #openOrCloseEase
         */
        public function toggleBottomDrawer(duration:Number = NaN):void
        {
            if(!this._bottomDrawer || this.isToggleBottomDrawerPending || this.isBottomDrawerDocked)
            {
                return;
            }
            this.isToggleTopDrawerPending = false;
            this.isToggleRightDrawerPending = false;
            this.isToggleBottomDrawerPending = true;
            this.isToggleLeftDrawerPending = false;
            this.pendingToggleDuration = duration;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Opens or closes the left drawer. If the <code>duration</code> argument
         * is <code>NaN</code>, the default <code>openOrCloseDuration</code> is
         * used. The default value of the <code>duration</code> argument is
         * <code>NaN</code>. Otherwise, this value is the duration of the
         * animation, in seconds.
         *
         * <p>To open or close the left drawer without animation, set the
         * <code>isLeftDrawerOpen</code> property.</p>
         *
         * @see #isLeftDrawerOpen
         * @see #openOrCloseDuration
         * @see #openOrCloseEase
         */
        public function toggleLeftDrawer(duration:Number = NaN):void
        {
            if(!this._leftDrawer || this.isToggleLeftDrawerPending || this.isLeftDrawerDocked)
            {
                return;
            }
            this.isToggleTopDrawerPending = false;
            this.isToggleRightDrawerPending = false;
            this.isToggleBottomDrawerPending = false;
            this.isToggleLeftDrawerPending = true;
            this.pendingToggleDuration = duration;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            var dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            var layoutInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_LAYOUT);

            if(dataInvalid)
            {
                this.refreshCurrentEventTarget();
            }

            if(sizeInvalid || layoutInvalid)
            {
                this.refreshDrawerStates();
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            this.layoutChildren();

            this.handlePendingActions();
        }

        /**
         * If the component's dimensions have not been set explicitly, it will
         * measure its content and determine an ideal size for itself. If the
         * <code>explicitWidth</code> or <code>explicitHeight</code> member
         * variables are set, those value will be used without additional
         * measurement. If one is set, but not the other, the dimension with the
         * explicit value will not be measured, but the other non-explicit
         * dimension will still need measurement.
         *
         * <p>Calls <code>setSizeInternal()</code> to set up the
         * <code>actualWidth</code> and <code>actualHeight</code> member
         * variables used for layout.</p>
         *
         * <p>Meant for internal use, and subclasses may override this function
         * with a custom implementation.</p>
         */
        protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }

            if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT &&
                this._content is IFeathersControl)
            {
                IFeathersControl(this._content).validate();
                var isTopDrawerDocked:Boolean = this.isTopDrawerDocked;
                if(isTopDrawerDocked && this._topDrawer is IFeathersControl)
                {
                    IFeathersControl(this._topDrawer).validate();
                }
                var isRightDrawerDocked:Boolean = this.isRightDrawerDocked;
                if(isRightDrawerDocked && this._rightDrawer is IFeathersControl)
                {
                    IFeathersControl(this._rightDrawer).validate();
                }
                var isBottomDrawerDocked:Boolean = this.isBottomDrawerDocked;
                if(isBottomDrawerDocked && this._bottomDrawer is IFeathersControl)
                {
                    IFeathersControl(this._bottomDrawer).validate();
                }
                var isLeftDrawerDocked:Boolean = this.isLeftDrawerDocked;
                if(isLeftDrawerDocked && this._leftDrawer is IFeathersControl)
                {
                    IFeathersControl(this._leftDrawer).validate();
                }
            }

            var newWidth:Number = this.explicitWidth;
            if(needsWidth)
            {
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    newWidth = this._content ? this._content.width : 0;
                    if(isLeftDrawerDocked)
                    {
                        newWidth += this._leftDrawer.width;
                    }
                    if(isRightDrawerDocked)
                    {
                        newWidth += this._rightDrawer.width;
                    }
                }
                else
                {
                    newWidth = this.stage.stageWidth;
                }
            }

            var newHeight:Number = this.explicitHeight;
            if(needsHeight)
            {
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    newHeight = this._content ? this._content.height : 0;
                    if(isTopDrawerDocked)
                    {
                        newHeight += this._topDrawer.width;
                    }
                    if(isBottomDrawerDocked)
                    {
                        newHeight += this._bottomDrawer.width;
                    }
                }
                else
                {
                    newHeight = this.stage.stageHeight;
                }
            }

            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * Positions and sizes the children.
         */
        protected function layoutChildren():void
        {
            if(this._topDrawer is IFeathersControl)
            {
                IFeathersControl(this._topDrawer).validate();
            }
            if(this._rightDrawer is IFeathersControl)
            {
                IFeathersControl(this._rightDrawer).validate();
            }
            if(this._bottomDrawer is IFeathersControl)
            {
                IFeathersControl(this._bottomDrawer).validate();
            }
            if(this._leftDrawer is IFeathersControl)
            {
                IFeathersControl(this._leftDrawer).validate();
            }
            var isTopDrawerOpen:Boolean = this.isTopDrawerOpen;
            var isRightDrawerOpen:Boolean = this.isRightDrawerOpen;
            var isBottomDrawerOpen:Boolean = this.isBottomDrawerOpen;
            var isLeftDrawerOpen:Boolean = this.isLeftDrawerOpen;
            var isTopDrawerDocked:Boolean = this.isTopDrawerDocked;
            var isRightDrawerDocked:Boolean = this.isRightDrawerDocked;
            var isBottomDrawerDocked:Boolean = this.isBottomDrawerDocked;
            var isLeftDrawerDocked:Boolean = this.isLeftDrawerDocked;
            var topDrawerHeight:Number = this._topDrawer ? this._topDrawer.height : 0;
            var rightDrawerWidth:Number = this._rightDrawer ? this._rightDrawer.width : 0;
            var bottomDrawerHeight:Number = this._bottomDrawer ? this._bottomDrawer.height : 0;
            var leftDrawerWidth:Number = this._leftDrawer ? this._leftDrawer.width : 0;

            var contentWidth:Number = this.actualWidth;
            if(isLeftDrawerDocked)
            {
                contentWidth -= leftDrawerWidth;
            }
            if(isRightDrawerDocked)
            {
                contentWidth -= rightDrawerWidth;
            }
            var contentHeight:Number = this.actualHeight;
            if(isTopDrawerDocked)
            {
                contentHeight -= topDrawerHeight;
            }
            if(isBottomDrawerDocked)
            {
                contentHeight -= bottomDrawerHeight;
            }

            if(isRightDrawerOpen)
            {
                var contentX:Number = -rightDrawerWidth;
                if(isLeftDrawerDocked)
                {
                    contentX += leftDrawerWidth;
                }
                this._content.x = contentX;
            }
            else if(isLeftDrawerOpen || isLeftDrawerDocked)
            {
                this._content.x = leftDrawerWidth;
            }
            else
            {
                this._content.x = 0;
            }
            if(isBottomDrawerOpen)
            {
                var contentY:Number = -bottomDrawerHeight;
                if(isTopDrawerDocked)
                {
                    contentY += topDrawerHeight;
                }
                this._content.y = contentY;
            }
            else if(isTopDrawerOpen || isTopDrawerDocked)
            {
                this._content.y = topDrawerHeight;
            }
            else
            {
                this._content.y = 0;
            }
            if(this._autoSizeMode != AUTO_SIZE_MODE_CONTENT)
            {
                this._content.width = contentWidth;
                this._content.height = contentHeight;

                //final validation to avoid juggler next frame issues
                if(this._content is IFeathersControl)
                {
                    IFeathersControl(this._content).validate();
                }
            }

            if(this._topDrawer)
            {
                var topDrawerX:Number = 0;
                var topDrawerY:Number = 0;
                if(isTopDrawerDocked)
                {
                    if(isBottomDrawerOpen)
                    {
                        topDrawerY -= bottomDrawerHeight;
                    }
                    if(!isLeftDrawerDocked)
                    {
                        topDrawerX = this._content.x;
                    }
                }
                this._topDrawer.x = topDrawerX;
                this._topDrawer.y = topDrawerY;
                this._topDrawer.width = this.actualWidth;
                this._topDrawer.visible = isTopDrawerOpen || isTopDrawerDocked;

                //final validation to avoid juggler next frame issues
                if(this._topDrawer is IFeathersControl)
                {
                    IFeathersControl(this._topDrawer).validate();
                }
            }

            if(this._rightDrawer)
            {
                var rightDrawerX:Number = this.actualWidth - rightDrawerWidth;
                var rightDrawerY:Number = 0;
                var rightDrawerHeight:Number = this.actualHeight;
                if(isRightDrawerDocked)
                {
                    rightDrawerX = this._content.x + this._content.width;
                    if(isTopDrawerDocked)
                    {
                        rightDrawerHeight -= topDrawerHeight;
                    }
                    if(isBottomDrawerDocked)
                    {
                        rightDrawerHeight -= bottomDrawerHeight;
                    }
                    rightDrawerY = this._content.y;
                }
                this._rightDrawer.x = rightDrawerX;
                this._rightDrawer.y = rightDrawerY;
                this._rightDrawer.height = rightDrawerHeight;
                this._rightDrawer.visible = isRightDrawerOpen || isRightDrawerDocked;

                //final validation to avoid juggler next frame issues
                if(this._rightDrawer is IFeathersControl)
                {
                    IFeathersControl(this._rightDrawer).validate();
                }
            }

            if(this._bottomDrawer)
            {
                var bottomDrawerX:Number = 0;
                var bottomDrawerY:Number = this.actualHeight - bottomDrawerHeight;
                if(isBottomDrawerDocked)
                {
                    if(!isLeftDrawerDocked)
                    {
                        bottomDrawerX = this._content.x;
                    }
                    bottomDrawerY = this._content.y + this._content.height;
                }
                this._bottomDrawer.x = bottomDrawerX;
                this._bottomDrawer.y = bottomDrawerY;
                this._bottomDrawer.width = this.actualWidth;
                this._bottomDrawer.visible = isBottomDrawerOpen || isBottomDrawerDocked;

                //final validation to avoid juggler next frame issues
                if(this._bottomDrawer is IFeathersControl)
                {
                    IFeathersControl(this._bottomDrawer).validate();
                }
            }

            if(this._leftDrawer)
            {
                var leftDrawerX:Number = 0;
                var leftDrawerY:Number = 0;
                var leftDrawerHeight:Number = this.actualHeight;
                if(isLeftDrawerDocked)
                {
                    if(isRightDrawerOpen)
                    {
                        leftDrawerX -= rightDrawerWidth;
                    }
                    if(isTopDrawerDocked)
                    {
                        leftDrawerHeight -= topDrawerHeight;
                    }
                    if(isBottomDrawerDocked)
                    {
                        leftDrawerHeight -= bottomDrawerHeight;
                    }
                    leftDrawerY = this._content.y;
                }
                this._leftDrawer.x = leftDrawerX;
                this._leftDrawer.y = leftDrawerY;
                this._leftDrawer.height = leftDrawerHeight;
                this._leftDrawer.visible = isLeftDrawerOpen || isLeftDrawerDocked;

                //final validation to avoid juggler next frame issues
                if(this._leftDrawer is IFeathersControl)
                {
                    IFeathersControl(this._leftDrawer).validate();
                }
            }
        }

        /**
         * @private
         */
        protected function handlePendingActions():void
        {
            if(this.isToggleTopDrawerPending)
            {
                this._isTopDrawerOpen = !this._isTopDrawerOpen;
                this.isToggleTopDrawerPending = false;
                this.openOrCloseTopDrawer();
            }
            else if(this.isToggleRightDrawerPending)
            {
                this._isRightDrawerOpen = !this._isRightDrawerOpen;
                this.isToggleRightDrawerPending = false;
                this.openOrCloseRightDrawer();
            }
            else if(this.isToggleBottomDrawerPending)
            {
                this._isBottomDrawerOpen = !this._isBottomDrawerOpen;
                this.isToggleBottomDrawerPending = false;
                this.openOrCloseBottomDrawer();
            }
            else if(this.isToggleLeftDrawerPending)
            {
                this._isLeftDrawerOpen = !this._isLeftDrawerOpen;
                this.isToggleLeftDrawerPending = false;
                this.openOrCloseLeftDrawer();
            }
        }

        /**
         * @private
         */
        protected function openOrCloseTopDrawer():void
        {
            if(!this._topDrawer || this.isTopDrawerDocked)
            {
                return;
            }
            if(this._openOrCloseTween)
            {
                this._openOrCloseTween.advanceTime(this._openOrCloseTween.totalTime);
                Loom2D.juggler.remove(this._openOrCloseTween);
                this._openOrCloseTween = null;
            }
            this.applyTopClipRect();
            this._topDrawer.visible = true;
            var targetPosition:Number = this._isTopDrawerOpen ? this._topDrawer.height : 0;
            this._openOrCloseTween = new Tween(this._content, this._openOrCloseDuration, this._openOrCloseEase);
            this._openOrCloseTween.animate("y", targetPosition);
            this._openOrCloseTween.onUpdate = openOrCloseTween_onUpdate;
            this._openOrCloseTween.onComplete = openOrCloseTween_onComplete;
            Loom2D.juggler.add(this._openOrCloseTween);
        }

        /**
         * @private
         */
        protected function openOrCloseRightDrawer():void
        {
            if(!this._rightDrawer || this.isRightDrawerDocked)
            {
                return;
            }
            if(this._openOrCloseTween)
            {
                this._openOrCloseTween.advanceTime(this._openOrCloseTween.totalTime);
                Loom2D.juggler.remove(this._openOrCloseTween);
                this._openOrCloseTween = null;
            }
            this.applyRightClipRect();
            this._rightDrawer.visible = true;
            var targetPosition:Number = 0;
            if(this._isRightDrawerOpen)
            {
                targetPosition = -this._rightDrawer.width;
            }
            if(this.isLeftDrawerDocked)
            {
                targetPosition += this._leftDrawer.width;
            }
            this._openOrCloseTween = new Tween(this._content, this._openOrCloseDuration, this._openOrCloseEase);
            this._openOrCloseTween.animate("x", targetPosition);
            this._openOrCloseTween.onUpdate = openOrCloseTween_onUpdate;
            this._openOrCloseTween.onComplete = openOrCloseTween_onComplete;
            Loom2D.juggler.add(this._openOrCloseTween);
        }

        /**
         * @private
         */
        protected function openOrCloseBottomDrawer():void
        {
            if(!this._bottomDrawer || this.isBottomDrawerDocked)
            {
                return;
            }
            if(this._openOrCloseTween)
            {
                this._openOrCloseTween.advanceTime(this._openOrCloseTween.totalTime);
                Loom2D.juggler.remove(this._openOrCloseTween);
                this._openOrCloseTween = null;
            }
            this.applyBottomClipRect();
            this._bottomDrawer.visible = true;
            var targetPosition:Number = 0;
            if(this._isBottomDrawerOpen)
            {
                targetPosition = -this._bottomDrawer.height;
            }
            if(this.isTopDrawerDocked)
            {
                targetPosition += this._topDrawer.height;
            }
            this._openOrCloseTween = new Tween(this._content, this._openOrCloseDuration, this._openOrCloseEase);
            this._openOrCloseTween.animate("y", targetPosition);
            this._openOrCloseTween.onUpdate = openOrCloseTween_onUpdate;
            this._openOrCloseTween.onComplete = openOrCloseTween_onComplete;
            Loom2D.juggler.add(this._openOrCloseTween);
        }

        /**
         * @private
         */
        protected function openOrCloseLeftDrawer():void
        {
            if(!this._leftDrawer || this.isLeftDrawerDocked)
            {
                return;
            }
            if(this._openOrCloseTween)
            {
                this._openOrCloseTween.advanceTime(this._openOrCloseTween.totalTime);
                Loom2D.juggler.remove(this._openOrCloseTween);
                this._openOrCloseTween = null;
            }
            this.applyLeftClipRect();
            this._leftDrawer.visible = true;
            var targetPosition:Number = this._isLeftDrawerOpen ? this._leftDrawer.width : 0;
            var duration:Number = !isNaN(this.pendingToggleDuration) ? this.pendingToggleDuration : this._openOrCloseDuration;
            this._openOrCloseTween = new Tween(this._content, duration, this._openOrCloseEase);
            this._openOrCloseTween.animate("x", targetPosition);
            this._openOrCloseTween.onUpdate = openOrCloseTween_onUpdate;
            this._openOrCloseTween.onComplete = openOrCloseTween_onComplete;
            Loom2D.juggler.add(this._openOrCloseTween);
        }

        /**
         * @private
         */
        protected function applyTopClipRect():void
        {
            if(!this._clipDrawers || !(this._topDrawer is Sprite))
            {
                return;
            }
            var topSprite:Sprite = Sprite(this._topDrawer);
            if(!topSprite.clipRect)
            {
                topSprite.clipRect = new Rectangle(0, 0, this.actualWidth, this._content.y);
            }
        }

        /**
         * @private
         */
        protected function applyRightClipRect():void
        {
            if(!this._clipDrawers || !(this._rightDrawer is Sprite))
            {
                return;
            }
            var rightSprite:Sprite = Sprite(this._rightDrawer);
            if(!rightSprite.clipRect)
            {
                rightSprite.clipRect = new Rectangle(0, 0, -this._content.x, this.actualHeight);
            }
        }

        /**
         * @private
         */
        protected function applyBottomClipRect():void
        {
            if(!this._clipDrawers || !(this._bottomDrawer is Sprite))
            {
                return;
            }
            var bottomSprite:Sprite = Sprite(this._bottomDrawer);
            if(!bottomSprite.clipRect)
            {
                bottomSprite.clipRect = new Rectangle(0, 0, this.actualWidth, -this._content.y);
            }
        }

        /**
         * @private
         */
        protected function applyLeftClipRect():void
        {
            if(!this._clipDrawers || !(this._leftDrawer is Sprite))
            {
                return;
            }
            var leftSprite:Sprite = Sprite(this._leftDrawer);
            if(!leftSprite.clipRect)
            {
                leftSprite.clipRect = new Rectangle(0, 0, this._content.x, this.actualHeight);
            }
        }

        /**
         * Uses the content event dispatcher fields and functions to generate a
         * content event dispatcher icon for the content.
         *
         * <p>All of the content event dispatcher fields and functions, ordered
         * by priority:</p>
         * <ol>
         *     <li><code>contentEventDispatcherFunction</code></li>
         *     <li><code>contentEventDispatcherField</code></li>
         * </ol>
         *
         * @see #content
         * @see #contentEventDispatcherField
         * @see #contentEventDispatcherFunction
         * @see #contentEventDispatcherChangeEventType
         */
        protected function contentToContentEventDispatcher():EventDispatcher
        {
            if(this._contentEventDispatcherFunction != null)
            {
                return this._contentEventDispatcherFunction(this._content) as EventDispatcher;
            }
            else if(this._contentEventDispatcherField != null && this._content && this._content.hasOwnProperty(this._contentEventDispatcherField))
            {
                return this._content.getType().getFieldOrPropertyValueByName(this._content, this._contentEventDispatcherField) as EventDispatcher;
            }
            return this._content;
        }

        /**
         * @private
         */
        protected function refreshCurrentEventTarget():void
        {
            if(this.contentEventDispatcher)
            {
                if ( _topDrawerToggleEventType )
                    this.contentEventDispatcher.removeEventListener(this._topDrawerToggleEventType, content_topDrawerToggleEventTypeHandler);
                
                if ( _rightDrawerToggleEventType )
                    this.contentEventDispatcher.removeEventListener(this._rightDrawerToggleEventType, content_rightDrawerToggleEventTypeHandler);
                    
                if ( _bottomDrawerToggleEventType )
                    this.contentEventDispatcher.removeEventListener(this._bottomDrawerToggleEventType, content_bottomDrawerToggleEventTypeHandler);
                
                if ( _leftDrawerToggleEventType )
                    this.contentEventDispatcher.removeEventListener(this._leftDrawerToggleEventType, content_leftDrawerToggleEventTypeHandler);
            }
            
            this.contentEventDispatcher = this.contentToContentEventDispatcher();
            
            if(this.contentEventDispatcher)
            {
                if ( _topDrawerToggleEventType )
                    this.contentEventDispatcher.addEventListener(this._topDrawerToggleEventType, content_topDrawerToggleEventTypeHandler);
    
                if ( _rightDrawerToggleEventType )
                    this.contentEventDispatcher.addEventListener(this._rightDrawerToggleEventType, content_rightDrawerToggleEventTypeHandler);
    
                if ( _bottomDrawerToggleEventType )
                    this.contentEventDispatcher.addEventListener(this._bottomDrawerToggleEventType, content_bottomDrawerToggleEventTypeHandler);
    
                if ( _leftDrawerToggleEventType )
                    this.contentEventDispatcher.addEventListener(this._leftDrawerToggleEventType, content_leftDrawerToggleEventTypeHandler);
            }
        }

        /**
         * @private
         */
        protected function refreshDrawerStates():void
        {
            if(this.isTopDrawerDocked)
            {
                this._isTopDrawerOpen = false;
            }
            if(this.isRightDrawerDocked)
            {
                this._isRightDrawerOpen = false;
            }
            if(this.isBottomDrawerDocked)
            {
                this._isBottomDrawerOpen = false;
            }
            if(this.isLeftDrawerDocked)
            {
                this._isLeftDrawerOpen = false;
            }
        }

        /**
         * @private
         */
        protected function handleTapToClose(touch:Touch):void
        {
            HELPER_POINT = touch.getLocation(this.stage);
            if(this != this.stage.hitTest(HELPER_POINT, true))
            {
                return;
            }

            if(this.isTopDrawerOpen)
            {
                this._isTopDrawerOpen = false;
                this.openOrCloseTopDrawer();
            }
            else if(this.isRightDrawerOpen)
            {
                this._isRightDrawerOpen = false;
                this.openOrCloseRightDrawer();
            }
            else if(this.isBottomDrawerOpen)
            {
                this._isBottomDrawerOpen = false;
                this.openOrCloseBottomDrawer();
            }
            else if(this.isLeftDrawerOpen)
            {
                this._isLeftDrawerOpen = false;
                this.openOrCloseLeftDrawer();
            }
        }

        /**
         * @private
         */
        protected function handleTouchBegan(touch:Touch):void
        {
            var exclusiveTouch:ExclusiveTouch = ExclusiveTouch.forStage(this.stage);
            if(exclusiveTouch.getClaim(touch.id))
            {
                //already claimed
                return;
            }

            HELPER_POINT = touch.getLocation(this);
            var localX:Number = HELPER_POINT.x;
            var localY:Number = HELPER_POINT.y;
            if(!this.isTopDrawerOpen && !this.isRightDrawerOpen && !this.isBottomDrawerOpen && !this.isLeftDrawerOpen)
            {
                if(this._openGesture == OPEN_GESTURE_NONE)
                {
                    return;
                }
                if(this._openGesture == OPEN_GESTURE_DRAG_CONTENT_EDGE)
                {
                    var isNearAnyEdge:Boolean = false;
                    if(this._topDrawer && !this.isTopDrawerDocked)
                    {
                        var topInches:Number = localY / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
                        if(topInches >= 0 && topInches <= this._openGestureEdgeSize)
                        {
                            isNearAnyEdge = true;
                        }
                    }
                    if(!isNearAnyEdge)
                    {
                        if(this._rightDrawer && !this.isRightDrawerDocked)
                        {
                            var rightInches:Number = (this.actualWidth - localX) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
                            if(rightInches >= 0 && rightInches <= this._openGestureEdgeSize)
                            {
                                isNearAnyEdge = true;
                            }
                        }
                        if(!isNearAnyEdge)
                        {
                            if(this._bottomDrawer && !this.isBottomDrawerDocked)
                            {
                                var bottomInches:Number = (this.actualHeight - localY) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
                                if(bottomInches >= 0 && bottomInches <= this._openGestureEdgeSize)
                                {
                                    isNearAnyEdge = true;
                                }
                            }
                            if(!isNearAnyEdge)
                            {
                                if(this._leftDrawer && !this.isLeftDrawerDocked)
                                {
                                    var leftInches:Number = localX / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
                                    if(leftInches >= 0 && leftInches <= this._openGestureEdgeSize)
                                    {
                                        isNearAnyEdge = true;
                                    }
                                }
                            }
                        }
                    }
                    if(!isNearAnyEdge)
                    {
                        return;
                    }
                }
            }
            else if(touch.target != this && !touch.isTouching(this._content) &&
                !(this.isTopDrawerDocked && touch.isTouching(this._topDrawer)) &&
                !(this.isRightDrawerDocked && touch.isTouching(this._rightDrawer)) &&
                !(this.isBottomDrawerDocked && touch.isTouching(this._bottomDrawer)) &&
                !(this.isLeftDrawerDocked && touch.isTouching(this._leftDrawer)))
            {
                //a drawer is open, let's only work with touches over the
                //content or other drawers that are docked
                return;
            }

            this.touchPointID = touch.id;
            this._velocityX = 0;
            this._velocityY = 0;
            this._previousVelocityX.length = 0;
            this._previousVelocityY.length = 0;
            this._previousTouchTime = Platform.getTime();
            this._previousTouchX = this._startTouchX = this._currentTouchX = localX;
            this._previousTouchY = this._startTouchY = this._currentTouchY = localY;
            this._isDragging = false;
            this._isDraggingTopDrawer = false;
            this._isDraggingRightDrawer = false;
            this._isDraggingBottomDrawer = false;
            this._isDraggingLeftDrawer = false;

            exclusiveTouch.addEventListener(Event.CHANGE, exclusiveTouch_changeHandler);
        }

        /**
         * @private
         */
        protected function handleTouchMoved(touch:Touch):void
        {
            HELPER_POINT = touch.getLocation(this);
            this._currentTouchX = HELPER_POINT.x;
            this._currentTouchY = HELPER_POINT.y;
            const now:int = Platform.getTime();
            const timeOffset:int = now - this._previousTouchTime;
            if(timeOffset > 0)
            {
                //we're keeping previous velocity updates to improve accuracy
                this._previousVelocityX[this._previousVelocityX.length] = this._velocityX;
                if(this._previousVelocityX.length > MAXIMUM_SAVED_VELOCITY_COUNT)
                {
                    this._previousVelocityX.shift();
                }
                this._previousVelocityY[this._previousVelocityY.length] = this._velocityY;
                if(this._previousVelocityY.length > MAXIMUM_SAVED_VELOCITY_COUNT)
                {
                    this._previousVelocityY.shift();
                }
                this._velocityX = (this._currentTouchX - this._previousTouchX) / timeOffset;
                this._velocityY = (this._currentTouchY - this._previousTouchY) / timeOffset;
                this._previousTouchTime = now;
                this._previousTouchX = this._currentTouchX;
                this._previousTouchY = this._currentTouchY;
            }
        }

        /**
         * @private
         */
        protected function handleDragEnd():void
        {
            //take the average for more accuracy
            var sum:Number = this._velocityX * CURRENT_VELOCITY_WEIGHT;
            var velocityCount:int = this._previousVelocityX.length;
            var totalWeight:Number = CURRENT_VELOCITY_WEIGHT;
            for(var i:int = 0; i < velocityCount; i++)
            {
                var weight:Number = VELOCITY_WEIGHTS[i];
                sum += this._previousVelocityX.shift() * weight;
                totalWeight += weight;
            }
            var inchesPerSecondX:Number = 1000 * (sum / totalWeight) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);

            sum = this._velocityY * CURRENT_VELOCITY_WEIGHT;
            velocityCount = this._previousVelocityY.length;
            totalWeight = CURRENT_VELOCITY_WEIGHT;
            for(i = 0; i < velocityCount; i++)
            {
                weight = VELOCITY_WEIGHTS[i];
                sum += this._previousVelocityY.shift() * weight;
                totalWeight += weight;
            }
            var inchesPerSecondY:Number = 1000 * (sum / totalWeight) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);

            this._isDragging = false;
            if(this._isDraggingTopDrawer)
            {
                this._isDraggingTopDrawer = false;
                if(!this._isTopDrawerOpen && inchesPerSecondY > this._minimumDrawerThrowVelocity)
                {
                    this._isTopDrawerOpen = true;
                }
                else if(this._isTopDrawerOpen && inchesPerSecondY < -this._minimumDrawerThrowVelocity)
                {
                    this._isTopDrawerOpen = false;
                }
                else
                {
                    this._isTopDrawerOpen = FeathersMath.roundToNearest(this._content.y, this._topDrawer.height) != 0;
                }
                this.openOrCloseTopDrawer();
            }
            else if(this._isDraggingRightDrawer)
            {
                this._isDraggingRightDrawer = false;
                if(!this._isRightDrawerOpen && inchesPerSecondX < -this._minimumDrawerThrowVelocity)
                {
                    this._isRightDrawerOpen = true;
                }
                else if(this._isRightDrawerOpen && inchesPerSecondX > this._minimumDrawerThrowVelocity)
                {
                    this._isRightDrawerOpen = false;
                }
                else
                {
                    var positionToCheck:Number = 0;
                    if(this.isLeftDrawerDocked)
                    {
                        positionToCheck = this._leftDrawer.width;
                    }
                    this._isRightDrawerOpen = FeathersMath.roundToNearest(this._content.x, this._rightDrawer.width) != positionToCheck;
                }
                this.openOrCloseRightDrawer();
            }
            else if(this._isDraggingBottomDrawer)
            {
                this._isDraggingBottomDrawer = false;
                if(!this._isBottomDrawerOpen && inchesPerSecondY < -this._minimumDrawerThrowVelocity)
                {
                    this._isBottomDrawerOpen = true;
                }
                else if(this._isBottomDrawerOpen && inchesPerSecondY > this._minimumDrawerThrowVelocity)
                {
                    this._isBottomDrawerOpen = false;
                }
                else
                {
                    positionToCheck = 0;
                    if(this.isTopDrawerDocked)
                    {
                        positionToCheck = this._topDrawer.height;
                    }
                    this._isBottomDrawerOpen = FeathersMath.roundToNearest(this._content.y, this._bottomDrawer.height) != positionToCheck;
                }
                this.openOrCloseBottomDrawer();
            }
            else if(this._isDraggingLeftDrawer)
            {
                this._isDraggingLeftDrawer = false;
                if(!this._isLeftDrawerOpen && inchesPerSecondX > this._minimumDrawerThrowVelocity)
                {
                    this._isLeftDrawerOpen = true;
                }
                else if(this._isLeftDrawerOpen && inchesPerSecondX < -this._minimumDrawerThrowVelocity)
                {
                    this._isLeftDrawerOpen = false;
                }
                else
                {
                    this._isLeftDrawerOpen = FeathersMath.roundToNearest(this._content.x, this._leftDrawer.width) != 0;
                }
                this.openOrCloseLeftDrawer();
            }
        }

        /**
         * @private
         */
        protected function handleDragMove():void
        {
            var contentX:Number = 0;
            var contentY:Number = 0;
            if(this.isLeftDrawerDocked)
            {
                contentX = this._leftDrawer.width;
            }
            if(this.isTopDrawerDocked)
            {
                contentY = this._topDrawer.height;
            }
            if(this._isDraggingLeftDrawer)
            {
                var leftDrawerWidth:Number = this._leftDrawer.width;
                if(this.isLeftDrawerOpen)
                {
                    contentX = leftDrawerWidth + this._currentTouchX - this._startTouchX;
                }
                else
                {
                    contentX = this._currentTouchX - this._startTouchX;
                }
                if(contentX < 0)
                {
                    contentX = 0;
                }
                if(contentX > leftDrawerWidth)
                {
                    contentX = leftDrawerWidth;
                }
            }
            else if(this._isDraggingRightDrawer)
            {
                var rightDrawerWidth:Number = this._rightDrawer.width;
                if(this.isRightDrawerOpen)
                {
                    contentX = -rightDrawerWidth + this._currentTouchX - this._startTouchX;
                }
                else
                {
                    contentX = this._currentTouchX - this._startTouchX;
                }
                if(contentX < -rightDrawerWidth)
                {
                    contentX = -rightDrawerWidth;
                }
                if(contentX > 0)
                {
                    contentX = 0;
                }
                if(this.isLeftDrawerDocked)
                {
                    contentX += this._leftDrawer.width;
                }
            }
            else if(this._isDraggingTopDrawer)
            {
                var topDrawerHeight:Number = this._topDrawer.height;
                if(this.isTopDrawerOpen)
                {
                    contentY = topDrawerHeight + this._currentTouchY - this._startTouchY;
                }
                else
                {
                    contentY = this._currentTouchY - this._startTouchY;
                }
                if(contentY < 0)
                {
                    contentY = 0;
                }
                if(contentY > topDrawerHeight)
                {
                    contentY = topDrawerHeight;
                }
                this._content.y = contentY;
            }
            else if(this._isDraggingBottomDrawer)
            {
                var bottomDrawerHeight:Number = this._bottomDrawer.height;
                if(this.isBottomDrawerOpen)
                {
                    contentY = -bottomDrawerHeight + this._currentTouchY - this._startTouchY;
                }
                else
                {
                    contentY = this._currentTouchY - this._startTouchY;
                }
                if(contentY < -bottomDrawerHeight)
                {
                    contentY = -bottomDrawerHeight;
                }
                if(contentY > 0)
                {
                    contentY = 0;
                }
                if(this.isTopDrawerDocked)
                {
                    contentY += this._topDrawer.height;
                }
            }
            this._content.x = contentX;
            this._content.y = contentY;
            this.openOrCloseTween_onUpdate();
        }

        /**
         * @private
         */
        protected function checkForDragToClose():void
        {
            var horizontalInchesMoved:Number = (this._currentTouchX - this._startTouchX) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
            var verticalInchesMoved:Number = (this._currentTouchY - this._startTouchY) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
            if(this.isLeftDrawerOpen && horizontalInchesMoved <= -this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingLeftDrawer = true;
                this.applyLeftClipRect();
            }
            else if(this.isRightDrawerOpen && horizontalInchesMoved >= this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingRightDrawer = true;
                this.applyRightClipRect();
            }
            else if(this.isTopDrawerOpen && verticalInchesMoved <= -this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingTopDrawer = true;
                this.applyTopClipRect();
            }
            else if(this.isBottomDrawerOpen && verticalInchesMoved >= this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingBottomDrawer = true;
                this.applyBottomClipRect();
            }

            if(this._isDragging)
            {
                this._startTouchY = this._currentTouchY;
                var exclusiveTouch:ExclusiveTouch = ExclusiveTouch.forStage(this.stage);
                exclusiveTouch.removeEventListener(Event.CHANGE, exclusiveTouch_changeHandler);
                exclusiveTouch.claimTouch(this.touchPointID, this);
                this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
            }
        }

        /**
         * @private
         */
        protected function checkForDragToOpen():void
        {
            var horizontalInchesMoved:Number = (this._currentTouchX - this._startTouchX) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
            var verticalInchesMoved:Number = (this._currentTouchY - this._startTouchY) / (DeviceCapabilities.dpi / Loom2D.contentScaleFactor);
            if(this._leftDrawer && !this.isLeftDrawerDocked && horizontalInchesMoved >= this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingLeftDrawer = true;
                this._leftDrawer.visible = true;
                this.applyLeftClipRect();
            }
            else if(this._rightDrawer && !this.isRightDrawerDocked && horizontalInchesMoved <= -this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingRightDrawer = true;
                this._rightDrawer.visible = true;
                this.applyRightClipRect();
            }
            else if(this._topDrawer && !this.isTopDrawerDocked && verticalInchesMoved >= this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingTopDrawer = true;
                this._topDrawer.visible = true;
                this.applyTopClipRect();
            }
            else if(this._bottomDrawer && !this.isBottomDrawerDocked && verticalInchesMoved <= -this._minimumDragDistance)
            {
                this._isDragging = true;
                this._isDraggingBottomDrawer = true;
                this._bottomDrawer.visible = true;
                this.applyBottomClipRect();
            }

            if(this._isDragging)
            {
                this._startTouchY = this._currentTouchY;
                var exclusiveTouch:ExclusiveTouch = ExclusiveTouch.forStage(this.stage);
                exclusiveTouch.claimTouch(this.touchPointID, this);
                exclusiveTouch.removeEventListener(Event.CHANGE, exclusiveTouch_changeHandler);
                this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
            }
        }

        /**
         * @private
         */
        protected function openOrCloseTween_onUpdate():void
        {
            if(!this._clipDrawers)
            {
                return;
            }
            var isTopDrawerDocked:Boolean = this.isTopDrawerDocked;
            var isRightDrawerDocked:Boolean = this.isRightDrawerDocked;
            var isBottomDrawerDocked:Boolean = this.isBottomDrawerDocked;
            var isLeftDrawerDocked:Boolean = this.isLeftDrawerDocked;
            if(this._topDrawer is Sprite)
            {
                var sprite:Sprite = Sprite(this._topDrawer);
                var clipRect:Rectangle = sprite.clipRect;
                if(clipRect)
                {
                    clipRect.height = this._content.y;
                }
            }
            if(this._rightDrawer is Sprite)
            {
                sprite = Sprite(this._rightDrawer);
                clipRect = sprite.clipRect;
                if(clipRect)
                {
                    var rightClipWidth:Number = -this._content.x;
                    if(isLeftDrawerDocked)
                    {
                        rightClipWidth += this.leftDrawer.width;
                    }
                    clipRect.x = this._rightDrawer.width - rightClipWidth;
                    clipRect.width = rightClipWidth;
                }
            }
            if(this._bottomDrawer is Sprite)
            {
                sprite = Sprite(this._bottomDrawer);
                clipRect = sprite.clipRect;
                if(clipRect)
                {
                    var bottomClipHeight:Number = -this._content.y;
                    if(isTopDrawerDocked)
                    {
                        bottomClipHeight += this.topDrawer.height;
                    }
                    clipRect.y = this._bottomDrawer.height - bottomClipHeight;
                    clipRect.height = bottomClipHeight;
                }
            }
            if(this._leftDrawer is Sprite)
            {
                sprite = Sprite(this._leftDrawer);
                clipRect = sprite.clipRect;
                if(clipRect)
                {
                    clipRect.width = this._content.x;
                }
            }
            var contentX:Number = this._content.x;
            var contentY:Number = this._content.y;
            if(isTopDrawerDocked)
            {
                if(isLeftDrawerDocked)
                {
                    this._topDrawer.x = contentX - this._leftDrawer.width;
                }
                else
                {
                    this._topDrawer.x = contentX;
                }
                this._topDrawer.y = contentY - this._topDrawer.height;
            }
            if(isRightDrawerDocked)
            {
                this._rightDrawer.x = contentX + this._content.width;
                this._rightDrawer.y = contentY;
            }
            if(isBottomDrawerDocked)
            {
                if(isLeftDrawerDocked)
                {
                    this._bottomDrawer.x = contentX - this._leftDrawer.width;
                }
                else
                {
                    this._bottomDrawer.x = contentX;
                }
                this._bottomDrawer.y = contentY + this._content.height;
            }
            if(isLeftDrawerDocked)
            {
                this._leftDrawer.x = contentX - this._leftDrawer.width;
                this._leftDrawer.y = contentY;
            }
        }

        /**
         * @private
         */
        protected function openOrCloseTween_onComplete():void
        {
            var isTopDrawerOpen:Boolean = this.isTopDrawerOpen;
            var isRightDrawerOpen:Boolean = this.isRightDrawerOpen;
            var isBottomDrawerOpen:Boolean = this.isBottomDrawerOpen;
            var isLeftDrawerOpen:Boolean = this.isLeftDrawerOpen;
            this._openOrCloseTween = null;
            if(this._topDrawer)
            {
                if(this._topDrawer is Sprite)
                {
                    Sprite(this._topDrawer).clipRect = null;
                }
                this._topDrawer.visible = isTopDrawerOpen || this.isTopDrawerDocked;
            }
            if(this._rightDrawer)
            {
                if(this._rightDrawer is Sprite)
                {
                    Sprite(this._rightDrawer).clipRect = null;
                }
                this._rightDrawer.visible = isRightDrawerOpen || this.isRightDrawerDocked;
            }
            if(this._bottomDrawer)
            {
                if(this._bottomDrawer is Sprite)
                {
                    Sprite(this._bottomDrawer).clipRect = null;
                }
                this._bottomDrawer.visible = isBottomDrawerOpen || this.isBottomDrawerDocked;
            }
            if(this._leftDrawer)
            {
                if(this._leftDrawer is Sprite)
                {
                    Sprite(this._leftDrawer).clipRect = null;
                }
                this._leftDrawer.visible = isLeftDrawerOpen || this.isLeftDrawerDocked;
            }
        }

        /**
         * @private
         */
        protected function content_eventDispatcherChangeHandler(event:Event):void
        {
            this.refreshCurrentEventTarget();
        }

        /**
         * @private
         */
        protected function drawers_addedToStageHandler(event:Event):void
        {
            this.stage.addEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
            //using priority here is a hack so that objects higher up in the
            //display list have a chance to cancel the event first.
            //var priority:int = -FeathersDisplayUtils.getDisplayObjectDepthFromStage(this);
            Loom2D.stage.addEventListener(KeyboardEvent.KEY_DOWN, drawers_nativeStage_keyDownHandler);
        }

        /**
         * @private
         */
        protected function drawers_removedFromStageHandler(event:Event):void
        {
            this.stage.removeEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
            Loom2D.stage.removeEventListener(KeyboardEvent.KEY_DOWN, drawers_nativeStage_keyDownHandler);
        }

        /**
         * @private
         */
        protected function drawers_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled || this._openOrCloseTween)
            {
                this.touchPointID = -1;
                return;
            }
            if(this.touchPointID >= 0)
            {
                var touch:Touch = event.getTouch(this);
                if(!touch || touch.id != this.touchPointID)
                {
                    return;
                }
                if(touch.phase == TouchPhase.MOVED)
                {
                    this.handleTouchMoved(touch);

                    if(!this._isDragging)
                    {
                        if(this.isTopDrawerOpen || this.isRightDrawerOpen || this.isBottomDrawerOpen || this.isLeftDrawerOpen)
                        {
                            this.checkForDragToClose();
                        }
                        else
                        {
                            this.checkForDragToOpen();
                        }
                    }
                    if(this._isDragging)
                    {
                        this.handleDragMove();
                    }
                }
                else if(touch.phase == TouchPhase.ENDED)
                {
                    this.touchPointID = -1;
                    if(this._isDragging)
                    {
                        this.handleDragEnd();
                        this.dispatchEventWith(FeathersEventType.END_INTERACTION);
                    }
                    else
                    {
                        ExclusiveTouch.forStage(this.stage).removeEventListener(Event.CHANGE, exclusiveTouch_changeHandler);
                        if(this.isTopDrawerOpen || this.isRightDrawerOpen || this.isBottomDrawerOpen || this.isLeftDrawerOpen)
                        {
                            //there is no drag, so we may have a tap
                            this.handleTapToClose(touch);
                        }
                    }

                }
            }
            else
            {
                touch = event.getTouch(this, TouchPhase.BEGAN);
                if(!touch)
                {
                    return;
                }

                this.handleTouchBegan(touch);
            }
        }

        /**
         * @private
         */
        protected function exclusiveTouch_changeHandler(event:Event, touchID:int):void
        {
            if(this.touchPointID < 0 || this.touchPointID != touchID || this._isDragging)
            {
                return;
            }

            var exclusiveTouch:ExclusiveTouch = ExclusiveTouch.forStage(this.stage);
            if(exclusiveTouch.getClaim(touchID) == this)
            {
                return;
            }

            this.touchPointID = -1;

        }

        /**
         * @private
         */
        protected function stage_resizeHandler(event:ResizeEvent):void
        {
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected function drawers_nativeStage_keyDownHandler(event:KeyboardEvent):void
        {
            if(event.keyCode == LoomKey.BUTTON_BACK)
            {
                var isAnyDrawerOpen:Boolean = false;
                if(this.isTopDrawerOpen)
                {
                    this.toggleTopDrawer();
                    isAnyDrawerOpen = true;
                }
                else if(this.isRightDrawerOpen)
                {
                    this.toggleRightDrawer();
                    isAnyDrawerOpen = true;
                }
                else if(this.isBottomDrawerOpen)
                {
                    this.toggleBottomDrawer();
                    isAnyDrawerOpen = true;
                }
                else if(this.isLeftDrawerOpen)
                {
                    this.toggleLeftDrawer();
                    isAnyDrawerOpen = true;
                }
            }
        }

        /**
         * @private
         */
        protected function content_topDrawerToggleEventTypeHandler(event:Event):void
        {
            if(!this._topDrawer || this.isTopDrawerDocked)
            {
                return;
            }
            this._isTopDrawerOpen = !this._isTopDrawerOpen;
            this.openOrCloseTopDrawer();
        }

        /**
         * @private
         */
        protected function content_rightDrawerToggleEventTypeHandler(event:Event):void
        {
            if(!this._rightDrawer || this.isRightDrawerDocked)
            {
                return;
            }
            this._isRightDrawerOpen = !this._isRightDrawerOpen;
            this.openOrCloseRightDrawer();
        }

        /**
         * @private
         */
        protected function content_bottomDrawerToggleEventTypeHandler(event:Event):void
        {
            if(!this._bottomDrawer || this.isBottomDrawerDocked)
            {
                return;
            }
            this._isBottomDrawerOpen = !this._isBottomDrawerOpen;
            this.openOrCloseBottomDrawer();
        }

        /**
         * @private
         */
        protected function content_leftDrawerToggleEventTypeHandler(event:Event):void
        {
            if(!this._leftDrawer || this.isLeftDrawerDocked)
            {
                return;
            }
            this._isLeftDrawerOpen = !this._isLeftDrawerOpen;
            this.openOrCloseLeftDrawer();
        }

        /**
         * @private
         */
        protected function content_resizeHandler(event:Event):void
        {
            if(this._isValidating || this._autoSizeMode != AUTO_SIZE_MODE_CONTENT)
            {
                return;
            }
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }
    }
}