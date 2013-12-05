/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.data.ListCollection;

    import loom2d.events.Event;

    [DefaultProperty(value="dataProvider")]
    /**
     * A set of related buttons with layout, customized using a data provider.
     *
     * The following example creates a button group with a few buttons:
     *
     * ~~~as3
     * var group:ButtonGroup = new ButtonGroup();
     * group.dataProvider = new ListCollection(
     * [
     *     { label: "Yes", triggered: yesButton_triggeredHandler },
     *     { label: "No", triggered: noButton_triggeredHandler },
     *     { label: "Cancel", triggered: cancelButton_triggeredHandler },
     * ]);;
     * this.addChild( group );
         * ~~~
     *
     * @see http://wiki.starling-framework.org/feathers/button-group
     */
    public class ButtonGroup extends FeathersControl
    {
        /**
         * @private
         */
        protected static const INVALIDATION_FLAG_BUTTON_FACTORY:String = "buttonFactory";

        /**
         * @private
         */
        private static const DEFAULT_BUTTON_FIELDS:Vector.<String> = new <String>
        [
            "defaultIcon",
            "upIcon",
            "downIcon",
            "hoverIcon",
            "disabledIcon",
            "defaultSelectedIcon",
            "selectedUpIcon",
            "selectedDownIcon",
            "selectedHoverIcon",
            "selectedDisabledIcon",
            "isSelected",
            "isToggle",
        ];

        /**
         * @private
         */
        private static const DEFAULT_BUTTON_EVENTS:Vector.<String> = new <String>
        [
            Event.TRIGGERED,
            Event.CHANGE,
        ];

        /**
         * The buttons are displayed in order from left to right.
         *
         * @see #direction
         */
        public static const DIRECTION_HORIZONTAL:String = "horizontal";

        /**
         * The buttons are displayed in order from top to bottom.
         *
         * @see #direction
         */
        public static const DIRECTION_VERTICAL:String = "vertical";

        /**
         * The default value added to the `nameList` of the buttons.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_BUTTON:String = "feathers-button-group-button";

        /**
         * @private
         */
        protected static function defaultButtonFactory():Button
        {
            return new Button();
        }

        /**
         * Constructor.
         */
        public function ButtonGroup()
        {
        }

        /**
         * The value added to the `nameList` of the buttons. This
         * variable is `protected` so that sub-classes can customize
         * the button name in their constructors instead of using the default
         * name defined by `DEFAULT_CHILD_NAME_BUTTON`.
         *
         * To customize the button name without subclassing, see
         * `customButtonName`.
         *
         * @see #customButtonName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var buttonName:String = DEFAULT_CHILD_NAME_BUTTON;

        /**
         * The value added to the `nameList` of the first button.
         *
         * To customize the first button name without subclassing, see
         * `customFirstButtonName`.
         *
         * @see #customFirstButtonName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var firstButtonName:String = DEFAULT_CHILD_NAME_BUTTON;

        /**
         * The value added to the `nameList` of the last button.
         *
         * To customize the last button name without subclassing, see
         * `customLastButtonName`.
         *
         * @see #customLastButtonName
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var lastButtonName:String = DEFAULT_CHILD_NAME_BUTTON;

        /**
         * @private
         */
        protected var activeFirstButton:Button;

        /**
         * @private
         */
        protected var inactiveFirstButton:Button;

        /**
         * @private
         */
        protected var activeLastButton:Button;

        /**
         * @private
         */
        protected var inactiveLastButton:Button;

        /**
         * @private
         */
        protected var activeButtons:Vector.<Button> = new <Button>[];

        /**
         * @private
         */
        protected var inactiveButtons:Vector.<Button> = new <Button>[];

        /**
         * @private
         */
        protected var _dataProvider:ListCollection;

        /**
         * The collection of data to be displayed with buttons.
         *
         * The following example sets the button group's data provider:
         *
         * ~~~as3
         * group.dataProvider = new ListCollection(
         * [
         *     { label: "Yes", triggered: yesButton_triggeredHandler },
         *     { label: "No", triggered: noButton_triggeredHandler },
         *     { label: "Cancel", triggered: cancelButton_triggeredHandler },
         * ]);
         * ~~~
         *
         * By default, items in the data provider support the following
         * properties from `Button`
         *
         *     - label
         *     - defaultIcon
         *     - upIcon
         *     - downIcon
         *     - hoverIcon
         *     - disabledIcon
         *     - defaultSelectedIcon
         *     - selectedUpIcon
         *     - selectedDownIcon
         *     - selectedHoverIcon
         *     - selectedDisabledIcon
         *     - isSelected
         *     - isToggle
         *     - isEnabled

         *
         * Additionally, you can add the following event listeners:
         * 
         *     - Event.TRIGGERED
         *     - Event.CHANGE

         *
         * You can pass a function to the `buttonInitializer`
         * property that can provide custom logic to interpret each item in the
         * data provider differently.
         *
         * @see Button
         * @see #buttonInitializer
         */
        public function get dataProvider():ListCollection
        {
            return this._dataProvider;
        }

        /**
         * @private
         */
        public function set dataProvider(value:ListCollection):void
        {
            if(this._dataProvider == value)
            {
                return;
            }
            if(this._dataProvider)
            {
                this._dataProvider.removeEventListener(Event.CHANGE, dataProvider_changeHandler);
            }
            this._dataProvider = value;
            if(this._dataProvider)
            {
                this._dataProvider.addEventListener(Event.CHANGE, dataProvider_changeHandler);
            }
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _direction:String = DIRECTION_VERTICAL;

        [Inspectable(type="String",enumeration="horizontal,vertical")]
        /**
         * The button group layout is either vertical or horizontal.
         *
         * The following example sets the layout direction of the buttons
         * to line them up horizontally:
         *
         * ~~~as3
         * group.direction = ButtonGroup.DIRECTION_HORIZONTAL;
         * ~~~
         */
        public function get direction():String
        {
            return _direction;
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
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _gap:Number = 0;

        /**
         * Space, in pixels, between buttons.
         *
         * The following example sets the gap used for the button layout to
         * 20 pixels:
         *
         * ~~~as3
         * group.gap = 20;
         * ~~~
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
        protected var _firstGap:Number = NaN;

        /**
         * Space, in pixels, between the first two buttons. If NaN, the standard
         * gap will be used.
         *
         * The following example sets the gap between the first and second
         * button to a different value than the standard gap:
         *
         * ~~~as3
         * group.firstGap = 30;
         * group.gap = 20;
         * ~~~
         *
         * @see #gap
         * @see #lastGap
         */
        public function get firstGap():Number
        {
            return this._firstGap;
        }

        /**
         * @private
         */
        public function set firstGap(value:Number):void
        {
            if(this._firstGap == value)
            {
                return;
            }
            this._firstGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _lastGap:Number = NaN;

        /**
         * Space, in pixels, between the last two buttons. If NaN, the standard
         * gap will be used.
         *
         * The following example sets the gap between the last and next to last
         * button to a different value than the standard gap:
         *
         * ~~~as3
         * group.lastGap = 30;
         * group.gap = 20;
         * ~~~
         *
         * @see #gap
         * @see #firstGap
         */
        public function get lastGap():Number
        {
            return this._lastGap;
        }

        /**
         * @private
         */
        public function set lastGap(value:Number):void
        {
            if(this._lastGap == value)
            {
                return;
            }
            this._lastGap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _buttonFactory:Function = defaultButtonFactory;

        /**
         * Creates a new button. A button must be an instance of `Button`.
         * This factory can be used to change properties on the buttons when
         * they are first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on a button.
         *
         * This function is expected to have the following signature:
         *
         * `function():Button`
         *
         * The following example skins the buttons using a custom button
         * factory:
         *
         * ~~~as3
         * group.buttonFactory = function():Button
         * {
         *     var button:Button = new Button();
         *     button.defaultSkin = new Image( texture );
         *     return button;
         * };
         * ~~~
         *
         * @see feathers.controls.Button
         * @see #firstButtonFactory
         * @see #lastButtonFactory
         */
        public function get buttonFactory():Function
        {
            return this._buttonFactory;
        }

        /**
         * @private
         */
        public function set buttonFactory(value:Function):void
        {
            if(this._buttonFactory == value)
            {
                return;
            }
            this._buttonFactory = value;
            this.invalidate(INVALIDATION_FLAG_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _firstButtonFactory:Function;

        /**
         * Creates a new first button. If the `firstButtonFactory` is
         * `null`, then the button group will use the `buttonFactory`.
         * The first button must be an instance of `Button`. This
         * factory can be used to change properties on the first button when
         * it is first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on the first button.
         *
         * This function is expected to have the following signature:
         *
         * `function():Button`
         *
         * The following example skins the first button using a custom
         * factory:
         *
         * ~~~as3
         * group.firstButtonFactory = function():Button
         * {
         *     var button:Button = new Button();
         *     button.defaultSkin = new Image( texture );
         *     return button;
         * };
         * ~~~
         *
         * @see feathers.controls.Button
         * @see #buttonFactory
         * @see #lastButtonFactory
         */
        public function get firstButtonFactory():Function
        {
            return this._firstButtonFactory;
        }

        /**
         * @private
         */
        public function set firstButtonFactory(value:Function):void
        {
            if(this._firstButtonFactory == value)
            {
                return;
            }
            this._firstButtonFactory = value;
            this.invalidate(INVALIDATION_FLAG_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _lastButtonFactory:Function;

        /**
         * Creates a new last button. If the `lastButtonFactory` is
         * `null`, then the button group will use the `buttonFactory`.
         * The last button must be an instance of `Button`. This
         * factory can be used to change properties on the last button when
         * it is first created. For instance, if you are skinning Feathers
         * components without a theme, you might use this factory to set skins
         * and other styles on the last button.
         *
         * This function is expected to have the following signature:
         *
         * `function():Button`
         *
         * The following example skins the last button using a custom
         * factory:
         *
         * ~~~as3
         * group.lastButtonFactory = function():Button
         * {
         *     var button:Button = new Button();
         *     button.defaultSkin = new Image( texture );
         *     return button;
         * };
         * ~~~
         *
         * @see feathers.controls.Button
         * @see #buttonFactory
         * @see #firstButtonFactory
         */
        public function get lastButtonFactory():Function
        {
            return this._lastButtonFactory;
        }

        /**
         * @private
         */
        public function set lastButtonFactory(value:Function):void
        {
            if(this._lastButtonFactory == value)
            {
                return;
            }
            this._lastButtonFactory = value;
            this.invalidate(INVALIDATION_FLAG_BUTTON_FACTORY);
        }

        /**
         * @private
         */
        protected var _buttonInitializer:Function = defaultButtonInitializer;

        /**
         * Modifies a button, perhaps by changing its label and icons, based on the
         * item from the data provider that the button is meant to represent. The
         * default buttonInitializer function can set the button's label and icons if
         * `label` and/or any of the `Button` icon fields
         * (`defaultIcon`, `upIcon`, etc.) are present in
         * the item. You can listen to `Event.TRIGGERED` and
         * `Event.CHANGE` by passing in functions for each.
         *
         * This function is expected to have the following signature:
         *
         * `function( button:Button, item:Object ):void`
         *
         * The following example provides a custom button initializer:
         *
         * ~~~as3
         * group.buttonInitializer = function( button:Button, item:Object ):void
         * {
         *     button.label = item.label;
         * };
         * ~~~
         */
        public function get buttonInitializer():Function
        {
            return this._buttonInitializer;
        }

        /**
         * @private
         */
        public function set buttonInitializer(value:Function):void
        {
            if(this._buttonInitializer == value)
            {
                return;
            }
            this._buttonInitializer = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _customButtonName:String;

        /**
         * A name to add to all buttons in this button group. Typically used by
         * a theme to provide different skins to different button groups.
         *
         * The following example provides a custom button name:
         *
         * ~~~as3
         * group.customButtonName = "my-custom-button-name";
         * ~~~
         *
         * @see feathers.core.FeathersControl#nameList
         * @see http://wiki.starling-framework.org/feathers/custom-themes
         */
        public function get customButtonName():String
        {
            return this._customButtonName;
        }

        /**
         * @private
         */
        public function set customButtonName(value:String):void
        {
            if(this._customButtonName == value)
            {
                return;
            }
            if(this._customButtonName)
            {
                for each(var button:Button in this.activeButtons)
                {
                    button.nameList.remove(this._customButtonName);
                }
            }
            this._customButtonName = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _customFirstButtonName:String;

        /**
         * A name to add to the first button in this button group. Typically
         * used by a theme to provide different skins to the first button.
         *
         * The following example provides a custom first button name:
         *
         * ~~~as3
         * group.customFirstButtonName = "my-custom-first-button-name";
         * ~~~
         *
         * @see feathers.core.FeathersControl#nameList
         * @see http://wiki.starling-framework.org/feathers/custom-themes
         */
        public function get customFirstButtonName():String
        {
            return this._customFirstButtonName;
        }

        /**
         * @private
         */
        public function set customFirstButtonName(value:String):void
        {
            if(this._customFirstButtonName == value)
            {
                return;
            }
            if(this._customFirstButtonName && this.activeFirstButton)
            {
                this.activeFirstButton.nameList.remove(this._customButtonName);
                this.activeFirstButton.nameList.remove(this._customFirstButtonName);
            }
            this._customFirstButtonName = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _customLastButtonName:String;

        /**
         * A name to add to the last button in this button group. Typically used
         * by a theme to provide different skins to the last button.
         *
         * The following example provides a custom last button name:
         *
         * ~~~as3
         * group.customLastButtonName = "my-custom-last-button-name";
         * ~~~
         *
         * @see feathers.core.FeathersControl#nameList
         * @see http://wiki.starling-framework.org/feathers/custom-themes
         */
        public function get customLastButtonName():String
        {
            return this._customLastButtonName;
        }

        /**
         * @private
         */
        public function set customLastButtonName(value:String):void
        {
            if(this._customLastButtonName == value)
            {
                return;
            }
            if(this._customLastButtonName && this.activeLastButton)
            {
                this.activeLastButton.nameList.remove(this._customButtonName);
                this.activeLastButton.nameList.remove(this._customLastButtonName);
            }
            this._customLastButtonName = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _buttonProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to all of the button
         * group's buttons. These values are shared by each button, so values
         * that cannot be shared (such as display objects that need to be added
         * to the display list) should be passed to buttons using the
         * `buttonFactory` or in a theme. The buttons in a button
         * group are instances of `feathers.controls.Button`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:

         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`

         *
         * The following example sets some properties on all of the buttons:
         *
         * ~~~as3
         * group.buttonProperties.horizontalAlign = Button.HORIZONTAL_ALIGN_LEFT;
         * group.buttonProperties.verticalAlign = Button.VERTICAL_ALIGN_TOP;
         * ~~~
         *
         * Setting properties in a `buttonFactory` function instead
         * of using `buttonProperties` will result in better
         * performance.
         *
         * @see #buttonFactory
         * @see #firstButtonFactory
         * @see #lastButtonFactory
         * @see feathers.controls.Button
         */
        public function get buttonProperties():Dictionary.<String, Object>
        {
            if(!this._buttonProperties)
            {
                this._buttonProperties = new Dictionary.<String, Object>;
            }
            return this._buttonProperties;
        }

        /**
         * @private
         */
        public function set buttonProperties(value:Dictionary.<String, Object>):void
        {
            if(this._buttonProperties == value)
            {
                return;
            }
            this._buttonProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        override public function dispose():void
        {
            this.dataProvider = null;
            super.dispose();
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            const buttonFactoryInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_BUTTON_FACTORY);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);

            if(dataInvalid || stateInvalid || buttonFactoryInvalid)
            {
                this.refreshButtons(buttonFactoryInvalid);
            }

            if(dataInvalid || buttonFactoryInvalid || stylesInvalid)
            {
                this.refreshButtonStyles();
            }

            if(dataInvalid || stateInvalid || buttonFactoryInvalid)
            {
                this.commitEnabled();
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(sizeInvalid || dataInvalid || buttonFactoryInvalid || stylesInvalid)
            {
                this.layoutButtons();
            }
        }

        /**
         * @private
         */
        protected function commitEnabled():void
        {
            const buttonCount:int = this.activeButtons.length;
            for(var i:int = 0; i < buttonCount; i++)
            {
                var button:Button = this.activeButtons[i];
                button.isEnabled = button.isEnabled && this._isEnabled;
            }
        }

        /**
         * @private
         */
        protected function refreshButtonStyles():void
        {
            for each(var button:Button in this.activeButtons)
            {
                Dictionary.mapToObject(this._buttonProperties, button);

                if(button == this.activeFirstButton && this._customFirstButtonName)
                {
                    if(!button.nameList.contains(this._customFirstButtonName))
                    {
                        button.nameList.add(this._customFirstButtonName);
                    }
                }
                else if(button == this.activeLastButton && this._customLastButtonName)
                {
                    if(!button.nameList.contains(this._customLastButtonName))
                    {
                        button.nameList.add(this._customLastButtonName);
                    }
                }
                else if(this._customButtonName && !button.nameList.contains(this._customButtonName))
                {
                    button.nameList.add(this._customButtonName);
                }
            }
        }

        /**
         * @private
         */
        protected function defaultButtonInitializer(button:Button, item:Object):void
        {
            if ( item is String )
            {
                button.label = item as String;
                return;
            }
            
            var itemAsDictionary:Dictionary.<String, Object> = item as Dictionary.<String, Object>;
            
            if( itemAsDictionary != null )
            {
                button.label = ( itemAsDictionary[ "label" ] != null ) ? itemAsDictionary[ "label" ] as String : "";
                button.isEnabled = ( itemAsDictionary[ "isEnabled" ] != null ) ? itemAsDictionary[ "isEnabled" ] as Boolean : true;
                
                var field:String;
                for each( field in DEFAULT_BUTTON_FIELDS )
                {
                    if ( itemAsDictionary[ field ] != null ) button.getType().setFieldOrPropertyValueByName( button, field, itemAsDictionary[ field ] );
                }
                for each( field in DEFAULT_BUTTON_EVENTS )
                {
                    if ( itemAsDictionary[ field ] != null ) button.addEventListener( field, itemAsDictionary[ field ] as Function );
                }
            }
            else
            {
                button.label = "";
            }
        }

        /**
         * @private
         */
        protected function refreshButtons(isFactoryInvalid:Boolean):void
        {
            var temp:Vector.<Button> = this.inactiveButtons;
            this.inactiveButtons = this.activeButtons;
            this.activeButtons = temp;
            this.activeButtons.length = 0;
            temp = null;
            if(isFactoryInvalid)
            {
                this.clearInactiveButtons();
            }
            else
            {
                if(this.activeFirstButton)
                {
                    this.inactiveButtons.shift();
                }
                this.inactiveFirstButton = this.activeFirstButton;

                if(this.activeLastButton)
                {
                    this.inactiveButtons.pop();
                }
                this.inactiveLastButton = this.activeLastButton;
            }
            this.activeFirstButton = null;
            this.activeLastButton = null;

            const itemCount:int = this._dataProvider ? this._dataProvider.length : 0;
            const lastItemIndex:int = itemCount - 1;
            for(var i:int = 0; i < itemCount; i++)
            {
                var item:Object = this._dataProvider.getItemAt(i);
                if(i == 0)
                {
                    var button:Button = this.activeFirstButton = this.createFirstButton(item);
                }
                else if(i == lastItemIndex)
                {
                    button = this.activeLastButton = this.createLastButton(item);
                }
                else
                {
                    button = this.createButton(item);
                }
                this.activeButtons.push(button);
            }
            this.clearInactiveButtons();
        }

        /**
         * @private
         */
        protected function clearInactiveButtons():void
        {
            const itemCount:int = this.inactiveButtons.length;
            for(var i:int = 0; i < itemCount; i++)
            {
                var button:Button = this.inactiveButtons.shift();
                this.destroyButton(button);
            }

            if(this.inactiveFirstButton)
            {
                this.destroyButton(this.inactiveFirstButton);
                this.inactiveFirstButton = null;
            }

            if(this.inactiveLastButton)
            {
                this.destroyButton(this.inactiveLastButton);
                this.inactiveLastButton = null;
            }
        }

        /**
         * @private
         */
        protected function createFirstButton(item:Object):Button
        {
            if(this.inactiveFirstButton)
            {
                var button:Button = this.inactiveFirstButton;
                this.inactiveFirstButton = null;
            }
            else
            {
                const factory:Function = this._firstButtonFactory != null ? this._firstButtonFactory : this._buttonFactory;
                button = Button(factory());
                if(this._customFirstButtonName)
                {
                    button.nameList.add(this._customFirstButtonName);
                }
                else
                {
                    button.nameList.add(this.firstButtonName);
                }
                this.addChild(button);
            }
            this._buttonInitializer(button, item);
            return button;
        }

        /**
         * @private
         */
        protected function createLastButton(item:Object):Button
        {
            if(this.inactiveLastButton)
            {
                var button:Button = this.inactiveLastButton;
                this.inactiveLastButton = null;
            }
            else
            {
                const factory:Function = this._lastButtonFactory != null ? this._lastButtonFactory : this._buttonFactory;
                button = Button(factory());
                if(this._customLastButtonName)
                {
                    button.nameList.add(this._customLastButtonName);
                }
                else
                {
                    button.nameList.add(this.lastButtonName);
                }
                this.addChild(button);
            }
            this._buttonInitializer(button, item);
            return button;
        }

        /**
         * @private
         */
        protected function createButton(item:Object):Button
        {
            if(this.inactiveButtons.length == 0)
            {
                var button:Button = this._buttonFactory() as Button;
                if(this._customButtonName)
                {
                    button.nameList.add(this._customButtonName);
                }
                else
                {
                    button.nameList.add(this.buttonName);
                }
                this.addChild(button);
            }
            else
            {
                button = this.inactiveButtons.shift();
            }
            this._buttonInitializer(button, item);
            return button;
        }

        /**
         * @private
         */
        protected function destroyButton(button:Button):void
        {
            this.removeChild(button, true);
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

            var newWidth:Number = this.explicitWidth;
            var newHeight:Number = this.explicitHeight;
            if(needsWidth)
            {
                newWidth = 0;
                for each(var button:Button in this.activeButtons)
                {
                    button.validate();
                    newWidth = Math.max(button.width, newWidth);
                }
                if(this._direction == DIRECTION_HORIZONTAL)
                {
                    var buttonCount:int = this.activeButtons.length;
                    newWidth = buttonCount * (newWidth + this._gap) - this._gap;
                    if(!isNaN(this._firstGap) && buttonCount > 1)
                    {
                        newWidth -= this._gap;
                        newWidth += this._firstGap;
                    }
                    if(!isNaN(this._lastGap) && buttonCount > 2)
                    {
                        newWidth -= this._gap;
                        newWidth += this._lastGap;
                    }
                }
            }

            if(needsHeight)
            {
                newHeight = 0;
                for each(button in this.activeButtons)
                {
                    button.validate();
                    newHeight = Math.max(button.height, newHeight);
                }
                if(this._direction != DIRECTION_HORIZONTAL)
                {
                    buttonCount = this.activeButtons.length;
                    newHeight = buttonCount * (newHeight + this._gap) - this._gap;
                    if(!isNaN(this._firstGap) && buttonCount > 1)
                    {
                        newHeight -= this._gap;
                        newHeight += this._firstGap;
                    }
                    if(!isNaN(this._lastGap) && buttonCount > 2)
                    {
                        newHeight -= this._gap;
                        newHeight += this._lastGap;
                    }
                }
            }
            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function layoutButtons():void
        {
            const hasFirstGap:Boolean = !isNaN(this._firstGap);
            const hasLastGap:Boolean = !isNaN(this._lastGap);
            const buttonCount:int = this.activeButtons.length;
            const secondToLastIndex:int = buttonCount - 2;
            const totalSize:Number = this._direction == DIRECTION_VERTICAL ? this.actualHeight : this.actualWidth;
            var totalButtonSize:Number = totalSize - (this._gap * (buttonCount - 1));
            if(hasFirstGap)
            {
                totalButtonSize += this._gap - this._firstGap;
            }
            if(hasLastGap)
            {
                totalButtonSize += this._gap - this._lastGap;
            }
            const buttonSize:Number = totalButtonSize / buttonCount;
            var position:Number = 0;
            for(var i:int = 0; i < buttonCount; i++)
            {
                var button:Button = this.activeButtons[i];
                if(this._direction == DIRECTION_VERTICAL)
                {
                    button.width = this.actualWidth;
                    button.height = buttonSize;
                    button.x = 0;
                    button.y = position;
                    position += button.height;
                }
                else //horizontal
                {
                    button.width = buttonSize;
                    button.height = this.actualHeight;
                    button.x = position;
                    button.y = 0;
                    position += button.width;
                }

                if(hasFirstGap && i == 0)
                {
                    position += this._firstGap;
                }
                else if(hasLastGap && i == secondToLastIndex)
                {
                    position += this._lastGap;
                }
                else
                {
                    position += this._gap;
                }
            }
        }

        /**
         * @private
         */
        protected function dataProvider_changeHandler(event:Event):void
        {
            this.invalidate(INVALIDATION_FLAG_DATA);
        }
    }
}
