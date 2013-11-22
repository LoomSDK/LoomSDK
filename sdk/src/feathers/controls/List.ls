/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.controls.renderers.DefaultListItemRenderer;
    import feathers.controls.supportClasses.ListDataViewPort;
    import feathers.core.IFocusDisplayObject;
    import feathers.data.ListCollection;
    import feathers.events.CollectionEventType;
    import feathers.events.FeathersEventType;
    import feathers.layout.ILayout;
    import feathers.layout.VerticalLayout;

    import loom2d.math.Point;
    //import flash.ui.Keyboard;

    import loom2d.events.Event;
    import loom2d.events.KeyboardEvent;

    /**
     * Dispatched when the selected item changes.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Dispatched when an item renderer is added to the list. When the layout is
     * virtualized, item renderers may not exist for every item in the data
     * provider. This event can be used to track which items currently have
     * renderers.
     *
     * @eventType feathers.events.FeathersEventType.RENDERER_ADD
     */
    [Event(name="rendererAdd",type="loom2d.events.Event")]

    /**
     * Dispatched when an item renderer is removed from the list. When the layout is
     * virtualized, item renderers may not exist for every item in the data
     * provider. This event can be used to track which items currently have
     * renderers.
     *
     * @eventType feathers.events.FeathersEventType.RENDERER_REMOVE
     */
    [Event(name="rendererRemove",type="loom2d.events.Event")]

    [DefaultProperty(value="dataProvider")]
    /**
     * Displays a one-dimensional list of items. Supports scrolling, custom
     * item renderers, and custom layouts.
     *
     * Layouts may be, and are highly encouraged to be, _virtual_,
     * meaning that the List is capable of creating a limited number of item
     * renderers to display a subset of the data provider instead of creating a
     * renderer for every single item. This allows for optimal performance with
     * very large data providers.
     *
     * @see http://wiki.starling-framework.org/feathers/list
     * @see GroupedList
     */
    public class List extends Scroller implements IFocusDisplayObject
    {
        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @copy feathers.controls.Scroller#SCROLL_POLICY_AUTO
         *
         * @see feathers.controls.Scroller#horizontalScrollPolicy
         * @see feathers.controls.Scroller#verticalScrollPolicy
         */
        public static const SCROLL_POLICY_AUTO:String = "auto";

        /**
         * @copy feathers.controls.Scroller#SCROLL_POLICY_ON
         *
         * @see feathers.controls.Scroller#horizontalScrollPolicy
         * @see feathers.controls.Scroller#verticalScrollPolicy
         */
        public static const SCROLL_POLICY_ON:String = "on";

        /**
         * @copy feathers.controls.Scroller#SCROLL_POLICY_OFF
         *
         * @see feathers.controls.Scroller#horizontalScrollPolicy
         * @see feathers.controls.Scroller#verticalScrollPolicy
         */
        public static const SCROLL_POLICY_OFF:String = "off";

        /**
         * @copy feathers.controls.Scroller#SCROLL_BAR_DISPLAY_MODE_FLOAT
         *
         * @see feathers.controls.Scroller#scrollBarDisplayMode
         */
        public static const SCROLL_BAR_DISPLAY_MODE_FLOAT:String = "float";

        /**
         * @copy feathers.controls.Scroller#SCROLL_BAR_DISPLAY_MODE_FIXED
         *
         * @see feathers.controls.Scroller#scrollBarDisplayMode
         */
        public static const SCROLL_BAR_DISPLAY_MODE_FIXED:String = "fixed";

        /**
         * @copy feathers.controls.Scroller#SCROLL_BAR_DISPLAY_MODE_NONE
         *
         * @see feathers.controls.Scroller#scrollBarDisplayMode
         */
        public static const SCROLL_BAR_DISPLAY_MODE_NONE:String = "none";

        /**
         * @copy feathers.controls.Scroller#INTERACTION_MODE_TOUCH
         *
         * @see feathers.controls.Scroller#interactionMode
         */
        public static const INTERACTION_MODE_TOUCH:String = "touch";

        /**
         * @copy feathers.controls.Scroller#INTERACTION_MODE_MOUSE
         *
         * @see feathers.controls.Scroller#interactionMode
         */
        public static const INTERACTION_MODE_MOUSE:String = "mouse";
        
        /**
         * Constructor.
         */
        public function List()
        {
            super();
            this._selectedIndices.addEventListener(Event.CHANGE, selectedIndices_changeHandler);
        }

        /**
         * @private
         * The guts of the List's functionality. Handles layout and selection.
         */
        protected var dataViewPort:ListDataViewPort;

        /**
         * @private
         */
        protected var _layout:ILayout;

        /**
         * The layout algorithm used to position and, optionally, size the
         * list's items.
         */
        public function get layout():ILayout
        {
            return this._layout;
        }

        /**
         * @private
         */
        public function set layout(value:ILayout):void
        {
            if(this._layout == value)
            {
                return;
            }
            this._layout = value;
            this.invalidate(INVALIDATION_FLAG_SCROLL);
        }
        
        /**
         * @private
         */
        protected var _dataProvider:ListCollection;
        
        /**
         * The collection of data displayed by the list.
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
                this._dataProvider.removeEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
            }
            this._dataProvider = value;
            if(this._dataProvider)
            {
                this._dataProvider.addEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
            }

            //reset the scroll position because this is a drastic change and
            //the data is probably completely different
            this.horizontalScrollPosition = 0;
            this.verticalScrollPosition = 0;

            this.invalidate(INVALIDATION_FLAG_DATA);
        }
        
        /**
         * @private
         */
        protected var _isSelectable:Boolean = true;
        
        /**
         * Determines if items in the list may be selected. By default only a
         * single item may be selected at any given time. In other words, if
         * item A is selected, and the user selects item B, item A will be
         * deselected automatically. Set `allowMultipleSelection`
         * to `true` to select more than one item without
         * automatically deselecting other items.
         * 
         * @default true
         * @see #allowMultipleSelection
         */
        public function get isSelectable():Boolean
        {
            return this._isSelectable;
        }
        
        /**
         * @private
         */
        public function set isSelectable(value:Boolean):void
        {
            if(this._isSelectable == value)
            {
                return;
            }
            this._isSelectable = value;
            if(!this._isSelectable)
            {
                this.selectedIndex = -1;
            }
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }
        
        /**
         * @private
         */
        protected var _selectedIndex:int = -1;
        
        /**
         * The index of the currently selected item. Returns -1 if no item is
         * selected.
         */
        public function get selectedIndex():int
        {
            return this._selectedIndex;
        }
        
        /**
         * @private
         */
        public function set selectedIndex(value:int):void
        {
            if(this._selectedIndex == value)
            {
                return;
            }
            if(value >= 0)
            {
                this._selectedIndices.data = new <int>[value];
            }
            else
            {
                this._selectedIndices.removeAll();
            }
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * The currently selected item. Returns null if no item is selected.
         */
        public function get selectedItem():Object
        {
            if(!this._dataProvider || this._selectedIndex < 0 || this._selectedIndex >= this._dataProvider.length)
            {
                return null;
            }

            return this._dataProvider.getItemAt(this._selectedIndex);
        }

        /**
         * @private
         */
        public function set selectedItem(value:Object):void
        {
            this.selectedIndex = this._dataProvider.getItemIndex(value);
        }

        /**
         * @private
         */
        protected var _allowMultipleSelection:Boolean = false;

        /**
         * If `true` multiple items may be selected at a time. If
         * `false`, then only a single item may be selected at a
         * time, and if the selection changes, other items are deselected. Has
         * no effect if `isSelectable` is `false`.
         *
         * @see #isSelectable
         */
        public function get allowMultipleSelection():Boolean
        {
            return this._allowMultipleSelection;
        }

        /**
         * @private
         */
        public function set allowMultipleSelection(value:Boolean):void
        {
            if(this._allowMultipleSelection == value)
            {
                return;
            }
            this._allowMultipleSelection = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * @private
         */
        protected var _selectedIndices:ListCollection = new ListCollection(new <int>[]);

        /**
         * The indices of the currently selected items. Returns an empty `Vector.&lt;int&gt;`
         * if no items are selected. If `allowMultipleSelection` is
         * `false`, only one item may be selected at a time.
         */
        public function get selectedIndices():Vector.<int>
        {
            return this._selectedIndices.data as Vector.<int>;
        }

        /**
         * @private
         */
        public function set selectedIndices(value:Vector.<int>):void
        {
            const oldValue:Vector.<int> = this._selectedIndices.data as Vector.<int>;
            if(oldValue == value)
            {
                return;
            }
            if(!value)
            {
                if(this._selectedIndices.length == 0)
                {
                    return;
                }
                this._selectedIndices.removeAll();
            }
            else
            {
                if(!this._allowMultipleSelection && value.length > 0)
                {
                    value.length = 1;
                }
                this._selectedIndices.data = value;
            }
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * The currently selected item. The getter returns an empty
         * `Vector.&lt;Object&gt;` if no item is selected. If any
         * items are selected, the getter creates a new
         * `Vector.&lt;Object&gt;` to return a list of selected
         * items.
         */
        public function get selectedItems():Vector.<Object>
        {
            const items:Vector.<Object> = new <Object>[];
            const indexCount:int = this._selectedIndices.length;
            for(var i:int = 0; i < indexCount; i++)
            {
                var index:int = this._selectedIndices.getItemAt(i) as int;
                var item:Object = this._dataProvider.getItemAt(index);
                items.push(item);
            }
            return items;
        }

        /**
         * @private
         */
        public function set selectedItems(value:Vector.<Object>):void
        {
            if(!value)
            {
                this.selectedIndex = -1;
                return;
            }
            const indices:Vector.<int> = new <int>[];
            const itemCount:int = value.length;
            for(var i:int = 0; i < itemCount; i++)
            {
                var item:Object = value[i];
                var index:int = this._dataProvider.getItemIndex(item);
                if(index >= 0)
                {
                    indices.push(index);
                }
            }
            this.selectedIndices = indices;
        }
        
        /**
         * @private
         */
        protected var _itemRendererProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to all of the list's item
         * renderers. These values are shared by each item renderer, so values
         * that cannot be shared (such as display objects that need to be added
         * to the display list) should be passed to the item renderers using an
         * `itemRendererFactory` or with a theme. The item renderers
         * are instances of `IListItemRenderer`. The available
         * properties depend on which `IListItemRenderer`
         * implementation is returned by `itemRendererFactory`.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:

         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`

         *
         * Setting properties in a `itemRendererFactory` function
         * instead of using `itemRendererProperties` will result in
         * better performance.
         *
         * @see #itemRendererFactory
         * @see feathers.controls.renderers.IListItemRenderer
         * @see feathers.controls.renderers.DefaultListItemRenderer
         */
        public function get itemRendererProperties():Object
        {
            if(!this._itemRendererProperties)
            {
                this._itemRendererProperties = new Dictionary.<String, Object>;
            }
            return this._itemRendererProperties;
        }

        /**
         * @private
         */
        public function set itemRendererProperties(value:Object):void
        {
            if(this._itemRendererProperties == value)
            {
                return;
            }

            this._itemRendererProperties = value as Dictionary.<String, Object>;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }
        
        /**
         * @private
         */
        protected var _itemRendererType:Type = DefaultListItemRenderer;
        
        /**
         * The class used to instantiate item renderers.
         *
         * @see feathers.controls.renderer.IListItemRenderer
         * @see #itemRendererFactory
         */
        public function get itemRendererType():Type
        {
            return this._itemRendererType;
        }
        
        /**
         * @private
         */
        public function set itemRendererType(value:Type):void
        {
            if(this._itemRendererType == value)
            {
                return;
            }
            
            this._itemRendererType = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }
        
        /**
         * @private
         */
        protected var _itemRendererFactory:Function;
        
        /**
         * A function called that is expected to return a new item renderer. Has
         * a higher priority than `itemRendererType`. Typically, you
         * would use an `itemRendererFactory` instead of an
         * `itemRendererType` if you wanted to initialize some
         * properties on each separate item renderer, such as skins.
         *
         * The function is expected to have the following signature:
         *
         * `function():IListItemRenderer`
         *
         * @see feathers.controls.renderers.IListItemRenderer
         * @see #itemRendererType
         */
        public function get itemRendererFactory():Function
        {
            return this._itemRendererFactory;
        }
        
        /**
         * @private
         */
        public function set itemRendererFactory(value:Function):void
        {
            //if(this._itemRendererFactory === value)
            if(this._itemRendererFactory == value)
            {
                return;
            }
            
            this._itemRendererFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }
        
        /**
         * @private
         */
        protected var _typicalItem:Object = null;
        
        /**
         * Used to auto-size the list. If the list's width or height is NaN, the
         * list will try to automatically pick an ideal size. This item is
         * used in that process to create a sample item renderer.
         */
        public function get typicalItem():Object
        {
            return this._typicalItem;
        }
        
        /**
         * @private
         */
        public function set typicalItem(value:Object):void
        {
            if(this._typicalItem == value)
            {
                return;
            }
            this._typicalItem = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _itemRendererName:String;

        /**
         * A name to add to all item renderers in this list. Typically used by a
         * theme to provide different skins to different lists.
         *
         * @see feathers.core.FeathersControl#nameList
         */
        public function get itemRendererName():String
        {
            return this._itemRendererName;
        }

        /**
         * @private
         */
        public function set itemRendererName(value:String):void
        {
            if(this._itemRendererName == value)
            {
                return;
            }
            this._itemRendererName = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * The pending item index to scroll to after validating. A value of
         * `-1` means that the scroller won't scroll to an item after
         * validating.
         */
        protected var pendingItemIndex:int = -1;

        /**
         * @private
         */
        override public function scrollToPosition(horizontalScrollPosition:Number, verticalScrollPosition:Number, animationDuration:Number = 0):void
        {
            this.pendingItemIndex = -1;
            super.scrollToPosition(horizontalScrollPosition, verticalScrollPosition, animationDuration);
        }

        /**
         * @private
         */
        override public function scrollToPageIndex(horizontalPageIndex:int, verticalPageIndex:int, animationDuration:Number = 0):void
        {
            this.pendingItemIndex = -1;
            super.scrollToPageIndex(horizontalPageIndex, verticalPageIndex, animationDuration);
        }
        
        /**
         * Scrolls the list so that the specified item is visible. If
         * `animationDuration` is greater than zero, the scroll will
         * animate. The duration is in seconds.
         * 
         * @param index The integer index of an item from the data provider.
         * @param animationDuration The length of time, in seconds, of the animation. May be zero to scroll instantly.
         */
        public function scrollToDisplayIndex(index:int, animationDuration:Number = 0):void
        {
            this.pendingHorizontalPageIndex = -1;
            this.pendingVerticalPageIndex = -1;
            this.pendingHorizontalScrollPosition = NaN;
            this.pendingVerticalScrollPosition = NaN;
            if(this.pendingItemIndex == index &&
                this.pendingScrollDuration == animationDuration)
            {
                return;
            }
            this.pendingItemIndex = index;
            this.pendingScrollDuration = animationDuration;
            this.invalidate(INVALIDATION_FLAG_PENDING_SCROLL);
        }

        /**
         * @private
         */
        override public function dispose():void
        {
            if(this._layout)
            {
                var l = this._layout;
                this._layout = null;
            }
            this.dataProvider = null;
            super.dispose();
            if(l) (l as Object).deleteNative();
        }
        
        /**
         * @private
         */
        override protected function initialize():void
        {
            const hasLayout:Boolean = this._layout != null;

            super.initialize();
            
            if(!this.dataViewPort)
            {
                this.viewPort = this.dataViewPort = new ListDataViewPort();
                this.dataViewPort.owner = this;
                this.viewPort = this.dataViewPort;
            }

            if(!hasLayout)
            {
                if(this._hasElasticEdges &&
                    this._verticalScrollPolicy == SCROLL_POLICY_AUTO &&
                    this._scrollBarDisplayMode != SCROLL_BAR_DISPLAY_MODE_FIXED)
                {
                    //so that the elastic edges work even when the max scroll
                    //position is 0, similar to iOS.
                    this.verticalScrollPolicy = SCROLL_POLICY_ON;
                }

                const layout:VerticalLayout = new VerticalLayout();
                layout.useVirtualLayout = true;
                layout.paddingTop = layout.paddingRight = layout.paddingBottom =
                    layout.paddingLeft = 0;
                layout.gap = 0;
                layout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_JUSTIFY;
                layout.verticalAlign = VerticalLayout.VERTICAL_ALIGN_TOP;
                layout.manageVisibility = true;
                this._layout = layout;
            }
        }
        
        /**
         * @private
         */
        override protected function draw():void
        {
            this.refreshDataViewPortProperties();
            super.draw();
            this.refreshFocusIndicator();
        }

        /**
         * @private
         */
        protected function refreshDataViewPortProperties():void
        {
            this.dataViewPort.isSelectable = this._isSelectable;
            this.dataViewPort.allowMultipleSelection = this._allowMultipleSelection;
            this.dataViewPort.selectedIndices = this._selectedIndices;
            this.dataViewPort.dataProvider = this._dataProvider;
            this.dataViewPort.itemRendererType = this._itemRendererType;
            this.dataViewPort.itemRendererFactory = this._itemRendererFactory;
            this.dataViewPort.itemRendererProperties = this._itemRendererProperties;
            this.dataViewPort.itemRendererName = this._itemRendererName;
            this.dataViewPort.typicalItem = this._typicalItem;
            this.dataViewPort.layout = this._layout;
        }

        /**
         * @private
         */
        override protected function handlePendingScroll():void
        {
            if(this.pendingItemIndex >= 0)
            {
                const item:Object = this._dataProvider.getItemAt(this.pendingItemIndex);
                if(item is Object)
                {
                    HELPER_POINT = this.dataViewPort.getScrollPositionForIndex(this.pendingItemIndex);
                    this.pendingItemIndex = -1;

                    if(this.pendingScrollDuration > 0)
                    {
                        this.throwTo(Math.max(0, Math.min(HELPER_POINT.x, this._maxHorizontalScrollPosition)),
                            Math.max(0, Math.min(HELPER_POINT.y, this._maxVerticalScrollPosition)), this.pendingScrollDuration);
                    }
                    else
                    {
                        this.horizontalScrollPosition = Math.max(0, Math.min(HELPER_POINT.x, this._maxHorizontalScrollPosition));
                        this.verticalScrollPosition = Math.max(0, Math.min(HELPER_POINT.y, this._maxVerticalScrollPosition));
                    }
                }
            }
            super.handlePendingScroll();
        }

        /**
         * @private
         */
        override protected function focusInHandler(event:Event):void
        {
            super.focusInHandler(event);
            //this.stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
        }

        /**
         * @private
         */
        override protected function focusOutHandler(event:Event):void
        {
            super.focusOutHandler(event);
            //this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
        }

        /**
         * @private
         */
/*        protected function stage_keyDownHandler(event:KeyboardEvent):void
        {
            if(!this._dataProvider)
            {
                return;
            }
            if(event.keyCode == Keyboard.HOME)
            {
                if(this._dataProvider.length > 0)
                {
                    this.selectedIndex = 0;
                }
            }
            else if(event.keyCode == Keyboard.END)
            {
                this.selectedIndex = this._dataProvider.length - 1;
            }
            else if(event.keyCode == Keyboard.UP)
            {
                this.selectedIndex = Math.max(0, this._selectedIndex - 1);
            }
            else if(event.keyCode == Keyboard.DOWN)
            {
                this.selectedIndex = Math.min(this._dataProvider.length - 1, this._selectedIndex + 1);
            }
        }*/

        /**
         * @private
         */
        protected function dataProvider_resetHandler(event:Event):void
        {
            this.horizontalScrollPosition = 0;
            this.verticalScrollPosition = 0;
        }
        
        /**
         * @private
         */
        protected function selectedIndices_changeHandler(event:Event):void
        {
            if(this._selectedIndices.length > 0)
            {
                this._selectedIndex = this._selectedIndices.getItemAt(0) as int;
            }
            else
            {
                if(this._selectedIndex < 0)
                {
                    //no change
                    return;
                }
                this._selectedIndex = -1;
            }
            this.dispatchEventWith(Event.CHANGE);
        }
    }
}