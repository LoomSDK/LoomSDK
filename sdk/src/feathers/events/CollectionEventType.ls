/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.events
{
    /**
     * Event `type` constants for collections. This class is
     * not a subclass of `loom2d.events.Event` because these
     * constants are meant to be used with `dispatchEventWith()` and
     * take advantage of the Starling's event object pooling. The object passed
     * to an event listener will be of type `loom2d.events.Event`.
     */
    public class CollectionEventType
    {
        /**
         * Dispatched when the data provider's source is completely replaced.
         */
        public static const RESET:String = "reset";

        /**
         * Dispatched when an item is added to the collection.
         */
        public static const ADD_ITEM:String = "addItem";

        /**
         * Dispatched when an item is removed from the collection.
         */
        public static const REMOVE_ITEM:String = "removeItem";

        /**
         * Dispatched when an item is replaced in the collection with a
         * different item.
         */
        public static const REPLACE_ITEM:String = "replaceItem";

        /**
         * Dispatched when an item in the collection has changed.
         */
        public static const UPDATE_ITEM:String = "updateItem";
    }
}
