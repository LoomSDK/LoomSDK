/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
	import loom2d.events.Event;

	/**
	 * Public properties and functions from `loom2d.events.EventDispatcher`
	 * in helpful interface form.
	 *
	 * Never cast an object to this type. Cast to `EventDispatcher`
	 * instead. This interface exists only to support easier code hinting.
	 *
	 * @see loom2d.events.EventDispatcher
	 */
	public interface IFeathersEventDispatcher
	{
		/**
		 * @see loom2d.events.EventDispatcher#addEventListener()
		 */
		function addEventListener(type:String, listener:Function):void;

		/**
		 * @see loom2d.events.EventDispatcher#removeEventListener()
		 */
		function removeEventListener(type:String, listener:Function):void;

		/**
		 * @see loom2d.events.EventDispatcher#removeEventListeners()
		 */
		function removeEventListeners(type:String = null):void;

		/**
		 * @see loom2d.events.EventDispatcher#dispatchEvent()
		 */
		function dispatchEvent(event:Event):void;

		/**
		 * @see loom2d.events.EventDispatcher#dispatchEventWith()
		 */
		function dispatchEventWith(type:String, bubbles:Boolean = false, data:Object = null):void;

		/**
		 * @see loom2d.events.EventDispatcher#hasEventListener()
		 */
		function hasEventListener(type:String):Boolean;
	}
}
