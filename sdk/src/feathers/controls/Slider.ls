/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.core.IFocusDisplayObject;
    import feathers.events.FeathersEventType;
    import feathers.utils.FeathersMath;

    import loom2d.math.Point;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.KeyboardEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    
    import loom.platform.Timer;
    import loom.platform.LoomKey;

    /**
     * Dispatched when the slider's value changes.
     *
     * @eventType starling.events.Event.CHANGE
     */
    [Event(name="change",type="starling.events.Event")]

    /**
     * Dispatched when the user starts dragging the slider's thumb or track.
     *
     * @eventType feathers.events.FeathersEventType.BEGIN_INTERACTION
     */
    [Event(name="beginInteraction",type="starling.events.Event")]

    /**
     * Dispatched when the user stops dragging the slider's thumb or track.
     *
     * @eventType feathers.events.FeathersEventType.END_INTERACTION
     */
    [Event(name="endInteraction",type="starling.events.Event")]

    /**
     * Select a value between a minimum and a maximum by dragging a thumb over
     * the bounds of a track. The slider's track is divided into two parts split
     * by the thumb.
     *
     * @see http://wiki.starling-framework.org/feathers/slider
     */
    public class Slider extends FeathersControl implements IScrollBar, IFocusDisplayObject
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
         * The slider's thumb may be dragged horizontally (on the x-axis).
         *
         * #direction
         */
        public static const DIRECTION_HORIZONTAL:String = "horizontal";
        
        /**
         * The slider's thumb may be dragged vertically (on the y-axis).
         *
         * #direction
         */
        public static const DIRECTION_VERTICAL:String = "vertical";

        /**
         * The slider has only one track, that fills the full length of the
         * slider. In this layout mode, the "minimum" track is displayed and
         * fills the entire length of the slider. The maximum track will not
         * exist.
         *
         * #trackLayoutMode
         */
        public static const TRACK_LAYOUT_MODE_SINGLE:String = "single";

        /**
         * The slider has two tracks, stretching to fill each side of the slider
         * with the thumb in the middle. The tracks will be resized as the thumb
         * moves. This layout mode is designed for sliders where the two sides
         * of the track may be colored differently to show the value
         * "filling up" as the slider is dragged.
         *
         * Since the width and height of the tracks will change, consider
         * sing a special display object such as a `Scale9Image`,
         * `Scale3Image` or a `TiledImage` that is
         * designed to be resized dynamically.
         *
         * #trackLayoutMode
         * @see feathers.display.Scale9Image
         * @see feathers.display.Scale3Image
         * @see feathers.display.TiledImage
         */
        public static const TRACK_LAYOUT_MODE_MIN_MAX:String = "minMax";

        /**
         * The slider's track dimensions fill the full width and height of the
         * slider.
         *
         * #trackScaleMode
         */
        public static const TRACK_SCALE_MODE_EXACT_FIT:String = "exactFit";

        /**
         * If the slider's direction is horizontal, the width of the track will
         * fill the full width of the slider, and if the slider's direction is
         * vertical, the height of the track will fill the full height of the
         * slider. The other edge will not be scaled.
         *
         * #trackScaleMode
         */
        public static const TRACK_SCALE_MODE_DIRECTIONAL:String = "directional";

        /**
         * The default value added to the `nameList` of the minimum
         * track.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_MINIMUM_TRACK:String = "feathers-slider-minimum-track";

        /**
         * The default value added to the `nameList` of the maximum
         * track.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_MAXIMUM_TRACK:String = "feathers-slider-maximum-track";

        /**
         * The default value added to the `nameList` of the thumb.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_THUMB:String = "feathers-slider-thumb";

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
         * Constructor.
         */
        public function Slider()
        {
            super();
            this.addEventListener(Event.REMOVED_FROM_STAGE, slider_removedFromStageHandler);
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
         * The thumb sub-component.
         */
        protected var thumb:Button;
        
        /**
         * The minimum track sub-component.
         */
        protected var minimumTrack:Button;

        /**
         * The maximum track sub-component.
         */
        protected var maximumTrack:Button;

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
         * @private
         */
        protected var _direction:String = DIRECTION_HORIZONTAL;

        [Inspectable(type="String",enumeration="horizontal,vertical")]
        /**
         * Determines if the slider's thumb can be dragged horizontally or
         * vertically. When this value changes, the slider's width and height
         * values do not change automatically.
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
            this.invalidate(INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY);
            this.invalidate(INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY);
            this.invalidate(INVALIDATION_FLAG_THUMB_FACTORY);
        }
        
        /**
         * @private
         */
        protected var _value:Number = 0;
        
        /**
         * The value of the slider, between the minimum and maximum.
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
            if(this._step != 0 && newValue != this._maximum && newValue != this._minimum)
            {
                newValue = FeathersMath.roundToNearest(newValue, this._step);
            }
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
         * The slider's value will not go lower than the minimum.
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
         * The slider's value will not go higher than the maximum.
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
         * As the slider's thumb is dragged, the value is snapped to a multiple
         * of the step. Paging using the slider's track will use the `step`
         * value if the `page` value is `NaN`. If the
         * `step` is zero, paging with the track will not be possible.
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
            if(this._step == value)
            {
                return;
            }
            this._step = value;
        }

        /**
         * @private
         */
        protected var _page:Number = NaN;

        /**
         * If the slider's track is touched, and the thumb is shown, the slider
         * value will be incremented or decremented by the page value. If the
         * thumb is hidden, this value is ignored, and the track may be dragged
         * instead.
         *
         * If this value is `NaN`, the `step` value
         * will be used instead. If the `step` value is zero, paging
         * with the track is not possible.
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
        }
        
        /**
         * @private
         */
        protected var isDragging:Boolean = false;
        
        /**
         * Determines if the slider dispatches the `Event.CHANGE`
         * event every time the thumb moves, or only once it stops moving.
         */
        public var liveDragging:Boolean = true;
        
        /**
         * @private
         */
        protected var _showThumb:Boolean = true;
        
        /**
         * Determines if the thumb should be displayed.
         */
        public function get showThumb():Boolean
        {
            return this._showThumb;
        }
        
        /**
         * @private
         */
        public function set showThumb(value:Boolean):void
        {
            if(this._showThumb == value)
            {
                return;
            }
            this._showThumb = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _minimumPadding:Number = 0;

        /**
         * The space, in pixels, between the minimum position of the thumb and
         * the minimum edge of the track. May be negative to extend the range of
         * the thumb.
         */
        public function get minimumPadding():Number
        {
            return this._minimumPadding;
        }

        /**
         * @private
         */
        public function set minimumPadding(value:Number):void
        {
            if(this._minimumPadding == value)
            {
                return;
            }
            this._minimumPadding = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _maximumPadding:Number = 0;

        /**
         * The space, in pixels, between the maximum position of the thumb and
         * the maximum edge of the track. May be negative to extend the range
         * of the thumb.
         */
        public function get maximumPadding():Number
        {
            return this._maximumPadding;
        }

        /**
         * @private
         */
        public function set maximumPadding(value:Number):void
        {
            if(this._maximumPadding == value)
            {
                return;
            }
            this._maximumPadding = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

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
         *
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
        protected var _trackScaleMode:String = TRACK_SCALE_MODE_DIRECTIONAL;

        [Inspectable(type="String",enumeration="exactFit,directional")]
        /**
         * Determines how the minimum and maximum track skins are positioned and
         * sized.
         *
         * @default TRACK_SCALE_MODE_DIRECTIONAL
         *
         * @see #TRACK_SCALE_MODE_DIRECTIONAL
         * @see #TRACK_SCALE_MODE_EXACT_FIT
         * @see #trackLayoutMode
         */
        public function get trackScaleMode():String
        {
            return this._trackScaleMode;
        }

        /**
         * @private
         */
        public function set trackScaleMode(value:String):void
        {
            if(this._trackScaleMode == value)
            {
                return;
            }
            this._trackScaleMode = value;
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
        protected var _minimumTrackFactory:Function;

        /**
         * A function used to generate the slider's minimum track sub-component.
         * The minimum track must be an instance of `Button`. This
         * factory can be used to change properties on the minimum track when it
         * is first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on the minimum track.
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
         * A name to add to the slider's minimum track sub-component. Typically
         * used by a theme to provide different skins to different sliders.
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
         * A set of key/value pairs to be passed down to the slider's minimum
         * track sub-component. The minimum track is a
         * `feathers.controls.Button` instance that is created by
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
        public function get minimumTrackProperties():Dictionary.<String, Object>
        {
            if(!this._minimumTrackProperties)
            {
                this._minimumTrackProperties = {};
            }
            return this._minimumTrackProperties;
        }

        /**
         * @private
         */
        public function set minimumTrackProperties(value:Dictionary.<String, Object>):void
        {
            if(this._minimumTrackProperties == value)
            {
                return;
            }
            
            if(!value)
            {
                value = {};
            }

            this._minimumTrackProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _maximumTrackFactory:Function;

        /**
         * A function used to generate the slider's maximum track sub-component.
         * The maximum track must be an instance of `Button`.
         * This factory can be used to change properties on the maximum track
         * when it is first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on the maximum track.
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
         * A name to add to the slider's maximum track sub-component. Typically
         * used by a theme to provide different skins to different sliders.
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
         * A set of key/value pairs to be passed down to the slider's maximum
         * track sub-component. The maximum track is a
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
                this._maximumTrackProperties = {};
            }
            return this._maximumTrackProperties;
        }
        
        /**
         * @private
         */
        public function set maximumTrackProperties(value:Dictionary.<String, Object>):void
        {
            if(this._maximumTrackProperties == value)
            {
                return;
            }
            
            if(!value)
            {
                value = {};
            }

            this._maximumTrackProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _thumbFactory:Function;

        /**
         * A function used to generate the slider's thumb sub-component.
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
         * A name to add to the slider's thumb sub-component. Typically
         * used by a theme to provide different skins to different sliders.
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
         * A set of key/value pairs to be passed down to the slider's thumb
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
         * @see feathers.controls.Button
         * @see #thumbFactory
         */
        public function get thumbProperties():Dictionary.<String, Object>
        {
            if(!this._thumbProperties)
            {
                this._thumbProperties = {};
            }
            return this._thumbProperties;
        }
        
        /**
         * @private
         */
        public function set thumbProperties(value:Dictionary.<String, Object>):void
        {
            if(this._thumbProperties == value)
            {
                return;
            }
            
            if(!value)
            {
                value = {};
            }
            
            this._thumbProperties = value;
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
            const focusInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_FOCUS);
            const thumbFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_THUMB_FACTORY);
            const minimumTrackFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_MINIMUM_TRACK_FACTORY);
            const maximumTrackFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_MAXIMUM_TRACK_FACTORY);

            if(thumbFactoryInvalid)
            {
                this.createThumb();
            }

            if(minimumTrackFactoryInvalid)
            {
                this.createMinimumTrack();
            }

            this.createOrDestroyMaximumTrackIfNeeded(maximumTrackFactoryInvalid);

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
            
            if(thumbFactoryInvalid || stateInvalid)
            {
                this.thumb.isEnabled = this._isEnabled;
            }
            if(minimumTrackFactoryInvalid || stateInvalid)
            {
                this.minimumTrack.isEnabled = this._isEnabled;
            }
            if((maximumTrackFactoryInvalid || stateInvalid) && this.maximumTrack)
            {
                this.maximumTrack.isEnabled = this._isEnabled;
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(thumbFactoryInvalid || minimumTrackFactoryInvalid || maximumTrackFactoryInvalid ||
                dataInvalid || stylesInvalid || sizeInvalid)
            {
                this.layoutChildren();
            }

            if(sizeInvalid || focusInvalid)
            {
                this.refreshFocusIndicator();
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

            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }
            this.thumb.validate();
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
                newWidth = Math.max(newWidth, this.thumb.width);
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
                newHeight = Math.max(newHeight, this.thumb.height);
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
            this.thumb = Button(factory());
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
            this.minimumTrack = Button(factory());
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
                this.maximumTrack = Button(factory());
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
        protected function refreshThumbStyles():void
        {
            Dictionary.mapToObject( this._thumbProperties, this.thumb );
            this.thumb.visible = this._showThumb;
        }
        
        /**
         * @private
         */
        protected function refreshMinimumTrackStyles():void
        {
            Dictionary.mapToObject( this._minimumTrackProperties, this.minimumTrack );
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
            
            Dictionary.mapToObject( this._maximumTrackProperties, this.maximumTrack );
        }

        /**
         * @private
         */
        protected function layoutChildren():void
        {
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
        protected function layoutThumb():void
        {
            //this will auto-size the thumb, if needed
            this.thumb.validate();

            if(this._direction == DIRECTION_VERTICAL)
            {
                const trackScrollableHeight:Number = this.actualHeight - this.thumb.height - this._minimumPadding - this._maximumPadding;
                this.thumb.x = (this.actualWidth - this.thumb.width) / 2;
                this.thumb.y = this._minimumPadding + trackScrollableHeight * (1 - (this._value - this._minimum) / (this._maximum - this._minimum));
            }
            else
            {
                const trackScrollableWidth:Number = this.actualWidth - this.thumb.width - this._minimumPadding - this._maximumPadding;
                this.thumb.x = this._minimumPadding + (trackScrollableWidth * (this._value - this._minimum) / (this._maximum - this._minimum));
                this.thumb.y = (this.actualHeight - this.thumb.height) / 2;
            }
        }

        /**
         * @private
         */
        protected function layoutTrackWithMinMax():void
        {
            if(this._direction == DIRECTION_VERTICAL)
            {
                this.maximumTrack.y = 0;
                this.maximumTrack.height = this.thumb.y + this.thumb.height / 2;
                this.minimumTrack.y = this.maximumTrack.height;
                this.minimumTrack.height = this.actualHeight - this.minimumTrack.y;

                if(this._trackScaleMode == TRACK_SCALE_MODE_DIRECTIONAL)
                {
                    this.maximumTrack.width = NaN;
                    this.maximumTrack.validate();
                    this.maximumTrack.x = (this.actualWidth - this.maximumTrack.width) / 2;
                    this.minimumTrack.width = NaN;
                    this.minimumTrack.validate();
                    this.minimumTrack.x = (this.actualWidth - this.minimumTrack.width) / 2;
                }
                else //exact fit
                {
                    this.maximumTrack.x = 0;
                    this.maximumTrack.width = this.actualWidth;
                    this.minimumTrack.x = 0;
                    this.minimumTrack.width = this.actualWidth;
                }
            }
            else //horizontal
            {
                this.minimumTrack.x = 0;
                this.minimumTrack.width = this.thumb.x + this.thumb.width / 2;
                this.maximumTrack.x = this.minimumTrack.width;
                this.maximumTrack.width = this.actualWidth - this.maximumTrack.x;

                if(this._trackScaleMode == TRACK_SCALE_MODE_DIRECTIONAL)
                {
                    this.minimumTrack.height = NaN;
                    this.minimumTrack.validate();
                    this.minimumTrack.y = (this.actualHeight - this.minimumTrack.height) / 2;
                    this.maximumTrack.height = NaN;
                    this.maximumTrack.validate();
                    this.maximumTrack.y = (this.actualHeight - this.maximumTrack.height) / 2;
                }
                else //exact fit
                {
                    this.minimumTrack.y = 0;
                    this.minimumTrack.height = this.actualHeight;
                    this.maximumTrack.y = 0;
                    this.maximumTrack.height = this.actualHeight;
                }
            }
        }

        /**
         * @private
         */
        protected function layoutTrackWithSingle():void
        {
            if(this._trackScaleMode == TRACK_SCALE_MODE_DIRECTIONAL)
            {
                if(this._direction == DIRECTION_VERTICAL)
                {
                    this.minimumTrack.y = 0;
                    this.minimumTrack.width = NaN;
                    this.minimumTrack.height = this.actualHeight;
                    this.minimumTrack.validate();
                    this.minimumTrack.x = (this.actualWidth - this.minimumTrack.width) / 2;
                }
                else //horizontal
                {
                    this.minimumTrack.x = 0;
                    this.minimumTrack.width = this.actualWidth;
                    this.minimumTrack.height = NaN;
                    this.minimumTrack.validate();
                    this.minimumTrack.y = (this.actualHeight - this.minimumTrack.height) / 2;
                }
            }
            else //exact fit
            {
                this.minimumTrack.x = 0;
                this.minimumTrack.y = 0;
                this.minimumTrack.width = this.actualWidth;
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
                const trackScrollableHeight:Number = this.actualHeight - this.thumb.height - this._minimumPadding - this._maximumPadding;
                const yOffset:Number = location.y - this._touchStartY - this._maximumPadding;
                const yPosition:Number = Math.min(Math.max(0, this._thumbStartY + yOffset), trackScrollableHeight);
                percentage = 1 - (yPosition / trackScrollableHeight);
            }
            else //horizontal
            {
                const trackScrollableWidth:Number = this.actualWidth - this.thumb.width - this._minimumPadding - this._maximumPadding;
                const xOffset:Number = location.x - this._touchStartX - this._minimumPadding;
                const xPosition:Number = Math.min(Math.max(0, this._thumbStartX + xOffset), trackScrollableWidth);
                percentage = xPosition / trackScrollableWidth;
            }

            return this._minimum + percentage * (this._maximum - this._minimum);
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
                    this._repeatTimer.repeats = true;
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
        protected function adjustPage():void
        {
            const page:Number = isNaN(this._page) ? this._step : this._page;
            if(this._touchValue < this._value)
            {
                this.value = Math.max(this._touchValue, this._value - page);
            }
            else if(this._touchValue > this._value)
            {
                this.value = Math.min(this._touchValue, this._value + page);
            }
        }

        /**
         * @private
         */
        protected function slider_removedFromStageHandler(event:Event):void
        {
            this._touchPointID = -1;
            const wasDragging:Boolean = this.isDragging;
            this.isDragging = false;
            if(wasDragging && !this.liveDragging)
            {
                this.dispatchEventWith(Event.CHANGE);
            }
        }

        /**
         * @private
         */
        override protected function focusInHandler(event:Event):void
        {
            super.focusInHandler(event);
            this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
        }

        /**
         * @private
         */
        override protected function focusOutHandler(event:Event):void
        {
            super.focusOutHandler(event);
            this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
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
                if(!this._showThumb && touch.phase == TouchPhase.MOVED)
                {
                    HELPER_POINT = touch.getLocation(this);
                    this.value = this.locationToValue(HELPER_POINT);
                }
                else if(touch.phase == TouchPhase.ENDED)
                {
                    if(this._repeatTimer)
                    {
                        this._repeatTimer.stop();
                    }
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
                        if(this._direction == DIRECTION_VERTICAL)
                        {
                            this._thumbStartX = HELPER_POINT.x;
                            this._thumbStartY = Math.min(this.actualHeight - this.thumb.height, Math.max(0, HELPER_POINT.y - this.thumb.height / 2));
                        }
                        else //horizontal
                        {
                            this._thumbStartX = Math.min(this.actualWidth - this.thumb.width, Math.max(0, HELPER_POINT.x - this.thumb.width / 2));
                            this._thumbStartY = HELPER_POINT.y;
                        }
                        this._touchStartX = HELPER_POINT.x;
                        this._touchStartY = HELPER_POINT.y;
                        this._touchValue = this.locationToValue(HELPER_POINT);
                        this.isDragging = true;
                        this.dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
                        if(this._showThumb)
                        {
                            this.adjustPage();
                            this.startRepeatTimer(this.adjustPage);
                        }
                        else
                        {
                            this.value = this._touchValue;
                        }
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
                this._touchPointID = -1;
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
                    this.value = this.locationToValue(HELPER_POINT);
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
        protected function stage_keyDownHandler(event:KeyboardEvent):void
        {
            if(event.keyCode == LoomKey.HOME)
            {
                this.value = this._minimum;
                return;
            }
            if(event.keyCode == LoomKey.END)
            {
                this.value = this._maximum;
                return;
            }
            const page:Number = isNaN(this._page) ? this._step : this._page;
            if(this._direction == Slider.DIRECTION_VERTICAL)
            {
                if(event.keyCode == LoomKey.UP_ARROW)
                {
                    if(event.shiftKey)
                    {
                        this.value += page;
                    }
                    else
                    {
                        this.value += this._step;
                    }
                }
                else if(event.keyCode == LoomKey.DOWN_ARROW)
                {
                    if(event.shiftKey)
                    {
                        this.value -= page;
                    }
                    else
                    {
                        this.value -= this._step;
                    }
                }
            }
            else
            {
                if(event.keyCode == LoomKey.LEFT_ARROW)
                {
                    if(event.shiftKey)
                    {
                        this.value -= page;
                    }
                    else
                    {
                        this.value -= this._step;
                    }
                }
                else if(event.keyCode == LoomKey.RIGHT_ARROW)
                {
                    if(event.shiftKey)
                    {
                        this.value += page;
                    }
                    else
                    {
                        this.value += this._step;
                    }
                }
            }
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
            this.currentRepeatAction();
        }
    }
}