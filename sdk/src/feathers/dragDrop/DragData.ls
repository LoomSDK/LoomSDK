/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.dragDrop
{
	/**
	 * Stores data associated with a drag and drop operation.
	 *
	 * @see DragDropManager
	 */
	public class DragData
	{
		/**
		 * Constructor.
		 */
		public function DragData()
		{
		}

		/**
		 * @private
		 */
		protected var _data:Dictionary.<String, Object> = {};

		/**
		 * Determines if the specified data format is available.
		 */
		public function hasDataForFormat(format:String):Boolean
		{
			return this._data[format] != null;
		}

		/**
		 * Returns data for the specified format.
		 */
		public function getDataForFormat(format:String):Object
		{
			if(this._data[format] != null)
			{
				return this._data[format];
			}
			return null;
		}

		/**
		 * Saves data for the specified format.
		 */
		public function setDataForFormat(format:String, data:Object):void
		{
			this._data[format] = data;
		}

		/**
		 * Removes all data for the specified format.
		 */
		public function clearDataForFormat(format:String):Object
		{
			var data:Object = this._data[format];
			this._data[format] = null;
			return data;
		}
	}
}
