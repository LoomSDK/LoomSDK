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
	
	import org.robotlegs.core.ICommandMap;
	import org.robotlegs.core.IInjector;
	import org.robotlegs.core.IReflector;
	
	/**
	 * An abstract <code>ICommandMap</code> implementation
	 */
	public class CommandMap implements ICommandMap
	{
		/**
		 * The <code>EventDispatcher</code> to listen to
		 */
		protected var eventDispatcher:EventDispatcher;
		
		/**
		 * The <code>IInjector</code> to inject with
		 */
		protected var injector:IInjector;
		
		/**
		 * The <code>IReflector</code> to reflect with
		 */
		protected var reflector:IReflector;
		
		/**
		 * Internal
		 *
		 * TODO: This needs to be documented
		 */
		protected var eventTypeMap:Dictionary.<String, Dictionary.<Type, Dictionary.<String, Function>>>;
		
		/**
		 * Internal
		 *
		 * Collection of command classes that have been verified to implement an <code>execute</code> method
		 */
		protected var verifiedCommandClasses:Dictionary.<Type, int>;
		
		protected var detainedCommands:Dictionary;
		
		//---------------------------------------------------------------------
		//  Constructor
		//---------------------------------------------------------------------
		
		/**
		 * Creates a new <code>CommandMap</code> object
		 *
		 * @param eventDispatcher The <code>EventDispatcher</code> to listen to
		 * @param injector An <code>IInjector</code> to use for this context
		 * @param reflector An <code>IReflector</code> to use for this context
		 */
		public function CommandMap(eventDispatcher:EventDispatcher, injector:IInjector, reflector:IReflector)
		{
			this.eventDispatcher = eventDispatcher;
			this.injector = injector;
			this.reflector = reflector;
			this.eventTypeMap = new Dictionary(false);
			this.verifiedCommandClasses = new Dictionary(false);
			this.detainedCommands = new Dictionary(false);
		}
		
		//---------------------------------------------------------------------
		//  API
		//---------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public function mapEvent(eventType:String, commandClass:Type, eventClass:Type = null, oneshot:Boolean = false):void
		{
			verifyCommandClass(commandClass);
			eventClass = eventClass ? eventClass : Event;

			eventTypeMap[eventType] = eventTypeMap[eventType] ? eventTypeMap[eventType] : new Dictionary(false);
			var eventClassMap:Dictionary.<Type, Dictionary.<Type, Function>> = eventTypeMap[eventType];
				
			eventClassMap[eventClass] = eventClassMap[eventClass] ? eventClassMap[eventClass] : new Dictionary(false);
			var callbacksByCommandClass:Dictionary.<Type, Function> = eventClassMap[eventClass];
				
			if (callbacksByCommandClass[commandClass] != null)
			{
				throw new ContextError(ContextError.E_COMMANDMAP_OVR + ' - eventType (' + eventType + ') and Command (' + commandClass + ')');
			}
			var callback:Function = function(event:Event):void
			{
				routeEventToCommand(event, commandClass, oneshot, eventClass);
			};
			eventDispatcher.addEventListener(eventType, callback); //, false, 0, true);
			callbacksByCommandClass[commandClass] = callback;
		}
		
		/**
		 * @inheritDoc
		 */
		public function unmapEvent(eventType:String, commandClass:Type, eventClass:Type = null):void
		{
			var eventClassMap:Dictionary.<Type, Dictionary.<Type, Function>> = eventTypeMap[eventType];
			if (eventClassMap == null) return;
			
			var callbacksByCommandClass:Dictionary.<Type, Function> = eventClassMap[eventClass ? eventClass : Event];
			if (callbacksByCommandClass == null) return;
			
			var callback:Function = callbacksByCommandClass[commandClass];
			if (callback == null) return;
			
			eventDispatcher.removeEventListener(eventType, callback); //, false);
			//delete callbacksByCommandClass[commandClass];
			callbacksByCommandClass[commandClass] = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function unmapEvents():void
		{
			for (var eventType:String in eventTypeMap)
			{
				var eventClassMap:Dictionary.<String, Dictionary.<Type, Function>> = eventTypeMap[eventType];
				for each (var callbacksByCommandClass:Dictionary.<Type, Function> in eventClassMap)
				{
					for each ( var callback:Function in callbacksByCommandClass)
					{
						eventDispatcher.removeEventListener(eventType, callback); //, false);
					}
				}
			}
			eventTypeMap = new Dictionary(false);
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasEventCommand(eventType:String, commandClass:Type, eventClass:Type = null):Boolean
		{
			var eventClassMap:Dictionary.<Type, Dictionary.<String, Function>> = eventTypeMap[eventType];
			if (eventClassMap == null) return false;
			
			var callbacksByCommandClass:Dictionary = eventClassMap[eventClass ? eventClass : Event];
			if (callbacksByCommandClass == null) return false;
			
			return callbacksByCommandClass[commandClass] != null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function execute(commandClass:Type, payload:Object = null, payloadClass:Type = null, named:String = ''):void
		{
			verifyCommandClass(commandClass);
			
			if (payload != null || payloadClass != null)
			{
				if(payloadClass == null)
					payloadClass = reflector.getClass(payload);

				if (payload is Event && payloadClass != Event)
					injector.mapValue(Event, payload);

				injector.mapValue(payloadClass, payload, named);
			}
			
			var command:Object = injector.instantiate(commandClass);
			
			if (payload != null || payloadClass != null)
			{
				if (payload is Event && payloadClass != Event)
					injector.unmap(Event);

				injector.unmap(payloadClass, named);
			}
			
			command.getType().getMethodInfo("execute").invoke(command, null);
		}
		
		/**
		 * @inheritDoc
		 */
		public function detain(command:Object):void
		{
			detainedCommands[command] = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function release(command:Object):void
		{
			if (detainedCommands[command])
			{
				detainedCommands[command] = null;
				//delete detainedCommands[command];
			}
		}
		
		//---------------------------------------------------------------------
		//  Internal
		//---------------------------------------------------------------------
		
		/**
		 * @throws org.robotlegs.base::ContextError 
		 */
		protected function verifyCommandClass(commandClass:Type):void
		{
			if (!verifiedCommandClasses[commandClass])
			{
				if(commandClass.getType().getMethodInfo("execute") != null)
					verifiedCommandClasses[commandClass] = 1;

				if (!verifiedCommandClasses[commandClass])
					throw new ContextError(ContextError.E_COMMANDMAP_NOIMPL + ' - ' + commandClass);
			}
		}
		
		/**
		 * Event Handler
		 *
		 * @param event The <code>Event</code>
		 * @param commandClass The Class to construct and execute
		 * @param oneshot Should this command mapping be removed after execution?
         * @return <code>true</code> if the event was routed to a Command and the Command was executed,
         *         <code>false</code> otherwise
		 */
		protected function routeEventToCommand(event:Event, commandClass:Type, oneshot:Boolean, originalEventClass:Type):Boolean
		{
			if (!(event is originalEventClass)) return false;
			
			execute(commandClass, event);
			
			if (oneshot) unmapEvent(event.type, commandClass, originalEventClass);
			
			return true;
		}
	
	}
}
