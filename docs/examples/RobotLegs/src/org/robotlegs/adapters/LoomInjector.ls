/*
 * Copyright (c) 2009 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.robotlegs.adapters
{
	import org.robotlegs.core.IInjector;
	import loom.utils.Injector;
	
	/**
	 * This is an implementation of the injector functionality using Loom's
	 * reflection APIs.
	 *
	 * @author bengarney
	 */
	public class LoomInjector implements IInjector
	{
		private var _injector:Injector = new Injector();

		public function mapValue(whenAskedFor:Type, useValue:Object, named:String = ""):Object
		{
			if(named == "") named = null;
			//trace("mapValue " + whenAskedFor.getTypeName() + " " + useValue.toString() + " " + named);
			_injector.mapValue(useValue, whenAskedFor, named);
			return useValue;
		}

		public function mapClass(whenAskedFor:Type, instantiateClass:Type, named:String = ""):Object
		{
			if(named == "") named = null;
			_injector.mapValue(instantiateClass.getConstructor().invoke(), whenAskedFor, named);
			return null;
		}

		public function injectInto(target:Object):void
		{
			//trace("inject into " + target);
			_injector.apply(target);
		}

		public function instantiate(clazz:Type):Object
		{
			var o = clazz.getConstructor().invoke();
			injectInto(o);
			return o;
		}
		
		public function createChild(applicationDomain:Object = null):IInjector
		{
			var i = new LoomInjector();
			i._injector.setParentInjector(_injector);
			return i;
		}
		
		public function unmap(clazz:Type, named:String = ""):void
		{
			_injector.mapValue(null, clazz, named);
		}

		public function hasMapping(clazz:Type, named:String = ""):Boolean
		{			
			return _injector.getValue(clazz, named) != null;
		}
		
		public function get applicationDomain():Object
		{
			return null;
		}
		
		public function set applicationDomain(value:Object):void
		{

		}
	
	}
}