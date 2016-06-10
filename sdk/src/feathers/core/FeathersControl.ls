/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
    import feathers.text.DummyTextEditor;
    import feathers.text.DummyTextRenderer;
    import feathers.text.BitmapFontTextRenderer;
    import feathers.text.BitmapFontTextEditor;

    import feathers.events.FeathersEventType;
    import feathers.layout.ILayoutData;
    import feathers.layout.ILayoutDisplayObject;

    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;

    import loom2d.display.DisplayObject;
    import loom2d.display.Sprite;
    import loom2d.events.Event;
    import loom2d.Loom2D;

    /**
     * Dispatched after initialize() has been called, but before the first time
     * that draw() has been called.
     *
     * @eventType feathers.events.FeathersEventType.INITIALIZE
     */
    [Event(name="initialize",type="loom2d.events.Event",desc="Dispatched after initialize() has been called")]

    /**
     * Dispatched when the width or height of the control changes.
     *
     * @eventType feathers.events.FeathersEventType.RESIZE
     */
    [Event(name="resize",type="loom2d.events.Event")]

    /**
     * Base class for all UI controls. Implements invalidation and sets up some
     * basic template functions like `initialize()` and
     * `draw()`.
     */
    public class FeathersControl extends Sprite implements IFeathersControl, ILayoutDisplayObject
    {
        /**
         * @private
         */
        private static const HELPER_MATRIX:Matrix = new Matrix();

        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         * Meant to be constant, but the ValidationQueue needs access to
         * Starling in its constructor, so it needs to be instantiated after
         * Starling is initialized.
         */
        protected static var VALIDATION_QUEUE:ValidationQueue;

        /**
         * @private
         * Used for clipping.
         *
         * @see #clipRect
         */
        protected static var currentScissorRect:Rectangle;

        /**
         * Flag to indicate that everything is invalid and should be redrawn.
         */
        public static const INVALIDATION_FLAG_ALL:String = "all";

        /**
         * Invalidation flag to indicate that the state has changed. Used by
         * `isEnabled`, but may be used for other control states too.
         *
         * @see #isEnabled
         */
        public static const INVALIDATION_FLAG_STATE:String = "state";

        /**
         * Invalidation flag to indicate that the dimensions of the UI control
         * have changed.
         */
        public static const INVALIDATION_FLAG_SIZE:String = "size";

        /**
         * Invalidation flag to indicate that the styles or visual appearance of
         * the UI control has changed.
         */
        public static const INVALIDATION_FLAG_STYLES:String = "styles";

        /**
         * Invalidation flag to indicate that the skin of the UI control has changed.
         */
        public static const INVALIDATION_FLAG_SKIN:String = "skin";

        /**
         * Invalidation flag to indicate that the layout of the UI control has
         * changed.
         */
        public static const INVALIDATION_FLAG_LAYOUT:String = "layout";

        /**
         * Invalidation flag to indicate that the primary data displayed by the
         * UI control has changed.
         */
        public static const INVALIDATION_FLAG_DATA:String = "data";

        /**
         * Invalidation flag to indicate that the scroll position of the UI
         * control has changed.
         */
        public static const INVALIDATION_FLAG_SCROLL:String = "scroll";

        /**
         * Invalidation flag to indicate that the selection of the UI control
         * has changed.
         */
        public static const INVALIDATION_FLAG_SELECTED:String = "selected";

        /**
         * Invalidation flag to indicate that the focus of the UI control has
         * changed.
         */
        public static const INVALIDATION_FLAG_FOCUS:String = "focus";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_TEXT_RENDERER:String = "textRenderer";

        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_TEXT_EDITOR:String = "textEditor";

        /**
         * @private
         */
        protected static const ILLEGAL_WIDTH_ERROR:String = "A component's width cannot be NaN.";

        /**
         * @private
         */
        protected static const ILLEGAL_HEIGHT_ERROR:String = "A component's height cannot be NaN.";

        /**
         * A function used by all UI controls that support text renderers to
         * create an ITextRenderer instance. You may replace the default
         * function with your own, if you prefer not to use the
         * BitmapFontTextRenderer.
         *
         * The function is expected to have the following signature:
         * `function():ITextRenderer`
         *
         * @see http://wiki.starling-framework.org/feathers/text-renderers
         * @see feathers.core.ITextRenderer
         */
        public static var defaultTextRendererFactory:Function;

        /**
         * A function used by all UI controls that support text editor to
         * create an `ITextEditor` instance. You may replace the
         * default function with your own, if you prefer not to use the
         * `StageTextTextEditor`.
         *
         * The function is expected to have the following signature:
         * `function():ITextEditor`
         *
         * @see http://wiki.starling-framework.org/feathers/text-editors
         * @see feathers.core.ITextEditor
         */
        public static var defaultTextEditorFactory:Function;

        /**
         * Static constructor.
         */
        static public function FeathersControl()
        {
            defaultTextRendererFactory = function():ITextRenderer
            {
                return new BitmapFontTextRenderer();
                //return null; // new BitmapFontTextRenderer();
            };

            defaultTextEditorFactory = function():ITextEditor
            {
                return new BitmapFontTextEditor();
                //return null; //new StageTextTextEditor();
            };
        }

        /**
         * Constructor.
         */
        public function FeathersControl()
        {
            super();
            if ( !VALIDATION_QUEUE ) VALIDATION_QUEUE = new ValidationQueue();
            this.addEventListener(Event.ADDED_TO_STAGE, initialize_addedToStageHandler);
            this.addEventListener(Event.FLATTEN, feathersControl_flattenHandler);
        }

        public override function dispose():void
        {
            if(this.layoutData)
            {
                Loom2D.juggler.delayCall( Object( this.layoutData ).deleteNative, 0.1 );
                this.layoutData = null;
            }

            super.dispose();
        }

        /**
         * @private
         */
        protected var _nameList:TokenList = new TokenList();

        /**
         * Contains a list of all "names" assigned to this control. Names are
         * like classes in CSS selectors. They are a non-unique identifier that
         * can differentiate multiple styles of the same type of UI control. A
         * single control may have many names, and many controls can share a
         * single name. Names may be added, removed, or toggled on the `nameList`.
         *
         * @see #name
         */
        public function get nameList():TokenList
        {
            return this._nameList;
        }

        /**
         * The concatenated `nameList`, with each name separated by
         * spaces. Names are like classes in CSS selectors. They are a
         * non-unique identifier that can differentiate multiple styles of the
         * same type of UI control. A single control may have many names, and
         * many controls can share a single name.
         *
         * @see #nameList
         */
        override public function get name():String
        {
            return this._nameList.value;
        }

        /**
         * @private
         */
        override public function set name(value:String):void
        {
            this._nameList.value = value;
        }

        /**
         * @private
         */
        protected var _isQuickHitAreaEnabled:Boolean = false;

        /**
         * Similar to mouseChildren on the classic display list. If true,
         * children cannot dispatch touch events, but hit tests will be much
         * faster.
         */
        public function get isQuickHitAreaEnabled():Boolean
        {
            return this._isQuickHitAreaEnabled;
        }

        /**
         * @private
         */
        public function set isQuickHitAreaEnabled(value:Boolean):void
        {
            this._isQuickHitAreaEnabled = value;
        }

        /**
         * @private
         */
        protected var _hitArea:Rectangle = new Rectangle();

        /**
         * @private
         */
        protected var _isInitialized:Boolean = false;

        /**
         * Determines if the component has been initialized yet. The
         * `initialize()` function is called one time only, when the
         * Feathers UI control is added to the display list for the first time.
         */
        public function get isInitialized():Boolean
        {
            return this._isInitialized;
        }

        /**
         * @private
         * A flag that indicates that everything is invalid. If true, no other
         * flags will need to be tracked.
         */
        protected var _isAllInvalid:Boolean = false;

        /**
         * @private
         */
        protected var _invalidationFlags = new Dictionary.<String, Object>();

        /**
         * @private
         */
        protected var _delayedInvalidationFlags = new Dictionary.<String, Object>();

        /**
         * @private
         */
        protected var _isEnabled:Boolean = true;

        /**
         * Indicates whether the control is interactive or not.
         */
        public function get isEnabled():Boolean
        {
            return _isEnabled;
        }

        /**
         * @private
         */
        public function set isEnabled(value:Boolean):void
        {
            if(this._isEnabled == value)
            {
                return;
            }
            this._isEnabled = value;
            this.invalidate(INVALIDATION_FLAG_STATE);
        }

        /**
         * The width value explicitly set by calling the width setter or
         * setSize().
         */
        protected var explicitWidth:Number = NaN;

        /**
         * The final width value that should be used for layout. If the width
         * has been explicitly set, then that value is used. If not, the actual
         * width will be calculated automatically. Each component has different
         * automatic sizing behavior, but it's usually based on the component's
         * skin or content, including text or subcomponents.
         */
        protected var actualWidth:Number = 0;

        /**
         * The width of the component, in pixels. This could be a value that was
         * set explicitly, or the component will automatically resize if no
         * explicit width value is provided. Each component has a different
         * automatic sizing behavior, but it's usually based on the component's
         * skin or content, including text or subcomponents.
         * 
         * **Note:** Values of the `width` and
         * `height` properties may not be accurate until after
         * validation. If you are seeing `width` or `height`
         * values of `0`, but you can see something on the screen and
         * know that the value should be larger, it may be because you asked for
         * the dimensions before the component had validated. Call
         * `validate()` to tell the component to immediately redraw
         * and calculate an accurate values for the dimensions.
         * 
         * @see feathers.core.IFeathersControl#validate()
         */
        override public function get width():Number
        {
            return this.actualWidth;
        }

        /**
         * @private
         */
        override public function set width(value:Number):void
        {
            if(this.explicitWidth == value)
            {
                return;
            }
            const valueIsNaN:Boolean = isNaN(value);
            if(valueIsNaN && isNaN(this.explicitWidth))
            {
                return;
            }
            this.explicitWidth = value;
            if(valueIsNaN)
            {
                this.actualWidth = 0;
                this.invalidate(INVALIDATION_FLAG_SIZE);
            }
            else
            {
                this.setSizeInternal(value, this.actualHeight, true);
            }
        }

        /**
         * The height value explicitly set by calling the height setter or
         * setSize().
         */
        protected var explicitHeight:Number = NaN;

        /**
         * The final height value that should be used for layout. If the height
         * has been explicitly set, then that value is used. If not, the actual
         * height will be calculated automatically. Each component has different
         * automatic sizing behavior, but it's usually based on the component's
         * skin or content, including text or subcomponents.
         */
        protected var actualHeight:Number = 0;

        /**
         * The height of the component, in pixels. This could be a value that
         * was set explicitly, or the component will automatically resize if no
         * explicit height value is provided. Each component has a different
         * automatic sizing behavior, but it's usually based on the component's
         * skin or content, including text or subcomponents.
         * 
         * **Note:** Values of the `width` and
         * `height` properties may not be accurate until after
         * validation. If you are seeing `width` or `height`
         * values of `0`, but you can see something on the screen and
         * know that the value should be larger, it may be because you asked for
         * the dimensions before the component had validated. Call
         * `validate()` to tell the component to immediately redraw
         * and calculate an accurate values for the dimensions.
         * 
         * @see feathers.core.IFeathersControl#validate()
         */
        override public function get height():Number
        {
            return this.actualHeight;
        }

        /**
         * @private
         */
        override public function set height(value:Number):void
        {
            if(this.explicitHeight == value)
            {
                return;
            }
            const valueIsNaN:Boolean = isNaN(value);
            if(valueIsNaN && isNaN(this.explicitHeight))
            {
                return;
            }
            this.explicitHeight = value;
            if(valueIsNaN)
            {
                this.actualHeight = 0;
                this.invalidate(INVALIDATION_FLAG_SIZE);
            }
            else
            {
                this.setSizeInternal(this.actualWidth, value, true);
            }
        }

        /**
         * @private
         */
        protected var _minTouchWidth:Number = 0;

        /**
         * If using `isQuickHitAreaEnabled`, and the hit area's
         * width is smaller than this value, it will be expanded.
         */
        public function get minTouchWidth():Number
        {
            return this._minTouchWidth;
        }

        /**
         * @private
         */
        public function set minTouchWidth(value:Number):void
        {
            if(this._minTouchWidth == value)
            {
                return;
            }
            this._minTouchWidth = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _minTouchHeight:Number = 0;

        /**
         * If using `isQuickHitAreaEnabled`, and the hit area's
         * height is smaller than this value, it will be expanded.
         */
        public function get minTouchHeight():Number
        {
            return this._minTouchHeight;
        }

        /**
         * @private
         */
        public function set minTouchHeight(value:Number):void
        {
            if(this._minTouchHeight == value)
            {
                return;
            }
            this._minTouchHeight = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _minWidth:Number = 0;

        /**
         * The minimum recommended width to be used for self-measurement and,
         * optionally, by any code that is resizing this component. This value
         * is not strictly enforced in all cases. An explicit width value that
         * is smaller than `minWidth` may be set and will not be
         * affected by the minimum.
         */
        public function get minWidth():Number
        {
            return this._minWidth;
        }

        /**
         * @private
         */
        public function set minWidth(value:Number):void
        {
            if(this._minWidth == value)
            {
                return;
            }
            if(isNaN(value))
            {
                Debug.assert("minWidth cannot be NaN");
            }
            this._minWidth = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _minHeight:Number = 0;

        /**
         * The minimum recommended height to be used for self-measurement and,
         * optionally, by any code that is resizing this component. This value
         * is not strictly enforced in all cases. An explicit height value that
         * is smaller than `minHeight` may be set and will not be
         * affected by the minimum.
         */
        public function get minHeight():Number
        {
            return this._minHeight;
        }

        /**
         * @private
         */
        public function set minHeight(value:Number):void
        {
            if(this._minHeight == value)
            {
                return;
            }
            if(isNaN(value))
            {
                Debug.assert("minHeight cannot be NaN");
            }
            this._minHeight = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _maxWidth:Number = Number.POSITIVE_INFINITY;

        /**
         * The maximum recommended width to be used for self-measurement and,
         * optionally, by any code that is resizing this component. This value
         * is not strictly enforced in all cases. An explicit width value that
         * is larger than `maxWidth` may be set and will not be
         * affected by the maximum.
         */
        public function get maxWidth():Number
        {
            return this._maxWidth;
        }

        /**
         * @private
         */
        public function set maxWidth(value:Number):void
        {
            if(this._maxWidth == value)
            {
                return;
            }
            if(isNaN(value))
            {
                Debug.assert("maxWidth cannot be NaN");
            }
            this._maxWidth = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _maxHeight:Number = Number.POSITIVE_INFINITY;

        /**
         * The maximum recommended height to be used for self-measurement and,
         * optionally, by any code that is resizing this component. This value
         * is not strictly enforced in all cases. An explicit height value that
         * is larger than `maxHeight` may be set and will not be
         * affected by the maximum.
         */
        public function get maxHeight():Number
        {
            return this._maxHeight;
        }

        /**
         * @private
         */
        public function set maxHeight(value:Number):void
        {
            if(this._maxHeight == value)
            {
                return;
            }
            if(isNaN(value))
            {
                Debug.assert("maxHeight cannot be NaN");
            }
            this._maxHeight = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected var _includeInLayout:Boolean = true;

        /**
         * @inheritDoc
         */
        public function get includeInLayout():Boolean
        {
            return this._includeInLayout;
        }

        /**
         * @private
         */
        public function set includeInLayout(value:Boolean):void
        {
            if(this._includeInLayout == value)
            {
                return;
            }
            this._includeInLayout = value;
            this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
        }

        /**
         * @private
         */
        protected var _layoutData:ILayoutData;

        /**
         * @inheritDoc
         */
        public function get layoutData():ILayoutData
        {
            return this._layoutData;
        }

        /**
         * @private
         */
        public function set layoutData(value:ILayoutData):void
        {
            if(this._layoutData == value)
            {
                return;
            }
            if(this._layoutData)
            {
                this._layoutData.removeEventListener(Event.CHANGE, layoutData_changeHandler);
            }
            this._layoutData = value;
            if(this._layoutData)
            {
                this._layoutData.addEventListener(Event.CHANGE, layoutData_changeHandler);
            }
            this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
        }

        /**
         * @private
         */
        protected var _focusManager:IFocusManager;

        /**
         * @copy feathers.core.IFocusDisplayObject#focusManager
         */
        public function get focusManager():IFocusManager
        {
            return this._focusManager;
        }

        /**
         * @private
         */
        public function set focusManager(value:IFocusManager):void
        {
            if(!(this is IFocusDisplayObject))
            {
                Debug.assert("Cannot pass a focus manager to a component that does not implement feathers.core.IFocusDisplayObject");
            }
            if(this._focusManager == value)
            {
                return;
            }
            this._focusManager = value;
            if(this._focusManager)
            {
                this.addEventListener(FeathersEventType.FOCUS_IN, focusInHandler);
                this.addEventListener(FeathersEventType.FOCUS_OUT, focusOutHandler);
            }
            else
            {
                this.removeEventListener(FeathersEventType.FOCUS_IN, focusInHandler);
                this.removeEventListener(FeathersEventType.FOCUS_OUT, focusOutHandler);
            }
        }

        /**
         * @private
         */
        protected var _isFocusEnabled:Boolean = true;

        /**
         * @copy feathers.core.IFocusDisplayObject#isFocusEnabled
         */
        public function get isFocusEnabled():Boolean
        {
            return this._isFocusEnabled;
        }

        /**
         * @private
         */
        public function set isFocusEnabled(value:Boolean):void
        {
            if(!(this is IFocusDisplayObject))
            {
                Debug.assert("Cannot enable focus on a component that does not implement feathers.core.IFocusDisplayObject");
            }
            if(this._isFocusEnabled == value)
            {
                return;
            }
            this._isFocusEnabled = value;
        }

        /**
         * @private
         */
        protected var _nextTabFocus:IFocusDisplayObject;

        /**
         * @copy feathers.core.IFocusDisplayObject#nextTabFocus
         */
        public function get nextTabFocus():IFocusDisplayObject
        {
            return this._nextTabFocus;
        }

        /**
         * @private
         */
        public function set nextTabFocus(value:IFocusDisplayObject):void
        {
            if(!(this is IFocusDisplayObject))
            {
                Debug.assert("Cannot set next tab focus on a component that does not implement feathers.core.IFocusDisplayObject");
            }
            this._nextTabFocus = value;
        }

        /**
         * @private
         */
        protected var _previousTabFocus:IFocusDisplayObject;

        /**
         * @copy feathers.core.IFocusDisplayObject#previousTabFocus
         */
        public function get previousTabFocus():IFocusDisplayObject
        {
            return this._previousTabFocus;
        }

        /**
         * @private
         */
        public function set previousTabFocus(value:IFocusDisplayObject):void
        {
            if(!(this is IFocusDisplayObject))
            {
                Debug.assert("Cannot set previous tab focus on a component that does not implement feathers.core.IFocusDisplayObject");
            }
            this._previousTabFocus = value;
        }

        /**
         * @private
         */
        protected var _focusIndicatorSkin:DisplayObject;

        /**
         * If this component supports focus, this optional skin will be
         * displayed above the component when `showFocus()` is
         * called. The focus indicator skin is not always displayed when the
         * component has focus. Typically, if the component receives focus from
         * a touch, the focus indicator is not displayed.
         *
         * The `touchable` of this skin will always be set to
         * `false` so that it does not "steal" touches from the
         * component or its sub-components. This skin will not affect the
         * dimensions of the component or its hit area. It is simply a visual
         * indicator of focus.
         */
        public function get focusIndicatorSkin():DisplayObject
        {
            return this._focusIndicatorSkin;
        }

        /**
         * @private
         */
        public function set focusIndicatorSkin(value:DisplayObject):void
        {
            if(!(this is IFocusDisplayObject))
            {
                Debug.assert("Cannot set focus indicator skin on a component that does not implement feathers.core.IFocusDisplayObject");
            }
            if(this._focusIndicatorSkin == value)
            {
                return;
            }
            if(this._focusIndicatorSkin && this._focusIndicatorSkin.parent)
            {
                this._focusIndicatorSkin.removeFromParent(false);
            }
            this._focusIndicatorSkin = value;
            if(this._focusIndicatorSkin)
            {
                this._focusIndicatorSkin.touchable = false;
            }
            if(this._focusManager && this._focusManager.focus as Object == this as Object)
            {
                this.invalidate(INVALIDATION_FLAG_STYLES);
            }
        }

        /**
         * Quickly sets all focus padding properties to the same value. The
         * `focusPadding` getter always returns the value of
         * `focusPaddingTop`, but the other focus padding values may
         * be different.
         *
         * The following example gives the button 2 pixels of focus padding
         * on all sides:
         *
         * ~~~as3
         * object.padding = 2;
         * ~~~
         */
        public function get focusPadding():Number
        {
            return this._focusPaddingTop;
        }

        /**
         * @private
         */
        public function set focusPadding(value:Number):void
        {
            this.focusPaddingTop = value;
            this.focusPaddingRight = value;
            this.focusPaddingBottom = value;
            this.focusPaddingLeft = value;
        }

        /**
         * @private
         */
        protected var _focusPaddingTop:Number = 0;

        /**
         * The minimum space, in pixels, between the object's top edge and the
         * top edge of the focus indicator skin. A negative value may be used
         * to expand the focus indicator skin outside the bounds of the object.
         *
         * The following example gives the focus indicator skin -2 pixels of
         * padding on the top edge only:
         *
         * ~~~as3
         * button.focusPaddingTop = -2;
         * ~~~
         */
        public function get focusPaddingTop():Number
        {
            return this._focusPaddingTop;
        }

        /**
         * @private
         */
        public function set focusPaddingTop(value:Number):void
        {
            if(this._focusPaddingTop == value)
            {
                return;
            }
            this._focusPaddingTop = value;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * @private
         */
        protected var _focusPaddingRight:Number = 0;

        /**
         * The minimum space, in pixels, between the object's right edge and the
         * right edge of the focus indicator skin. A negative value may be used
         * to expand the focus indicator skin outside the bounds of the object.
         *
         * The following example gives the focus indicator skin -2 pixels of
         * padding on the right edge only:
         *
         * ~~~as3
         * button.focusPaddingRight = -2;
         * ~~~
         */
        public function get focusPaddingRight():Number
        {
            return this._focusPaddingRight;
        }

        /**
         * @private
         */
        public function set focusPaddingRight(value:Number):void
        {
            if(this._focusPaddingRight == value)
            {
                return;
            }
            this._focusPaddingRight = value;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * @private
         */
        protected var _focusPaddingBottom:Number = 0;

        /**
         * The minimum space, in pixels, between the object's bottom edge and the
         * bottom edge of the focus indicator skin. A negative value may be used
         * to expand the focus indicator skin outside the bounds of the object.
         *
         * The following example gives the focus indicator skin -2 pixels of
         * padding on the bottom edge only:
         *
         * ~~~as3
         * button.focusPaddingBottom = -2;
         * ~~~
         */
        public function get focusPaddingBottom():Number
        {
            return this._focusPaddingBottom;
        }

        /**
         * @private
         */
        public function set focusPaddingBottom(value:Number):void
        {
            if(this._focusPaddingBottom == value)
            {
                return;
            }
            this._focusPaddingBottom = value;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * @private
         */
        protected var _focusPaddingLeft:Number = 0;

        /**
         * The minimum space, in pixels, between the object's left edge and the
         * left edge of the focus indicator skin. A negative value may be used
         * to expand the focus indicator skin outside the bounds of the object.
         *
         * The following example gives the focus indicator skin -2 pixels of
         * padding on the right edge only:
         *
         * ~~~as3
         * button.focusPaddingLeft = -2;
         * ~~~
         */
        public function get focusPaddingLeft():Number
        {
            return this._focusPaddingLeft;
        }

        /**
         * @private
         */
        public function set focusPaddingLeft(value:Number):void
        {
            if(this._focusPaddingLeft == value)
            {
                return;
            }
            this._focusPaddingLeft = value;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * @private
         */
        protected var _hasFocus:Boolean = false;

        /**
         * @private
         */
        protected var _showFocus:Boolean = false;

        /**
         * @private
         * Flag to indicate that the control is currently validating.
         */
        protected var _isValidating:Boolean = false;

        /**
         * @private
         */
        protected var _invalidateCount:int = 0;

        /**
         * @private
         */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if(!resultRect)
            {
                resultRect = new Rectangle();
            }

            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;

            if (targetSpace == this) // optimization
            {
                minX = 0;
                minY = 0;
                maxX = this.actualWidth;
                maxY = this.actualHeight;
            }
            else
            {
                this.getTargetTransformationMatrix(targetSpace, HELPER_MATRIX);

                HELPER_POINT = HELPER_MATRIX.transformCoord(0, 0);
                minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
                maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
                minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
                maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;

                HELPER_POINT = HELPER_MATRIX.transformCoord(0, this.actualHeight);
                minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
                maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
                minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
                maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;

                HELPER_POINT = HELPER_MATRIX.transformCoord(this.actualWidth, 0);
                minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
                maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
                minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
                maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;

                HELPER_POINT = HELPER_MATRIX.transformCoord(this.actualWidth, this.actualHeight);
                minX = minX < HELPER_POINT.x ? minX : HELPER_POINT.x;
                maxX = maxX > HELPER_POINT.x ? maxX : HELPER_POINT.x;
                minY = minY < HELPER_POINT.y ? minY : HELPER_POINT.y;
                maxY = maxY > HELPER_POINT.y ? maxY : HELPER_POINT.y;
            }

            resultRect.x = minX;
            resultRect.y = minY;
            resultRect.width  = maxX - minX;
            resultRect.height = maxY - minY;

            return resultRect;
        }

        /**
         * @private
         */
        override public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if(this._isQuickHitAreaEnabled)
            {
                if(forTouch && (!this.visible || !this.touchable))
                {
                    return null;
                }
                const clipRect:Rectangle = this.clipRect;
                if(clipRect && !clipRect.containsPoint(localPoint))
                {
                    return null;
                }
                return this._hitArea.containsPoint(localPoint) ? this : null;
            }
            return super.hitTest(localPoint, forTouch);
        }

        /**
         * Call this function to tell the UI control that a redraw is pending.
         * The redraw will happen immediately before Starling renders the UI
         * control to the screen. The validation system exists to ensure that
         * multiple properties can be set together without redrawing multiple
         * times in between each property change.
         * 
         * If you cannot wait until later for the validation to happen, you
         * can call `validate()` to redraw immediately. As an example,
         * you might want to validate immediately if you need to access the
         * correct `width` or `height` values of the UI
         * control, since these values are calculated during validation.
         * 
         * @see feathers.core.FeathersControl#validate()
         */
        public function invalidate(flag:String = INVALIDATION_FLAG_ALL):void
        {
            const isAlreadyInvalid:Boolean = this.isInvalid();
            var isAlreadyDelayedInvalid:Boolean = false;
            if(this._isValidating)
            {
                for(var otherFlag:String in this._delayedInvalidationFlags)
                {
                    isAlreadyDelayedInvalid = true;
                    break;
                }
            }
            if(!flag || flag == INVALIDATION_FLAG_ALL)
            {
                if(this._isValidating)
                {
                    this._delayedInvalidationFlags[INVALIDATION_FLAG_ALL] = true;
                }
                else
                {
                    this._isAllInvalid = true;
                }
            }
            else
            {
                if(this._isValidating)
                {
                    this._delayedInvalidationFlags[flag] = true;
                }
                else if(flag != INVALIDATION_FLAG_ALL)
                {
                    this._invalidationFlags[flag] = true;
                }
            }
            if(!this.stage || !this._isInitialized)
            {
                //we'll add this component to the queue later, after it has been
                //added to the stage.
                return;
            }
            if(this._isValidating)
            {
                if(isAlreadyDelayedInvalid)
                {
                    return;
                }
                this._invalidateCount++;
                VALIDATION_QUEUE.addControl(this, this._invalidateCount >= 10);
                return;
            }
            if(isAlreadyInvalid)
            {
                return;
            }
            this._invalidateCount = 0;
            VALIDATION_QUEUE.addControl(this, false);
        }

        /**
         * Immediately validates the control, which triggers a redraw, if one
         * is pending. Validation exists to postpone redrawing a component until
         * the last possible moment before rendering so that multiple properties
         * can be changed at once without requiring a full redraw after each
         * change.
         * 
         * A component cannot validate if it does not have access to the
         * stage and if it hasn't initialized yet. A component initializes the
         * first time that it has been added to the stage.
         * 
         * @see #invalidate()
         * @see #initialize()
         * @see feathers.events.FeathersEventType#!INITIALIZE
         */
        public function validate():void
        {
            if(!this.stage || !this._isInitialized || !this.isInvalid())
            {
                return;
            }

            if(this._isValidating)
            {
                //we were already validating, and something else told us to
                //validate. that's bad.
                VALIDATION_QUEUE.addControl(this, true);
                return;
            }

            this._isValidating = true;
            this.draw();
            
            for(var flag:String in this._invalidationFlags)
            {
                //delete this._invalidationFlags[flag];
                this._invalidationFlags[flag] = null;
            }
            
            this._isAllInvalid = false;
            
            for(flag in this._delayedInvalidationFlags)
            {
                if(flag == INVALIDATION_FLAG_ALL)
                {
                    this._isAllInvalid = true;
                }
                else
                {
                    this._invalidationFlags[flag] = true;
                }
                
                //delete this._delayedInvalidationFlags[flag];
                this._delayedInvalidationFlags[flag] = null;
            }

            this._isValidating = false;
        }

        /**
         * Indicates whether the control is pending validation or not. By
         * default, returns `true` if any invalidation flag has been
         * set. If you pass in a specific flag, returns `true` only
         * if that flag has been set (others may be set too, but it checks the
         * specific flag only. If all flags have been marked as invalid, always
         * returns `true`.
         */
        public function isInvalid(flag:String = null):Boolean
        {
            if(this._isAllInvalid)
            {
                return true;
            }
            if(!flag) //return true if any flag is set
            {
                for(flag in this._invalidationFlags)
                {
                    return true;
                }
                return false;
            }
            return this._invalidationFlags[flag] != null;
        }

        /**
         * Sets both the width and the height of the control.
         */
        public function setSize(width:Number, height:Number):void
        {
            this.explicitWidth = width;
            var widthIsNaN:Boolean = isNaN(width);
            if(widthIsNaN)
            {
                this.actualWidth = 0;
            }
            this.explicitHeight = height;
            var heightIsNaN:Boolean = isNaN(height);
            if(heightIsNaN)
            {
                this.actualHeight = 0;
            }

            if(widthIsNaN || heightIsNaN)
            {
                this.invalidate(INVALIDATION_FLAG_SIZE);
            }
            else
            {
                this.setSizeInternal(width, height, true);
            }
        }

        /**
         * @copy feathers.core.IFocusDisplayObject#showFocus()
         */
        public function showFocus():void
        {
            if(!this._hasFocus || !this._focusIndicatorSkin)
            {
                return;
            }

            this._showFocus = true;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * @copy feathers.core.IFocusDisplayObject#hideFocus()
         */
        public function hideFocus():void
        {
            if(!this._hasFocus || !this._focusIndicatorSkin)
            {
                return;
            }

            this._showFocus = false;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * Sets the width and height of the control, with the option of
         * invalidating or not. Intended to be used when the `width`
         * and `height` values have not been set explicitly, and the
         * UI control needs to measure itself and choose an "ideal" size.
         */
        protected function setSizeInternal(width:Number, height:Number, canInvalidate:Boolean):Boolean
        {
            if(!isNaN(this.explicitWidth))
            {
                width = this.explicitWidth;
            }
            else
            {
                width = Math.min(this._maxWidth, Math.max(this._minWidth, width));
            }
            if(!isNaN(this.explicitHeight))
            {
                height = this.explicitHeight;
            }
            else
            {
                height = Math.min(this._maxHeight, Math.max(this._minHeight, height));
            }
            if(isNaN(width))
            {
                Debug.assert(ILLEGAL_WIDTH_ERROR);
            }
            if(isNaN(height))
            {
                Debug.assert(ILLEGAL_HEIGHT_ERROR);
            }
            var resized:Boolean = false;
            if(this.actualWidth != width)
            {
                this.actualWidth = width;
                this._hitArea.width = Math.max(width, this._minTouchWidth);
                this._hitArea.x = (this.actualWidth - this._hitArea.width) / 2;
                if(this._hitArea.x != this._hitArea.x)
                {
                    this._hitArea.x = 0;
                }
                resized = true;
            }
            if(this.actualHeight != height)
            {
                this.actualHeight = height;
                this._hitArea.height = Math.max(height, this._minTouchHeight);
                this._hitArea.y = (this.actualHeight - this._hitArea.height) / 2;
                if(this._hitArea.y != this._hitArea.y)
                {
                    this._hitArea.y = 0;
                }
                resized = true;
            }
            if(resized)
            {
                if(canInvalidate)
                {
                    this.invalidate(INVALIDATION_FLAG_SIZE);
                }
                this.dispatchEventWith(FeathersEventType.RESIZE);
            }
            return resized;
        }

        /**
         * Called the first time that the UI control is added to the stage, and
         * you should override this function to customize the initialization
         * process. Do things like create children and set up event listeners.
         * After this function is called, `FeathersEventType.INITIALIZE`
         * is dispatched.
         *
         * @see feathers.events.FeathersEventType#!INITIALIZE
         */
        protected function initialize():void
        {

        }

        /**
         * Override to customize layout and to adjust properties of children.
         * Called when the component validates, if any flags have been marked
         * to indicate that validation is pending.
         */
        protected function draw():void
        {

        }

        /**
         * Updates the focus indicator skin by showing or hiding it and
         * adjusting its position and dimensions. This function is not called
         * automatically. Components that support focus should call this
         * function at an appropriate point within the `draw()`
         * function. This function may be overridden if the default behavior is
         * not desired.
         */
        protected function refreshFocusIndicator():void
        {
            if(this._focusIndicatorSkin)
            {
                if(this._hasFocus && this._showFocus)
                {
                    if(this._focusIndicatorSkin.parent != this)
                    {
                        this.addChild(this._focusIndicatorSkin);
                    }
                    else
                    {
                        this.setChildIndex(this._focusIndicatorSkin, this.numChildren - 1);
                    }
                }
                else if(this._focusIndicatorSkin.parent)
                {
                    this._focusIndicatorSkin.removeFromParent(false);
                }
                this._focusIndicatorSkin.x = this._focusPaddingLeft;
                this._focusIndicatorSkin.y = this._focusPaddingTop;
                this._focusIndicatorSkin.width = this.actualWidth - this._focusPaddingLeft - this._focusPaddingRight;
                this._focusIndicatorSkin.height = this.actualHeight - this._focusPaddingTop - this._focusPaddingBottom;
            }
        }

        /**
         * Default event handler for `FeathersEventType.FOCUS_IN`
         * that may be overridden in subclasses to perform additional actions
         * when the component receives focus.
         */
        protected function focusInHandler(event:Event):void
        {
            this._hasFocus = true;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * Default event handler for `FeathersEventType.FOCUS_OUT`
         * that may be overridden in subclasses to perform additional actions
         * when the component loses focus.
         */
        protected function focusOutHandler(event:Event):void
        {
            this._hasFocus = false;
            this.invalidate(INVALIDATION_FLAG_FOCUS);
        }

        /**
         * @private
         */
        protected function feathersControl_flattenHandler(event:Event):void
        {
            if(!this.stage || !this._isInitialized)
            {
                Debug.assert("Cannot flatten this component until it is initialized and has access to the stage.");
            }
            this.validate();
        }

        /**
         * @private
         * Initialize the control, if it hasn't been initialized yet. Then,
         * invalidate.
         */
        protected function initialize_addedToStageHandler(event:Event):void
        {
            if(event.target != this)
            {
                return;
            }
            if(!this._isInitialized)
            {
                this.initialize();
                this.invalidate(); //invalidate everything
                this._isInitialized = true;
                this.dispatchEventWith(FeathersEventType.INITIALIZE, false);
            }

            if(this.isInvalid())
            {
                this._invalidateCount = 0;
                VALIDATION_QUEUE.addControl(this, false);
            }
        }

        /**
         * @private
         */
        protected function layoutData_changeHandler(event:Event):void
        {
            this.dispatchEventWith(FeathersEventType.LAYOUT_DATA_CHANGE);
        }
    }
}