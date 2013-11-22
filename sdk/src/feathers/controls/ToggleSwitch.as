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
    import feathers.core.ITextRenderer;
    import feathers.core.IToggle;
    import feathers.core.PropertyProxy;
    import feathers.events.FeathersEventType;
    import feathers.system.DeviceCapabilities;

    import Loom2D.Math.Point;
    import Loom2D.Math.Rectangle;
    import flash.ui.Keyboard;

    import starling.animation.Transitions;
    import starling.animation.Tween;
    import Loom2D.Loom2D;
    import Loom2D.Display.DisplayObject;
    import Loom2D.Events.Event;
    import Loom2D.Events.KeyboardEvent;
    import Loom2D.Events.Touch;
    import Loom2D.Events.TouchEvent;
    import Loom2D.Events.TouchPhase;

    /**
     * @inheritDoc
     */
    [Event(name="change",type="starling.events.Event")]

    /**
     * Similar to a light switch with on and off states. Generally considered an
     * alternative to a check box.
     *
     * @see http://wiki.starling-framework.org/feathers/toggle-switch
     * @see Check
     */
    public class ToggleSwitch extends FeathersControl implements IToggle, IFocusDisplayObject
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
         * The minimum physical distance (in inches) that a touch must move
         * before the scroller starts scrolling.
         */
        private static const MINIMUM_DRAG_DISTANCE:Number = 0.04;

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_THUMB_FACTORY:String = "thumbFactory";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_ON_TRACK_FACTORY:String = "onTrackFactory";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_OFF_TRACK_FACTORY:String = "offTrackFactory";

        /**
         * The ON and OFF labels will be aligned to the middle vertically,
         * based on the full character height of the font.
         *
         * @see #labelAlign
         */
        public static const LABEL_ALIGN_MIDDLE:String = "middle";

        /**
         * The ON and OFF labels will be aligned to the middle vertically,
         * based on only the baseline value of the font.
         *
         * @see #labelAlign
         */
        public static const LABEL_ALIGN_BASELINE:String = "baseline";

        /**
         * The toggle switch has only one track skin, stretching to fill the
         * full length of switch. In this layout mode, the on track is
         * displayed and fills the entire length of the toggle switch. The off
         * track will not exist.
         *
         * @see #trackLayoutMode
         */
        public static const TRACK_LAYOUT_MODE_SINGLE:String = "single";

        /**
         * The toggle switch has two tracks, stretching to fill each side of the
         * scroll bar with the thumb in the middle. The tracks will be resized
         * as the thumb moves. This layout mode is designed for toggle switches
         * where the two sides of the track may be colored differently to better
         * differentiate between the on state and the off state.
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
        public static const TRACK_LAYOUT_MODE_ON_OFF:String = "onOff";

        /**
         * The default value added to the `nameList` of the off label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_OFF_LABEL:String = "feathers-toggle-switch-off-label";

        /**
         * The default value added to the `nameList` of the on label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_ON_LABEL:String = "feathers-toggle-switch-on-label";

        /**
         * The default value added to the `nameList` of the off track.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_OFF_TRACK:String = "feathers-toggle-switch-off-track";

        /**
         * The default value added to the `nameList` of the on track.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_ON_TRACK:String = "feathers-toggle-switch-on-track";

        /**
         * The default value added to the `nameList` of the thumb.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_THUMB:String = "feathers-toggle-switch-thumb";

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
        protected static function defaultOnTrackFactory():Button
        {
            return new Button();
        }

        /**
         * @private
         */
        protected static function defaultOffTrackFactory():Button
        {
            return new Button();
        }

        /**
         * Constructor.
         */
        public function ToggleSwitch()
        {
            super();
            this.addEventListener(TouchEvent.TOUCH, toggleSwitch_touchHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, toggleSwitch_removedFromStageHandler);
        }

        /**
         * The value added to the `nameList` of the off label. This
         * variable is `protected` so that sub-classes can customize
         * the on label name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_ON_LABEL`.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var onLabelName:String = DEFAULT_CHILD_NAME_ON_LABEL;

        /**
         * The value added to the `nameList` of the on label. This
         * variable is `protected` so that sub-classes can customize
         * the off label name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_OFF_LABEL`.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var offLabelName:String = DEFAULT_CHILD_NAME_OFF_LABEL;

        /**
         * The value added to the `nameList` of the on track. This
         * variable is `protected` so that sub-classes can customize
         * the on track name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_ON_TRACK`.
         *
         * To customize the on track name without subclassing, see
         * `customOnTrackName`.
         *
         * @see #customOnTrackName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var onTrackName:String = DEFAULT_CHILD_NAME_ON_TRACK;

        /**
         * The value added to the `nameList` of the off track. This
         * variable is `protected` so that sub-classes can customize
         * the off track name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_OFF_TRACK`.
         *
         * To customize the off track name without subclassing, see
         * `customOffTrackName`.
         *
         * @see #customOffTrackName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var offTrackName:String = DEFAULT_CHILD_NAME_OFF_TRACK;

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
         * The "on" text renderer sub-component.
         */
        protected var onTextRenderer:ITextRenderer;

        /**
         * The "off" text renderer sub-component.
         */
        protected var offTextRenderer:ITextRenderer;

        /**
         * The "on" track sub-component.
         */
        protected var onTrack:Button;

        /**
         * The "off" track sub-component.
         */
        protected var offTrack:Button;

        /**
         * @private
         */
        protected var _paddingRight:Number = 0;

        /**
         * The minimum space, in pixels, between the switch's right edge and the
         * switch's content.
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
        protected var _paddingLeft:Number = 0;

        /**
         * The minimum space, in pixels, between the switch's left edge and the
         * switch's content.
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
        protected var _showLabels:Boolean = true;

        /**
         * Determines if the labels should be drawn. The onTrackSkin and
         * offTrackSkin backgrounds may include the text instead.
         */
        public function get showLabels():Boolean
        {
            return _showLabels;
        }

        /**
         * @private
         */
        public function set showLabels(value:Boolean):void
        {
            if(this._showLabels == value)
            {
                return;
            }
            this._showLabels = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _showThumb:Boolean = true;

        /**
         * Determines if the thumb should be displayed. This stops interaction
         * while still displaying the background.
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
        protected var _trackLayoutMode:String = TRACK_LAYOUT_MODE_SINGLE;

        [Inspectable(type="String",enumeration="single,onOff")]
        /**
         * Determines how the on and off track skins are positioned and sized.
         *
         * @default TRACK_LAYOUT_MODE_SINGLE
         * @see #TRACK_LAYOUT_MODE_SINGLE
         * @see #TRACK_LAYOUT_MODE_ON_OFF
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
        protected var _defaultLabelProperties:Dictionary.<String, Object>;

        /**
         * The default label properties are a set of key/value pairs to be
         * passed down to the toggle switch's label text renderers, and it is
         * used when no specific properties are defined for a specific label
         * text renderer's current state. The label text renderers are `ITextRenderer`
         * instances. The available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * @see #labelFactory
         * @see feathers.core.ITextRenderer
         * @see feathers.core.BitmapFontTextRenderer
         * @see feathers.core.TextFieldTextRenderer
         * @see #onLabelProperties
         * @see #offLabelProperties
         * @see #disabledLabelProperties
         */
        public function get defaultLabelProperties():Dictionary.<String, Object>
        {
            if(!this._defaultLabelProperties)
            {
                this._defaultLabelProperties = new Dictionary.<String, Object>;
            }
            return this._defaultLabelProperties;
        }

        /**
         * @private
         */
        public function set defaultLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._defaultLabelProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _disabledLabelProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the toggle switch's
         * label text renderers when the toggle switch is disabled. The label
         * text renderers are `ITextRenderer` instances. The
         * available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * @see #labelFactory
         * @see feathers.core.ITextRenderer
         * @see feathers.core.BitmapFontTextRenderer
         * @see feathers.core.TextFieldTextRenderer
         * @see #defaultLabelProperties
         */
        public function get disabledLabelProperties():Dictionary.<String, Object>
        {
            if(!this._disabledLabelProperties)
            {
                this._disabledLabelProperties = new Dictionary.<String, Object>;
            }
            return this._disabledLabelProperties;
        }

        /**
         * @private
         */
        public function set disabledLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._disabledLabelProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _onLabelProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the toggle switch's
         * ON label text renderer. If `null`, then
         * `defaultLabelProperties` is used instead. The label text
         * renderers are `ITextRenderer` instances. The available
         * properties depend on which `ITextRenderer` implementation
         * is returned by `labelFactory`. The most common
         * implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * @see #labelFactory
         * @see feathers.core.ITextRenderer
         * @see feathers.core.BitmapFontTextRenderer
         * @see feathers.core.TextFieldTextRenderer
         * @see #defaultLabelProperties
         */
        public function get onLabelProperties():Dictionary.<String, Object>
        {
            if(!this._onLabelProperties)
            {
                this._onLabelProperties = new Dictionary.<String, Object>;
            }
            return this._onLabelProperties;
        }

        /**
         * @private
         */
        public function set onLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._onLabelProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _offLabelProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the toggle switch's
         * OFF label text renderer. If `null`, then
         * `defaultLabelProperties` is used instead. The label text
         * renderers are `ITextRenderer` instances. The available
         * properties depend on which `ITextRenderer` implementation
         * is returned by `labelFactory`. The most common
         * implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * @see #labelFactory
         * @see feathers.core.ITextRenderer
         * @see feathers.core.BitmapFontTextRenderer
         * @see feathers.core.TextFieldTextRenderer
         * @see #defaultLabelProperties
         */
        public function get offLabelProperties():Dictionary.<String, Object>
        {
            if(!this._offLabelProperties)
            {
                this._offLabelProperties = new Dictionary.<String, Object>;
            }
            return this._offLabelProperties;
        }

        /**
         * @private
         */
        public function set offLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._offLabelProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _labelAlign:String = LABEL_ALIGN_BASELINE;

        [Inspectable(type="String",enumeration="baseline,middle")]
        /**
         * The vertical alignment of the label.
         */
        public function get labelAlign():String
        {
            return this._labelAlign;
        }

        /**
         * @private
         */
        public function set labelAlign(value:String):void
        {
            if(this._labelAlign == value)
            {
                return;
            }
            this._labelAlign = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _labelFactory:Function;

        /**
         * A function used to instantiate the toggle switch's label text
         * renderer sub-components. The label text renderers must be instances
         * of `ITextRenderer`. This factory can be used to change
         * properties on the label text renderer when it is first created. For
         * instance, if you are skinning Feathers components without a theme,
         * you might use this factory to style the label text renderer.
         *
         * The factory should have the following function signature:
         * `function():ITextRenderer`
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.core.FeathersControl#defaultTextRendererFactory
         */
        public function get labelFactory():Function
        {
            return this._labelFactory;
        }

        /**
         * @private
         */
        public function set labelFactory(value:Function):void
        {
            if(this._labelFactory == value)
            {
                return;
            }
            this._labelFactory = value;
            this.invalidate(INVALIDATION_FLAG_TEXT_RENDERER);
        }

        /**
         * @private
         */
        protected var onTrackSkinOriginalWidth:Number = NaN;

        /**
         * @private
         */
        protected var onTrackSkinOriginalHeight:Number = NaN;

        /**
         * @private
         */
        protected var offTrackSkinOriginalWidth:Number = NaN;

        /**
         * @private
         */
        protected var offTrackSkinOriginalHeight:Number = NaN;

        /**
         * @private
         */
        protected var _isSelected:Boolean = false;

        /**
         * Indicates if the toggle switch is selected (ON) or not (OFF).
         */
        public function get isSelected():Boolean
        {
            return this._isSelected;
        }

        /**
         * @private
         */
        public function set isSelected(value:Boolean):void
        {
            //normally, we'd check to see if selected actually changed or not
            //but the animation is triggered by the draw cycle, so we always
            //need to invalidate. notice that the event isn't dispatched
            //unless the value changes.
            const oldSelected:Boolean = this._isSelected;
            this._isSelected = value;
            this._isSelectionChangedByUser = false;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
            if(this._isSelected != oldSelected)
            {
                this.dispatchEventWith(Event.CHANGE);
            }
        }

        /**
         * @private
         */
        protected var _toggleDuration:Number = 0.15;

        /**
         * The duration, in seconds, of the animation when the toggle switch
         * is toggled and animates the position of the thumb.
         */
        public function get toggleDuration():Number
        {
            return this._toggleDuration;
        }

        /**
         * @private
         */
        public function set toggleDuration(value:Number):void
        {
            this._toggleDuration = value;
        }

        /**
         * @private
         */
        protected var _toggleEase:Object = Transitions.EASE_OUT;

        /**
         * The easing function used for toggle animations.
         */
        public function get toggleEase():Object
        {
            return this._toggleEase;
        }

        /**
         * @private
         */
        public function set toggleEase(value:Object):void
        {
            this._toggleEase = value;
        }

        /**
         * @private
         */
        protected var _onText:String = "ON";

        /**
         * The text to display in the ON label.
         */
        public function get onText():String
        {
            return this._onText;
        }

        /**
         * @private
         */
        public function set onText(value:String):void
        {
            if(value === null)
            {
                value = "";
            }
            if(this._onText == value)
            {
                return;
            }
            this._onText = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _offText:String = "OFF";

        /**
         * The text to display in the OFF label.
         */
        public function get offText():String
        {
            return this._offText;
        }

        /**
         * @private
         */
        public function set offText(value:String):void
        {
            if(value === null)
            {
                value = "";
            }
            if(this._offText == value)
            {
                return;
            }
            this._offText = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _toggleTween:Tween;

        /**
         * @private
         */
        protected var _ignoreTapHandler:Boolean = false;

        /**
         * @private
         */
        protected var _touchPointID:int = -1;

        /**
         * @private
         */
        protected var _thumbStartX:Number;

        /**
         * @private
         */
        protected var _touchStartX:Number;

        /**
         * @private
         */
        protected var _isSelectionChangedByUser:Boolean = false;

        /**
         * @private
         */
        protected var _onTrackFactory:Function;

        /**
         * A function used to generate the toggle switch's on track
         * sub-component. The on track must be an instance of `Button`.
         * This factory can be used to change properties on the on track when it
         * is first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on the on track.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #onTrackProperties
         */
        public function get onTrackFactory():Function
        {
            return this._onTrackFactory;
        }

        /**
         * @private
         */
        public function set onTrackFactory(value:Function):void
        {
            if(this._onTrackFactory == value)
            {
                return;
            }
            this._onTrackFactory = value;
            this.invalidate(INVALIDATION_FLAG_ON_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _customOnTrackName:String;

        /**
         * A name to add to the toggle switch's on track sub-component. Typically
         * used by a theme to provide different skins to different toggle switches.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #onTrackFactory
         * @see #onTrackProperties
         */
        public function get customOnTrackName():String
        {
            return this._customOnTrackName;
        }

        /**
         * @private
         */
        public function set customOnTrackName(value:String):void
        {
            if(this._customOnTrackName == value)
            {
                return;
            }
            this._customOnTrackName = value;
            this.invalidate(INVALIDATION_FLAG_ON_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _onTrackProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the toggle switch's on
         * track sub-component. The on track is a
         * `feathers.controls.Button` instance.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `onTrackFactory` function
         * instead of using `onTrackProperties` will result in
         * better performance.
         * 
         * @see feathers.controls.Button
         * @see #onTrackFactory
         */
        public function get onTrackProperties():Dictionary.<String, Object>
        {
            if(!this._onTrackProperties)
            {
                this._onTrackProperties = new Dictionary.<String, Object>;
            }
            return this._onTrackProperties;
        }

        /**
         * @private
         */
        public function set onTrackProperties(value:Dictionary.<String, Object>):void
        {
            if(this._onTrackProperties == value)
            {
                return;
            }
            this._onTrackProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _offTrackFactory:Function;

        /**
         * A function used to generate the toggle switch's off track
         * sub-component. The off track must be an instance of `Button`.
         * This factory can be used to change properties on the off track when it
         * is first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on the off track.
         *
         * The function should have the following signature:
         * `function():Button`
         *
         * @see feathers.controls.Button
         * @see #offTrackProperties
         */
        public function get offTrackFactory():Function
        {
            return this._offTrackFactory;
        }

        /**
         * @private
         */
        public function set offTrackFactory(value:Function):void
        {
            if(this._offTrackFactory == value)
            {
                return;
            }
            this._offTrackFactory = value;
            this.invalidate(INVALIDATION_FLAG_OFF_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _customOffTrackName:String;

        /**
         * A name to add to the toggle switch's off track sub-component. Typically
         * used by a theme to provide different skins to different toggle switches.
         *
         * @see feathers.core.FeathersControl#nameList
         * @see #offTrackFactory
         * @see #offTrackProperties
         */
        public function get customOffTrackName():String
        {
            return this._customOffTrackName;
        }

        /**
         * @private
         */
        public function set customOffTrackName(value:String):void
        {
            if(this._customOffTrackName == value)
            {
                return;
            }
            this._customOffTrackName = value;
            this.invalidate(INVALIDATION_FLAG_OFF_TRACK_FACTORY);
        }

        /**
         * @private
         */
        protected var _offTrackProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to the toggle switch's off
         * track sub-component. The off track is a
         * `feathers.controls.Button` instance.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `offTrackFactory` function
         * instead of using `offTrackProperties` will result in
         * better performance.
         * 
         * @see feathers.controls.Button
         * @see #offTrackFactory
         */
        public function get offTrackProperties():Dictionary.<String, Object>
        {
            if(!this._offTrackProperties)
            {
                this._offTrackProperties = new Dictionary.<String, Object>;
            }
            return this._offTrackProperties;
        }

        /**
         * @private
         */
        public function set offTrackProperties(value:Dictionary.<String, Object>):void
        {
            if(this._offTrackProperties == value)
            {
                return;
            }
            this._offTrackProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _thumbFactory:Function;

        /**
         * A function used to generate the toggle switch's thumb sub-component.
         * This can be used to change properties on the thumb when it is first
         * created. For instance, if you are skinning Feathers components
         * without a theme, you might use `thumbFactory` to set
         * skins and text styles on the thumb.
         *
         * The function should have the following signature:
         * `function():Button`
         *
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
         * A name to add to the toggle switch's thumb sub-component. Typically
         * used by a theme to provide different skins to different toggle switches.
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
         * A set of key/value pairs to be passed down to the toggle switch's
         * thumb sub-component. The thumb is a
         * `feathers.controls.Button` instance.
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
                this._thumbProperties = new Dictionary.<String, Object>;
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
            this._thumbProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const selectionInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SELECTED);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const focusInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_FOCUS);
            const textRendererInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_TEXT_RENDERER);
            const thumbFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_THUMB_FACTORY);
            const onTrackFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_ON_TRACK_FACTORY);
            const offTrackFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_OFF_TRACK_FACTORY);

            if(thumbFactoryInvalid)
            {
                this.createThumb();
            }

            if(onTrackFactoryInvalid)
            {
                this.createOnTrack();
            }

            this.createOrDestroyOffTrackIfNeeded(offTrackFactoryInvalid);

            if(textRendererInvalid)
            {
                this.createLabels();
            }

            if(stylesInvalid)
            {
                this.refreshOnLabelStyles();
                this.refreshOffLabelStyles();
            }

            if(thumbFactoryInvalid || stylesInvalid)
            {
                this.refreshThumbStyles();
            }
            if(onTrackFactoryInvalid || stylesInvalid)
            {
                this.refreshOnTrackStyles();
            }
            if((offTrackFactoryInvalid || stylesInvalid) && this.offTrack)
            {
                this.refreshOffTrackStyles();
            }

            if(thumbFactoryInvalid || stateInvalid)
            {
                this.thumb.isEnabled = this._isEnabled;
            }
            if(onTrackFactoryInvalid || stateInvalid)
            {
                this.onTrack.isEnabled = this._isEnabled;
            }
            if((offTrackFactoryInvalid || stateInvalid) && this.offTrack)
            {
                this.offTrack.isEnabled = this._isEnabled;
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(sizeInvalid || stylesInvalid || selectionInvalid)
            {
                this.updateSelection();
            }

            if(stylesInvalid || sizeInvalid || stateInvalid || selectionInvalid)
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
            if(isNaN(this.onTrackSkinOriginalWidth) || isNaN(this.onTrackSkinOriginalHeight))
            {
                this.onTrack.validate();
                this.onTrackSkinOriginalWidth = this.onTrack.width;
                this.onTrackSkinOriginalHeight = this.onTrack.height;
            }
            if(this.offTrack)
            {
                if(isNaN(this.offTrackSkinOriginalWidth) || isNaN(this.offTrackSkinOriginalHeight))
                {
                    this.offTrack.validate();
                    this.offTrackSkinOriginalWidth = this.offTrack.width;
                    this.offTrackSkinOriginalHeight = this.offTrack.height;
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
                if(this.offTrack)
                {
                    newWidth = Math.min(this.onTrackSkinOriginalWidth, this.offTrackSkinOriginalWidth) + this.thumb.width / 2;
                }
                else
                {
                    newWidth = this.onTrackSkinOriginalWidth;
                }
            }
            if(needsHeight)
            {
                if(this.offTrack)
                {
                    newHeight = Math.max(this.onTrackSkinOriginalHeight, this.offTrackSkinOriginalHeight);
                }
                else
                {
                    newHeight = this.onTrackSkinOriginalHeight;
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
        protected function createOnTrack():void
        {
            if(this.onTrack)
            {
                this.onTrack.removeFromParent(true);
                this.onTrack = null;
            }

            const factory:Function = this._onTrackFactory != null ? this._onTrackFactory : defaultOnTrackFactory;
            const onTrackName:String = this._customOnTrackName != null ? this._customOnTrackName : this.onTrackName;
            this.onTrack = Button(factory.call());
            this.onTrack.nameList.add(onTrackName);
            this.onTrack.keepDownStateOnRollOut = true;
            this.addChildAt(this.onTrack, 0);
        }

        /**
         * @private
         */
        protected function createOrDestroyOffTrackIfNeeded(offTrackFactoryInvalid:Boolean):void
        {
            if(this._trackLayoutMode == TRACK_LAYOUT_MODE_ON_OFF)
            {
                if(!offTrackFactoryInvalid)
                {
                    return;
                }
                if(this.offTrack)
                {
                    this.offTrack.removeFromParent(true);
                    this.offTrack = null;
                }
                const factory:Function = this._offTrackFactory != null ? this._offTrackFactory : defaultOffTrackFactory;
                const offTrackName:String = this._customOffTrackName != null ? this._customOffTrackName : this.offTrackName;
                this.offTrack = Button(factory.call());
                this.offTrack.nameList.add(offTrackName);
                this.offTrack.keepDownStateOnRollOut = true;
                this.addChildAt(this.offTrack, 1);
            }
            else if(this.offTrack) //single
            {
                this.offTrack.removeFromParent(true);
                this.offTrack = null;
            }
        }

        /**
         * @private
         */
        protected function createLabels():void
        {
            if(this.offTextRenderer)
            {
                this.removeChild(DisplayObject(this.offTextRenderer), true);
                this.offTextRenderer = null;
            }
            if(this.onTextRenderer)
            {
                this.removeChild(DisplayObject(this.onTextRenderer), true);
                this.onTextRenderer = null;
            }

            const index:int = this.getChildIndex(this.thumb);
            const factory:Function = this._labelFactory != null ? this._labelFactory : FeathersControl.defaultTextRendererFactory;
            this.offTextRenderer = ITextRenderer(factory.call());
            this.offTextRenderer.nameList.add(this.offLabelName);
            if(this.offTextRenderer is FeathersControl)
            {
                FeathersControl(this.offTextRenderer).clipRect = new Rectangle();
            }
            this.addChildAt(DisplayObject(this.offTextRenderer), index);

            this.onTextRenderer = ITextRenderer(factory.call());
            this.onTextRenderer.nameList.add(this.onLabelName);
            if(this.onTextRenderer is FeathersControl)
            {
                FeathersControl(this.onTextRenderer).clipRect = new Rectangle();
            }
            this.addChildAt(DisplayObject(this.onTextRenderer), index);
        }

        /**
         * @private
         */
        protected function layoutChildren():void
        {
            this.thumb.validate();
            this.thumb.y = (this.actualHeight - this.thumb.height) / 2;

            const maxLabelWidth:Number = Math.max(0, this.actualWidth - this.thumb.width - this._paddingLeft - this._paddingRight);
            var totalLabelHeight:Number = Math.max(this.onTextRenderer.height, this.offTextRenderer.height);
            var labelHeight:Number;
            if(this._labelAlign == LABEL_ALIGN_MIDDLE)
            {
                labelHeight = totalLabelHeight;
            }
            else //baseline
            {
                labelHeight = Math.max(this.onTextRenderer.baseline, this.offTextRenderer.baseline);
            }

            if(this.onTextRenderer is FeathersControl)
            {
                var clipRect:Rectangle = FeathersControl(this.onTextRenderer).clipRect;
                clipRect.width = maxLabelWidth;
                clipRect.height = totalLabelHeight;
                FeathersControl(this.onTextRenderer).clipRect = clipRect;
            }

            this.onTextRenderer.y = (this.actualHeight - labelHeight) / 2;

            if(this.offTextRenderer is FeathersControl)
            {
                clipRect = FeathersControl(this.offTextRenderer).clipRect;
                clipRect.width = maxLabelWidth;
                clipRect.height = totalLabelHeight;
                FeathersControl(this.offTextRenderer).clipRect = clipRect;
            }

            this.offTextRenderer.y = (this.actualHeight - labelHeight) / 2;

            this.layoutTracks();
        }

        /**
         * @private
         */
        protected function layoutTracks():void
        {
            const maxLabelWidth:Number = Math.max(0, this.actualWidth - this.thumb.width - this._paddingLeft - this._paddingRight);
            const thumbOffset:Number = this.thumb.x - this._paddingLeft;

            var onScrollOffset:Number = maxLabelWidth - thumbOffset - (maxLabelWidth - this.onTextRenderer.width) / 2;
            if(this.onTextRenderer is FeathersControl)
            {
                const displayOnLabelRenderer:FeathersControl = FeathersControl(this.onTextRenderer);
                var currentClipRect:Rectangle = displayOnLabelRenderer.clipRect;
                currentClipRect.x = onScrollOffset
                displayOnLabelRenderer.clipRect = currentClipRect;
            }
            this.onTextRenderer.x = this._paddingLeft - onScrollOffset;

            var offScrollOffset:Number = -thumbOffset - (maxLabelWidth - this.offTextRenderer.width) / 2;
            if(this.offTextRenderer is FeathersControl)
            {
                const displayOffLabelRenderer:FeathersControl = FeathersControl(this.offTextRenderer);
                currentClipRect = displayOffLabelRenderer.clipRect;
                currentClipRect.x = offScrollOffset
                displayOffLabelRenderer.clipRect = currentClipRect;
            }
            this.offTextRenderer.x = this.actualWidth - this._paddingRight - maxLabelWidth - offScrollOffset;

            if(this._trackLayoutMode == TRACK_LAYOUT_MODE_ON_OFF)
            {
                this.layoutTrackWithOnOff();
            }
            else
            {
                this.layoutTrackWithSingle();
            }
        }

        /**
         * @private
         */
        protected function updateSelection():void
        {
            this.thumb.validate();

            var xPosition:Number = this._paddingLeft;
            if(this._isSelected)
            {
                xPosition = this.actualWidth - this.thumb.width - this._paddingRight;
            }

            //stop the tween, no matter what
            if(this._toggleTween)
            {
                Loom2D.juggler.remove(this._toggleTween);
                this._toggleTween = null;
            }

            if(this._isSelectionChangedByUser)
            {
                this._toggleTween = new Tween(this.thumb, this._toggleDuration, this._toggleEase);
                this._toggleTween.animate("x", xPosition);
                this._toggleTween.onUpdate = selectionTween_onUpdate;
                this._toggleTween.onComplete = selectionTween_onComplete;
                Loom2D.juggler.add(this._toggleTween);
            }
            else
            {
                this.thumb.x = xPosition;
            }
            this._isSelectionChangedByUser = false;
        }

        /**
         * @private
         */
        protected function refreshOnLabelStyles():void
        {
            //no need to style the label field if there's no text to display
            if(!this._showLabels || !this._showThumb)
            {
                this.onTextRenderer.visible = false;
                return;
            }

            var properties:PropertyProxy;
            if(!this._isEnabled)
            {
                properties = this._disabledLabelProperties;
            }
            if(!properties && this._onLabelProperties)
            {
                properties = this._onLabelProperties;
            }
            if(!properties)
            {
                properties = this._defaultLabelProperties;
            }

            this.onTextRenderer.text = this._onText;
            if(properties)
            {
                Dictionary.mapToObject(properties, onTextRenderer);
            }
            this.onTextRenderer.validate();
            this.onTextRenderer.visible = true;
        }

        /**
         * @private
         */
        protected function refreshOffLabelStyles():void
        {
            //no need to style the label field if there's no text to display
            if(!this._showLabels || !this._showThumb)
            {
                this.offTextRenderer.visible = false;
                return;
            }

            var properties:PropertyProxy;
            if(!this._isEnabled)
            {
                properties = this._disabledLabelProperties;
            }
            if(!properties && this._offLabelProperties)
            {
                properties = this._offLabelProperties;
            }
            if(!properties)
            {
                properties = this._defaultLabelProperties;
            }

            this.offTextRenderer.text = this._offText;
            if(properties)
            {
                Dictionary.mapToObject(properties, onTextRenderer);
            }
            this.offTextRenderer.validate();
            this.offTextRenderer.visible = true;
        }

        /**
         * @private
         */
        protected function refreshThumbStyles():void
        {
            Dictionary.mapToObject(_thumbProperties, thumb);
            this.thumb.visible = this._showThumb;
        }

        /**
         * @private
         */
        protected function refreshOnTrackStyles():void
        {
            Dictionary.mapToObject(_onTrackProperties, onTrack);
        }

        /**
         * @private
         */
        protected function refreshOffTrackStyles():void
        {
            if(!this.offTrack)
            {
                return;
            }
            Dictionary.mapToObject(_offTrackProperties, offTrack);
        }

        /**
         * @private
         */
        protected function layoutTrackWithOnOff():void
        {
            this.onTrack.x = 0;
            this.onTrack.y = 0;
            this.onTrack.width = this.thumb.x + this.thumb.width / 2;
            this.onTrack.height = this.actualHeight;

            this.offTrack.x = this.onTrack.width;
            this.offTrack.y = 0;
            this.offTrack.width = this.actualWidth - this.offTrack.x;
            this.offTrack.height = this.actualHeight;
        }

        /**
         * @private
         */
        protected function layoutTrackWithSingle():void
        {
            this.onTrack.x = 0;
            this.onTrack.y = 0;
            this.onTrack.width = this.actualWidth;
            this.onTrack.height = this.actualHeight;
        }

        /**
         * @private
         */
        protected function childProperties_onChange(proxy:PropertyProxy, name:Object):void
        {
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected function toggleSwitch_removedFromStageHandler(event:Event):void
        {
            this._touchPointID = -1;
        }

        /**
         * @private
         */
        override protected function focusInHandler(event:Event):void
        {
            super.focusInHandler(event);
            this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
            this.stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
        }

        /**
         * @private
         */
        override protected function focusOutHandler(event:Event):void
        {
            super.focusOutHandler(event);
            this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
            this.stage.removeEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
        }

        /**
         * @private
         */
        protected function toggleSwitch_touchHandler(event:TouchEvent):void
        {
            if(this._ignoreTapHandler)
            {
                this._ignoreTapHandler = false;
                return;
            }
            if(!this._isEnabled)
            {
                this._touchPointID = -1;
                return;
            }

            const touches:Vector.<Touch> = event.getTouches(this, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                return;
            }
            var touch:Touch;
            for each(var currentTouch:Touch in touches)
            {
                if((this._touchPointID >= 0 && currentTouch.id == this._touchPointID) ||
                    (this._touchPointID < 0 && currentTouch.phase == TouchPhase.ENDED))
                {
                    touch = currentTouch;
                    break;
                }
            }
            if(!touch || touch.phase != TouchPhase.ENDED)
            {
                HELPER_TOUCHES_VECTOR.length = 0;
                return;
            }

            this._touchPointID = -1;
            touch.getLocation(this.stage, HELPER_POINT);
            if(this.contains(this.stage.hitTest(HELPER_POINT, true)))
            {
                this.isSelected = !this._isSelected;
                this._isSelectionChangedByUser = true;
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
                touch.getLocation(this, HELPER_POINT);
                const trackScrollableWidth:Number = this.actualWidth - this._paddingLeft - this._paddingRight - this.thumb.width;
                if(touch.phase == TouchPhase.MOVED)
                {
                    const xOffset:Number = HELPER_POINT.x - this._touchStartX;
                    const xPosition:Number = Math.min(Math.max(this._paddingLeft, this._thumbStartX + xOffset), this._paddingLeft + trackScrollableWidth);
                    this.thumb.x = xPosition;
                    this.layoutTracks();
                }
                else if(touch.phase == TouchPhase.ENDED)
                {
                    const inchesMoved:Number = Math.abs(HELPER_POINT.x - this._touchStartX) / DeviceCapabilities.dpi;
                    if(inchesMoved > MINIMUM_DRAG_DISTANCE)
                    {
                        this._touchPointID = -1;
                        this.isSelected = this.thumb.x > (this._paddingLeft + trackScrollableWidth / 2);
                        this._isSelectionChangedByUser = true;
                        this._ignoreTapHandler = true;
                    }
                }
            }
            else
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        touch.getLocation(this, HELPER_POINT);
                        this._touchPointID = touch.id;
                        this._thumbStartX = this.thumb.x;
                        this._touchStartX = HELPER_POINT.x;
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
            if(event.keyCode == Keyboard.ESCAPE)
            {
                this._touchPointID = -1;
            }
            if(this._touchPointID >= 0 || event.keyCode != Keyboard.SPACE)
            {
                return;
            }
            this._touchPointID = int.MAX_VALUE;
        }

        /**
         * @private
         */
        protected function stage_keyUpHandler(event:KeyboardEvent):void
        {
            if(this._touchPointID != int.MAX_VALUE || event.keyCode != Keyboard.SPACE)
            {
                return;
            }
            this._touchPointID = -1;
            this.isSelected = !this._isSelected;
        }

        /**
         * @private
         */
        protected function selectionTween_onUpdate():void
        {
            this.layoutTracks();
        }

        /**
         * @private
         */
        protected function selectionTween_onComplete():void
        {
            this._toggleTween = null;
        }
    }
}