/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.events.FeathersEventType;
    import feathers.utils.FeathersMath;

    import loom2d.math.Point;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    import loom.platform.Timer;

    /**
     * Dispatched when the scroll bar's value changes.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Dispatched when the user starts interacting with the scroll bar's thumb,
     * track, or buttons.
     *
     * @eventType feathers.events.FeathersEventType.BEGIN_INTERACTION
     */
    [Event(name="beginInteraction",type="loom2d.events.Event")]

    /**
     * Dispatched when the user stops interacting with the scroll bar's thumb,
     * track, or buttons.
     *
     * @eventType feathers.events.FeathersEventType.END_INTERACTION
     */
    [Event(name="endInteraction",type="loom2d.events.Event")]

    /**
     * Select a value between a minimum and a maximum by dragging a thumb over
     * a physical range or by using step buttons. This is a desktop-centric
     * scroll bar with many skinnable parts. For mobile, the
     * `SimpleScrollBar` is probably a better choice as it provides
     * only the thumb to indicate position without all the extra chrome.
     *
     * @see http://wiki.starling-framework.org/feathers/scroll-bar
     * @see SimpleScrollBar
     */
    public class ScrollBar extends FeathersControl implements IScrollBar
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
        protected static const INVALIDATION_FLAG_THUMB_FACTORY:String = "thumbFactory";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY:String = "minimumTrackFactory";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY:String = "maximumTrackFactory";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY:String = "decrementButtonFactory";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY:String = "incrementButtonFactory";

        /**
         * The scroll bar's thumb may be dragged horizontally (on the x-axis).
         *
         * @see #direction
         */
        public static const DIRECTION_HORIZONTAL:String = "horizontal";

        /**
         * The scroll bar's thumb may be dragged vertically (on the y-axis).
         *
         * @see #direction
         */
        public static const DIRECTION_VERTICAL:String = "vertical";

        /**
         * The scroll bar has only one track, that fills the full length of the
         * scroll bar. In this layout mode, the "minimum" track is displayed and
         * fills the entire length of the scroll bar. The maximum track will not
         * exist.
         *
         * @see #trackLayoutMode
         */
        public static const TRACK_LAYOUT_MODE_SINGLE:String = "single";

        /**
         * The scroll bar has two tracks, stretching to fill each side of the
         * scroll bar with the thumb in the middle. The tracks will be resized
         * as the thumb moves. This layout mode is designed for scroll bars
         * where the two sides of the track may be colored differently to show
         * the value "filling up" as the thumb is dragged or to highlight the
         * track when it is triggered to scroll by a page instead of a step.
         *
         * Since the width and height of the tracks will change, consider
         * sing a special display object such as a `Scale9Image`,
         * `Scale3Image` or a `TiledImage` that is
         * designed to be resized dynamically.
         *
         * @see #trackLayoutMode
         * @see feathers.display.Scale9Image
         * @see feathers.display.Scale3Image
         * @see feathers.display.TiledImage
         */
        public static const TRACK_LAYOUT_MODE_MIN_MAX:String = "minMax";

        /**
         * The default value added to the `nameList` of the minimum
         * track.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_MINIMUM_TRACK:String = "feathers-scroll-bar-minimum-track";

        /**
         * The default value added to the `nameList` of the maximum
         * track.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_MAXIMUM_TRACK:String = "feathers-scroll-bar-maximum-track";

        /**
         * The default value added to the `nameList` of the thumb.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_THUMB:String = "feathers-scroll-bar-thumb";

        /**
         * The default value added to the `nameList` of the decrement
         * button.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_DECREMENT_BUTTON:String = "feathers-scroll-bar-decrement-button";

        /**
         * The default value added to the `nameList` of the increment
         * button.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_INCREMENT_BUTTON:String = "feathers-scroll-bar-increment-button";

        /**
         * @private
         */
        protected static function defaultThumbFactory():Button
        {
            return new Button();
        }

        /**
         * @private
         */
        protected static function defaultMinimumTrackFactory():Button
        {
            return new Button();
        }

        /**
         * @private
         */
        protected static function defaultMaximumTrackFactory():Button
        {
            return new Button();
        }

        /**
         * @private
         */
        protected static function defaultDecrementButtonFactory():Button
        {
            return new Button();
        }

        /**
         * @private
         */
        protected static function defaultIncrementButtonFactory():Button
        {
            return new Button();
        }

        /**
         * Constructor.
         */
        public function ScrollBar()
        {
            this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
        }

        /**
         * The value added to the `nameList` of the minimum track. This
         * variable is `protected` so that sub-classes can customize
         * the minimum track name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_MINIMUM_TRACK`.
         *
         * To customize the minimum track name without subclassing, see
         * `customMinimumTrackName`.
         *
         * @see #customMinimumTrackName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var minimumTrackName:String = DEFAULT_CHILD_NAME_MINIMUM_TRACK;

        /**
         * The value added to the `nameList` of the maximum track. This
         * variable is `protected` so that sub-classes can customize
         * the maximum track name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_MAXIMUM_TRACK`.
         *
         * To customize the maximum track name without subclassing, see
         * `customMaximumTrackName`.
         *
         * @see #customMaximumTrackName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var maximumTrackName:String = DEFAULT_CHILD_NAME_MAXIMUM_TRACK;

        /**
         * The value added to the `nameList` of the thumb. This
         * variable is `protected` so that sub-classes can customize
         * the thumb name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_THUMB`.
         *
         * To customize the thumb name without subclassing, see
         * `customThumbName`.
         *
         * @see #customThumbName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var thumbName:String = DEFAULT_CHILD_NAME_THUMB;

        /**
         * The value added to the `nameList` of the decrement button. This
         * variable is `protected` so that sub-classes can customize
         * the decrement button name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_DECREMENT_BUTTON`.
         *
         * To customize the decrement button name without subclassing, see
         * `customDecrementButtonName`.
         *
         * @see #customDecrementButtonName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var decrementButtonName:String = DEFAULT_CHILD_NAME_DECREMENT_BUTTON;

        /**
         * The value added to the `nameList` of the increment button. This
         * variable is `protected` so that sub-classes can customize
         * the increment button name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_INCREMENT_BUTTON`.
         *
         * To customize the increment button name without subclassing, see
         * `customIncrementButtonName`.
         *
         * @see #customIncrementButtonName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var incrementButtonName:String = DEFAULT_CHILD_NAME_INCREMENT_BUTTON;

        /**
         * @private
         */
        protected var thumbOriginalWidth:Number = NaN;

        /**
         * @private
         */
        protected var thumbOriginalHeight:Number = NaN;

        /**
         * @private
         */
        protected var minimumTrackOriginalWidth:Number = NaN;

        /**
         * @private
         */
        protected var minimumTrackOriginalHeight:Number = NaN;

        /**
         * @private
         */
        protected var maximumTrackOriginalWidth:Number = NaN;

        /**
         * @private
         */
        protected var maximumTrackOriginalHeight:Number = NaN;

        /**
         * The scroll bar's decrement button sub-component.
         */
        protected var decrementButton:Button;

        /**
         * The scroll bar's increment button sub-component.
         */
        protected var incrementButton:Button;

        /**
         * The scroll bar's thumb sub-component.
         */
        protected var thumb:Button;

        /**
         * The scroll bar's minimum track sub-component.
         */
        protected var minimumTrack:Button;

        /**
         * The scroll bar's maximum track sub-component.
         */
        protected var maximumTrack:Button;

        /**
         * @private
         */
        protected var _direction:String = DIRECTION_HORIZONTAL;

        [Inspectable(type="String",enumeration="horizontal,vertical")]
        /**
         * Determines if the scroll bar's thumb can be dragged horizontally or
         * vertically. When this value changes, the scroll bar's width and
         * height values do not change automatically.
         *
         * @default DIRECTION_HORIZONTAL
         * @see #DIRECTION_HORIZONTAL
         * @see #DIRECTION_VERTICAL
         */
        public function get direction():String
        {
            return this._direction;
        }

        /**
         * @private
         */
        public function set direction(value:String):void
        {
            if(this._direction == value)
            {
                return;
            }
            this._direction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
            this.invalidate(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);
            this.invalidate(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
            this.invalidate(INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY);
            this.invalidate(INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY);
            this.invalidate(INVALIDATION_FLAG_THUMB_FACTORY);
        }

        /**
         * @private
         */
        protected var _value:Number = 0;

        /**
         * @inheritDoc
         */
        public function get value():Number
        {
            return this._value;
        }

        /**
         * @private
         */
        public function set value(newValue:Number):void
        {
            newValue = FeathersMath.clamp(newValue, this._minimum, this._maximum);
            if(this._value == newValue)
            {
                return;
            }
            this._value = newValue;
            this.invalidate(INVALIDATION_FLAG_DATA);
            if(this.liveDragging || !this.isDragging)
            {
                this.dispatchEventWith(Event.CHANGE);
            }
        }

        /**
         * @private
         */
        protected var _minimum:Number = 0;

        /**
         * @inheritDoc
         */
        public function get minimum():Number
        {
            return this._minimum;
        }

        /**
         * @private
         */
        public function set minimum(value:Number):void
        {
            if(this._minimum == value)
            {
                return;
            }
            this._minimum = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _maximum:Number = 0;

        /**
         * @inheritDoc
         */
        public function get maximum():Number
        {
            return this._maximum;
        }

        /**
         * @private
         */
        public function set maximum(value:Number):void
        {
            if(this._maximum == value)
            {
                return;
            }
            this._maximum = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _step:Number = 0;

        /**
         * @inheritDoc
         */
        public function get step():Number
        {
            return this._step;
        }

        /**
         * @private
         */
        public function set step(value:Number):void
        {
            this._step = value;
        }

        /**
         * @private
         */
        protected var _page:Number = 0;

        /**
         * @inheritDoc
         */
        public function get page():Number
        {
            return this._page;
        }

        /**
         * @private
         */
        public function set page(value:Number):void
        {
            if(this._page == value)
            {
                return;
            }
            this._page = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
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
         * The minimum space, in pixels, above the content, not
         * including the track(s).
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
         * The minimum space, in pixels, to the right of the content, not
         * including the track(s).
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
         * The minimum space, in pixels, below the content, not
         * including the track(s).
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
         * The minimum space, in pixels, to the left of the content, not
         * including the track(s).
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
        protected var currentRepeatAction:Function;

        /**
         * @private
         */
        protected var _repeatTimer:Timer;

        /**
         * @private
         */
        protected var _repeatDelay:Number = 0.05;

        /**
         * The time, in seconds, before actions are repeated. The first repeat
         * happens after a delay that is five times longer than the following
         * repeats.
         */
        public function get repeatDelay():Number
        {
            return this._repeatDelay;
        }

        /**
         * @private
         */
        public function set repeatDelay(value:Number):void
        {
            if(this._repeatDelay == value)
            {
                return;
            }
            this._repeatDelay = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var isDragging:Boolean = false;

        /**
         * Determines if the scroll bar dispatches the `Event.CHANGE`
         * event every time the thumb moves, or only once it stops moving.
         */
        public var liveDragging:Boolean = true;

        /**
         * @private
         */
        protected var _trackLayoutMode:String = TRACK_LAYOUT_MODE_SINGLE;

        [Inspectable(type="String",enumeration="single,minMax")]
        /**
         * Determines how the minimum and maximum track skins are positioned and
         * sized.
         *
         * @default TRACK_LAYOUT_MODE_SINGLE
         * @see #TRACK_LAYOUT_MODE_SINGLE
         * @see #TRACK_LAYOUT_MODE_MIN_MAX
         */
        public function get trackLayoutMode():String
        {
            return this._trackLayoutMode;
        }

        /**
         * @private
         */
        public function set trackLayoutMode(value:String):void
        {
            if(this._trackLayoutMode == value)
            {
                return;
            }
            this._trackLayoutMode = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _minimumTrackFactory:Function;

        /**
         * A function used to generate the scroll bar's minimum track
         * sub-component. The minimum track must be an instance of
         * `Button`. This factory can be used to change properties on
         * the minimum track when it is first created. For instance, if you
         * are skinning Feathers components without a theme, you might use this
         * factory to set skins and other styles on the minimum track.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #minimumTrackProperties
         */
        public function get minimumTrackFactory():Function
        {
            return this._minimumTrackFactory;
        }

        /**
         * @private
         */
        public function set minimumTrackFactory(value:Function):void
        {
            if(this._minimumTrackFactory == value)
            {
                return;
            }
            this._minimumTrackFactory = value;
            this.invalidate(INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _customMinimumTrackName:String;

        /**
         * A name to add to the scroll bar's minimum track sub-component. Typically
         * used by a theme to provide different skins to different scroll bars.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #minimumTrackFactory
         * @see #minimumTrackProperties
         */
        public function get customMinimumTrackName():String
        {
            return this._customMinimumTrackName;
        }

        /**
         * @private
         */
        public function set customMinimumTrackName(value:String):void
        {
            if(this._customMinimumTrackName == value)
            {
                return;
            }
            this._customMinimumTrackName = value;
            this.invalidate(INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _minimumTrackProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroll bar's
         * minimum track sub-component. The minimum track is a
         * `feathers.controls.Button` instance. that is created by
         * `minimumTrackFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `minimumTrackFactory` function
         * instead of using `minimumTrackProperties` will result in
         * better performance.
         *
         * @see #minimumTrackFactory
         * @see feathers.controls.Button
         */
        public function get minimumTrackProperties():Object
        {
            if(!this._minimumTrackProperties)
            {
                this._minimumTrackProperties = new Dictionary.<String, Object>;
            }
            return this._minimumTrackProperties;
        }

        /**
         * @private
         */
        public function set minimumTrackProperties(value:Dictionary.<String, Object>):void
        {
            if(this._minimumTrackProperties == value)
                return;
            this._minimumTrackProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _maximumTrackFactory:Function;

        /**
         * A function used to generate the scroll bar's maximum track
         * sub-component. The maximum track must be an instance of
         * `Button`. This factory can be used to change properties on
         * the maximum track when it is first created. For instance, if you
         * are skinning Feathers components without a theme, you might use this
         * factory to set skins and other styles on the maximum track.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #maximumTrackProperties
         */
        public function get maximumTrackFactory():Function
        {
            return this._maximumTrackFactory;
        }

        /**
         * @private
         */
        public function set maximumTrackFactory(value:Function):void
        {
            if(this._maximumTrackFactory == value)
            {
                return;
            }
            this._maximumTrackFactory = value;
            this.invalidate(INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _customMaximumTrackName:String;

        /**
         * A name to add to the scroll bar's maximum track sub-component. Typically
         * used by a theme to provide different skins to different scroll bars.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #maximumTrackFactory
         * @see #maximumTrackProperties
         */
        public function get customMaximumTrackName():String
        {
            return this._customMaximumTrackName;
        }

        /**
         * @private
         */
        public function set customMaximumTrackName(value:String):void
        {
            if(this._customMaximumTrackName == value)
            {
                return;
            }
            this._customMaximumTrackName = value;
            this.invalidate(INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _maximumTrackProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroll bar's
         * maximum track sub-component. The maximum track is a
         * `feathers.controls.Button` instance that is created by
         * `maximumTrackFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `maximumTrackFactory` function
         * instead of using `maximumTrackProperties` will result in
         * better performance.
         *
         * @see #maximumTrackFactory
         * @see feathers.controls.Button
         */
        public function get maximumTrackProperties():Dictionary.<String, Object>
        {
            if(!this._maximumTrackProperties)
            {
                this._maximumTrackProperties = new Dictionary.<String, Object>;
            }
            return this._maximumTrackProperties;
        }

        /**
         * @private
         */
        public function set maximumTrackProperties(value:Dictionary.<String, Object>):void
        {
            if(this._maximumTrackProperties == value)
                return;
            this._maximumTrackProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _thumbFactory:Function;

        /**
         * A function used to generate the scroll bar's thumb sub-component.
         * The thumb must be an instance of `Button`. This factory
         * can be used to change properties on the thumb when it is first
         * created. For instance, if you are skinning Feathers components
         * without a theme, you might use this factory to set skins and other
         * styles on the thumb.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #thumbProperties
         */
        public function get thumbFactory():Function
        {
            return this._thumbFactory;
        }

        /**
         * @private
         */
        public function set thumbFactory(value:Function):void
        {
            if(this._thumbFactory == value)
            {
                return;
            }
            this._thumbFactory = value;
            this.invalidate(INVALIDATION_FLAG_THUMB_FACTORY);
        }

        /**
         * @private
         */
        protected var _customThumbName:String;

        /**
         * A name to add to the scroll bar's thumb sub-component. Typically
         * used by a theme to provide different skins to different scroll bars.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #thumbFactory
         * @see #thumbProperties
         */
        public function get customThumbName():String
        {
            return this._customThumbName;
        }

        /**
         * @private
         */
        public function set customThumbName(value:String):void
        {
            if(this._customThumbName == value)
            {
                return;
            }
            this._customThumbName = value;
            this.invalidate(INVALIDATION_FLAG_THUMB_FACTORY);
        }

        /**
         * @private
         */
        protected var _thumbProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroll bar's thumb
         * sub-component. The thumb is a `feathers.controls.Button`
         * instance that is created by `thumbFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `thumbFactory` function instead
         * of using `thumbProperties` will result in better
         * performance.
         *
         * @see #thumbFactory
         * @see feathers.controls.Button
         */
        public function get thumbProperties():Dictionary.<String, Object>
        {
            if(!this._thumbProperties)
                this._thumbProperties = new Dictionary.<String, Object>();
            return this._thumbProperties;
        }

        /**
         * @private
         */
        public function set thumbProperties(value:Dictionary.<String, Object>):void
        {
            this._thumbProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _decrementButtonFactory:Function;

        /**
         * A function used to generate the scroll bar's decrement button
         * sub-component. The decrement button must be an instance of
         * `Button`. This factory can be used to change properties on
         * the decrement button when it is first created. For instance, if you
         * are skinning Feathers components without a theme, you might use this
         * factory to set skins and other styles on the decrement button.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #decrementButtonProperties
         */
        public function get decrementButtonFactory():Function
        {
            return this._decrementButtonFactory;
        }

        /**
         * @private
         */
        public function set decrementButtonFactory(value:Function):void
        {
            if(this._decrementButtonFactory == value)
            {
                return;
            }
            this._decrementButtonFactory = value;
            this.invalidate(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _customDecrementButtonName:String;

        /**
         * A name to add to the scroll bar's decrement button sub-component. Typically
         * used by a theme to provide different skins to different scroll bars.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #decrementButtonFactory
         * @see #decrementButtonProperties
         */
        public function get customDecrementButtonName():String
        {
            return this._customDecrementButtonName;
        }

        /**
         * @private
         */
        public function set customDecrementButtonName(value:String):void
        {
            if(this._customDecrementButtonName == value)
            {
                return;
            }
            this._customDecrementButtonName = value;
            this.invalidate(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _decrementButtonProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroll bar's
         * decrement button sub-component. The decrement button is a
         * `feathers.controls.Button` instance that is created by
         * `decrementButtonFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `decrementButtonFactory`
         * function instead of using `decrementButtonProperties` will
         * result in better performance.
         *
         * @see #decrementButtonFactory
         * @see feathers.controls.Button
         */
        public function get decrementButtonProperties():Dictionary.<String, Object>
        {
            if(!this._decrementButtonProperties)
            {
                this._decrementButtonProperties = new Dictionary.<String, Object>();
            }
            return this._decrementButtonProperties;
        }

        /**
         * @private
         */
        public function set decrementButtonProperties(value:Dictionary.<String, Object>):void
        {
            if(this._decrementButtonProperties == value)
            {
                return;
            }
            this._decrementButtonProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _incrementButtonFactory:Function;

        /**
         * A function used to generate the scroll bar's increment button
         * sub-component. The increment button must be an instance of
         * `Button`. This factory can be used to change properties on
         * the increment button when it is first created. For instance, if you
         * are skinning Feathers components without a theme, you might use this
         * factory to set skins and other styles on the increment button.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #incrementButtonProperties
         */
        public function get incrementButtonFactory():Function
        {
            return this._incrementButtonFactory;
        }

        /**
         * @private
         */
        public function set incrementButtonFactory(value:Function):void
        {
            if(this._incrementButtonFactory == value)
            {
                return;
            }
            this._incrementButtonFactory = value;
            this.invalidate(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _customIncrementButtonName:String;

        /**
         * A name to add to the scroll bar's increment button sub-component. Typically
         * used by a theme to provide different skins to different scroll bars.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #incrementButtonFactory
         * @see #incrementButtonProperties
         */
        public function get customIncrementButtonName():String
        {
            return this._customIncrementButtonName;
        }

        /**
         * @private
         */
        public function set customIncrementButtonName(value:String):void
        {
            if(this._customIncrementButtonName == value)
            {
                return;
            }
            this._customIncrementButtonName = value;
            this.invalidate(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _incrementButtonProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the scroll bar's
         * increment button sub-component. The increment button is a
         * `feathers.controls.Button` instance that is created by
         * `incrementButtonFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `incrementButtonFactory`
         * function instead of using `incrementButtonProperties` will
         * result in better performance.
         *
         * @see #incrementButtonFactory
         * @see feathers.controls.Button
         */
        public function get incrementButtonProperties():Dictionary.<String, Object>
        {
            if(!this._incrementButtonProperties)
            {
                this._incrementButtonProperties = new Dictionary.<String, Object>;
            }
            return this._incrementButtonProperties;
        }

        /**
         * @private
         */
        public function set incrementButtonProperties(value:Dictionary.<String, Object>):void
        {
            if(this._incrementButtonProperties == value)
            {
                return;
            }
            this._incrementButtonProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _touchPointID:int = -1;

        /**
         * @private
         */
        protected var _touchStartX:Number = NaN;

        /**
         * @private
         */
        protected var _touchStartY:Number = NaN;

        /**
         * @private
         */
        protected var _thumbStartX:Number = NaN;

        /**
         * @private
         */
        protected var _thumbStartY:Number = NaN;

        /**
         * @private
         */
        protected var _touchValue:Number;

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const thumbFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_THUMB_FACTORY);
            const minimumTrackFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY);
            const maximumTrackFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY);
            const incrementButtonFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_INCREMENT_BUTTON_FACTORY);
            const decrementButtonFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DECREMENT_BUTTON_FACTORY);

            if(thumbFactoryInvalid)
            {
                this.createThumb();
            }
            if(minimumTrackFactoryInvalid)
            {
                this.createMinimumTrack();
            }
            this.createOrDestroyMaximumTrackIfNeeded(maximumTrackFactoryInvalid);
            if(decrementButtonFactoryInvalid)
            {
                this.createDecrementButton();
            }
            if(incrementButtonFactoryInvalid)
            {
                this.createIncrementButton();
            }

            if(thumbFactoryInvalid || stylesInvalid)
            {
                this.refreshThumbStyles();
            }
            if(minimumTrackFactoryInvalid || stylesInvalid)
            {
                this.refreshMinimumTrackStyles();
            }
            if((maximumTrackFactoryInvalid || stylesInvalid) && this.maximumTrack)
            {
                this.refreshMaximumTrackStyles();
            }
            if(decrementButtonFactoryInvalid || stylesInvalid)
            {
                this.refreshDecrementButtonStyles();
            }
            if(incrementButtonFactoryInvalid || stylesInvalid)
            {
                this.refreshIncrementButtonStyles();
            }

            const isEnabled:Boolean = this._isEnabled && this._maximum > this._minimum;
            if(stateInvalid || dataInvalid || thumbFactoryInvalid)
            {
                this.thumb.isEnabled = isEnabled;
            }
            if(stateInvalid || dataInvalid || minimumTrackFactoryInvalid)
            {
                this.minimumTrack.isEnabled = isEnabled;
            }
            if((stateInvalid || dataInvalid || maximumTrackFactoryInvalid) && this.maximumTrack)
            {
                this.maximumTrack.isEnabled = isEnabled;
            }
            if(stateInvalid || dataInvalid || decrementButtonFactoryInvalid)
            {
                this.decrementButton.isEnabled = isEnabled;
            }
            if(stateInvalid || dataInvalid || incrementButtonFactoryInvalid)
            {
                this.incrementButton.isEnabled = isEnabled;
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(thumbFactoryInvalid || minimumTrackFactoryInvalid || maximumTrackFactoryInvalid ||
                decrementButtonFactoryInvalid || incrementButtonFactoryInvalid ||
                dataInvalid || stylesInvalid || sizeInvalid)
            {
                this.layout();
            }
        }

        /**
         * @private
         */
        protected function autoSizeIfNeeded():Boolean
        {
            if(isNaN(this.minimumTrackOriginalWidth) || isNaN(this.minimumTrackOriginalHeight))
            {
                this.minimumTrack.validate();
                this.minimumTrackOriginalWidth = this.minimumTrack.width;
                this.minimumTrackOriginalHeight = this.minimumTrack.height;
            }
            if(this.maximumTrack)
            {
                if(isNaN(this.maximumTrackOriginalWidth) || isNaN(this.maximumTrackOriginalHeight))
                {
                    this.maximumTrack.validate();
                    this.maximumTrackOriginalWidth = this.maximumTrack.width;
                    this.maximumTrackOriginalHeight = this.maximumTrack.height;
                }
            }
            if(isNaN(this.thumbOriginalWidth) || isNaN(this.thumbOriginalHeight))
            {
                this.thumb.validate();
                this.thumbOriginalWidth = this.thumb.width;
                this.thumbOriginalHeight = this.thumb.height;
            }
            this.decrementButton.validate();
            this.incrementButton.validate();

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
                if(this._direction == DIRECTION_VERTICAL)
                {
                    if(this.maximumTrack)
                    {
                        newWidth = Math.max(this.minimumTrackOriginalWidth, this.maximumTrackOriginalWidth);
                    }
                    else
                    {
                        newWidth = this.minimumTrackOriginalWidth;
                    }
                }
                else //horizontal
                {
                    if(this.maximumTrack)
                    {
                        newWidth = Math.min(this.minimumTrackOriginalWidth, this.maximumTrackOriginalWidth) + this.thumb.width / 2;
                    }
                    else
                    {
                        newWidth = this.minimumTrackOriginalWidth;
                    }
                }
            }
            if(needsHeight)
            {
                if(this._direction == DIRECTION_VERTICAL)
                {
                    if(this.maximumTrack)
                    {
                        newHeight = Math.min(this.minimumTrackOriginalHeight, this.maximumTrackOriginalHeight) + this.thumb.height / 2;
                    }
                    else
                    {
                        newHeight = this.minimumTrackOriginalHeight;
                    }
                }
                else //horizontal
                {
                    if(this.maximumTrack)
                    {
                        newHeight = Math.max(this.minimumTrackOriginalHeight, this.maximumTrackOriginalHeight);
                    }
                    else
                    {
                        newHeight = this.minimumTrackOriginalHeight;
                    }
                }
            }
            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function createThumb():void
        {
            if(this.thumb)
            {
                this.thumb.removeFromParent(true);
                this.thumb = null;
            }

            const factory:Function = this._thumbFactory != null ? this._thumbFactory : defaultThumbFactory;
            const thumbName:String = this._customThumbName != null ? this._customThumbName : this.thumbName;
            this.thumb = Button(factory.call());
            this.thumb.nameList.add(thumbName);
            this.thumb.keepDownStateOnRollOut = true;
            this.thumb.addEventListener(TouchEvent.TOUCH, thumb_touchHandler);
            this.addChild(this.thumb);
        }

        /**
         * @private
         */
        protected function createMinimumTrack():void
        {
            if(this.minimumTrack)
            {
                this.minimumTrack.removeFromParent(true);
                this.minimumTrack = null;
            }

            const factory:Function = this._minimumTrackFactory != null ? this._minimumTrackFactory : defaultMinimumTrackFactory;
            const minimumTrackName:String = this._customMinimumTrackName != null ? this._customMinimumTrackName : this.minimumTrackName;
            this.minimumTrack = Button(factory.call());
            this.minimumTrack.nameList.add(minimumTrackName);
            this.minimumTrack.keepDownStateOnRollOut = true;
            this.minimumTrack.addEventListener(TouchEvent.TOUCH, track_touchHandler);
            this.addChildAt(this.minimumTrack, 0);
        }

        /**
         * @private
         */
        protected function createOrDestroyMaximumTrackIfNeeded(maximumTrackFactoryInvalid:Boolean):void
        {
            if(this._trackLayoutMode == TRACK_LAYOUT_MODE_MIN_MAX)
            {
                if(!maximumTrackFactoryInvalid)
                {
                    return;
                }
                if(this.maximumTrack)
                {
                    this.maximumTrack.removeFromParent(true);
                    this.maximumTrack = null;
                }
                const factory:Function = this._maximumTrackFactory != null ? this._maximumTrackFactory : defaultMaximumTrackFactory;
                const maximumTrackName:String = this._customMaximumTrackName != null ? this._customMaximumTrackName : this.maximumTrackName;
                this.maximumTrack = Button(factory.call());
                this.maximumTrack.nameList.add(maximumTrackName);
                this.maximumTrack.keepDownStateOnRollOut = true;
                this.maximumTrack.addEventListener(TouchEvent.TOUCH, track_touchHandler);
                this.addChildAt(this.maximumTrack, 1);
            }
            else if(this.maximumTrack) //single
            {
                this.maximumTrack.removeFromParent(true);
                this.maximumTrack = null;
            }
        }

        /**
         * @private
         */
        protected function createDecrementButton():void
        {
            if(this.decrementButton)
            {
                this.decrementButton.removeFromParent(true);
                this.decrementButton = null;
            }

            const factory:Function = this._decrementButtonFactory != null ? this._decrementButtonFactory : defaultDecrementButtonFactory;
            const decrementButtonName:String = this._customDecrementButtonName != null ? this._customDecrementButtonName : this.decrementButtonName;
            this.decrementButton = Button(factory.call());
            this.decrementButton.nameList.add(decrementButtonName);
            this.decrementButton.keepDownStateOnRollOut = true;
            this.decrementButton.addEventListener(TouchEvent.TOUCH, decrementButton_touchHandler);
            this.addChild(this.decrementButton);
        }

        /**
         * @private
         */
        protected function createIncrementButton():void
        {
            if(this.incrementButton)
            {
                this.incrementButton.removeFromParent(true);
                this.incrementButton = null;
            }

            const factory:Function = this._incrementButtonFactory != null ? this._incrementButtonFactory : defaultIncrementButtonFactory;
            const incrementButtonName:String = this._customIncrementButtonName != null ? this._customIncrementButtonName : this.incrementButtonName;
            this.incrementButton = Button(factory.call());
            this.incrementButton.nameList.add(incrementButtonName);
            this.incrementButton.keepDownStateOnRollOut = true;
            this.incrementButton.addEventListener(TouchEvent.TOUCH, incrementButton_touchHandler);
            this.addChild(this.incrementButton);
        }

        /**
         * @private
         */
        protected function refreshThumbStyles():void
        {
            Dictionary.mapToObject(this._thumbProperties, this.thumb);
        }

        /**
         * @private
         */
        protected function refreshMinimumTrackStyles():void
        {
            Dictionary.mapToObject(this._minimumTrackProperties, this.minimumTrack);
        }

        /**
         * @private
         */
        protected function refreshMaximumTrackStyles():void
        {
            if(!this.maximumTrack)
            {
                return;
            }

            Dictionary.mapToObject(this._maximumTrackProperties, this.maximumTrack);
        }

        /**
         * @private
         */
        protected function refreshDecrementButtonStyles():void
        {
            Dictionary.mapToObject(this._decrementButtonProperties, this.decrementButton);
        }

        /**
         * @private
         */
        protected function refreshIncrementButtonStyles():void
        {
            Dictionary.mapToObject(this._incrementButtonProperties, this.incrementButton);
        }

        /**
         * @private
         */
        protected function layout():void
        {
            this.layoutStepButtons();
            this.layoutThumb();

            if(this._trackLayoutMode == TRACK_LAYOUT_MODE_MIN_MAX)
            {
                this.layoutTrackWithMinMax();
            }
            else //single
            {
                this.layoutTrackWithSingle();
            }
        }

        /**
         * @private
         */
        protected function layoutStepButtons():void
        {
            if(this._direction == DIRECTION_VERTICAL)
            {
                this.decrementButton.x = (this.actualWidth - this.decrementButton.width) / 2;
                this.decrementButton.y = 0;
                this.incrementButton.x = (this.actualWidth - this.incrementButton.width) / 2;
                this.incrementButton.y = this.actualHeight - this.incrementButton.height;
            }
            else
            {
                this.decrementButton.x = 0;
                this.decrementButton.y = (this.actualHeight - this.decrementButton.height) / 2;
                this.incrementButton.x = this.actualWidth - this.incrementButton.width;
                this.incrementButton.y = (this.actualHeight - this.incrementButton.height) / 2;
            }
        }

        /**
         * @private
         */
        protected function layoutThumb():void
        {
            const range:Number = this._maximum - this._minimum;
            this.thumb.visible = range > 0;
            if(!this.thumb.visible)
            {
                return;
            }

            //this will auto-size the thumb, if needed
            this.thumb.validate();

            var contentWidth:Number = this.actualWidth - this._paddingLeft - this._paddingRight;
            var contentHeight:Number = this.actualHeight - this._paddingTop - this._paddingBottom;
            const adjustedPageStep:Number = Math.min(range, this._page == 0 ? range : this._page);
            var valueOffset:Number = 0;
            if(this._value < this._minimum)
            {
                valueOffset = (this._minimum - this._value);
            }
            if(this._value > this._maximum)
            {
                valueOffset = (this._value - this._maximum);
            }
            if(this._direction == DIRECTION_VERTICAL)
            {
                contentHeight -= (this.decrementButton.height + this.incrementButton.height);
                const thumbMinHeight:Number = this.thumb.minHeight > 0 ? this.thumb.minHeight : this.thumbOriginalHeight;
                this.thumb.width = this.thumbOriginalWidth;
                this.thumb.height = Math.max(thumbMinHeight, contentHeight * adjustedPageStep / range);
                const trackScrollableHeight:Number = contentHeight - this.thumb.height;
                this.thumb.x = this._paddingLeft + (this.actualWidth - this._paddingLeft - this._paddingRight - this.thumb.width) / 2;
                this.thumb.y = this.decrementButton.height + this._paddingTop + Math.max(0, Math.min(trackScrollableHeight, trackScrollableHeight * (this._value - this._minimum) / range));
            }
            else //horizontal
            {
                contentWidth -= (this.decrementButton.width + this.decrementButton.width);
                const thumbMinWidth:Number = this.thumb.minWidth > 0 ? this.thumb.minWidth : this.thumbOriginalWidth;
                this.thumb.width = Math.max(thumbMinWidth, contentWidth * adjustedPageStep / range);
                this.thumb.height = this.thumbOriginalHeight;
                const trackScrollableWidth:Number = contentWidth - this.thumb.width;
                this.thumb.x = this.decrementButton.width + this._paddingLeft + Math.max(0, Math.min(trackScrollableWidth, trackScrollableWidth * (this._value - this._minimum) / range));
                this.thumb.y = this._paddingTop + (this.actualHeight - this._paddingTop - this._paddingBottom - this.thumb.height) / 2;
            }
        }

        /**
         * @private
         */
        protected function layoutTrackWithMinMax():void
        {
            if(this._direction == DIRECTION_VERTICAL)
            {
                this.minimumTrack.x = 0;
                this.minimumTrack.y = 0;
                this.minimumTrack.width = this.actualWidth;
                this.minimumTrack.height = (this.thumb.y + this.thumb.height / 2) - this.minimumTrack.y;

                this.maximumTrack.x = 0;
                this.maximumTrack.y = this.minimumTrack.y + this.minimumTrack.height;
                this.maximumTrack.width = this.actualWidth;
                this.maximumTrack.height = this.actualHeight - this.maximumTrack.y;
            }
            else //horizontal
            {
                this.minimumTrack.x = 0;
                this.minimumTrack.y = 0;
                this.minimumTrack.width = (this.thumb.x + this.thumb.width / 2) - this.minimumTrack.x;
                this.minimumTrack.height = this.actualHeight;

                this.maximumTrack.x = this.minimumTrack.x + this.minimumTrack.width;
                this.maximumTrack.y = 0;
                this.maximumTrack.width = this.actualWidth - this.maximumTrack.x;
                this.maximumTrack.height = this.actualHeight;
            }
        }

        /**
         * @private
         */
        protected function layoutTrackWithSingle():void
        {
            if(this._direction == DIRECTION_VERTICAL)
            {
                this.minimumTrack.x = 0;
                this.minimumTrack.y = 0;
                this.minimumTrack.width = this.actualWidth;
                this.minimumTrack.height = this.actualHeight - this.minimumTrack.y;
            }
            else //horizontal
            {
                this.minimumTrack.x = 0;
                this.minimumTrack.y = 0;
                this.minimumTrack.width = this.actualWidth - this.minimumTrack.x;
                this.minimumTrack.height = this.actualHeight;
            }
        }

        /**
         * @private
         */
        protected function locationToValue(location:Point):Number
        {
            var percentage:Number;
            if(this._direction == DIRECTION_VERTICAL)
            {
                const trackScrollableHeight:Number = this.actualHeight - this.thumb.height - this.decrementButton.height - this.incrementButton.height - this._paddingTop - this._paddingBottom;
                const yOffset:Number = location.y - this._touchStartY - this._paddingTop;
                const yPosition:Number = Math.min(Math.max(0, this._thumbStartY + yOffset - this.decrementButton.height), trackScrollableHeight);
                percentage = yPosition / trackScrollableHeight;
            }
            else //horizontal
            {
                const trackScrollableWidth:Number = this.actualWidth - this.thumb.width - this.decrementButton.width - this.incrementButton.width - this._paddingLeft - this._paddingRight;
                const xOffset:Number = location.x - this._touchStartX - this._paddingLeft;
                const xPosition:Number = Math.min(Math.max(0, this._thumbStartX + xOffset - this.decrementButton.width), trackScrollableWidth);
                percentage = xPosition / trackScrollableWidth;
            }

            return this._minimum + percentage * (this._maximum - this._minimum);
        }

        /**
         * @private
         */
        protected function decrement():void
        {
            this.value -= this._step;
        }

        /**
         * @private
         */
        protected function increment():void
        {
            this.value += this._step;
        }

        /**
         * @private
         */
        protected function adjustPage():void
        {
            if(this._touchValue < this._value)
            {
                var newValue:Number = Math.max(this._touchValue, this._value - this._page);
                if(this._step != 0 && newValue != this._maximum && newValue != this._minimum)
                {
                    newValue = FeathersMath.roundToNearest(newValue, this._step);
                }
                this.value = newValue;
            }
            else if(this._touchValue > this._value)
            {
                newValue = Math.min(this._touchValue, this._value + this._page);
                if(this._step != 0 && newValue != this._maximum && newValue != this._minimum)
                {
                    newValue = FeathersMath.roundToNearest(newValue, this._step);
                }
                this.value = newValue;
            }
        }

        /**
         * @private
         */
        protected function startRepeatTimer(action:Function):void
        {
            this.currentRepeatAction = action;
            if(this._repeatDelay > 0)
            {
                if(!this._repeatTimer)
                {
                    this._repeatTimer = new Timer(this._repeatDelay * 1000);
                    this._repeatTimer.onComplete += repeatTimer_timerHandler;
                }
                else
                {
                    this._repeatTimer.reset();
                    this._repeatTimer.delay = this._repeatDelay * 1000;
                }
                this._repeatTimer.start();
            }
        }

        /**
         * @private
         */
        protected function removedFromStageHandler(event:Event):void
        {
            this._touchPointID = -1;
            if(this._repeatTimer)
            {
                this._repeatTimer.stop();
            }
        }

        /**
         * @private
         */
        protected function track_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                this._touchPointID = -1;
                return;
            }

            const touches:Vector.<Touch> = event.getTouches(DisplayObject(event.currentTarget), null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                return;
            }
            if(this._touchPointID >= 0)
            {
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
                if(touch.phase == TouchPhase.ENDED)
                {
                    this._touchPointID = -1;
                    this._repeatTimer.stop();
                    this.dispatchEventWith(FeathersEventType.END_INTERACTION);
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this._touchPointID = touch.id;
                        this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                        HELPER_POINT = touch.getLocation(this);
                        this._touchStartX = HELPER_POINT.x;
                        this._touchStartY = HELPER_POINT.y;
                        this._thumbStartX = HELPER_POINT.x;
                        this._thumbStartY = HELPER_POINT.y;
                        this._touchValue = this.locationToValue(HELPER_POINT);
                        this.adjustPage();
                        this.startRepeatTimer(this.adjustPage);
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function thumb_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                return;
            }
            const touches:Vector.<Touch> = event.getTouches(this.thumb, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                return;
            }
            if(this._touchPointID >= 0)
            {
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
                    HELPER_POINT = touch.getLocation(this);
                    var newValue:Number = this.locationToValue(HELPER_POINT);
                    if(this._step != 0 && newValue != this._maximum && newValue != this._minimum)
                    {
                        newValue = FeathersMath.roundToNearest(newValue, this._step);
                    }
                    this.value = newValue;
                }
                else if(touch.phase == TouchPhase.ENDED)
                {
                    this._touchPointID = -1;
                    this.isDragging = false;
                    if(!this.liveDragging)
                    {
                        this.dispatchEventWith(Event.CHANGE);
                    }
                    this.dispatchEventWith(FeathersEventType.END_INTERACTION);
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        HELPER_POINT = touch.getLocation(this);
                        this._touchPointID = touch.id;
                        this._thumbStartX = this.thumb.x;
                        this._thumbStartY = this.thumb.y;
                        this._touchStartX = HELPER_POINT.x;
                        this._touchStartY = HELPER_POINT.y;
                        this.isDragging = true;
                        this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function decrementButton_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                return;
            }
            const touches:Vector.<Touch> = event.getTouches(this.decrementButton, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                return;
            }

            if(this._touchPointID >= 0)
            {
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
                    //end of hover
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this._touchPointID = -1;
                    this._repeatTimer.stop();
                    this.dispatchEventWith(FeathersEventType.END_INTERACTION);
                }
            }
            else //if we get here, we don't have a saved touch ID yet
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                        this.decrement();
                        this.startRepeatTimer(this.decrement);
                        this._touchPointID = touch.id;
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function incrementButton_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                return;
            }
            const touches:Vector.<Touch> = event.getTouches(this.incrementButton, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                return;
            }

            if(this._touchPointID >= 0)
            {
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
                    //end of hover
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }
                if(touch.phase == TouchPhase.ENDED)
                {
                    this._touchPointID = -1;
                    this._repeatTimer.stop();
                    this.dispatchEventWith(FeathersEventType.END_INTERACTION);
                }
            }
            else //if we get here, we don't have a saved touch ID yet
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                        this.increment();
                        this.startRepeatTimer(this.increment);
                        this._touchPointID = touch.id;
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

        /**
         * @private
         */
        protected function repeatTimer_timerHandler(timer:Timer):void
        {
            if(this._repeatTimer.currentCount < 5)
            {
                return;
            }
            this.currentRepeatAction.call();
        }
    }
}
