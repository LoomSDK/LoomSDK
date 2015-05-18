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
    import feathers.core.IFocusDisplayObject;
    import feathers.core.ILabel;
    import feathers.core.ITextRenderer;
    import feathers.core.IToggle;
    import feathers.events.FeathersEventType;
    import feathers.skins.StateWithToggleValueSelector;

    import loom2d.math.Point;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    /**
     * Dispatched when the button is released while the touch is still
     * within the button's bounds (a tap or click that should trigger the
     * button).
     *
     * @eventType loom2d.events.Event.TRIGGERED
     */
    [Event(name="triggered",type="loom2d.events.Event")]

    /**
     * Dispatched when the button is selected or unselected. A button's
     * selection may be changed by the user when `isToggle` is set to
     * `true`. The selection may be changed programmatically at any
     * time, regardless of the value of `isToggle`.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * A push (or optionally, toggle) button control.
     *
     * The following example creates a button, gives it a label and listens
     * for when the button is triggered:
     *
     * ~~~as3
     * var button:Button = new Button();
     * button.label = "Click Me";
     * button.addEventListener( Event.TRIGGERED, button_triggeredHandler );
     * this.addChild( button );
     * ~~~
     *
     * @see http://wiki.starling-framework.org/feathers/button
     */
    public class Button extends FeathersControl implements IToggle, ILabel, IFocusDisplayObject
    {
        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new Vector.<Touch>[];

        /**
         * The default value added to the `nameList` of the label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_LABEL:String = "feathers-button-label";

        /**
         * An alternate name to use with Button to allow a theme to give it
         * a more prominent, "call-to-action" style. If a theme does not provide
         * a skin for the call-to-action button, the theme will automatically
         * fall back to using the default button skin.
         *
         * An alternate name should always be added to a component's
         * `nameList` before the component is added to the stage for
         * the first time.
         *
         * In the following example, the call-to-action style is applied to
         * a button:
         *
         * ~~~as3
         * var button:Button = new Button();
         * button.nameList.add( Button.ALTERNATE_NAME_CALL_TO_ACTION_BUTTON );
         * this.addChild( button );
         * ~~~
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const ALTERNATE_NAME_CALL_TO_ACTION_BUTTON:String = "feathers-call-to-action-button";

        /**
         * An alternate name to use with Button to allow a theme to give it
         * a less prominent, "quiet" style. If a theme does not provide
         * a skin for the quiet button, the theme will automatically fall back
         * to using the default button skin.
         *
         * An alternate name should always be added to a component's
         * `nameList` before the component is added to the stage for
         * the first time.
         *
         * In the following example, the quiet button style is applied to
         * a button:
         *
         * ~~~as3
         * var button:Button = new Button();
         * button.nameList.add( Button.ALTERNATE_NAME_QUIET_BUTTON );
         * this.addChild( button );
         * ~~~
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const ALTERNATE_NAME_QUIET_BUTTON:String = "feathers-quiet-button";

        /**
         * An alternate name to use with Button to allow a theme to give it
         * a highly prominent, "danger" style. An example would be a delete
         * button or some other button that has a destructive action that cannot
         * be undone if the button is triggered. If a theme does not provide
         * a skin for the danger button, the theme will automatically fall back
         * to using the default button skin.
         *
         * An alternate name should always be added to a component's
         * `nameList` before the component is added to the stage for
         * the first time.
         *
         * In the following example, the danger button style is applied to
         * a button:
         *
         * ~~~as3
         * var button:Button = new Button();
         * button.nameList.add( Button.ALTERNATE_NAME_DANGER_BUTTON );
         * this.addChild( button );
         * ~~~
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const ALTERNATE_NAME_DANGER_BUTTON:String = "feathers-danger-button";

        /**
         * An alternate name to use with Button to allow a theme to give it
         * a "back button" style, perhaps with an arrow pointing backward. If a
         * theme does not provide a skin for the back button, the theme will
         * automatically fall back to using the default button skin.
         *
         * An alternate name should always be added to a component's
         * `nameList` before the component is added to the stage for
         * the first time.
         *
         * In the following example, the back button style is applied to
         * a button:
         *
         * ~~~as3
         * var button:Button = new Button();
         * button.nameList.add( Button.ALTERNATE_NAME_BACK_BUTTON );
         * this.addChild( button );
         * ~~~
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const ALTERNATE_NAME_BACK_BUTTON:String = "feathers-back-button";

        /**
         * An alternate name to use with Button to allow a theme to give it
         * a "forward" button style, perhaps with an arrow pointing forward. If
         * a theme does not provide a skin for the forward button, the theme
         * will automatically fall back to using the default button skin.
         *
         * An alternate name should always be added to a component's
         * `nameList` before the component is added to the stage for
         * the first time.
         *
         * In the following example, the forward button style is applied to
         * a button:
         *
         * ~~~as3
         * var button:Button = new Button();
         * button.nameList.add( Button.ALTERNATE_NAME_FORWARD_BUTTON );
         * this.addChild( button );
         * ~~~
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const ALTERNATE_NAME_FORWARD_BUTTON:String = "feathers-forward-button";

        /**
         * Identifier for the button's up state. Can be used for styling purposes.
         *
         * @see #stateToSkinFunction
         * @see #stateToIconFunction
         * @see #stateToLabelPropertiesFunction
         */
        public static const STATE_UP:String = "up";

        /**
         * Identifier for the button's down state. Can be used for styling purposes.
         *
         * @see #stateToSkinFunction
         * @see #stateToIconFunction
         * @see #stateToLabelPropertiesFunction
         */
        public static const STATE_DOWN:String = "down";

        /**
         * Identifier for the button's hover state. Can be used for styling purposes.
         *
         * @see #stateToSkinFunction
         * @see #stateToIconFunction
         * @see #stateToLabelPropertiesFunction
         */
        public static const STATE_HOVER:String = "hover";

        /**
         * Identifier for the button's disabled state. Can be used for styling purposes.
         *
         * @see #stateToSkinFunction
         * @see #stateToIconFunction
         * @see #stateToLabelPropertiesFunction
         */
        public static const STATE_DISABLED:String = "disabled";

        /**
         * The icon will be positioned above the label.
         *
         * @see #iconPosition
         */
        public static const ICON_POSITION_TOP:String = "top";

        /**
         * The icon will be positioned to the right of the label.
         *
         * @see #iconPosition
         */
        public static const ICON_POSITION_RIGHT:String = "right";

        /**
         * The icon will be positioned below the label.
         *
         * @see #iconPosition
         */
        public static const ICON_POSITION_BOTTOM:String = "bottom";

        /**
         * The icon will be positioned to the left of the label.
         *
         * @see #iconPosition
         */
        public static const ICON_POSITION_LEFT:String = "left";

        /**
         * The icon will be positioned manually with no relation to the position
         * of the label. Use `iconOffsetX` and `iconOffsetY`
         * to set the icon's position.
         *
         * @see #iconPosition
         * @see #iconOffsetX
         * @see #iconOffsetY
         */
        public static const ICON_POSITION_MANUAL:String = "manual";

        /**
         * The icon will be positioned to the left the label, and the bottom of
         * the icon will be aligned to the baseline of the label text.
         *
         * @see #iconPosition
         */
        public static const ICON_POSITION_LEFT_BASELINE:String = "leftBaseline";

        /**
         * The icon will be positioned to the right the label, and the bottom of
         * the icon will be aligned to the baseline of the label text.
         *
         * @see #iconPosition
         */
        public static const ICON_POSITION_RIGHT_BASELINE:String = "rightBaseline";

        /**
         * The icon and label will be aligned horizontally to the left edge of the button.
         *
         * @see #horizontalAlign
         */
        public static const HORIZONTAL_ALIGN_LEFT:String = "left";

        /**
         * The icon and label will be aligned horizontally to the center of the button.
         *
         * @see #horizontalAlign
         */
        public static const HORIZONTAL_ALIGN_CENTER:String = "center";

        /**
         * The icon and label will be aligned horizontally to the right edge of the button.
         *
         * @see #horizontalAlign
         */
        public static const HORIZONTAL_ALIGN_RIGHT:String = "right";

        /**
         * The icon and label will be aligned vertically to the top edge of the button.
         */
        public static const VERTICAL_ALIGN_TOP:String = "top";

        /**
         * The icon and label will be aligned vertically to the middle of the button.
         *
         * @see #verticalAlign
         */
        public static const VERTICAL_ALIGN_MIDDLE:String = "middle";

        /**
         * The icon and label will be aligned vertically to the bottom edge of the button.
         *
         * @see #verticalAlign
         */
        public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";

        /**
         * Constructor
         */
        public function Button()
        {
            this.isQuickHitAreaEnabled = true;
            this.addEventListener(TouchEvent.TOUCH, button_touchHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, button_removedFromStageHandler);
        }

        /**
         * The value added to the `nameList` of the label. This
         * variable is `protected` so that sub-classes can customize
         * the label name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_LABEL`.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var labelName:String = DEFAULT_CHILD_NAME_LABEL;

        /**
         * The text renderer for the button's label.
         */
        protected var labelTextRenderer:ITextRenderer;

        /**
         * @private
         */
        protected var currentSkin:DisplayObject;

        /**
         * @private
         */
        protected var currentIcon:DisplayObject;

        /**
         * @private
         */
        protected var _touchPointID:int = -1;

        /**
         * @private
         */
        protected var _isHoverSupported:Boolean = false;

        /**
         * @private
         */
        override public function set isEnabled(value:Boolean):void
        {
            if(this._isEnabled == value)
            {
                return;
            }

            // super is not currently supported for properties.
            // super.isEnabled = value;
            // Replace with verbatim implementation from FeathersControl:
            if(this._isEnabled == value)
            {
                return;
            }
            this._isEnabled = value;
            this.invalidate(INVALIDATION_FLAG_STATE);


            if(!this._isEnabled)
            {
                this.touchable = false;
                this.currentState = STATE_DISABLED;
                this._touchPointID = -1;
            }
            else
            {
                //might be in another state for some reason
                //let's only change to up if needed
                if(this.currentState == STATE_DISABLED)
                {
                    this.currentState = STATE_UP;
                }
                this.touchable = true;
            }
        }

        /**
         * @private
         */
        protected var _currentState:String = STATE_UP;

        /**
         * @private
         */
        protected function get currentState():String
        {
            return this._currentState;
        }

        /**
         * @private
         */
        protected function set currentState(value:String):void
        {
            if(this._currentState == value)
            {
                return;
            }
            if(this.stateNames.indexOf(value) < 0)
            {
                throw new ArgumentError("Invalid state: " + value + ".");
            }
            this._currentState = value;
            this.invalidate(INVALIDATION_FLAG_STATE);
        }

        /**
         * @private
         */
        protected var _label:String = null;

        /**
         * The text displayed on the button.
         *
         * The following example gives the button some label text:
         *
         * ~~~as3
         * button.label = "Click Me";
         * ~~~
         */
        public function get label():String
        {
            return this._label;
        }

        /**
         * @private
         */
        public function set label(value:String):void
        {
            if(this._label == value)
            {
                return;
            }
            this._label = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _isToggle:Boolean = false;

        /**
         * Determines if the button may be selected or unselected when clicked.
         *
         * The following example enables the button to toggle and listens for
         * `Event.CHANGE`:
         *
         * ~~~as3
         * button.isToggle = true;
         * button.addEventListener( Event.CHANGE, button_changeHandler );
         * ~~~
         *
         * @see #event:change
         */
        public function get isToggle():Boolean
        {
            return this._isToggle;
        }

        /**
         * @private
         */
        public function set isToggle(value:Boolean):void
        {
            this._isToggle = value;
        }

        /**
         * @private
         */
        protected var _isSelected:Boolean = false;

        /**
         * Indicates if the button is selected or not. The button may be
         * selected programmatically, even if `isToggle` is `false`,
         * but generally, `isToggle` should be set to `true`
         * to allow the user to select and deselect it.
         *
         * The following example enables the button to toggle and selects it
         * automatically:
         *
         * ~~~as3
         * button.isToggle = true;
         * button.isSelected = true;
         * ~~~
         *
         * @see #isToggle
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
            if(this._isSelected == value)
            {
                return;
            }
            this._isSelected = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _iconPosition:String = ICON_POSITION_LEFT;

        [Inspectable(type="String",enumeration="top,right,bottom,left,rightBaseline,leftBaseline,manual")]
        /**
         * The location of the icon, relative to the label.
         *
         * The following example positions the icon to the right of the
         * label:
         *
         * ~~~as3
         * button.label = "Click Me";
         * button.defaultIcon = new Image( texture );
         * button.iconPosition = Button.ICON_POSITION_RIGHT;
         * ~~~
         */
        public function get iconPosition():String
        {
            return this._iconPosition;
        }

        /**
         * @private
         */
        public function set iconPosition(value:String):void
        {
            if(this._iconPosition == value)
            {
                return;
            }
            this._iconPosition = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _gap:Number = 0;

        /**
         * The space, in pixels, between the icon and the label. Applies to
         * either horizontal or vertical spacing, depending on the value of
         * `iconPosition`.
         *
         * If `gap` is set to `Number.POSITIVE_INFINITY`,
         * the label and icon will be positioned as far apart as possible. In
         * other words, they will be positioned at the edges of the button,
         * adjusted for padding.
         *
         * The following example creates a gap of 50 pixels between the label
         * and the icon:
         *
         * ~~~as3
         * button.label = "Click Me";
         * button.defaultIcon = new Image( texture );
         * button.gap = 50;
         * ~~~
         *
         * @see #iconPosition
         */
        public function get gap():Number
        {
            return this._gap;
        }

        /**
         * @private
         */
        public function set gap(value:Number):void
        {
            if(this._gap == value)
            {
                return;
            }
            this._gap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _horizontalAlign:String = HORIZONTAL_ALIGN_CENTER;

        [Inspectable(type="String",enumeration="left,center,right")]
        /**
         * The location where the button's content is aligned horizontally (on
         * the x-axis).
         *
         * The following example aligns the button's content to the left:
         *
         * ~~~as3
         * button.horizontalAlign = Button.HORIZONTAL_ALIGN_LEFT;
         * ~~~
         */
        public function get horizontalAlign():String
        {
            return this._horizontalAlign;
        }

        /**
         * @private
         */
        public function set horizontalAlign(value:String):void
        {
            if(this._horizontalAlign == value)
            {
                return;
            }
            this._horizontalAlign = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _verticalAlign:String = VERTICAL_ALIGN_MIDDLE;

        [Inspectable(type="String",enumeration="top,middle,bottom")]
        /**
         * The location where the button's content is aligned vertically (on
         * the y-axis).
         *
         * The following example aligns the button's content to the top:
         *
         * ~~~as3
         * button.verticalAlign = Button.VERTICAL_ALIGN_TOP;
         * ~~~
         */
        public function get verticalAlign():String
        {
            return _verticalAlign;
        }

        /**
         * @private
         */
        public function set verticalAlign(value:String):void
        {
            if(this._verticalAlign == value)
            {
                return;
            }
            this._verticalAlign = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * Quickly sets all padding properties to the same value. The
         * `padding` getter always returns the value of
         * `paddingTop`, but the other padding values may be
         * different.
         *
         * The following example gives the button 20 pixels of padding on all
         * sides:
         *
         * ~~~as3
         * button.padding = 20;
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
         * The minimum space, in pixels, between the button's top edge and the
         * button's content.
         *
         * The following example gives the button 20 pixels of padding on the
         * top edge only:
         *
         * ~~~as3
         * button.paddingTop = 20;
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
         * The minimum space, in pixels, between the button's right edge and the
         * button's content.
         *
         * The following example gives the button 20 pixels of padding on the
         * right edge only:
         *
         * ~~~as3
         * button.paddingRight = 20;
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
         * The minimum space, in pixels, between the button's bottom edge and
         * the button's content.
         *
         * The following example gives the button 20 pixels of padding on the
         * bottom edge only:
         *
         * ~~~as3
         * button.paddingBottom = 20;
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
         * The minimum space, in pixels, between the button's left edge and the
         * button's content.
         *
         * The following example gives the button 20 pixels of padding on the
         * left edge only:
         *
         * ~~~as3
         * button.paddingLeft = 20;
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
        protected var _labelOffsetX:Number = 0;

        /**
         * Offsets the x position of the label by a certain number of pixels.
         *
         * The following example offsets the x position of the button's label
         * by 20 pixels:
         *
         * ~~~as3
         * button.labelOffsetX = 20;
         * ~~~
         */
        public function get labelOffsetX():Number
        {
            return this._labelOffsetX;
        }

        /**
         * @private
         */
        public function set labelOffsetX(value:Number):void
        {
            if(this._labelOffsetX == value)
            {
                return;
            }
            this._labelOffsetX = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _labelOffsetY:Number = 0;

        /**
         * Offsets the y position of the label by a certain number of pixels.
         *
         * The following example offsets the y position of the button's label
         * by 20 pixels:
         *
         * ~~~as3
         * button.labelOffsetY = 20;
         * ~~~
         */
        public function get labelOffsetY():Number
        {
            return this._labelOffsetY;
        }

        /**
         * @private
         */
        public function set labelOffsetY(value:Number):void
        {
            if(this._labelOffsetY == value)
            {
                return;
            }
            this._labelOffsetY = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _iconOffsetX:Number = 0;

        /**
         * Offsets the x position of the icon by a certain number of pixels.
         *
         * The following example offsets the x position of the button's icon
         * by 20 pixels:
         *
         * ~~~as3
         * button.iconOffsetX = 20;
         * ~~~
         */
        public function get iconOffsetX():Number
        {
            return this._iconOffsetX;
        }

        /**
         * @private
         */
        public function set iconOffsetX(value:Number):void
        {
            if(this._iconOffsetX == value)
            {
                return;
            }
            this._iconOffsetX = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _iconOffsetY:Number = 0;

        /**
         * Offsets the y position of the icon by a certain number of pixels.
         *
         * The following example offsets the y position of the button's icon
         * by 20 pixels:
         *
         * ~~~as3
         * button.iconOffsetY = 20;
         * ~~~
         */
        public function get iconOffsetY():Number
        {
            return this._iconOffsetY;
        }

        /**
         * @private
         */
        public function set iconOffsetY(value:Number):void
        {
            if(this._iconOffsetY == value)
            {
                return;
            }
            this._iconOffsetY = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * Determines if a pressed button should remain in the down state if a
         * touch moves outside of the button's bounds. Useful for controls like
         * `Slider` and `ToggleSwitch` to keep a thumb in
         * the down state while it is dragged around.
         *
         * The following example ensures that the button's down state remains
         * active when the button is pressed but the touch moves outside the
         * button's bounds:
         *
         * ~~~as3
         * button.keepDownStateOnRollOut = true;
         * ~~~
         */
        public var keepDownStateOnRollOut:Boolean = false;

        /**
         * @private
         */
        protected var _stateNames:Vector.<String> = new Vector.<String>
        [
            STATE_UP, STATE_DOWN, STATE_HOVER, STATE_DISABLED
        ];

        /**
         * A list of all valid state names.
         */
        protected function get stateNames():Vector.<String>
        {
            return this._stateNames;
        }

        /**
         * @private
         */
        protected var _originalSkinWidth:Number = NaN;

        /**
         * @private
         */
        protected var _originalSkinHeight:Number = NaN;

        /**
         * @private
         */
        protected var _stateToSkinFunction:Function;

        /**
         * Returns a skin for the current state.
         *
         * The following function signature is expected:
         * `function(target:Button, state:Object, oldSkin:DisplayObject = null):DisplayObject`.
         */
        public function get stateToSkinFunction():Function
        {
            return this._stateToSkinFunction;
        }

        /**
         * @private
         */
        public function set stateToSkinFunction(value:Function):void
        {
            if(this._stateToSkinFunction == value)
            {
                return;
            }
            this._stateToSkinFunction = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _stateToIconFunction:Function;

        /**
         * Returns an icon for the current state.
         *
         * The following function signature is expected:
         * `function(target:Button, state:Object, oldIcon:DisplayObject = null):DisplayObject`.
         */
        public function get stateToIconFunction():Function
        {
            return this._stateToIconFunction;
        }

        /**
         * @private
         */
        public function set stateToIconFunction(value:Function):void
        {
            if(this._stateToIconFunction == value)
            {
                return;
            }
            this._stateToIconFunction = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _stateToLabelPropertiesFunction:Function;

        /**
         * Returns a text format for the current state.
         *
         * The following function signature is expected:
         * `function(target:Button, state:Object):Object`.
         */
        public function get stateToLabelPropertiesFunction():Function
        {
            return this._stateToLabelPropertiesFunction;
        }

        /**
         * @private
         */
        public function set stateToLabelPropertiesFunction(value:Function):void
        {
            if(this._stateToLabelPropertiesFunction == value)
            {
                return;
            }
            this._stateToLabelPropertiesFunction = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         * Chooses an appropriate skin based on the state and the selection.
         */
        protected var _skinSelector:StateWithToggleValueSelector = new StateWithToggleValueSelector();

        /**
         * The skin used when no other skin is defined for the current state.
         * Intended for use when multiple states should use the same skin.
         *
         * The following example gives the button a default skin to use for
         * all states when no specific skin is available:
         *
         * ~~~as3
         * button.defaultSkin = new Image( texture );
          * ~~~
         *
         * @see #stateToSkinFunction
         * @see #upSkin
         * @see #downSkin
         * @see #hoverSkin
         * @see #disabledSkin
         * @see #defaultSelectedSkin
         * @see #selectedUpSkin
         * @see #selectedDownSkin
         * @see #selectedHoverSkin
         * @see #selectedDisabledSkin
         */
        public function get defaultSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.defaultValue);
        }

        /**
         * @private
         */
        public function set defaultSkin(value:DisplayObject):void
        {
            if(this._skinSelector.defaultValue == value)
            {
                return;
            }
            this._skinSelector.defaultValue = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used when no other skin is defined for the current state
         * when the button is selected. Has a higher priority than
         * `defaultSkin`, but a lower priority than other selected
         * skins.
         *
         * The following example gives the button a default skin to use for
         * all selected states when no specific skin is available:
         *
         * ~~~as3
         * button.defaultSelectedSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #selectedUpSkin
         * @see #selectedDownSkin
         * @see #selectedHoverSkin
         * @see #selectedDisabledSkin
         */
        public function get defaultSelectedSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.defaultSelectedValue);
        }

        /**
         * @private
         */
        public function set defaultSelectedSkin(value:DisplayObject):void
        {
            if(this._skinSelector.defaultSelectedValue == value)
            {
                return;
            }
            this._skinSelector.defaultSelectedValue = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's up state. If `null`, then
         * `defaultSkin` is used instead.
         *
         * The following example gives the button a skin for the up state:
         *
         * ~~~as3
         * button.upSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #selectedUpSkin
         */
        public function get upSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_UP, false));
        }

        /**
         * @private
         */
        public function set upSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_UP, false) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_UP, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's down state. If `null`, then
         * `defaultSkin` is used instead.
         *
         * The following example gives the button a skin for the down state:
         *
         * ~~~as3
         * button.downSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #selectedDownSkin
         */
        public function get downSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_DOWN, false));
        }

        /**
         * @private
         */
        public function set downSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_DOWN, false) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_DOWN, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's hover state. If `null`, then
         * `defaultSkin` is used instead.
         *
         * The following example gives the button a skin for the hover state:
         *
         * ~~~as3
         * button.hoverSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #selectedHoverSkin
         */
        public function get hoverSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_HOVER, false));
        }

        /**
         * @private
         */
        public function set hoverSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_HOVER, false) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_HOVER, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's disabled state. If `null`,
         * then `defaultSkin` is used instead.
         *
         * The following example gives the button a skin for the disabled state:
         *
         * ~~~as3
         * button.disabledSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #selectedDisabledSkin
         */
        public function get disabledSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_DISABLED, false));
        }

        /**
         * @private
         */
        public function set disabledSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_DISABLED, false) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_DISABLED, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's up state when the button is selected.
         * If `null`, then `defaultSelectedSkin` is used
         * instead. If `defaultSelectedSkin` is also
         * `null`, then `defaultSkin` is used.
         *
         * The following example gives the button a skin for the selected up state:
         *
         * ~~~as3
         * button.selectedUpSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #defaultSelectedSkin
         */
        public function get selectedUpSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_UP, true));
        }

        /**
         * @private
         */
        public function set selectedUpSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_UP, true) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_UP, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's down state when the button is
         * selected. If `null`, then `defaultSelectedSkin`
         * is used instead. If `defaultSelectedSkin` is also
         * `null`, then `defaultSkin` is used.
         *
         * The following example gives the button a skin for the selected down state:
         *
         * ~~~as3
         * button.selectedDownSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #defaultSelectedSkin
         */
        public function get selectedDownSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_DOWN, true));
        }

        /**
         * @private
         */
        public function set selectedDownSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_DOWN, true) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_DOWN, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's hover state when the button is
         * selected. If `null`, then `defaultSelectedSkin`
         * is used instead. If `defaultSelectedSkin` is also
         * `null`, then `defaultSkin` is used.
         *
         * The following example gives the button a skin for the selected hover state:
         *
         * ~~~as3
         * button.selectedHoverSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #defaultSelectedSkin
         */
        public function get selectedHoverSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_HOVER, true));
        }

        /**
         * @private
         */
        public function set selectedHoverSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_HOVER, true) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_HOVER, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The skin used for the button's disabled state when the button is
         * selected. If `null`, then `defaultSelectedSkin`
         * is used instead. If `defaultSelectedSkin` is also
         * `null`, then `defaultSkin` is used.
         *
         * The following example gives the button a skin for the selected disabled state:
         *
         * ~~~as3
         * button.selectedDisabledSkin = new Image( texture );
         * ~~~
         *
         * @see #defaultSkin
         * @see #defaultSelectedSkin
         */
        public function get selectedDisabledSkin():DisplayObject
        {
            return DisplayObject(this._skinSelector.getValueForState(STATE_DISABLED, true));
        }

        /**
         * @private
         */
        public function set selectedDisabledSkin(value:DisplayObject):void
        {
            if(this._skinSelector.getValueForState(STATE_DISABLED, true) == value)
            {
                return;
            }
            this._skinSelector.setValueForState(value, STATE_DISABLED, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }
        
        /**
         * @private
         */
        protected var _labelFactory:Function;

        /**
         * A function used to instantiate the button's label text renderer
         * sub-component. By default, the button will use the global text
         * renderer factory, `FeathersControl.defaultTextRendererFactory()`,
         * to create the label text renderer. The label text renderer must be an
         * instance of `ITextRenderer`. To change properties on the
         * label text renderer, see `defaultLabelProperties` and the
         * other "`LabelProperties`" properties for each button
         * state.
         *
         * The factory should have the following function signature:
         * `function():ITextRenderer`
         *
         * The following example gives the button a custom factory for the
         * label text renderer:
         *
         * ~~~as3
         * button.labelFactory = function():ITextRenderer {
         *    ⇥return new TextFieldTextRenderer();
         * }
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.core.FeathersControl#defaultTextRendererFactory
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
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
        protected var _labelPropertiesSelector:StateWithToggleValueSelector = new StateWithToggleValueSelector();

        /**
         * The default label properties are a set of key/value pairs to be
         * passed down to the button's label text renderer, and it is used when
         * no specific properties are defined for the button's current state.
         * Intended for use when multiple states should share the same
         * properties. The label text renderer is an `ITextRenderer`
         * instance. The available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button default label properties to
         * use for all states when no specific label properties are available:
         *
         * ~~~as3
         * button.defaultLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * button.defaultLabelProperties.wordWrap = true;
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultSelectedLabelProperties
         * @see #stateToLabelPropertiesFunction
         */
        public function get defaultLabelProperties():Dictionary.<String, Object>
        {
            if(!this._labelPropertiesSelector.defaultValue)
                this._labelPropertiesSelector.defaultValue = new Dictionary.<String, Object>();
            return this._labelPropertiesSelector.defaultValue as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set defaultLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.defaultValue = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the up state. If `null`,
         * then `defaultLabelProperties` is used instead. The label
         * text renderer is an `ITextRenderer` instance. The
         * available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * up state:
         *
         * ~~~as3
         * button.upLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #selectedUpLabelProperties
         */
        public function get upLabelProperties():Dictionary.<String, Object>
        {
            return this._labelPropertiesSelector.getValueForState(STATE_UP, false) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set upLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_UP, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the down state. If `null`,
         * then `defaultLabelProperties` is used instead. The label
         * text renderer is an `ITextRenderer` instance. The
         * available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * down state:
         *
         * ~~~as3
         * button.downLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #selectedDownLabelProperties
         */
        public function get downLabelProperties():Dictionary.<String, Object>
        {
            var returnValue:Dictionary.<String, Object> = this._labelPropertiesSelector.getValueForState(STATE_DOWN, false) as Dictionary.<String, Object>;
            if ( !returnValue ) downLabelProperties = returnValue = {};
            return returnValue;
        }

        /**
         * @private
         */
        public function set downLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_DOWN, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the hover state. If `null`,
         * then `defaultLabelProperties` is used instead. The label
         * text renderer is an `ITextRenderer` instance. The
         * available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * hover state:
         *
         * ~~~as3
         * button.hoverLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #selectedHoverLabelProperties
         */
        public function get hoverLabelProperties():Dictionary.<String, Object>
        {
            return this._labelPropertiesSelector.getValueForState(STATE_HOVER, false) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set hoverLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_HOVER, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the disabled state. If `null`,
         * then `defaultLabelProperties` is used instead. The label
         * text renderer is an `ITextRenderer` instance. The
         * available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * disabled state:
         *
         * ~~~as3
         * button.disabledLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #selectedDisabledLabelProperties
         */
        public function get disabledLabelProperties():Dictionary.<String, Object>
        {
            if(this._labelPropertiesSelector.getValueForState(STATE_DISABLED, false) == null)
                this._labelPropertiesSelector.setValueForState(new Dictionary.<String, Object>, STATE_DISABLED, false);
            return this._labelPropertiesSelector.getValueForState(STATE_DISABLED, false) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set disabledLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_DISABLED, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The default selected label properties are a set of key/value pairs to
         * be passed down ot the button's label text renderer, and it is used
         * when the button is selected and no specific properties are defined
         * for the button's current state. If `null`, then
         * `defaultLabelProperties` is used instead. The label
         * text renderer is an `ITextRenderer` instance. The
         * available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button default label properties to
         * use for all selected states when no specific label properties are
         * available:
         *
         * ~~~as3
         * button.defaultSelectedLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * button.defaultSelectedLabelProperties.wordWrap = true;
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         */
        public function get defaultSelectedLabelProperties():Dictionary.<String, Object>
        {
            if(!this._labelPropertiesSelector.defaultSelectedValue)
                this._labelPropertiesSelector.defaultSelectedValue = new Dictionary.<String, Object>();
            return this._labelPropertiesSelector.defaultSelectedValue as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set defaultSelectedLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.defaultSelectedValue = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the up state and is selected. If
         * `null`, then `defaultSelectedLabelProperties`
         * is used instead. If `defaultSelectedLabelProperties` is also
         * `null`, then `defaultLabelProperties` is used.
         * The label text renderer is an `ITextRenderer` instance.
         * The available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * selected up state:
         *
         * ~~~as3
         * button.selectedUpLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #defaultSelectedLabelProperties
         * @see #upLabelProperties
         */
        public function get selectedUpLabelProperties():Dictionary.<String, Object>
        {
            if(!this._labelPropertiesSelector.getValueForState(STATE_UP, true))
                this._labelPropertiesSelector.setValueForState(new Dictionary.<String, Object>, STATE_UP, true);
            return this._labelPropertiesSelector.getValueForState(STATE_UP, true) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set selectedUpLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_UP, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the down state and is selected.
         * If `null`, then `defaultSelectedLabelProperties`
         * is used instead. If `defaultSelectedLabelProperties` is also
         * `null`, then `defaultLabelProperties` is used.
         * The label text renderer is an `ITextRenderer` instance.
         * The available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * selected down state:
         *
         * ~~~as3
         * button.selectedDownLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #defaultSelectedLabelProperties
         * @see #downLabelProperties
         */
        public function get selectedDownLabelProperties():Dictionary.<String, Object>
        {
            if(!this._labelPropertiesSelector.getValueForState(STATE_DOWN, true))
                this._labelPropertiesSelector.setValueForState(new Dictionary.<String, Object>, STATE_DOWN, true);
            return this._labelPropertiesSelector.getValueForState(STATE_DOWN, true) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set selectedDownLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_DOWN, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the hover state and is selected.
         * If `null`, then `defaultSelectedLabelProperties`
         * is used instead. If `defaultSelectedLabelProperties` is also
         * `null`, then `defaultLabelProperties` is used.
         * The label text renderer is an `ITextRenderer` instance.
         * The available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * selected hover state:
         *
         * ~~~as3
         * button.selectedHoverLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #defaultSelectedLabelProperties
         * @see #hoverLabelProperties
         */
        public function get selectedHoverLabelProperties():Dictionary.<String, Object>
        {
            if(!this._labelPropertiesSelector.getValueForState(STATE_HOVER, true))
                this._labelPropertiesSelector.setValueForState(new Dictionary.<String, Object>, STATE_HOVER, true);
            return this._labelPropertiesSelector.getValueForState(STATE_HOVER, true) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set selectedHoverLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_HOVER, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A set of key/value pairs to be passed down ot the button's label
         * text renderer when the button is in the disabled state and is
         * selected. If `null`, then `defaultSelectedLabelProperties`
         * is used instead. If `defaultSelectedLabelProperties` is also
         * `null`, then `defaultLabelProperties` is used.
         * The label text renderer is an `ITextRenderer` instance.
         * The available properties depend on which `ITextRenderer`
         * implementation is returned by `labelFactory`. The most
         * common implementations are `BitmapFontTextRenderer` and
         * `TextFieldTextRenderer`.
         *
         * The following example gives the button label properties for the
         * selected disabled state:
         *
         * ~~~as3
         * button.selectedDisabledLabelProperties.textFormat = new BitmapFontTextFormat( bitmapFont );
         * ~~~
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.controls.text.BitmapFontTextRenderer
         * @see feathers.controls.text.TextFieldTextRenderer
         * @see #defaultLabelProperties
         * @see #defaultSelectedLabelProperties
         * @see #disabledLabelProperties
         */
        public function get selectedDisabledLabelProperties():Dictionary.<String, Object>
        {
            if(!this._labelPropertiesSelector.getValueForState(STATE_DISABLED, true))
                this._labelPropertiesSelector.setValueForState(new Dictionary.<String, Object>, STATE_DISABLED, true);
            return this._labelPropertiesSelector.getValueForState(STATE_DISABLED, true) as Dictionary.<String, Object>;
        }

        /**
         * @private
         */
        public function set selectedDisabledLabelProperties(value:Dictionary.<String, Object>):void
        {
            this._labelPropertiesSelector.setValueForState(value, STATE_DISABLED, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _iconSelector:StateWithToggleValueSelector = new StateWithToggleValueSelector();

        /**
         * The icon used when no other icon is defined for the current state.
         * Intended for use when multiple states should use the same icon.
         *
         * The following example gives the button a default icon to use for
         * all states when no specific icon is available:
         *
         * ~~~as3
         * button.defaultIcon = new Image( texture );
         * ~~~
         *
         * @see #stateToIconFunction
         * @see #upIcon
         * @see #downIcon
         * @see #hoverIcon
         * @see #disabledIcon
         * @see #defaultSelectedIcon
         * @see #selectedUpIcon
         * @see #selectedDownIcon
         * @see #selectedHoverIcon
         * @see #selectedDisabledIcon
         */
        public function get defaultIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.defaultValue);
        }

        /**
         * @private
         */
        public function set defaultIcon(value:DisplayObject):void
        {
            if(this._iconSelector.defaultValue == value)
            {
                return;
            }
            this._iconSelector.defaultValue = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used when no other icon is defined for the current state
         * when the button is selected. Has a higher priority than
         * `defaultIcon`, but a lower priority than other selected
         * icons.
         *
         * The following example gives the button a default icon to use for
         * all selected states when no specific icon is available:
         *
         * ~~~as3
         * button.defaultSelectedIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #selectedUpIcon
         * @see #selectedDownIcon
         * @see #selectedHoverIcon
         * @see #selectedDisabledIcon
         */
        public function get defaultSelectedIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.defaultSelectedValue);
        }

        /**
         * @private
         */
        public function set defaultSelectedIcon(value:DisplayObject):void
        {
            if(this._iconSelector.defaultSelectedValue == value)
            {
                return;
            }
            this._iconSelector.defaultSelectedValue = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's up state. If `null`, then
         * `defaultIcon` is used instead.
         *
         * The following example gives the button an icon for the up state:
         *
         * ~~~as3
         * button.upIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #selectedUpIcon
         */
        public function get upIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_UP, false));
        }

        /**
         * @private
         */
        public function set upIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_UP, false) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_UP, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's down state. If `null`, then
         * `defaultIcon` is used instead.
         *
         * The following example gives the button an icon for the down state:
         *
         * ~~~as3
         * button.downIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #selectedDownIcon
         */
        public function get downIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_DOWN, false));
        }

        /**
         * @private
         */
        public function set downIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_DOWN, false) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_DOWN, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's hover state. If `null`, then
         * `defaultIcon` is used instead.
         *
         * The following example gives the button an icon for the hover state:
         *
         * ~~~as3
         * button.hoverIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #selectedDownIcon
         */
        public function get hoverIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_HOVER, false));
        }

        /**
         * @private
         */
        public function set hoverIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_HOVER, false) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_HOVER, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's disabled state. If `null`, then
         * `defaultIcon` is used instead.
         *
         * The following example gives the button an icon for the disabled state:
         *
         * ~~~as3
         * button.disabledIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #selectedDisabledIcon
         */
        public function get disabledIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_DISABLED, false));
        }

        /**
         * @private
         */
        public function set disabledIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_DISABLED, false) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_DISABLED, false);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's up state when the button is
         * selected. If `null`, then `defaultSelectedIcon`
         * is used instead. If `defaultSelectedIcon` is also
         * `null`, then `defaultIcon` is used.
         *
         * The following example gives the button an icon for the selected up state:
         *
         * ~~~as3
         * button.selectedUpIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #defaultSelectedIcon
         */
        public function get selectedUpIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_UP, true));
        }

        /**
         * @private
         */
        public function set selectedUpIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_UP, true) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_UP, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's down state when the button is
         * selected. If `null`, then `defaultSelectedIcon`
         * is used instead. If `defaultSelectedIcon` is also
         * `null`, then `defaultIcon` is used.
         *
         * The following example gives the button an icon for the selected down state:
         *
         * ~~~as3
         * button.selectedDownIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #defaultSelectedIcon
         */
        public function get selectedDownIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_DOWN, true));
        }

        /**
         * @private
         */
        public function set selectedDownIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_DOWN, true) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_DOWN, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's hover state when the button is
         * selected. If `null`, then `defaultSelectedIcon`
         * is used instead. If `defaultSelectedIcon` is also
         * `null`, then `defaultIcon` is used.
         *
         * The following example gives the button an icon for the selected hover state:
         *
         * ~~~as3
         * button.selectedHoverIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #defaultSelectedIcon
         */
        public function get selectedHoverIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_HOVER, true));
        }

        /**
         * @private
         */
        public function set selectedHoverIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_HOVER, true) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_HOVER, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The icon used for the button's disabled state when the button is
         * selected. If `null`, then `defaultSelectedIcon`
         * is used instead. If `defaultSelectedIcon` is also
         * `null`, then `defaultIcon` is used.
         *
         * The following example gives the button an icon for the selected disabled state:
         *
         * ~~~as3
         * button.selectedDisabledIcon = new Image( texture );
         * ~~~
         *
         * @see #defaultIcon
         * @see #defaultSelectedIcon
         */
        public function get selectedDisabledIcon():DisplayObject
        {
            return DisplayObject(this._iconSelector.getValueForState(STATE_DISABLED, true));
        }

        /**
         * @private
         */
        public function set selectedDisabledIcon(value:DisplayObject):void
        {
            if(this._iconSelector.getValueForState(STATE_DISABLED, true) == value)
            {
                return;
            }
            this._iconSelector.setValueForState(value, STATE_DISABLED, true);
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _autoFlatten:Boolean = false;

        /**
         * Determines if the button should automatically call `flatten()`
         * after it finishes drawing. In some cases, this will improve
         * performance.
         *
         * The following example tells the button to flatten after it validates:
         *
         * ~~~as3
         * button.autoFlatten = true;
         * ~~~
         */
        public function get autoFlatten():Boolean
        {
            return this._autoFlatten;
        }

        /**
         * @private
         */
        public function set autoFlatten(value:Boolean):void
        {
            if(this._autoFlatten == value)
            {
                return;
            }
            this._autoFlatten = value;
            this.unflatten();
            if(this._autoFlatten)
            {
                this.flatten();
            }
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const selectedInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SELECTED);
            const textRendererInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_TEXT_RENDERER);
            const focusInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_FOCUS);

            if(textRendererInvalid)
            {
                this.createLabel();
            }

            if(textRendererInvalid || dataInvalid)
            {
                this.refreshLabelData();
            }

            if(stylesInvalid || stateInvalid || selectedInvalid)
            {
                this.refreshSkin();
                this.refreshIcon();
            }

            if(textRendererInvalid || stylesInvalid || stateInvalid || selectedInvalid)
            {
                this.refreshLabelStyles();
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(stylesInvalid || stateInvalid || selectedInvalid || sizeInvalid)
            {
                this.scaleSkin();
            }

            if(textRendererInvalid || stylesInvalid || stateInvalid || selectedInvalid || dataInvalid || sizeInvalid)
            {
                this.layoutContent();
            }

            if(sizeInvalid || focusInvalid)
            {
                this.refreshFocusIndicator();
            }

            if(this._autoFlatten)
            {
                this.unflatten();
                this.flatten();
            }
        }

        /**
         * @private
         */
        protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }
            this.refreshMaxLabelWidth(true);
            HELPER_POINT = this.labelTextRenderer.measureText();
            if(this.currentIcon is IFeathersControl)
            {
                IFeathersControl(this.currentIcon).validate();
            }
            var newWidth:Number = this.explicitWidth;
            if(needsWidth)
            {
                if(this.currentIcon && this.label)
                {
                    if(this._iconPosition != ICON_POSITION_TOP && this._iconPosition != ICON_POSITION_BOTTOM &&
                        this._iconPosition != ICON_POSITION_MANUAL)
                    {
                        var adjustedGap:Number = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingLeft, this._paddingRight) : this._gap;
                        newWidth = this.currentIcon.width + adjustedGap + HELPER_POINT.x;
                    }
                    else
                    {
                        newWidth = Math.max(this.currentIcon.width, HELPER_POINT.x);
                    }
                }
                else if(this.currentIcon)
                {
                    newWidth = this.currentIcon.width;
                }
                else if(this.label)
                {
                    newWidth = HELPER_POINT.x;
                }
                newWidth += this._paddingLeft + this._paddingRight;
                if(isNaN(newWidth))
                {
                    if(isNaN(this._originalSkinWidth))
                    {
                        newWidth = 0;
                    }
                    else
                    {
                        newWidth = this._originalSkinWidth;
                    }
                }
                else if(!isNaN(this._originalSkinWidth))
                {
                    newWidth = Math.max(newWidth, this._originalSkinWidth);
                }
            }

            var newHeight:Number = this.explicitHeight;
            if(needsHeight)
            {
                if(this.currentIcon && this.label)
                {
                    if(this._iconPosition == ICON_POSITION_TOP || this._iconPosition == ICON_POSITION_BOTTOM)
                    {
                        adjustedGap = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingTop, this._paddingBottom) : this._gap;
                        newHeight = this.currentIcon.height + adjustedGap + HELPER_POINT.y;
                    }
                    else
                    {
                        newHeight = Math.max(this.currentIcon.height, HELPER_POINT.y);
                    }
                }
                else if(this.currentIcon)
                {
                    newHeight = this.currentIcon.height;
                }
                else if(this.label)
                {
                    newHeight = HELPER_POINT.y;
                }
                newHeight += this._paddingTop + this._paddingBottom;
                if(isNaN(newHeight))
                {
                    if(isNaN(this._originalSkinHeight))
                    {
                        newHeight = 0;
                    }
                    else
                    {
                        newHeight = this._originalSkinHeight;
                    }
                }
                else if(!isNaN(this._originalSkinHeight))
                {
                    newHeight = Math.max(newHeight, this._originalSkinHeight);
                }
            }

            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function createLabel():void
        {
            if(this.labelTextRenderer)
            {
                this.removeChild(DisplayObject(this.labelTextRenderer), true);
                this.labelTextRenderer = null;
            }

            const factory:Function = this._labelFactory != null ? this._labelFactory : FeathersControl.defaultTextRendererFactory;
            this.labelTextRenderer = ITextRenderer(factory.call());
            this.labelTextRenderer.nameList.add(this.labelName);
            this.addChild(DisplayObject(this.labelTextRenderer));
        }

        /**
         * @private
         */
        protected function refreshLabelData():void
        {
            this.labelTextRenderer.text = this._label;
            this.labelTextRenderer.visible = this._label != null && this._label.length > 0;
        }

        /**
         * @private
         */
        protected function refreshSkin():void
        {
            const oldSkin:DisplayObject = this.currentSkin;
            if(this._stateToSkinFunction != null)
            {
                this.currentSkin = DisplayObject(this._stateToSkinFunction.call(null, this, this._currentState, oldSkin));
            }
            else
            {
                this.currentSkin = DisplayObject(this._skinSelector.updateValue.call(null, this, this._currentState, this.currentSkin));
            }
            if(this.currentSkin != oldSkin)
            {
                if(oldSkin)
                {
                    this.removeChild(oldSkin, false);
                }
                if(this.currentSkin)
                {
                    this.addChildAt(this.currentSkin, 0);
                }
            }
            if(this.currentSkin && (isNaN(this._originalSkinWidth) || isNaN(this._originalSkinHeight)))
            {
                if(this.currentSkin is IFeathersControl)
                {
                    IFeathersControl(this.currentSkin).validate();
                }
                this._originalSkinWidth = this.currentSkin.width;
                this._originalSkinHeight = this.currentSkin.height;
            }
        }

        /**
         * @private
         */
        protected function refreshIcon():void
        {
            const oldIcon:DisplayObject = this.currentIcon;
            if(this._stateToIconFunction != null)
            {
                this.currentIcon = DisplayObject(this._stateToIconFunction(this, this._currentState, oldIcon));
            }
            else
            {
                this.currentIcon = DisplayObject(this._iconSelector.updateValue(this, this._currentState, this.currentIcon));
            }
            if(this.currentIcon != oldIcon)
            {
                if(oldIcon)
                {
                    this.removeChild(oldIcon, false);
                }
                if(this.currentIcon)
                {
                    this.addChild(this.currentIcon);
                }
            }
        }

        /**
         * @private
         */
        protected function refreshLabelStyles():void
        {
            if(this._stateToLabelPropertiesFunction != null)
            {
                var properties:Dictionary.<String, Object> = this._stateToLabelPropertiesFunction.call(this, this._currentState) as Dictionary.<String, Object>;
            }
            else
            {
                properties = this._labelPropertiesSelector.updateValue(this, this._currentState) as Dictionary.<String, Object>;
            }

            const displayLabelRenderer:DisplayObject = DisplayObject(this.labelTextRenderer);

            if(properties)
                Dictionary.mapToObject(properties, displayLabelRenderer);
        }

        /**
         * @private
         */
        protected function scaleSkin():void
        {
            if(!this.currentSkin)
            {
                return;
            }
            this.currentSkin.x = 0;
            this.currentSkin.y = 0;
            if(this.currentSkin.width != this.actualWidth)
            {
                this.currentSkin.width = this.actualWidth;
            }
            if(this.currentSkin.height != this.actualHeight)
            {
                this.currentSkin.height = this.actualHeight;
            }
        }

        /**
         * @private
         */
        protected function layoutContent():void
        {
            if(this.currentIcon is IFeathersControl)
            {
                IFeathersControl(this.currentIcon).validate();
            }
            this.refreshMaxLabelWidth(false);
            if(this._label && this.currentIcon)
            {
                this.labelTextRenderer.validate();
                this.positionSingleChild(DisplayObject(this.labelTextRenderer));
                if(this._iconPosition != ICON_POSITION_MANUAL)
                {
                    this.positionLabelAndIcon();
                }

            }
            else if(this._label && !this.currentIcon)
            {
                this.labelTextRenderer.validate();
                this.positionSingleChild(DisplayObject(this.labelTextRenderer));
            }
            else if(!this._label && this.currentIcon && this._iconPosition != ICON_POSITION_MANUAL)
            {
                this.positionSingleChild(this.currentIcon);
            }

            if(this.currentIcon)
            {
                if(this._iconPosition == ICON_POSITION_MANUAL)
                {
                    this.currentIcon.x = this._paddingLeft;
                    this.currentIcon.y = this._paddingTop;
                }
                this.currentIcon.x += this._iconOffsetX;
                this.currentIcon.y += this._iconOffsetY;
            }
            if(this._label)
            {
                this.labelTextRenderer.x += this._labelOffsetX;
                this.labelTextRenderer.y += this._labelOffsetY;
            }
        }

        /**
         * @private
         */
        protected function refreshMaxLabelWidth(forMeasurement:Boolean):void
        {
            var calculatedWidth:Number = this.actualWidth;
            if(forMeasurement)
            {
                calculatedWidth = isNaN(this.explicitWidth) ? this._maxWidth : this.explicitWidth;
            }
            if(this._label && this.currentIcon)
            {
                if(this._iconPosition == ICON_POSITION_LEFT || this._iconPosition == ICON_POSITION_LEFT_BASELINE ||
                    this._iconPosition == ICON_POSITION_RIGHT || this._iconPosition == ICON_POSITION_RIGHT_BASELINE)
                {
                    const adjustedGap:Number = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingLeft, this._paddingRight) : this._gap;
                    this.labelTextRenderer.maxWidth = calculatedWidth - this._paddingLeft - this._paddingRight - this.currentIcon.width - adjustedGap;
                }
                else
                {
                    this.labelTextRenderer.maxWidth = calculatedWidth - this._paddingLeft - this._paddingRight;
                }

            }
            else if(this._label && !this.currentIcon)
            {
                this.labelTextRenderer.maxWidth = calculatedWidth - this._paddingLeft - this._paddingRight;
            }
        }

        /**
         * @private
         */
        protected function positionSingleChild(displayObject:DisplayObject):void
        {
            if(this._horizontalAlign == HORIZONTAL_ALIGN_LEFT)
            {
                displayObject.x = this._paddingLeft;
            }
            else if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
            {
                displayObject.x = this.actualWidth - this._paddingRight - displayObject.width;
            }
            else //center
            {
                displayObject.x = this._paddingLeft + (this.actualWidth - this._paddingLeft - this._paddingRight - displayObject.width) / 2;
            }
            if(this._verticalAlign == VERTICAL_ALIGN_TOP)
            {
                displayObject.y = this._paddingTop;
            }
            else if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
            {
                displayObject.y = this.actualHeight - this._paddingBottom - displayObject.height;
            }
            else //middle
            {
                displayObject.y = this._paddingTop + (this.actualHeight - this._paddingTop - this._paddingBottom - displayObject.height) / 2;
            }
        }

        /**
         * @private
         */
        protected function positionLabelAndIcon():void
        {
            if(this._iconPosition == ICON_POSITION_TOP)
            {
                if(this._gap == Number.POSITIVE_INFINITY)
                {
                    this.currentIcon.y = this._paddingTop;
                    this.labelTextRenderer.y = this.actualHeight - this._paddingBottom - this.labelTextRenderer.height;
                }
                else
                {
                    if(this._verticalAlign == VERTICAL_ALIGN_TOP)
                    {
                        this.labelTextRenderer.y += this.currentIcon.height + this._gap;
                    }
                    else if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
                    {
                        this.labelTextRenderer.y += (this.currentIcon.height + this._gap) / 2;
                    }
                    this.currentIcon.y = this.labelTextRenderer.y - this.currentIcon.height - this._gap;
                }
            }
            else if(this._iconPosition == ICON_POSITION_RIGHT || this._iconPosition == ICON_POSITION_RIGHT_BASELINE)
            {
                if(this._gap == Number.POSITIVE_INFINITY)
                {
                    this.labelTextRenderer.x = this._paddingLeft;
                    this.currentIcon.x = this.actualWidth - this._paddingRight - this.currentIcon.width;
                }
                else
                {
                    if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
                    {
                        this.labelTextRenderer.x -= this.currentIcon.width + this._gap;
                    }
                    else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
                    {
                        this.labelTextRenderer.x -= (this.currentIcon.width + this._gap) / 2;
                    }
                    this.currentIcon.x = this.labelTextRenderer.x + this.labelTextRenderer.width + this._gap;
                }
            }
            else if(this._iconPosition == ICON_POSITION_BOTTOM)
            {
                if(this._gap == Number.POSITIVE_INFINITY)
                {
                    this.labelTextRenderer.y = this._paddingTop;
                    this.currentIcon.y = this.actualHeight - this._paddingBottom - this.currentIcon.height;
                }
                else
                {
                    if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
                    {
                        this.labelTextRenderer.y -= this.currentIcon.height + this._gap;
                    }
                    else if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
                    {
                        this.labelTextRenderer.y -= (this.currentIcon.height + this._gap) / 2;
                    }
                    this.currentIcon.y = this.labelTextRenderer.y + this.labelTextRenderer.height + this._gap;
                }
            }
            else if(this._iconPosition == ICON_POSITION_LEFT || this._iconPosition == ICON_POSITION_LEFT_BASELINE)
            {
                if(this._gap == Number.POSITIVE_INFINITY)
                {
                    this.currentIcon.x = this._paddingLeft;
                    this.labelTextRenderer.x = this.actualWidth - this._paddingRight - this.labelTextRenderer.width;
                }
                else
                {
                    if(this._horizontalAlign == HORIZONTAL_ALIGN_LEFT)
                    {
                        this.labelTextRenderer.x += this._gap + this.currentIcon.width;
                    }
                    else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
                    {
                        this.labelTextRenderer.x += (this._gap + this.currentIcon.width) / 2;
                    }
                    this.currentIcon.x = this.labelTextRenderer.x - this._gap - this.currentIcon.width;
                }
            }

            if(this._iconPosition == ICON_POSITION_LEFT || this._iconPosition == ICON_POSITION_RIGHT)
            {
                if(this._verticalAlign == VERTICAL_ALIGN_TOP)
                {
                    this.currentIcon.y = this._paddingTop;
                }
                else if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
                {
                    this.currentIcon.y = this.actualHeight - this._paddingBottom - this.currentIcon.height;
                }
                else
                {
                    this.currentIcon.y = this._paddingTop + (this.actualHeight - this._paddingTop - this._paddingBottom - this.currentIcon.height) / 2;
                }
            }
            else if(this._iconPosition == ICON_POSITION_LEFT_BASELINE || this._iconPosition == ICON_POSITION_RIGHT_BASELINE)
            {
                this.currentIcon.y = this.labelTextRenderer.y + (this.labelTextRenderer.baseline) - this.currentIcon.height;
            }
            else //top or bottom
            {
                if(this._horizontalAlign == HORIZONTAL_ALIGN_LEFT)
                {
                    this.currentIcon.x = this._paddingLeft;
                }
                else if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
                {
                    this.currentIcon.x = this.actualWidth - this._paddingRight - this.currentIcon.width;
                }
                else
                {
                    this.currentIcon.x = this._paddingLeft + (this.actualWidth - this._paddingLeft - this._paddingRight - this.currentIcon.width) / 2;
                }
            }
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
        protected function button_removedFromStageHandler(event:Event):void
        {
            this._touchPointID = -1;
            this.currentState = this._isEnabled ? STATE_UP : STATE_DISABLED;
        }

        /**
         * @private
         */
        protected function button_touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                return;
            }

            const touches:Vector.<Touch> = event.getTouches(this, null, HELPER_TOUCHES_VECTOR);
            
            trace("TOUCHING", touches);
            
            if(touches.length == 0)
            {
                //end of hover
                this.currentState = STATE_UP;
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
                    this.currentState = STATE_UP;
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }

                HELPER_POINT = touch.getLocation(this.stage);
                var isInBounds:Boolean = this.contains(this.stage.hitTest(HELPER_POINT, true));
                if(touch.phase == TouchPhase.MOVED)
                {
                    if(isInBounds || this.keepDownStateOnRollOut)
                    {
                        this.currentState = STATE_DOWN;
                    }
                    else
                    {
                        this.currentState = STATE_UP;
                    }
                }
                else if(touch.phase == TouchPhase.ENDED)
                {
                    this._touchPointID = -1;
                    if(isInBounds)
                    {
                        if(this._isHoverSupported)
                        {
                            this.currentState = (isInBounds && this._isHoverSupported) ? STATE_HOVER : STATE_UP;
                        }
                        else
                        {
                            this.currentState = STATE_UP;
                        }
                        this.dispatchEventWith(Event.TRIGGERED);
                        if(this._isToggle)
                        {
                            this.isSelected = !this._isSelected;
                        }
                    }
                    else
                    {
                        this.currentState = STATE_UP;
                    }
                }
            }
            else //if we get here, we don't have a saved touch ID yet
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this.currentState = STATE_DOWN;
                        this._touchPointID = touch.id;
                        break;
                    }
                    else if(touch.phase == TouchPhase.HOVER)
                    {
                        this.currentState = STATE_HOVER;
                        this._isHoverSupported = true;
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
            if (this.nativeDeleted())
                return;

            if(event.keyCode == LoomKey.ESCAPE)
            {
                this._touchPointID = -1;
                this.currentState = STATE_UP;
            }
            if(this._touchPointID >= 0 || event.keyCode != LoomKey.SPACEBAR)
            {
                return;
            }
            this._touchPointID = int.MAX_VALUE;
            this.currentState = STATE_DOWN;
        }

        /**
         * @private
         */
        protected function stage_keyUpHandler(event:KeyboardEvent):void
        {
            if(this.nativeDeleted() || this._touchPointID != int.MAX_VALUE || event.keyCode != LoomKey.SPACEBAR)
            {
                return;
            }
            this._touchPointID = -1;
            this.currentState = STATE_UP;
            this.dispatchEventWith(Event.TRIGGERED);
            if(this._isToggle)
            {
                this.isSelected = !this._isSelected;
            }
        }
    }
}
