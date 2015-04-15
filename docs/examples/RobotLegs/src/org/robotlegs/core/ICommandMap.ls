/*
 * Copyright (c) 2009 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.robotlegs.core
{
	

	/**
	 * The Robotlegs CommandMap contract
	 */
	public interface ICommandMap
	{
		/**
		 * Detain a Command instance
		 * 
		 * @param command The Command instance to detain
		 */		
		function detain(command:Object):void;
		
		/**
		 * Release a Command instance
		 * 
		 * @param command The Command instance to release for garbage collection
		 */		
		function release(command:Object):void;
		
		/**
		 * Execute a Command with an optional payload
		 * 
		 * <p>The <code>commandType</code> must implement an execute() method</p>
		 * 
		 * @param commandType The Type to instantiate - must have an execute() method
		 * @param payload An optional payload
		 * @param payloadType  An optional class to inject the payload as
		 * @param named An optional name for the payload injection
		 * 
		 * @throws org.robotlegs.base::ContextError
		 */		
		function execute(commandType:Type, payload:Object = null, payloadType:Type = null, named:String = ''):void;
		
		/**
		 * Map a Type to an Event type
		 * 
		 * <p>The <code>commandType</code> must implement an execute() method</p>
		 * 
		 * @param eventType The Event type to listen for
		 * @param commandType The Type to instantiate - must have an execute() method
		 * @param eventType Optional Event class for a stronger mapping. Defaults to <code>flash.events.Event</code>. Your commandType can optionally [Inject] a variable of this type to access the event that triggered the command.
		 * @param oneshot Unmap the Type after execution?
		 * 
		 * @throws org.robotlegs.base::ContextError
		 */
		function mapEvent(eventType:String, commandType:Type, eventClass:Type = null, oneshot:Boolean = false):void;
		
		/**
		 * Unmap a Type to Event type mapping
		 *
		 * @param eventType The Event type
		 * @param commandType The Type to unmap
		 * @param eventType Optional Event class for a stronger mapping. Defaults to <code>flash.events.Event</code>.
		 */
		function unmapEvent(eventType:String, commandType:Type, eventClass:Type = null):void;
		
		/**
		 * Removes all mappings made through <code>mapEvent</code>
		 */		
		function unmapEvents():void;
		
		/**
		 * Check if a Type has been mapped to an Event type
		 *
		 * @param eventType The Event type
		 * @param commandType The Type
		 * @param eventType Optional Event class for a stronger mapping. Defaults to <code>flash.events.Event</code>.
		 * @return Whether the Type is mapped to this Event type
		 */
		function hasEventCommand(eventType:String, commandType:Type, eventClass:Type = null):Boolean;
	}
}
