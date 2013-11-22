/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.events
{
    import feathers.dragDrop.DragData;

    import loom2d.events.Event;

    /**
     * Events used by the `DragDropManager`.
     *
     * @see feathers.dragDrop.DragDropManager
     */
    public class DragDropEvent extends Event
    {
        /**
         * Dispatched by the `IDragSource` when a drag starts.
         *
         * @see feathers.dragDrop.IDragSource
         */
        public static const DRAG_START:String = "dragStart";

        /**
         * Dispatched by the `IDragSource` when a drag completes.
         * This is always dispatched, even when there wasn't a successful drop.
         * See the `isDropped` property to determine if the drop
         * was successful.
         *
         * @see feathers.dragDrop.IDragSource
         */
        public static const DRAG_COMPLETE:String = "dragComplete";

        /**
         * Dispatched by a `IDropTarget` when a drag enters its
         * bounds.
         *
         * @see feathers.dragDrop.IDropTarget
         */
        public static const DRAG_ENTER:String = "dragEnter";

        /**
         * Dispatched by a `IDropTarget` when a drag moves to a new
         * location within its bounds.
         *
         * @see feathers.dragDrop.IDropTarget
         */
        public static const DRAG_MOVE:String = "dragMove";

        /**
         * Dispatched by a `IDropTarget` when a drag exits its
         * bounds.
         *
         * @see feathers.dragDrop.IDropTarget
         */
        public static const DRAG_EXIT:String = "dragExit";

        /**
         * Dispatched by a `IDropTarget` when a drop occurs.
         *
         * @see feathers.dragDrop.IDropTarget
         */
        public static const DRAG_DROP:String = "dragDrop";

        /**
         * Constructor.
         */
        public function DragDropEvent(type:String, dragData:DragData, isDropped:Boolean, localX:Number = NaN, localY:Number = NaN)
        {
            super(type, false, dragData);
            this.isDropped = isDropped;
            this.localX = localX;
            this.localY = localY;
        }

        /**
         * The `DragData` associated with the current drag.
         */
        public function get dragData():DragData
        {
            return DragData(this.data);
        }

        /**
         * Determines if there has been a drop.
         */
        public var isDropped:Boolean;

        /**
         * The x location, in pixels, of the current action, in the local
         * coordinate system of the `IDropTarget`.
         *
         * @see feathers.dragDrop.IDropTarget
         */
        public var localX:Number;

        /**
         * The y location, in pixels, of the current action, in the local
         * coordinate system of the `IDropTarget`.
         *
         * @see feathers.dragDrop.IDropTarget
         */
        public var localY:Number;
    }
}
