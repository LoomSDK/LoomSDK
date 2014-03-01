/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
    import system.errors.IllegalOperationError;

    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;

    /**
     * Dispatched when the selection changes.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Controls the selection of two or more IToggle instances where only one
     * may be selected at a time.
     * 
     * @see IToggle
     */
    public class ToggleGroup extends EventDispatcher
    {
        /**
         * Constructor.
         */
        public function ToggleGroup()
        {
        }

        /**
         * @private
         */
        protected var _items:Vector.<IToggle> = new Vector.<IToggle>;

        /**
         * @private
         */
        protected var _ignoreChanges:Boolean = false;

        /**
         * @private
         */
        protected var _isSelectionRequired:Boolean = true;

        /**
         * Determines if the user can deselect the currently selected item or
         * not. The selection may always be cleared programmatically by setting
         * the selected index to `-1` or the selected item to
         * `null`.
         *
         * If `isSelectionRequired` is set to `true`
         * and the toggle group has items that were added previously, and there
         * is no currently selected item, the item at index `0` will
         * be selected automatically.
         */
        public function get isSelectionRequired():Boolean
        {
            return this._isSelectionRequired;
        }

        /**
         * @private
         */
        public function set isSelectionRequired(value:Boolean):void
        {
            if(this._isSelectionRequired == value)
            {
                return;
            }
            this._isSelectionRequired = value;
            if(this._isSelectionRequired && this._selectedIndex < 0 && this._items.length > 0)
            {
                this.selectedIndex = 0;
            }
        }
        
        /**
         * The currently selected toggle.
         */
        public function get selectedItem():IToggle
        {
            if(this._selectedIndex < 0)
            {
                return null;
            }
            return this._items[this._selectedIndex];
        }
        
        /**
         * @private
         */
        public function set selectedItem(value:IToggle):void
        {
            this.selectedIndex = this._items.indexOf(value);
        }
        
        /**
         * @private
         */
        protected var _selectedIndex:int = -1;
        
        /**
         * The index of the currently selected toggle.
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
            const itemCount:int = this._items.length;
            if(value < -1 || value >= itemCount)
            {
                // RangeError
                throw new Error("Index " + value + " is out of range " + itemCount + " for ToggleGroup.");
            }
            const hasChanged:Boolean = this._selectedIndex != value;
            this._selectedIndex = value;

            //refresh all the items
            this._ignoreChanges = true;
            for(var i:int = 0; i < itemCount; i++)
            {
                var item:IToggle = this._items[i];
                item.isSelected = i == value;
            }
            this._ignoreChanges = false;
            if(hasChanged)
            {
                //only dispatch if there's been a change. we didn't return
                //early because this setter could be called if an item is
                //unselected. if selection is required, we need to reselect the
                //item (happens below in the item's onChange listener).
                this.dispatchEventWith(Event.CHANGE);
            }
        }
        
        /**
         * Adds a toggle to the group. If it is the first item added to the
         * group, and `isSelectionRequired` is `true`, it
         * will be selected automatically.
         */
        public function addItem(item:IToggle):void
        {
            if(!item)
            {
                throw new ArgumentError("IToggle passed to ToggleGroup addItem() must not be null.");
            }
            
            const index:int = this._items.indexOf(item);
            if(index >= 0)
            {
                throw new IllegalOperationError("Cannot add an item to a ToggleGroup more than once.");
            }
            this._items.push(item);
            if(this._selectedIndex < 0 && this._isSelectionRequired)
            {
                this.selectedItem = item;
            }
            else
            {
                item.isSelected = false;
            }
            item.addEventListener(Event.CHANGE, item_changeHandler);

            if(item is IGroupedToggle)
            {
                IGroupedToggle(item).toggleGroup = this;
            }
        }
        
        /**
         * Removes a toggle from the group. If the item being removed is
         * selected and `isSelectionRequired` is `true`,
         * the final item will be selected. If `isSelectionRequired`
         * is `false` instead, no item will be selected.
         */
        public function removeItem(item:IToggle):void
        {
            const index:int = this._items.indexOf(item);
            if(index < 0)
            {
                return;
            }
            this._items.splice(index, 1);
            item.removeEventListener(Event.CHANGE, item_changeHandler);
            if(item is IGroupedToggle)
            {
                IGroupedToggle(item).toggleGroup = null;
            }
            if(this._selectedIndex >= this._items.length)
            {
                if(this._isSelectionRequired)
                {
                    this.selectedIndex = this._items.length - 1;
                }
                else
                {
                    this.selectedIndex = -1;
                }
            }
        }

        /**
         * Removes all toggles from the group. No item will be selected.
         */
        public function removeAllItems():void
        {
            const itemCount:int = this._items.length;
            for(var i:int = 0; i < itemCount; i++)
            {
                var item:IToggle = _items.shift();
                item.removeEventListener(Event.CHANGE, item_changeHandler);
                if(item is IGroupedToggle)
                {
                    IGroupedToggle(item).toggleGroup = null;
                }
            }
            this.selectedIndex = -1;
        }

        /**
         * Determines if the group includes the specified item.
         */
        public function hasItem(item:IToggle):Boolean
        {
            const index:int = this._items.indexOf(item);
            return index >= 0;
        }
        
        /**
         * @private
         */
        protected function item_changeHandler(event:Event):void
        {
            if(this._ignoreChanges)
            {
                return;
            }

            const item:IToggle = IToggle(event.currentTarget);
            const index:int = this._items.indexOf(item);
            if(item.isSelected || (this._isSelectionRequired && this._selectedIndex == index))
            {
                //don't let it deselect the item
                this.selectedIndex = index;
            }
            else if(!item.isSelected)
            {
                this.selectedIndex = -1;
            }
        }
        
    }
}