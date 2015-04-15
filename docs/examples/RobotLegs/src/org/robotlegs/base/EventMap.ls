/*
 * Copyright (c) 2009 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.robotlegs.base
{
	import loom2d.events.Event;
	import loom2d.events.EventDispatcher;
	
	import org.robotlegs.core.IEventMap;
	
	/**
	 * An abstract <code>IEventMap</code> implementation
	 */
	public class EventMap implements IEventMap
	{
		/**
		 * The <code>EventDispatcher</code>
		 */
		protected var eventDispatcher:EventDispatcher;
		
		/**
		 * @private
		 */
		protected var _dispatcherListeningEnabled:Boolean = true;
		
		/**
		 * @private
		 */
		protected var listeners:Vector.<Dictionary.<String, Object>>;
		
		//---------------------------------------------------------------------
		//  Constructor
		//---------------------------------------------------------------------
		
		/**
		 * Creates a new <code>EventMap</code> object
		 *
		 * @param eventDispatcher An <code>EventDispatcher</code> to treat as a bus
		 */
		public function EventMap(eventDispatcher:EventDispatcher)
		{
			listeners = new Vector.<Object>();
			this.eventDispatcher = eventDispatcher;
		}
		
		//---------------------------------------------------------------------
		//  API
		//---------------------------------------------------------------------
		
		/**
		 * @return Is shared dispatcher listening allowed?
		 */
		public function get dispatcherListeningEnabled():Boolean
		{
			return _dispatcherListeningEnabled;
		}
		
		/**
		 * @private
		 */
		public function set dispatcherListeningEnabled(value:Boolean):void
		{
			_dispatcherListeningEnabled = value;
		}
		
		/**
		 * The same as calling <code>addEventListener</code> directly on the <code>EventDispatcher</code>,
		 * but keeps a list of listeners for easy (usually automatic) removal.
		 *
		 * @param dispatcher The <code>EventDispatcher</code> to listen to
		 * @param type The <code>Event</code> type to listen for
		 * @param listener The <code>Event</code> handler
		 * @param eventClass Optional Event class for a stronger mapping. Defaults to <code>flash.events.Event</code>.
		 * @param useCapture
		 * @param priority
		 * @param useWeakReference
		 */
		public function mapListener(dispatcher:EventDispatcher, type:String, listener:Function, eventClass:Type = null, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = true):void
		{
			if (dispatcherListeningEnabled == false && dispatcher == eventDispatcher)
			{
				throw new ContextError(ContextError.E_EVENTMAP_NOSNOOPING);
			}
			eventClass = eventClass ? eventClass : Event;
			
			var params:Dictionary.<String, Object>;
			var i:int = listeners.length;
			while (i--)
			{
				params = listeners[i];
				if (params['dispatcher'] as EventDispatcher == dispatcher
					&& params['type'] as String == type
					&& params['listener'] as Function == listener
					/*&& params['useCapture'] as  == useCapture*/
					&& params['eventClass'] as Type == eventClass)
				{
					return;
				}
			}
			
			var callback:Function = function(event:Event):void
				{
					routeEventToListener(event, listener, eventClass);
				};
			params = {
					dispatcher: dispatcher,
					type: type,
					listener: listener,
					eventClass: eventClass,
					callback: callback,
					useCapture: useCapture
				};
			listeners.push(params);
			dispatcher.addEventListener(type, callback); //, useCapture, priority, useWeakReference);
		}
		
		/**
		 * The same as calling <code>removeEventListener</code> directly on the <code>EventDispatcher</code>,
		 * but updates our local list of listeners.
		 *
		 * @param dispatcher The <code>EventDispatcher</code>
		 * @param type The <code>Event</code> type
		 * @param listener The <code>Event</code> handler
		 * @param eventClass Optional Event class for a stronger mapping. Defaults to <code>flash.events.Event</code>.
		 * @param useCapture
		 */
		public function unmapListener(dispatcher:EventDispatcher, type:String, listener:Function, eventClass:Type = null, useCapture:Boolean = false):void
		{
			eventClass = eventClass ? eventClass : Event;
			var params:Dictionary.<String, Object>;
			var i:int = listeners.length;
			while (i--)
			{
				params = listeners[i];
				if (params['dispatcher'] as EventDispatcher == dispatcher
					&& params['type'] as String == type
					&& params['listener'] as Function == listener
					/*&& params['useCapture'] == useCapture */
					&& params['eventClass'] as Type == eventClass)
				{
					dispatcher.removeEventListener(type, params['callback'] as Function); //, useCapture);
					listeners.splice(i, 1);
					return;
				}
			}
		}
		
		/**
		 * Removes all listeners registered through <code>mapListener</code>
		 */
		public function unmapListeners():void
		{
			var params:Dictionary.<String, Object>;
			var dispatcher:EventDispatcher;
			while (params = listeners.pop())
			{
				dispatcher = params['dispatcher'] as EventDispatcher;
				dispatcher.removeEventListener(params['type'] as String, params['callback'] as Function); //, params.useCapture);
			}
		}
		
		//---------------------------------------------------------------------
		//  Internal
		//---------------------------------------------------------------------
		
		/**
		 * Event Handler
		 *
		 * @param event The <code>Event</code>
		 * @param listener
		 * @param originalEventClass
		 */
		protected function routeEventToListener(event:Event, listener:Function, originalEventClass:Type):void
		{
			if (event is originalEventClass)
			{
				listener(event);
			}
		}
	}
}
