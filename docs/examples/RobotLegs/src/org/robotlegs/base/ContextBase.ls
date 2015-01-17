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
	import loom2d.events.EventDispatcher;
	
	import org.robotlegs.core.IContext;
	
	/**
	 * An abstract <code>IContext</code> implementation
	 */
	public class ContextBase extends EventDispatcher implements IContext
	{
		//---------------------------------------------------------------------
		//  Constructor
		//---------------------------------------------------------------------
		
		/**
		 * Abstract Context Implementation
		 *
		 * <p>Extend this class to create a Framework or Application context</p>
		 */
		public function ContextBase()
		{
		}
		
		//---------------------------------------------------------------------
		//  API
		//---------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public function get eventDispatcher():EventDispatcher
		{
			return this;
		}
	}
}
