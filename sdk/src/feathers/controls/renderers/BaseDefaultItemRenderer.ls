/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.renderers
{
    import feathers.controls.Button;
    import feathers.controls.ImageLoader;
    import feathers.text.DummyTextRenderer;
    import feathers.core.FeathersControl;
    import feathers.core.IFeathersControl;
    import feathers.core.ITextRenderer;
    import feathers.events.FeathersEventType;

    import loom2d.math.Point;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.TouchEvent;

    import loom.platform.Timer;

    /**
     * An abstract class for item renderer implementations.
     */
    public class BaseDefaultItemRenderer extends Button
    {
        /**
         * The default value added to the `nameList` of the accessory
         * label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_ACCESSORY_LABEL:String = "feathers-item-renderer-accessory-label";

        /**
         * The accessory will be positioned above its origin.
         *
         * @see #accessoryPosition
         */
        public static const ACCESSORY_POSITION_TOP:String = "top";

        /**
         * The accessory will be positioned to the right of its origin.
         *
         * @see #accessoryPosition
         */
        public static const ACCESSORY_POSITION_RIGHT:String = "right";

        /**
         * The accessory will be positioned below its origin.
         *
         * @see #accessoryPosition
         */
        public static const ACCESSORY_POSITION_BOTTOM:String = "bottom";

        /**
         * The accessory will be positioned to the left of its origin.
         *
         * @see #accessoryPosition
         */
        public static const ACCESSORY_POSITION_LEFT:String = "left";

        /**
         * The accessory will be positioned manually with no relation to another
         * child. Use `accessoryOffsetX` and `accessoryOffsetY`
         * to set the accessory position.
         *
         * The `accessoryPositionOrigin` property will be ignored
         * if `accessoryPosition` is set to `ACCESSORY_POSITION_MANUAL`.
         *
         * @see #accessoryPosition
         * @see #accessoryOffsetX
         * @see #accessoryOffsetY
         */
        public static const ACCESSORY_POSITION_MANUAL:String = "manual";

        /**
         * The layout order will be the label first, then the accessory relative
         * to the label, then the icon relative to both. Best used when the
         * accessory should be between the label and the icon or when the icon
         * position shouldn't be affected by the accessory.
         *
         * @see #layoutOrder
         */
        public static const LAYOUT_ORDER_LABEL_ACCESSORY_ICON:String = "labelAccessoryIcon";

        /**
         * The layout order will be the label first, then the icon relative to
         * label, then the accessory relative to both.
         *
         * @see #layoutOrder
         */
        public static const LAYOUT_ORDER_LABEL_ICON_ACCESSORY:String = "labelIconAccessory";

        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        protected static var DOWN_STATE_DELAY_MS:int = 250;

        /**
         * @private
         */
        protected static function defaultLoaderFactory():ImageLoader
        {
            return new ImageLoader();
        }

        /**
         * Constructor.
         */
        public function BaseDefaultItemRenderer()
        {
            super();
            this.isQuickHitAreaEnabled = false;
            this.addEventListener(Event.TRIGGERED, itemRenderer_triggeredHandler);
        }

        /**
         * The value added to the `nameList` of the accessory label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var accessoryLabelName:String = DEFAULT_CHILD_NAME_ACCESSORY_LABEL;

        /**
         * @private
         */
        protected var iconImage:ImageLoader;

        /**
         * @private
         */
        protected var accessoryImage:ImageLoader;

        /**
         * @private
         */
        protected var accessoryLabel:ITextRenderer;

        /**
         * @private
         */
        protected var accessory:DisplayObject;

        /**
         * @private
         */
        protected var _data:Object;

        /**
         * The item displayed by this renderer.
         */
        public function get data():Object
        {
            return this._data;
        }

        /**
         * @private
         */
        public function set data(value:Object):void
        {
            if(this._data == value)
            {
                return;
            }
            this._data = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _owner:IFeathersControl;

        /**
         * @private
         */
        protected var _delayedCurrentState:String;

        /**
         * @private
         */
        protected var _stateDelayTimer:Timer;

        /**
         * @private
         */
        protected var _useStateDelayTimer:Boolean = true;

        /**
         * If true, the down state (and subsequent state changes) will be
         * delayed to make scrolling look nicer.
         */
        public function get useStateDelayTimer():Boolean
        {
            return this._useStateDelayTimer;
        }

        /**
         * @private
         */
        public function set useStateDelayTimer(value:Boolean):void
        {
            this._useStateDelayTimer = value;
        }

        /**
         * Determines if the item renderer can be selected even if
         * `isToggle` is set to `false`. Subclasses are
         * expected to change this value, if required.
         */
        protected var isSelectableWithoutToggle:Boolean = true;

        /**
         * @private
         */
        protected var _itemHasLabel:Boolean = true;

        /**
         * If true, the label will come from the renderer's item using the
         * appropriate field or function for the label. If false, the label may
         * be set externally.
         */
        public function get itemHasLabel():Boolean
        {
            return this._itemHasLabel;
        }

        /**
         * @private
         */
        public function set itemHasLabel(value:Boolean):void
        {
            if(this._itemHasLabel == value)
            {
                return;
            }
            this._itemHasLabel = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _itemHasIcon:Boolean = true;

        /**
         * If true, the icon will come from the renderer's item using the
         * appropriate field or function for the icon. If false, the icon may
         * be skinned for each state externally.
         */
        public function get itemHasIcon():Boolean
        {
            return this._itemHasIcon;
        }

        /**
         * @private
         */
        public function set itemHasIcon(value:Boolean):void
        {
            if(this._itemHasIcon == value)
            {
                return;
            }
            this._itemHasIcon = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _itemHasAccessory:Boolean = true;

        /**
         * If true, the accessory will come from the renderer's item using the
         * appropriate field or function for the accessory. If false, the
         * accessory may be set using other means.
         */
        public function get itemHasAccessory():Boolean
        {
            return this._itemHasAccessory;
        }

        /**
         * @private
         */
        public function set itemHasAccessory(value:Boolean):void
        {
            if(this._itemHasAccessory == value)
            {
                return;
            }
            this._itemHasAccessory = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessoryPosition:String = ACCESSORY_POSITION_RIGHT;

        [Inspectable(type="String",enumeration="top,right,bottom,left,manual")]
        /**
         * The location of the accessory, relative to one of the other children.
         * Use `ACCESSORY_POSITION_MANUAL` to position the accessory
         * from the top-left corner.
         *
         * @see #layoutOrder
         */
        public function get accessoryPosition():String
        {
            return this._accessoryPosition;
        }

        /**
         * @private
         */
        public function set accessoryPosition(value:String):void
        {
            if(this._accessoryPosition == value)
            {
                return;
            }
            this._accessoryPosition = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _layoutOrder:String = LAYOUT_ORDER_LABEL_ICON_ACCESSORY;

        [Inspectable(type="String",enumeration="labelIconAccessory,labelAccessoryIcon")]
        /**
         * The accessory's position will be based on which other child (the
         * label or the icon) the accessory should be relative to.
         *
         * The `accessoryPositionOrigin` property will be ignored
         * if `accessoryPosition` is set to `ACCESSORY_POSITION_MANUAL`.
         *
         * @see #accessoryPosition
         * @see #iconPosition
         * @see LAYOUT_ORDER_LABEL_ICON_ACCESSORY
         * @see LAYOUT_ORDER_LABEL_ACCESSORY_ICON
         */
        public function get layoutOrder():String
        {
            return this._layoutOrder;
        }

        /**
         * @private
         */
        public function set layoutOrder(value:String):void
        {
            if(this._layoutOrder == value)
            {
                return;
            }
            this._layoutOrder = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _accessoryOffsetX:Number = 0;

        /**
         * Offsets the x position of the accessory by a certain number of pixels.
         */
        public function get accessoryOffsetX():Number
        {
            return this._accessoryOffsetX;
        }

        /**
         * @private
         */
        public function set accessoryOffsetX(value:Number):void
        {
            if(this._accessoryOffsetX == value)
            {
                return;
            }
            this._accessoryOffsetX = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _accessoryOffsetY:Number = 0;

        /**
         * Offsets the y position of the accessory by a certain number of pixels.
         */
        public function get accessoryOffsetY():Number
        {
            return this._accessoryOffsetY;
        }

        /**
         * @private
         */
        public function set accessoryOffsetY(value:Number):void
        {
            if(this._accessoryOffsetY == value)
            {
                return;
            }
            this._accessoryOffsetY = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _accessoryGap:Number = NaN;

        /**
         * The space, in pixels, between the accessory and the other child it is
         * positioned relative to. Applies to either horizontal or vertical
         * spacing, depending on the value of `accessoryPosition`. If
         * the value is `NaN`, the value of the `gap`
         * property will be used instead.
         *
         * If `accessoryGap` is set to `Number.POSITIVE_INFINITY`,
         * the accessory and the component it is relative to will be positioned
         * as far apart as possible.
         *
         * @see #gap
         * @see #accessoryPosition
         */
        public function get accessoryGap():Number
        {
            return this._accessoryGap;
        }

        /**
         * @private
         */
        public function set accessoryGap(value:Number):void
        {
            if(this._accessoryGap == value)
            {
                return;
            }
            this._accessoryGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        override protected function set currentState(value:String):void
        {
            if(!this._isToggle && !this.isSelectableWithoutToggle)
            {
                value = STATE_UP;
            }
            if(this._useStateDelayTimer)
            {
                if(this._stateDelayTimer && this._stateDelayTimer.running)
                {
                    this._delayedCurrentState = value;
                    return;
                }

                if(value == Button.STATE_DOWN)
                {
                    if(this._currentState == value)
                    {
                        return;
                    }
                    this._delayedCurrentState = value;
                    if(this._stateDelayTimer)
                    {
                        this._stateDelayTimer.reset();
                    }
                    else
                    {
                        this._stateDelayTimer = new Timer(DOWN_STATE_DELAY_MS);
                        this._stateDelayTimer.onComplete += stateDelayTimer_timerCompleteHandler;
                    }
                    this._stateDelayTimer.start();
                    return;
                }
            }
            super.currentState = value;
        }

        /**
         * If enabled, calls event.stopPropagation() when TouchEvents are
         * dispatched by the accessory.
         */
        public var stopAccessoryTouchEventPropagation:Boolean = true;

        /**
         * @private
         */
        protected var _labelField:String = "label";

        /**
         * The field in the item that contains the label text to be displayed by
         * the renderer. If the item does not have this field, and a
         * `labelFunction` is not defined, then the renderer will
         * default to calling `toString()` on the item. To omit the
         * label completely, either provide a custom item renderer without a
         * label or define a `labelFunction` that returns an empty
         * string.
         *
         * All of the label fields and functions, ordered by priority:
         * 
         *     1. `labelFunction`
         *     2. `labelField`

         *
         * @see #labelFunction
         */
        public function get labelField():String
        {
            return this._labelField;
        }

        /**
         * @private
         */
        public function set labelField(value:String):void
        {
            if(this._labelField == value)
            {
                return;
            }
            this._labelField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _labelFunction:Function;

        /**
         * A function used to generate label text for a specific item. If this
         * function is not null, then the `labelField` will be
         * ignored.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):String`
         *
         * All of the label fields and functions, ordered by priority:
         * 
         *     1. `labelFunction`
         *     2. `labelField`

         *
         * @see #labelField
         */
        public function get labelFunction():Function
        {
            return this._labelFunction;
        }

        /**
         * @private
         */
        public function set labelFunction(value:Function):void
        {
            if(this._labelFunction == value)
            {
                return;
            }
            this._labelFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _iconField:String = "icon";

        /**
         * The field in the item that contains a display object to be displayed
         * as an icon or other graphic next to the label in the renderer.
         *
         * All of the icon fields and functions, ordered by priority:
         * 
         *     1. `iconSourceFunction`
         *     2. `iconSourceField`
         *     3. `iconFunction`
         *     4. `iconField`

         *
         * @see #iconFunction
         * @see #iconSourceField
         * @see #iconSourceFunction
         */
        public function get iconField():String
        {
            return this._iconField;
        }

        /**
         * @private
         */
        public function set iconField(value:String):void
        {
            if(this._iconField == value)
            {
                return;
            }
            this._iconField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _iconFunction:Function;

        /**
         * A function used to generate an icon for a specific item.
         *
         * Note: As the list scrolls, this function will almost always be
         * called more than once for each individual item in the list's data
         * provider. Your function should not simply return a new icon every
         * time. This will result in the unnecessary creation and destruction of
         * many icons, which will overwork the garbage collector and hurt
         * performance. It's better to return a new icon the first time this
         * function is called for a particular item and then return the same
         * icon if that item is passed to this function again.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):DisplayObject`
         *
         * All of the icon fields and functions, ordered by priority:
         * 
         *     1. `iconSourceFunction`
         *     2. `iconSourceField`
         *     3. `iconFunction`
         *     4. `iconField`

         *
         * @see #iconField
         * @see #iconSourceField
         * @see #iconSourceFunction
         */
        public function get iconFunction():Function
        {
            return this._iconFunction;
        }

        /**
         * @private
         */
        public function set iconFunction(value:Function):void
        {
            if(this._iconFunction == value)
            {
                return;
            }
            this._iconFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _iconSourceField:String = "iconSource";

        /**
         * The field in the item that contains a `loom2d.textures.Texture`
         * or a URL that points to a bitmap to be used as the item renderer's
         * icon. The renderer will automatically manage and reuse an internal
         * `ImageLoader` sub-component and this value will be passed
         * to the `source` property. The `ImageLoader` may
         * be customized by changing the `iconLoaderFactory`.
         *
         * Using an icon source will result in better performance than
         * passing in an `ImageLoader` or `Image` through
         * a `iconField` or `iconFunction`
         * because the renderer can avoid costly display list manipulation.
         *
         * All of the icon fields and functions, ordered by priority:
         * 
         *     1. `iconSourceFunction`
         *     2. `iconSourceField`
         *     3. `iconFunction`
         *     4. `iconField`

         *
         * @see feathers.controls.ImageLoader#source
         * @see #iconLoaderFactory
         * @see #iconSourceFunction
         * @see #iconField
         * @see #iconFunction
         */
        public function get iconSourceField():String
        {
            return this._iconSourceField;
        }

        /**
         * @private
         */
        public function set iconSourceField(value:String):void
        {
            if(this._iconSourceField == value)
            {
                return;
            }
            this._iconSourceField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _iconSourceFunction:Function;

        /**
         * A function used to generate a `loom2d.textures.Texture`
         * or a URL that points to a bitmap to be used as the item renderer's
         * icon. The renderer will automatically manage and reuse an internal
         * `ImageLoader` sub-component and this value will be passed
         * to the `source` property. The `ImageLoader` may
         * be customized by changing the `iconLoaderFactory`.
         *
         * Using an icon source will result in better performance than
         * passing in an `ImageLoader` or `Image` through
         * a `iconField` or `iconFunction`
         * because the renderer can avoid costly display list manipulation.
         *
         * Note: As the list scrolls, this function will almost always be
         * called more than once for each individual item in the list's data
         * provider. Your function should not simply return a new texture every
         * time. This will result in the unnecessary creation and destruction of
         * many textures, which will overwork the garbage collector and hurt
         * performance. Creating a new texture at all is dangerous, unless you
         * are absolutely sure to dispose it when necessary because neither the
         * list nor its item renderer will dispose of the texture for you. If
         * you are absolutely sure that you are managing the texture memory with
         * proper disposal, it's better to return a new texture the first
         * time this function is called for a particular item and then return
         * the same texture if that item is passed to this function again.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):Object`
         *
         * The return value is a valid value for the `source`
         * property of an `ImageLoader` component.
         *
         * All of the icon fields and functions, ordered by priority:
         * 
         *     1. `iconSourceFunction`
         *     2. `iconSourceField`
         *     3. `iconFunction`
         *     4. `iconField`

         *
         * @see feathers.controls.ImageLoader#source
         * @see #iconLoaderFactory
         * @see #iconSourceField
         * @see #iconField
         * @see #iconFunction
         */
        public function get iconSourceFunction():Function
        {
            return this._iconSourceFunction;
        }

        /**
         * @private
         */
        public function set iconSourceFunction(value:Function):void
        {
            if(this._iconSourceFunction == value)
            {
                return;
            }
            this._iconSourceFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessoryField:String = "accessory";

        /**
         * The field in the item that contains a display object to be positioned
         * in the accessory position of the renderer. If you wish to display an
         * `Image` in the accessory position, it's better for
         * performance to use `accessorySourceField` instead.
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         *
         * @see #accessorySourceField
         * @see #accessoryFunction
         * @see #accessorySourceFunction
         * @see #accessoryLabelField
         * @see #accessoryLabelFunction
         */
        public function get accessoryField():String
        {
            return this._accessoryField;
        }

        /**
         * @private
         */
        public function set accessoryField(value:String):void
        {
            if(this._accessoryField == value)
            {
                return;
            }
            this._accessoryField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessoryFunction:Function;

        /**
         * A function that returns a display object to be positioned in the
         * accessory position of the renderer. If you wish to display an
         * `Image` in the accessory position, it's better for
         * performance to use `accessorySourceFunction` instead.
         *
         * Note: As the list scrolls, this function will almost always be
         * called more than once for each individual item in the list's data
         * provider. Your function should not simply return a new accessory
         * every time. This will result in the unnecessary creation and
         * destruction of many icons, which will overwork the garbage collector
         * and hurt performance. It's better to return a new accessory the first
         * time this function is called for a particular item and then return
         * the same accessory if that item is passed to this function again.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):DisplayObject`
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         *
         * @see #accessoryField
         * @see #accessorySourceField
         * @see #accessorySourceFunction
         * @see #accessoryLabelField
         * @see #accessoryLabelFunction
         */
        public function get accessoryFunction():Function
        {
            return this._accessoryFunction;
        }

        /**
         * @private
         */
        public function set accessoryFunction(value:Function):void
        {
            if(this._accessoryFunction == value)
            {
                return;
            }
            this._accessoryFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessorySourceField:String = "accessorySource";

        /**
         * A field in the item that contains a `loom2d.textures.Texture`
         * or a URL that points to a bitmap to be used as the item renderer's
         * accessory. The renderer will automatically manage and reuse an internal
         * `ImageLoader` sub-component and this value will be passed
         * to the `source` property. The `ImageLoader` may
         * be customized by changing the `accessoryLoaderFactory`.
         *
         * Using an accessory source will result in better performance than
         * passing in an `ImageLoader` or `Image` through
         * a `accessoryField` or `accessoryFunction` because
         * the renderer can avoid costly display list manipulation.
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         *
         * @see feathers.controls.ImageLoader#source
         * @see #accessoryLoaderFactory
         * @see #accessorySourceFunction
         * @see #accessoryField
         * @see #accessoryFunction
         * @see #accessoryLabelField
         * @see #accessoryLabelFunction
         */
        public function get accessorySourceField():String
        {
            return this._accessorySourceField;
        }

        /**
         * @private
         */
        public function set accessorySourceField(value:String):void
        {
            if(this._accessorySourceField == value)
            {
                return;
            }
            this._accessorySourceField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessorySourceFunction:Function;

        /**
         * A function that generates a `loom2d.textures.Texture`
         * or a URL that points to a bitmap to be used as the item renderer's
         * accessory. The renderer will automatically manage and reuse an internal
         * `ImageLoader` sub-component and this value will be passed
         * to the `source` property. The `ImageLoader` may
         * be customized by changing the `accessoryLoaderFactory`.
         *
         * Using an accessory source will result in better performance than
         * passing in an `ImageLoader` or `Image` through
         * a `accessoryField` or `accessoryFunction`
         * because the renderer can avoid costly display list manipulation.
         *
         * Note: As the list scrolls, this function will almost always be
         * called more than once for each individual item in the list's data
         * provider. Your function should not simply return a new texture every
         * time. This will result in the unnecessary creation and destruction of
         * many textures, which will overwork the garbage collector and hurt
         * performance. Creating a new texture at all is dangerous, unless you
         * are absolutely sure to dispose it when necessary because neither the
         * list nor its item renderer will dispose of the texture for you. If
         * you are absolutely sure that you are managing the texture memory with
         * proper disposal, it's better to return a new texture the first
         * time this function is called for a particular item and then return
         * the same texture if that item is passed to this function again.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):Object`
         *
         * The return value is a valid value for the `source`
         * property of an `ImageLoader` component.
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         *
         * @see feathers.controls.ImageLoader#source
         * @see #accessoryLoaderFactory
         * @see #accessorySourceField
         * @see #accessoryField
         * @see #accessoryFunction
         * @see #accessoryLabelField
         * @see #accessoryLabelFunction
         */
        public function get accessorySourceFunction():Function
        {
            return this._accessorySourceFunction;
        }

        /**
         * @private
         */
        public function set accessorySourceFunction(value:Function):void
        {
            if(this._accessorySourceFunction == value)
            {
                return;
            }
            this._accessorySourceFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessoryLabelField:String = "accessoryLabel";

        /**
         * The field in the item that contains a string to be displayed in a
         * renderer-managed `Label` in the accessory position of the
         * renderer. The renderer will automatically reuse an internal
         * `Label` and swap the text when the data changes. This
         * `Label` may be skinned by changing the
         * `accessoryLabelFactory`.
         *
         * Using an accessory label will result in better performance than
         * passing in a `Label` through a `accessoryField`
         * or `accessoryFunction` because the renderer can avoid
         * costly display list manipulation.
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         *
         * @see #accessoryLabelFactory
         * @see #accessoryLabelFunction
         * @see #accessoryField
         * @see #accessoryFunction
         * @see #accessorySourceField
         * @see #accessorySourceFunction
         */
        public function get accessoryLabelField():String
        {
            return this._accessoryLabelField;
        }

        /**
         * @private
         */
        public function set accessoryLabelField(value:String):void
        {
            if(this._accessoryLabelField == value)
            {
                return;
            }
            this._accessoryLabelField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _accessoryLabelFunction:Function;

        /**
         * A function that returns a string to be displayed in a
         * renderer-managed `Label` in the accessory position of the
         * renderer. The renderer will automatically reuse an internal
         * `Label` and swap the text when the data changes. This
         * `Label` may be skinned by changing the
         * `accessoryLabelFactory`.
         *
         * Using an accessory label will result in better performance than
         * passing in a `Label` through a `accessoryField`
         * or `accessoryFunction` because the renderer can avoid
         * costly display list manipulation.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):String`
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         *
         * @see #accessoryLabelFactory
         * @see #accessoryLabelField
         * @see #accessoryField
         * @see #accessoryFunction
         * @see #accessorySourceField
         * @see #accessorySourceFunction
         */
        public function get accessoryLabelFunction():Function
        {
            return this._accessoryLabelFunction;
        }

        /**
         * @private
         */
        public function set accessoryLabelFunction(value:Function):void
        {
            if(this._accessoryLabelFunction == value)
            {
                return;
            }
            this._accessoryLabelFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _iconLoaderFactory:Function = defaultLoaderFactory;

        /**
         * A function that generates an `ImageLoader` that uses the result
         * of `iconSourceField` or `iconSourceFunction`.
         * Useful for transforming the `ImageLoader` in some way. For
         * example, you might want to scale the texture for current DPI or apply
         * pixel snapping.
         *
         * The function is expected to have the following signature:
         * `function():ImageLoader`
         *
         * @see feathers.controls.ImageLoader
         * @see #iconSourceField
         * @see #iconSourceFunction
         */
        public function get iconLoaderFactory():Function
        {
            return this._iconLoaderFactory;
        }

        /**
         * @private
         */
        public function set iconLoaderFactory(value:Function):void
        {
            if(this._iconLoaderFactory == value)
            {
                return;
            }
            this._iconLoaderFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _accessoryLoaderFactory:Function = defaultLoaderFactory;

        /**
         * A function that generates an `ImageLoader` that uses the result
         * of `accessorySourceField` or `accessorySourceFunction`.
         * Useful for transforming the `ImageLoader` in some way. For
         * example, you might want to scale the texture for current DPI or apply
         * pixel snapping.
         *
         * The function is expected to have the following signature:
         * `function():ImageLoader`
         *
         * @see feathers.controls.ImageLoader
         * @see #accessorySourceField;
         * @see #accessorySourceFunction;
         */
        public function get accessoryLoaderFactory():Function
        {
            return this._accessoryLoaderFactory;
        }

        /**
         * @private
         */
        public function set accessoryLoaderFactory(value:Function):void
        {
            if(this._accessoryLoaderFactory == value)
            {
                return;
            }
            this._accessoryLoaderFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _accessoryLabelFactory:Function;

        /**
         * A function that generates `ITextRenderer` that uses the result
         * of `accessoryLabelField` or `accessoryLabelFunction`.
         * Can be used to set properties on the `ITextRenderer`.
         *
         * The function is expected to have the following signature:
         * `function():ITextRenderer`
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.core.FeathersControl#defaultTextRendererFactory
         * @see #accessoryLabelField
         * @see #accessoryLabelFunction
         */
        public function get accessoryLabelFactory():Function
        {
            return this._accessoryLabelFactory;
        }

        /**
         * @private
         */
        public function set accessoryLabelFactory(value:Function):void
        {
            if(this._accessoryLabelFactory == value)
            {
                return;
            }
            this._accessoryLabelFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _accessoryLabelProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to a label accessory. The
         * title is an `ITextRenderer` instance. The available
         * properties depend on which `ITextRenderer` implementation
         * is used.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * Setting properties in a `accessoryLabelFactory`
         * function instead of using `accessoryLabelProperties` will
         * result in better performance.
         *
         * @see feathers.core.ITextRenderer
         * @see #accessoryLabelFactory
         * @see #accessoryLabelField
         * @see #accessoryLabelFunction
         */
        public function get accessoryLabelProperties():Dictionary.<String, Object>
        {
            if(!this._accessoryLabelProperties)
            {
                this._accessoryLabelProperties = new Dictionary.<String, Object>;
            }
            return this._accessoryLabelProperties;
        }

        /**
         * @private
         */
        public function set accessoryLabelProperties(value:Dictionary.<String, Object>):void
        {
            if(this._accessoryLabelProperties == value)
            {
                return;
            }
            this._accessoryLabelProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        override public function dispose():void
        {
            this.replaceIcon(null);
            this.replaceAccessory(null);
            if(this._stateDelayTimer)
            {
                if(this._stateDelayTimer.running)
                {
                    this._stateDelayTimer.stop();
                }
                this._stateDelayTimer.onComplete -= stateDelayTimer_timerCompleteHandler;
                this._stateDelayTimer = null;
            }
            super.dispose();
        }

        /**
         * Using `labelField` and `labelFunction`,
         * generates a label from the item.
         *
         * All of the label fields and functions, ordered by priority:
         * 
         *     1. `labelFunction`
         *     2. `labelField`

         */
        public function itemToLabel(item:Object):String
        {
            if(this._labelFunction != null)
            {
                return this._labelFunction.call(null, item).toString();
            }
            else if(this._labelField != null && item && item.hasOwnProperty(this._labelField))
            {
                var labelObj:Object = item.getType().getFieldOrPropertyValueByName(item, this._labelField);
                return labelObj.toString();
            }
            else if(item is Object)
            {
                return item.toString();
            }
            return "";
        }

        /**
         * Uses the icon fields and functions to generate an icon for a specific
         * item.
         *
         * All of the icon fields and functions, ordered by priority:
         * 
         *     1. `iconSourceFunction`
         *     2. `iconSourceField`
         *     3. `iconFunction`
         *     4. `iconField`

         */
        protected function itemToIcon(item:Object):DisplayObject
        {
            if(this._iconSourceFunction != null)
            {
                var source:Object = this._iconSourceFunction.call(null, item);
                this.refreshIconSource(source);
                return this.iconImage;
            }
            else if(this._iconSourceField != null && item && item.hasOwnProperty(this._iconSourceField))
            {
                source = item.getType().getFieldOrPropertyValueByName(item, this._iconSourceField);
                //source = item[this._iconSourceField];
                this.refreshIconSource(source);
                return this.iconImage;
            }
            else if(this._iconFunction != null)
            {
                return this._iconFunction.call(null, item) as DisplayObject;
            }
            else if(this._iconField != null && item && item.hasOwnProperty(this._iconField))
            {
                //return item[this._iconField] as DisplayObject;
                return item.getType().getFieldOrPropertyValueByName(item, this._iconField) as DisplayObject;
            }

            return null;
        }

        /**
         * Uses the accessory fields and functions to generate an accessory for
         * a specific item.
         *
         * All of the accessory fields and functions, ordered by priority:
         * 
         *     1. `accessorySourceFunction`
         *     2. `accessorySourceField`
         *     3. `accessoryLabelFunction`
         *     4. `accessoryLabelField`
         *     5. `accessoryFunction`
         *     6. `accessoryField`

         */
        protected function itemToAccessory(item:Object):DisplayObject
        {
            if(this._accessorySourceFunction != null)
            {
                var source:Object = this._accessorySourceFunction.call(null, item);
                this.refreshAccessorySource(source);
                return this.accessoryImage;
            }
            else if(this._accessorySourceField != null && item && item.hasOwnProperty(this._accessorySourceField))
            {
                //source = item[this._accessorySourceField];
                source = item.getType().getFieldOrPropertyValueByName(item, this._accessorySourceField);
                this.refreshAccessorySource(source);
                return this.accessoryImage;
            }
            else if(this._accessoryLabelFunction != null)
            {
                var label:String = this._accessoryLabelFunction.call(null, item).toString();
                this.refreshAccessoryLabel(label);
                return DisplayObject(this.accessoryLabel);
            }
            else if(this._accessoryLabelField != null && item && item.hasOwnProperty(this._accessoryLabelField))
            {
                label = item.getType().getFieldOrPropertyValueByName(item, this._accessoryLabelField).toString();
                this.refreshAccessoryLabel(label);
                return DisplayObject(this.accessoryLabel);
            }
            else if(this._accessoryFunction != null)
            {
                return this._accessoryFunction.call(null, item) as DisplayObject;
            }
            else if(this._accessoryField != null && item && item.hasOwnProperty(this._accessoryField))
            {
                //return item[this._accessoryField] as DisplayObject;
                return item.getType().getFieldOrPropertyValueByName(item, this._accessoryField) as DisplayObject;
            }

            return null;
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            if(dataInvalid)
            {
                this.commitData();
            }
            if(dataInvalid || stylesInvalid)
            {
                this.refreshAccessoryLabelStyles();
            }
            super.draw();
        }

        /**
         * @private
         */
        override protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }
            this.refreshMaxLabelWidth(true);
            HELPER_POINT = this.labelTextRenderer.measureText();
            if(this.accessory is IFeathersControl)
            {
                IFeathersControl(this.accessory).validate();
            }
            if(this.currentIcon is IFeathersControl)
            {
                IFeathersControl(this.currentIcon).validate();
            }
            var newWidth:Number = this.explicitWidth;
            if(needsWidth)
            {
                if(this._label)
                {
                    newWidth = HELPER_POINT.x;
                }
                var adjustedGap:Number = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingLeft, this._paddingRight) : this._gap;
                if(this._layoutOrder == LAYOUT_ORDER_LABEL_ACCESSORY_ICON)
                {
                    newWidth = this.addAccessoryWidth(newWidth, adjustedGap);
                    newWidth = this.addIconWidth(newWidth, adjustedGap);
                }
                else
                {
                    newWidth = this.addIconWidth(newWidth, adjustedGap);
                    newWidth = this.addAccessoryWidth(newWidth, adjustedGap);
                }
                newWidth += this._paddingLeft + this._paddingRight;
                if(isNaN(newWidth))
                {
                    newWidth = this._originalSkinWidth;
                }
                else if(!isNaN(this._originalSkinWidth))
                {
                    newWidth = Math.max(newWidth, this._originalSkinWidth);
                }
                if(isNaN(newWidth))
                {
                    newWidth = 0;
                }
            }

            var newHeight:Number = this.explicitHeight;
            if(needsHeight)
            {
                if(this._label)
                {
                    newHeight = HELPER_POINT.y;
                }
                adjustedGap = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingTop, this._paddingBottom) : this._gap;
                if(this._layoutOrder == LAYOUT_ORDER_LABEL_ACCESSORY_ICON)
                {
                    newHeight = this.addAccessoryHeight(newHeight, adjustedGap);
                    newHeight = this.addIconHeight(newHeight, adjustedGap);
                }
                else
                {
                    newHeight = this.addIconHeight(newHeight, adjustedGap);
                    newHeight = this.addAccessoryHeight(newHeight, adjustedGap);
                }
                newHeight += this._paddingTop + this._paddingBottom;
                if(isNaN(newHeight))
                {
                    newHeight = this._originalSkinHeight;
                }
                else if(!isNaN(this._originalSkinHeight))
                {
                    newHeight = Math.max(newHeight, this._originalSkinHeight);
                }
                if(isNaN(newHeight))
                {
                    newHeight = 0;
                }
            }

            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function addIconWidth(width:Number, gap:Number):Number
        {
            if(!this.currentIcon || isNaN(this.currentIcon.width))
            {
                return width;
            }
            if(this._iconPosition == ICON_POSITION_LEFT || this._iconPosition == ICON_POSITION_LEFT_BASELINE || this._iconPosition == ICON_POSITION_RIGHT || this._iconPosition == ICON_POSITION_RIGHT_BASELINE)
            {
                width += this.currentIcon.width + gap;
            }
            else
            {
                width = Math.max(width, this.currentIcon.width);
            }
            return width;
        }

        /**
         * @private
         */
        protected function addAccessoryWidth(width:Number, gap:Number):Number
        {
            if(!this.accessory || isNaN(this.accessory.width))
            {
                return width;
            }

            if(this._accessoryPosition == ACCESSORY_POSITION_LEFT || this._accessoryPosition == ACCESSORY_POSITION_RIGHT)
            {
                var adjustedAccessoryGap:Number = isNaN(this._accessoryGap) ? gap : this._accessoryGap;
                if(adjustedAccessoryGap == Number.POSITIVE_INFINITY)
                {
                    adjustedAccessoryGap = Math.min(this._paddingLeft, this._paddingRight, this._gap);
                }
                width += this.accessory.width + adjustedAccessoryGap;
            }
            else
            {
                width = Math.max(width, this.accessory.width);
            }
            return width;
        }


        /**
         * @private
         */
        protected function addIconHeight(height:Number, gap:Number):Number
        {
            if(!this.currentIcon || isNaN(this.currentIcon.height))
            {
                return height;
            }
            if(this._iconPosition == ICON_POSITION_TOP || this._iconPosition == ICON_POSITION_BOTTOM)
            {
                height += this.currentIcon.height + gap;
            }
            else
            {
                height = Math.max(height, this.currentIcon.height);
            }
            return height;
        }

        /**
         * @private
         */
        protected function addAccessoryHeight(height:Number, gap:Number):Number
        {
            if(!this.accessory || isNaN(this.accessory.height))
            {
                return height;
            }
            if(this._accessoryPosition == ACCESSORY_POSITION_TOP || this._accessoryPosition == ACCESSORY_POSITION_BOTTOM)
            {
                var adjustedAccessoryGap:Number = isNaN(this._accessoryGap) ? gap : this._accessoryGap;
                if(adjustedAccessoryGap == Number.POSITIVE_INFINITY)
                {
                    adjustedAccessoryGap = Math.min(this._paddingTop, this._paddingBottom, this._gap);
                }
                height += this.accessory.height + adjustedAccessoryGap;
            }
            else
            {
                height = Math.max(height, this.accessory.height);
            }
            return height;
        }

        /**
         * @private
         */
        protected function commitData():void
        {
            if(this._owner)
            {
                if(this._itemHasLabel)
                {
                    this._label = this.itemToLabel(this._data);
                }
                if(this._itemHasIcon)
                {
                    const newIcon:DisplayObject = this.itemToIcon(this._data);
                    this.replaceIcon(newIcon);
                }
                if(this._itemHasAccessory)
                {
                    const newAccessory:DisplayObject = this.itemToAccessory(this._data);
                    this.replaceAccessory(newAccessory);
                }
            }
            else
            {
                if(this._itemHasLabel)
                {
                    this._label = "";
                }
                if(this._itemHasIcon)
                {
                    this.replaceIcon(null);
                }
                if(this._itemHasAccessory)
                {
                    this.replaceAccessory(null);
                }
            }
        }

        /**
         * @private
         */
        protected function replaceIcon(newIcon:DisplayObject):void
        {
            if(this.iconImage && this.iconImage != newIcon)
            {
                this.iconImage.removeEventListener(Event.COMPLETE, loader_completeOrErrorHandler);
                this.iconImage.removeEventListener(FeathersEventType.ERROR, loader_completeOrErrorHandler);
                this.iconImage.dispose();
                this.iconImage = null;
            }

            if(this._itemHasIcon && this.currentIcon && this.currentIcon != newIcon)
            {
                //the icon is created using the data provider, and it is not
                //created inside this class, so it is not our responsibility to
                //dispose the icon. if we dispose it, it may break something.
                this.currentIcon.removeFromParent(false);
            }
            this.defaultIcon = newIcon;
        }

        /**
         * @private
         */
        protected function replaceAccessory(newAccessory:DisplayObject):void
        {
            if(this.accessory == newAccessory)
            {
                return;
            }

            if(this.accessory)
            {
                this.accessory.removeEventListener(FeathersEventType.RESIZE, accessory_resizeHandler);
                this.accessory.removeEventListener(TouchEvent.TOUCH, accessory_touchHandler);

                //the accessory may have come from outside of this class. it's
                //up to that code to dispose of the accessory. in fact, if we
                //disposed of it here, we will probably screw something up, so
                //let's just remove it.
                this.accessory.removeFromParent();
            }

            if(this.accessoryLabel && this.accessoryLabel as Object != newAccessory as Object)
            {
                //we can dispose this one, though, since we created it
                this.accessoryLabel.dispose();
                this.accessoryLabel = null;
            }

            if(this.accessoryImage && this.accessoryImage != newAccessory)
            {
                this.accessoryImage.removeEventListener(Event.COMPLETE, loader_completeOrErrorHandler);
                this.accessoryImage.removeEventListener(FeathersEventType.ERROR, loader_completeOrErrorHandler);

                //same ability to dispose here
                this.accessoryImage.dispose();
                this.accessoryImage = null;
            }

            this.accessory = newAccessory;

            if(this.accessory)
            {
                if(this.accessory is IFeathersControl)
                {
                    //if(!(this.accessory is BitmapFontTextRenderer))
                    //{
                    //    this.accessory.addEventListener(TouchEvent.TOUCH, accessory_touchHandler);
                    //}
                    this.accessory.addEventListener(FeathersEventType.RESIZE, accessory_resizeHandler);
                }
                this.addChild(this.accessory);
            }
        }

        /**
         * @private
         */
        protected function refreshAccessoryLabelStyles():void
        {
            if(!this.accessoryLabel)
            {
                return;
            }

            const displayAccessoryLabel:DisplayObject = DisplayObject(this.accessoryLabel);
            Dictionary.mapToObject(this._accessoryLabelProperties, displayAccessoryLabel);
        }

        /**
         * @private
         */
        protected function refreshIconSource(source:Object):void
        {
            if(!this.iconImage)
            {
                this.iconImage = this._iconLoaderFactory.call() as ImageLoader;
                this.iconImage.addEventListener(Event.COMPLETE, loader_completeOrErrorHandler);
                this.iconImage.addEventListener(FeathersEventType.ERROR, loader_completeOrErrorHandler);
            }
            this.iconImage.source = source;
        }

        /**
         * @private
         */
        protected function refreshAccessorySource(source:Object):void
        {
            if(!this.accessoryImage)
            {
                this.accessoryImage = this._accessoryLoaderFactory.call() as ImageLoader;
                this.accessoryImage.addEventListener(Event.COMPLETE, loader_completeOrErrorHandler);
                this.accessoryImage.addEventListener(FeathersEventType.ERROR, loader_completeOrErrorHandler);
            }
            this.accessoryImage.source = source;
        }

        /**
         * @private
         */
        protected function refreshAccessoryLabel(label:String):void
        {
            if(!this.accessoryLabel)
            {
                const factory:Function = this._accessoryLabelFactory != null ? this._accessoryLabelFactory : FeathersControl.defaultTextRendererFactory;
                this.accessoryLabel = ITextRenderer(factory.call());
                this.accessoryLabel.nameList.add(this.accessoryLabelName);
            }
            this.accessoryLabel.text = label;
        }

        /**
         * @private
         */
        override protected function layoutContent():void
        {
            this.refreshMaxLabelWidth(false);
            if(this._label)
            {
                this.labelTextRenderer.validate();
                const labelRenderer:DisplayObject = DisplayObject(this.labelTextRenderer);
            }
            if(this.accessory is IFeathersControl)
            {
                IFeathersControl(this.accessory).validate();
            }
            if(this.currentIcon is IFeathersControl)
            {
                IFeathersControl(this.currentIcon).validate();
            }

            const iconIsInLayout:Boolean = this.currentIcon && this._iconPosition != ICON_POSITION_MANUAL;
            const accessoryIsInLayout:Boolean = this.accessory && this._accessoryPosition != ACCESSORY_POSITION_MANUAL;
            const accessoryGap:Number = isNaN(this._accessoryGap) ? this._gap : this._accessoryGap;
            if(this._label && iconIsInLayout && accessoryIsInLayout)
            {
                this.positionSingleChild(labelRenderer);
                if(this._layoutOrder == LAYOUT_ORDER_LABEL_ACCESSORY_ICON)
                {
                    this.positionRelativeToOthers(this.accessory, labelRenderer, null, this._accessoryPosition, accessoryGap, null, 0);
                    var iconPosition:String = this._iconPosition;
                    if(iconPosition == ICON_POSITION_LEFT_BASELINE)
                    {
                        iconPosition = ICON_POSITION_LEFT;
                    }
                    else if(iconPosition == ICON_POSITION_RIGHT_BASELINE)
                    {
                        iconPosition = ICON_POSITION_RIGHT;
                    }
                    this.positionRelativeToOthers(this.currentIcon, labelRenderer, this.accessory, iconPosition, this._gap, this._accessoryPosition, accessoryGap);
                }
                else
                {
                    this.positionLabelAndIcon();
                    this.positionRelativeToOthers(this.accessory, labelRenderer, this.currentIcon, this._accessoryPosition, accessoryGap, this._iconPosition, this._gap);
                }
            }
            else if(this._label)
            {
                this.positionSingleChild(labelRenderer);
                //we won't position both the icon and accessory here, otherwise
                //we would have gone into the previous conditional
                if(iconIsInLayout)
                {
                    this.positionLabelAndIcon();
                }
                else if(accessoryIsInLayout)
                {
                    this.positionRelativeToOthers(this.accessory, labelRenderer, null, this._accessoryPosition, accessoryGap, null, 0);
                }
            }
            else if(iconIsInLayout)
            {
                this.positionSingleChild(this.currentIcon);
                if(accessoryIsInLayout)
                {
                    this.positionRelativeToOthers(this.accessory, this.currentIcon, null, this._accessoryPosition, accessoryGap, null, 0);
                }
            }
            else if(accessoryIsInLayout)
            {
                this.positionSingleChild(this.accessory);
            }

            if(this.accessory)
            {
                if(!accessoryIsInLayout)
                {
                    this.accessory.x = this._paddingLeft;
                    this.accessory.y = this._paddingTop;
                }
                this.accessory.x += this._accessoryOffsetX;
                this.accessory.y += this._accessoryOffsetY;
            }
            if(this.currentIcon)
            {
                if(!iconIsInLayout)
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
        override protected function refreshMaxLabelWidth(forMeasurement:Boolean):void
        {
            if(!this._label)
            {
                return;
            }
            var calculatedWidth:Number = this.actualWidth;
            if(forMeasurement)
            {
                calculatedWidth = isNaN(this.explicitWidth) ? this._maxWidth : this.explicitWidth;
            }
            if(this.accessory is IFeathersControl)
            {
                IFeathersControl(this.accessory).validate();
            }
            const adjustedGap:Number = this._gap == Number.POSITIVE_INFINITY ? Math.min(this._paddingLeft, this._paddingRight) : this._gap;
            if(this.currentIcon && (this._iconPosition == ICON_POSITION_LEFT || this._iconPosition == ICON_POSITION_LEFT_BASELINE ||
                this._iconPosition == ICON_POSITION_RIGHT || this._iconPosition == ICON_POSITION_RIGHT_BASELINE))
            {
                calculatedWidth -= (adjustedGap + this.currentIcon.width);
            }

            if(this.accessory && (this._accessoryPosition == ACCESSORY_POSITION_LEFT || this._accessoryPosition == ACCESSORY_POSITION_RIGHT))
            {
                const accessoryGap:Number = (isNaN(this._accessoryGap) || this._accessoryGap == Number.POSITIVE_INFINITY) ? adjustedGap : this._accessoryGap;
                calculatedWidth -= (accessoryGap + this.accessory.width);
            }

            this.labelTextRenderer.maxWidth = calculatedWidth - this._paddingLeft - this._paddingRight;
        }

        /**
         * @private
         */
        protected function positionRelativeToOthers(object:DisplayObject, relativeTo:DisplayObject, relativeTo2:DisplayObject, position:String, gap:Number, otherPosition:String, otherGap:Number):void
        {
            const relativeToX:Number = relativeTo2 ? Math.min(relativeTo.x, relativeTo2.x) : relativeTo.x;
            const relativeToY:Number = relativeTo2 ? Math.min(relativeTo.y, relativeTo2.y) : relativeTo.y;
            const relativeToWidth:Number = relativeTo2 ? (Math.max(relativeTo.x + relativeTo.width, relativeTo2.x + relativeTo2.width) - relativeToX) : relativeTo.width;
            const relativeToHeight:Number = relativeTo2 ? (Math.max(relativeTo.y + relativeTo.height, relativeTo2.y + relativeTo2.height) - relativeToY) : relativeTo.height;
            var newRelativeToX:Number = relativeToX;
            var newRelativeToY:Number = relativeToY;
            if(position == ACCESSORY_POSITION_TOP)
            {
                if(gap == Number.POSITIVE_INFINITY)
                {
                    object.y = this._paddingTop;
                    newRelativeToY = this.actualHeight - this._paddingBottom - relativeToHeight;
                }
                else
                {
                    if(this._verticalAlign == VERTICAL_ALIGN_TOP)
                    {
                        newRelativeToY += object.height + gap;
                    }
                    else if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
                    {
                        newRelativeToY += (object.height + gap) / 2;
                    }
                    if(relativeTo2)
                    {
                        newRelativeToY = Math.max(newRelativeToY, this._paddingTop + object.height + gap);
                    }
                    object.y = newRelativeToY - object.height - gap;
                }
            }
            else if(position == ACCESSORY_POSITION_RIGHT)
            {
                if(gap == Number.POSITIVE_INFINITY)
                {
                    newRelativeToX = this._paddingLeft;
                    object.x = this.actualWidth - this._paddingRight - object.width;
                }
                else
                {
                    if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
                    {
                        newRelativeToX -= (object.width + gap);
                    }
                    else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
                    {
                        newRelativeToX -= (object.width + gap) / 2;
                    }
                    if(relativeTo2)
                    {
                        newRelativeToX = Math.min(newRelativeToX, this.actualWidth - this._paddingRight - object.width - relativeToWidth - gap);
                    }
                    object.x = newRelativeToX + relativeToWidth + gap;
                }
            }
            else if(position == ACCESSORY_POSITION_BOTTOM)
            {
                if(gap == Number.POSITIVE_INFINITY)
                {
                    newRelativeToY = this._paddingTop;
                    object.y = this.actualHeight - this._paddingBottom - object.height;
                }
                else
                {
                    if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
                    {
                        newRelativeToY -= (object.height + gap);
                    }
                    else if(this._verticalAlign == VERTICAL_ALIGN_MIDDLE)
                    {
                        newRelativeToY -= (object.height + gap) / 2;
                    }
                    if(relativeTo2)
                    {
                        newRelativeToY = Math.min(newRelativeToY, this.actualHeight - this._paddingBottom - object.height - relativeToHeight - gap);
                    }
                    object.y = newRelativeToY + relativeToHeight + gap;
                }
            }
            else if(position == ACCESSORY_POSITION_LEFT)
            {
                if(gap == Number.POSITIVE_INFINITY)
                {
                    object.x = this._paddingLeft;
                    newRelativeToX = this.actualWidth - this._paddingRight - relativeToWidth;
                }
                else
                {
                    if(this._horizontalAlign == HORIZONTAL_ALIGN_LEFT)
                    {
                        newRelativeToX += gap + object.width;
                    }
                    else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
                    {
                        newRelativeToX += (gap + object.width) / 2;
                    }
                    if(relativeTo2)
                    {
                        newRelativeToX = Math.max(newRelativeToX, this._paddingLeft + object.width + gap);
                    }
                    object.x = newRelativeToX - gap - object.width;
                }
            }

            var offsetX:Number = newRelativeToX - relativeToX;
            var offsetY:Number = newRelativeToY - relativeToY;
            if(!relativeTo2 || otherGap != Number.POSITIVE_INFINITY || !(
                (position == ACCESSORY_POSITION_TOP && otherPosition == ACCESSORY_POSITION_TOP) ||
                (position == ACCESSORY_POSITION_RIGHT && otherPosition == ACCESSORY_POSITION_RIGHT) ||
                (position == ACCESSORY_POSITION_BOTTOM && otherPosition == ACCESSORY_POSITION_BOTTOM) ||
                (position == ACCESSORY_POSITION_LEFT && otherPosition == ACCESSORY_POSITION_LEFT)
            ))
            {
                relativeTo.x += offsetX;
                relativeTo.y += offsetY;
            }
            if(relativeTo2)
            {
                if(otherGap != Number.POSITIVE_INFINITY || !(
                    (position == ACCESSORY_POSITION_LEFT && otherPosition == ACCESSORY_POSITION_RIGHT) ||
                    (position == ACCESSORY_POSITION_RIGHT && otherPosition == ACCESSORY_POSITION_LEFT) ||
                    (position == ACCESSORY_POSITION_TOP && otherPosition == ACCESSORY_POSITION_BOTTOM) ||
                    (position == ACCESSORY_POSITION_BOTTOM && otherPosition == ACCESSORY_POSITION_TOP)
                ))
                {
                    relativeTo2.x += offsetX;
                    relativeTo2.y += offsetY;
                }
                if(gap == Number.POSITIVE_INFINITY && otherGap == Number.POSITIVE_INFINITY)
                {
                    if(position == ACCESSORY_POSITION_RIGHT && otherPosition == ACCESSORY_POSITION_LEFT)
                    {
                        relativeTo.x = relativeTo2.x + (object.x - relativeTo2.x + relativeTo2.width - relativeTo.width) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_LEFT && otherPosition == ACCESSORY_POSITION_RIGHT)
                    {
                        relativeTo.x = object.x + (relativeTo2.x - object.x + object.width - relativeTo.width) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_RIGHT && otherPosition == ACCESSORY_POSITION_RIGHT)
                    {
                        relativeTo2.x = relativeTo.x + (object.x - relativeTo.x + relativeTo.width - relativeTo2.width) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_LEFT && otherPosition == ACCESSORY_POSITION_LEFT)
                    {
                        relativeTo2.x = object.x + (relativeTo.x - object.x + object.width - relativeTo2.width) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_BOTTOM && otherPosition == ACCESSORY_POSITION_TOP)
                    {
                        relativeTo.y = relativeTo2.y + (object.y - relativeTo2.y + relativeTo2.height - relativeTo.height) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_TOP && otherPosition == ACCESSORY_POSITION_BOTTOM)
                    {
                        relativeTo.y = object.y + (relativeTo2.y - object.y + object.height - relativeTo.height) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_BOTTOM && otherPosition == ACCESSORY_POSITION_BOTTOM)
                    {
                        relativeTo2.y = relativeTo.y + (object.y - relativeTo.y + relativeTo.height - relativeTo2.height) / 2;
                    }
                    else if(position == ACCESSORY_POSITION_TOP && otherPosition == ACCESSORY_POSITION_TOP)
                    {
                        relativeTo2.y = object.y + (relativeTo.y - object.y + object.height - relativeTo2.height) / 2;
                    }
                }
            }

            if(position == ACCESSORY_POSITION_LEFT || position == ACCESSORY_POSITION_RIGHT)
            {
                if(this._verticalAlign == VERTICAL_ALIGN_TOP)
                {
                    object.y = this._paddingTop;
                }
                else if(this._verticalAlign == VERTICAL_ALIGN_BOTTOM)
                {
                    object.y = this.actualHeight - this._paddingBottom - object.height;
                }
                else
                {
                    object.y = this._paddingTop + (this.actualHeight - this._paddingTop - this._paddingBottom - object.height) / 2;
                }
            }
            else if(position == ACCESSORY_POSITION_TOP || position == ACCESSORY_POSITION_BOTTOM)
            {
                if(this._horizontalAlign == HORIZONTAL_ALIGN_LEFT)
                {
                    object.x = this._paddingLeft;
                }
                else if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
                {
                    object.x = this.actualWidth - this._paddingRight - object.width;
                }
                else
                {
                    object.x = this._paddingLeft + (this.actualWidth - this._paddingLeft - this._paddingRight - object.width) / 2;
                }
            }
        }

        /**
         * @private
         */
        protected function handleOwnerScroll():void
        {
            this._touchPointID = -1;
            if(this._stateDelayTimer && this._stateDelayTimer.running)
            {
                this._stateDelayTimer.stop();
            }
            this._delayedCurrentState = null;
            if(this._currentState != Button.STATE_UP)
            {
                super.currentState = Button.STATE_UP;
            }
        }

        /**
         * @private
         */
        protected function itemRenderer_triggeredHandler(event:Event):void
        {
            if(this._isToggle || !this.isSelectableWithoutToggle)
            {
                return;
            }
            this.isSelected = true;
        }

        /**
         * @private
         */
        protected function stateDelayTimer_timerCompleteHandler(timer:Timer):void
        {
            super.currentState = this._delayedCurrentState;
            this._delayedCurrentState = null;
        }

        /**
         * @private
         */
        protected function accessory_touchHandler(event:TouchEvent):void
        {
            if(!this.stopAccessoryTouchEventPropagation ||
                this.accessory as Object == this.accessoryLabel as Object ||
                this.accessory as Object == this.accessoryImage as Object )
            {
                //do nothing
                return;
            }
            event.stopPropagation();
        }

        /**
         * @private
         */
        protected function accessory_resizeHandler(event:Event):void
        {
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected function loader_completeOrErrorHandler(event:Event):void
        {
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }
    }
}