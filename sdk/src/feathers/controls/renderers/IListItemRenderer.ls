/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.renderers
{
    import feathers.controls.*;
    import feathers.core.IToggle;

    /**
     * Interface to implement a renderer for a list item.
     */
    public interface IListItemRenderer extends IToggle
    {
        /**
         * An item from the list's data provider. The data may change if this
         * item renderer is reused for a new item because it's no longer needed
         * for the original item.
         */
        function get data():Object;
        
        /**
         * @private
         */
        function set data(value:Object):void;
        
        /**
         * The index (numeric position, starting from zero) of the item within
         * the list's data provider. Like the `data` property, this
         * value may change if this item renderer is reused by the list for a
         * different item.
         */
        function get index():int;
        
        /**
         * @private
         */
        function set index(value:int):void;
        
        /**
         * The list that contains this item renderer.
         */
        function get owner():List;
        
        /**
         * @private
         */
        function set owner(value:List):void;
    }
}