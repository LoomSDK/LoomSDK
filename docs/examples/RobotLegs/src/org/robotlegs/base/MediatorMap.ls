/*
 * Copyright (c) 2009, 2010 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.robotlegs.base
{
	import loom2d.display.DisplayObject;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Sprite;
	import loom2d.events.Event;
	//import loom2d.utils.Dictionary;
	//import loom2d.utils.getQualifiedClassName;
	
	import org.robotlegs.core.IInjector;
	import org.robotlegs.core.IMediator;
	import org.robotlegs.core.IMediatorMap;
	import org.robotlegs.core.IReflector;
	
	/**
	 * An abstract <code>IMediatorMap</code> implementation
	 */
	public class MediatorMap extends ViewMapBase implements IMediatorMap
	{
		/**
		 * @private
		 */
		protected static const enterFrameDispatcher:Sprite = new Sprite();
		
		/**
		 * @private
		 */
		protected var mediatorByView:Dictionary.<Object, IMediator>;
		
		/**
		 * @private
		 */
		protected var mappingConfigByView:Dictionary.<Object, MappingConfig>;
		
		/**
		 * @private
		 */
		protected var mappingConfigByViewClassName:Dictionary.<String, MappingConfig>;
		
		/**
		 * @private
		 */
		protected var mediatorsMarkedForRemoval:Dictionary.<DisplayObject, DisplayObject>;
		
		/**
		 * @private
		 */
		protected var hasMediatorsMarkedForRemoval:Boolean;
		
		/**
		 * @private
		 */
		protected var reflector:IReflector;
		
		
		//---------------------------------------------------------------------
		//  Constructor
		//---------------------------------------------------------------------
		
		/**
		 * Creates a new <code>MediatorMap</code> object
		 *
		 * @param contextView The root view node of the context. The map will listen for ADDED_TO_STAGE events on this node
		 * @param injector An <code>IInjector</code> to use for this context
		 * @param reflector An <code>IReflector</code> to use for this context
		 */
		public function MediatorMap(contextView:DisplayObjectContainer, injector:IInjector, reflector:IReflector)
		{
			super(contextView, injector);
			
			this.reflector = reflector;
			
			// mappings - if you can do it with fewer dictionaries you get a prize
			this.mediatorByView = new Dictionary(true);
			this.mappingConfigByView = new Dictionary(true);
			this.mappingConfigByViewClassName = new Dictionary(false);
			this.mediatorsMarkedForRemoval = new Dictionary(false);
		}
		
		//---------------------------------------------------------------------
		//  API
		//---------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public function mapView(viewClassOrName:Object, mediatorClass:Type, injectViewAs:Object = null, autoCreate:Boolean = true, autoRemove:Boolean = true):void
		{
			var viewClassName:String = reflector.getFQCN(viewClassOrName);
			
			if (mappingConfigByViewClassName[viewClassName] != null)
				throw new ContextError(ContextError.E_MEDIATORMAP_OVR + ' - ' + mediatorClass);
			
			if (reflector.classExtendsOrImplements(mediatorClass, IMediator) == false)
				throw new ContextError(ContextError.E_MEDIATORMAP_NOIMPL + ' - ' + mediatorClass);
			
			var config:MappingConfig = new MappingConfig();
			config.mediatorClass = mediatorClass;
			config.autoCreate = autoCreate;
			config.autoRemove = autoRemove;
			if (injectViewAs)
			{
				if (injectViewAs is Vector.<Object>)
				{
					config.typedViewClasses = (injectViewAs as Vector.<Object>).concat();
				}
				else if (injectViewAs is Type)
				{
					config.typedViewClasses = [injectViewAs];
				}
			}
			else if (viewClassOrName is Type)
			{
				config.typedViewClasses = [viewClassOrName];
			}
			mappingConfigByViewClassName[viewClassName] = config;
			
			if (autoCreate || autoRemove)
			{
				viewListenerCount++;
				if (viewListenerCount == 1)
					addListeners();
			}
			
			// This was a bad idea - causes unexpected eager instantiation of object graph 
			if (autoCreate && contextView && (viewClassName == contextView.getTypeName() ))
				createMediatorUsing(contextView, viewClassName, config);
		}
		
		/**
		 * @inheritDoc
		 */
		public function unmapView(viewClassOrName:Object):void
		{
			var viewClassName:String = reflector.getFQCN(viewClassOrName);
			var config:MappingConfig = mappingConfigByViewClassName[viewClassName];
			if (config && (config.autoCreate || config.autoRemove))
			{
				viewListenerCount--;
				if (viewListenerCount == 0)
					removeListeners();
			}
			//delete mappingConfigByViewClassName[viewClassName];
			mappingConfigByViewClassName[viewClassName] = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function createMediator(viewComponent:Object):IMediator
		{
			return createMediatorUsing(viewComponent);
		}
		
		/**
		 * @inheritDoc
		 */
		public function registerMediator(viewComponent:Object, mediator:IMediator):void
		{
			var mediatorClass:Type = reflector.getClass(mediator);
			injector.hasMapping(mediatorClass) && injector.unmap(mediatorClass);
			injector.mapValue(mediatorClass, mediator);
			mediatorByView[viewComponent] = mediator;
			mappingConfigByView[viewComponent] = mappingConfigByViewClassName[viewComponent.getTypeName()];
			mediator.setViewComponent(viewComponent);
			mediator.preRegister();
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeMediator(mediator:IMediator):IMediator
		{
			if (mediator)
			{
				var viewComponent:Object = mediator.getViewComponent();
				var mediatorClass:Type = mediator.getType();
				//delete mediatorByView[viewComponent];
				//delete mappingConfigByView[viewComponent];
				mediatorByView[viewComponent] = null;
				mappingConfigByView[viewComponent] = null;				
				mediator.preRemove();
				mediator.setViewComponent(null);
				injector.hasMapping(mediatorClass) && injector.unmap(mediatorClass);
			}
			return mediator;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeMediatorByView(viewComponent:Object):IMediator
		{
			return removeMediator(retrieveMediator(viewComponent));
		}
		
		/**
		 * @inheritDoc
		 */
		public function retrieveMediator(viewComponent:Object):IMediator
		{
			return mediatorByView[viewComponent];
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasMapping(viewClassOrName:Object):Boolean
		{
			var viewClassName:String = reflector.getFQCN(viewClassOrName);
			return (mappingConfigByViewClassName[viewClassName] != null);
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasMediatorForView(viewComponent:Object):Boolean
		{
			return mediatorByView[viewComponent] != null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasMediator(mediator:IMediator):Boolean
		{
			for each (var med:IMediator in mediatorByView)
				if (med == mediator)
					return true;
			return false;
		}
		
		//---------------------------------------------------------------------
		//  Internal
		//---------------------------------------------------------------------
		
		/**
		 * @private
		 */		
		protected override function addListeners():void
		{
			if (contextView && enabled)
			{
				contextView.addEventListener(Event.ADDED, onViewAdded); //, useCapture, 0, true);
				contextView.addEventListener(Event.REMOVED, onViewRemoved); //, useCapture, 0, true);
			}
		}
		
		/**
		 * @private
		 */		
		protected override function removeListeners():void
		{
			if (contextView)
			{
				contextView.removeEventListener(Event.ADDED, onViewAdded); //, useCapture);
				contextView.removeEventListener(Event.REMOVED, onViewRemoved); //, useCapture);
			}
		}
		
		/**
		 * @private
		 */		
		protected override function onViewAdded(e:Event):void
		{
			if (mediatorsMarkedForRemoval[e.target])
			{
				//delete mediatorsMarkedForRemoval[e.target];
				mediatorsMarkedForRemoval[e.target] = null;
				return;
			}
			
			var viewClassName:String = e.target.getTypeName();
			var config:MappingConfig = mappingConfigByViewClassName[viewClassName];
			if (config && config.autoCreate)
				createMediatorUsing(e.target, viewClassName, config);
		}
		
		/**
		 * @private
		 */		
		protected function createMediatorUsing(viewComponent:Object, viewClassName:String = '', config:MappingConfig = null):IMediator
		{
			var mediator:IMediator = mediatorByView[viewComponent];
			if (mediator == null)
			{
				viewClassName = viewClassName ? viewClassName : viewComponent.getTypeName();
				config = config ? config : mappingConfigByViewClassName[viewClassName];
				if (config)
				{
					for each (var claxx:Type in config.typedViewClasses) 
					{
						injector.mapValue(claxx, viewComponent);
					}
					mediator = injector.instantiate(config.mediatorClass) as IMediator;
					for each (var clazz:Type in config.typedViewClasses) 
					{
						injector.unmap(clazz);
					}
					registerMediator(viewComponent, mediator);
				}
			}
			return mediator;			
		}		
		
		/**
		 * Flex framework work-around part #5
		 */
		protected function onViewRemoved(e:Event):void
		{
			var config:MappingConfig = mappingConfigByView[e.target];
			if (config && config.autoRemove)
			{
				mediatorsMarkedForRemoval[e.target as DisplayObject] = e.target as DisplayObject;
				if (!hasMediatorsMarkedForRemoval)
				{
					hasMediatorsMarkedForRemoval = true;
					enterFrameDispatcher.addEventListener(Event.ENTER_FRAME, removeMediatorLater);
				}
			}
		}
		
		/**
		 * Flex framework work-around part #6
		 */
		protected function removeMediatorLater(event:Event):void
		{
			enterFrameDispatcher.removeEventListener(Event.ENTER_FRAME, removeMediatorLater);
			for each (var view:DisplayObject in mediatorsMarkedForRemoval)
			{
				if (!view.stage)
					removeMediatorByView(view);
				//delete mediatorsMarkedForRemoval[view];
				mediatorsMarkedForRemoval[view] = null;
			}
			hasMediatorsMarkedForRemoval = false;
		}
	}

	class MappingConfig
	{
		public var mediatorClass:Type;
		public var typedViewClasses:Vector.<Type>;
		public var autoCreate:Boolean;
		public var autoRemove:Boolean;
	}

}

