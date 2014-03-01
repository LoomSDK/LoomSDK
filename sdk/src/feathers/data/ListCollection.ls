/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data
{
    import feathers.events.CollectionEventType;

    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;

    /**
     * Dispatched when the underlying data source changes and the ui will
     * need to redraw the data.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Dispatched when the collection has changed drastically, such as when
     * the underlying data source is replaced completely.
     *
     * @eventType feathers.events.CollectionEventType.RESET
     */
    [Event(name="reset",type="loom2d.events.Event")]

    /**
     * Dispatched when an item is added to the collection.
     *
     * The `data` property of the event is the index of the
     * item that has been updated. It is of type `int`.
     *
     * @eventType feathers.events.CollectionEventType.ADD_ITEM
     */
    [Event(name="addItem",type="loom2d.events.Event")]

    /**
     * Dispatched when an item is removed from the collection.
     *
     * The `data` property of the event is the index of the
     * item that has been updated. It is of type `int`.
     *
     * @eventType feathers.events.CollectionEventType.REMOVE_ITEM
     */
    [Event(name="removeItem",type="loom2d.events.Event")]

    /**
     * Dispatched when an item is replaced in the collection.
     *
     * The `data` property of the event is the index of the
     * item that has been updated. It is of type `int`.
     *
     * @eventType feathers.events.CollectionEventType.REPLACE_ITEM
     */
    [Event(name="replaceItem",type="loom2d.events.Event")]

    /**
     * Dispatched when a property of an item in the collection has changed
     * and the item doesn't have its own change event or signal. This event
     * is only dispatched when the `updateItemAt()` function is
     * called on the `ListCollection`.
     *
     * In general, it's better for the items themselves to dispatch events
     * or signals when their properties change.
     *
     * The `data` property of the event is the index of the
     * item that has been updated. It is of type `int`.
     *
     * @eventType feathers.events.CollectionEventType.UPDATE_ITEM
     */
    [Event(name="updateItem",type="loom2d.events.Event")]

    [DefaultProperty(value="data")]
    /**
     * Wraps a data source with a common API for use with UI controls, like
     * lists, that support one dimensional collections of data. Supports custom
     * "data descriptors" so that unexpected data sources may be used. Supports
     * Arrays, Vectors, and XMLLists automatically.
     * 
     * @see ArrayListCollectionDataDescriptor
     * @see VectorListCollectionDataDescriptor
     * @see XMLListListCollectionDataDescriptor
     */
    public class ListCollection extends EventDispatcher
    {
        /**
         * Constructor.
         */
        public function ListCollection(data:Object = null)
        {
            if(!data)
            {
                //default to an array if no data is provided
                data = [];
            }
            this.data = data;
        }
        
        /**
         * @private
         */
        protected var _data:Object;
        
        /**
         * The data source for this collection. May be any type of data, but a
         * `dataDescriptor` needs to be provided to translate from
         * the data source's APIs to something that can be understood by
         * `ListCollection`.
         * 
         * Data sources of type Array, Vector, and XMLList are automatically
         * detected, and no `dataDescriptor` needs to be set if the
         * `ListCollection` uses one of these types.
         */
        public function get data():Object
        {
            return _data;
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
            if(!value)
            {
                this.removeAll();
                return;
            }
            this._data = value;
            
            // Check for Vector type and auto assign if found
            if ( _data is Vector && _dataDescriptor.getType() != VectorListCollectionDataDescriptor ) dataDescriptor = new VectorListCollectionDataDescriptor();
            
            this.dispatchEventWith(CollectionEventType.RESET);
            this.dispatchEventWith(Event.CHANGE);
        }
        
        /**
         * @private
         */
        protected var _dataDescriptor:IListCollectionDataDescriptor;

        /**
         * Describes the underlying data source by translating APIs.
         * 
         * @see IListCollectionDataDescriptor
         */
        public function get dataDescriptor():IListCollectionDataDescriptor
        {
            return this._dataDescriptor;
        }
        
        /**
         * @private
         */
        public function set dataDescriptor(value:IListCollectionDataDescriptor):void
        {
            if(this._dataDescriptor == value)
            {
                return;
            }
            this._dataDescriptor = value;
            this.dispatchEventWith(CollectionEventType.RESET);
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * The number of items in the collection.
         */
        public function get length():int
        {
            return this._dataDescriptor.getLength(this._data);
        }

        /**
         * If an item doesn't dispatch an event or signal to indicate that it
         * has changed, you can manually tell the collection about the change,
         * and the collection will dispatch the `CollectionEventType.UPDATE_ITEM`
         * event to manually notify the component that renders the data.
         */
        public function updateItemAt(index:int):void
        {
            this.dispatchEventWith(CollectionEventType.UPDATE_ITEM, false, index);
        }
        
        /**
         * Returns the item at the specified index in the collection.
         */
        public function getItemAt(index:int):Object
        {
            return this._dataDescriptor.getItemAt(this._data, index);
        }
        
        /**
         * Determines which index the item appears at within the collection. If
         * the item isn't in the collection, returns `-1`.
         */
        public function getItemIndex(item:Object):int
        {
            return this._dataDescriptor.getItemIndex(this._data, item);
        }
        
        /**
         * Adds an item to the collection, at the specified index.
         */
        public function addItemAt(item:Object, index:int):void
        {
            this._dataDescriptor.addItemAt(this._data, item, index);
            this.dispatchEventWith(Event.CHANGE);
            this.dispatchEventWith(CollectionEventType.ADD_ITEM, false, index);
        }
        
        /**
         * Removes the item at the specified index from the collection and
         * returns it.
         */
        public function removeItemAt(index:int):Object
        {
            const item:Object = this._dataDescriptor.removeItemAt(this._data, index);
            this.dispatchEventWith(Event.CHANGE);
            this.dispatchEventWith(CollectionEventType.REMOVE_ITEM, false, index);
            return item;
        }
        
        /**
         * Removes a specific item from the collection.
         */
        public function removeItem(item:Object):void
        {
            const index:int = this.getItemIndex(item);
            if(index >= 0)
            {
                this.removeItemAt(index);
            }
        }

        /**
         * Removes all items from the collection.
         */
        public function removeAll():void
        {
            this._dataDescriptor.removeAll(this._data);
            this.dispatchEventWith(Event.CHANGE);
            this.dispatchEventWith(CollectionEventType.RESET, false);
        }
        
        /**
         * Replaces the item at the specified index with a new item.
         */
        public function setItemAt(item:Object, index:int):void
        {
            this._dataDescriptor.setItemAt(this._data, item, index);
            this.dispatchEventWith(Event.CHANGE);
            this.dispatchEventWith(CollectionEventType.REPLACE_ITEM, false, index);
        }

        /**
         * Adds an item to the end of the collection.
         */
        public function addItem(item:Object):void
        {
            this.addItemAt(item, this.length);
        }

        /**
         * Adds an item to the end of the collection.
         */
        public function push(item:Object):void
        {
            this.addItemAt(item, this.length);
        }

        /**
         * Adds all items from another collection.
         */
        public function addAll(collection:ListCollection):void
        {
            const otherCollectionLength:int = collection.length;
            for(var i:int = 0; i < otherCollectionLength; i++)
            {
                var item:Object = collection.getItemAt(i);
                this.addItem(item);
            }
        }

        /**
         * Adds all items from another collection, placing the items at a
         * specific index in this collection.
         */
        public function addAllAt(collection:ListCollection, index:int):void
        {
            const otherCollectionLength:int = collection.length;
            var currentIndex:int = index;
            for(var i:int = 0; i < otherCollectionLength; i++)
            {
                var item:Object = collection.getItemAt(i);
                this.addItemAt(item, currentIndex);
                currentIndex++;
            }
        }
        
        /**
         * Removes the item from the end of the collection and returns it.
         */
        public function pop():Object
        {
            return this.removeItemAt(this.length - 1);
        }
        
        /**
         * Adds an item to the beginning of the collection.
         */
        public function unshift(item:Object):void
        {
            this.addItemAt(item, 0);
        }
        
        /**
         * Removed the item from the beginning of the collection and returns it. 
         */
        public function shift():Object
        {
            return this.removeItemAt(0);
        }

        /**
         * Determines if the specified item is in the collection.
         */
        public function contains(item:Object):Boolean
        {
            return this.getItemIndex(item) >= 0;
        }
    }
}