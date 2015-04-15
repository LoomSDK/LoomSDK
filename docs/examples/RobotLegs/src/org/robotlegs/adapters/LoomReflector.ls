/*
 * Copyright (c) 2009 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.robotlegs.adapters
{
	import org.robotlegs.core.IReflector;
	
	/**
	 * This is an implementation of the RobotLegs reflector API using Loom's
	 * reflection APIs.
	 * 
	 * @author bengarney
	 */
	public class LoomReflector implements IReflector
	{
		function classExtendsOrImplements(classOrClassName:Object, superclass:Type):Boolean
		{
			if(classOrClassName is String)
			{
				// We need to dynamically resolve the type by name.
				var t = Type.getTypeByName(classOrClassName as String) as Type;
				Debug.assert(t != null, "Failed to resolve type " + (classOrClassName as String));
				classOrClassName = t;
			}

			if(classOrClassName is Type)
			{
				// This can be optimized.
				var o = (classOrClassName as Type).getConstructor().invoke();
				return o is superclass;
			}
			else
			{
				return classOrClassName is superclass;
			}
		}
		
		function getClass(value:Object):Type
		{
			return value.getType();			
		}

		function getFQCN(value:Object, replaceColons:Boolean = false):String
		{
			if(replaceColons)
			{
				// Use String.replace().
				throw new Error("NYI");
			}

			return value.getTypeName();
		}
	}
}