// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package loom2d.events 
{
    import system.Dictionary;
    
    import loom2d.display.DisplayObject;
    
    /** The EventDispatcher class is the base class for all classes that dispatch events. 
     *  This is the Loom version of the Flash class with the same name. 
     *  
     *  The event mechanism is a key feature of Starling's architecture. Objects can communicate 
     *  with each other through events. Compared the the Flash event system, Starling's event system
     *  was simplified. The main difference is that Starling events have no "Capture" phase.
     *  They are simply dispatched at the target and may optionally bubble up. They cannot move 
     *  in the opposite direction.  
     *  
     *  @see Event
     *  @see Loom.Display.DisplayObject DisplayObject
     */
     
    [Native(managed)]
    public native class EventDispatcher
    {
        private var mEventListeners:Dictionary.<String, Vector.<Function>>;
        
        /** Helper object. */
        private static var sBubbleChains:Vector.<Object> = new Vector.<Object>();
        
        /** Creates an EventDispatcher. */
        public function EventDispatcher()
        {  }
        
        /** Registers an event listener at a certain object. */
        public function addEventListener(type:String, listener:Function):void
        {
            if (mEventListeners == null)
                mEventListeners = new Dictionary.<String, Function>();
            
            var listeners:Vector.<Function> = mEventListeners[type] as Vector.<Function>;
            if (listeners == null)
                mEventListeners[type] = new Vector.<Function>[listener];
            else if (listeners.indexOf(listener) == -1) // check for duplicates
                listeners.push(listener);
        }
        
        /** Removes an event listener from the object. */
        public function removeEventListener(type:String, listener:Function):void
        {
            if (mEventListeners)
            {
                var listeners:Vector.<Function> = mEventListeners[type] as Vector.<Function>;
                if (listeners)
                {
                    var numListeners:int = listeners.length;
                    var remainingListeners:Vector.<Function> = new Vector.<Function>();
                    
                    for (var i:int=0; i<numListeners; ++i)
                        if (listeners[i] != listener) remainingListeners.push(listeners[i]);
                    
                    mEventListeners[type] = remainingListeners;
                }
            }
        }
        
        /** Removes all event listeners with a certain type, or all of them if type is null. 
         *  Be careful when removing all event listeners: you never know who else was listening. */
        public function removeEventListeners(type:String=null):void
        {
            if (type && mEventListeners)
                mEventListeners[type] = null;
            else
                mEventListeners = null;
        }
        
        /** Dispatches an event to all objects that have registered listeners for its type. 
         *  If an event with enabled 'bubble' property is dispatched to a display object, it will 
         *  travel up along the line of parents, until it either hits the root object or someone
         *  stops its propagation manually. */
        public function dispatchEvent(event:Event):void
        {
            var bubbles:Boolean = event.bubbles;
            
            if (!bubbles && (mEventListeners == null || !mEventListeners[event.type]))
                return; // no need to do anything
            
            // we save the current target and restore it later;
            // this allows users to re-dispatch events without creating a clone.
            
            var previousTarget:EventDispatcher = event.target;
            event.setTarget(this);
            
            if (bubbles && (this as DisplayObject)) bubbleEvent(event);
            else                                    invokeEvent(event);
            
            if (previousTarget) event.setTarget(previousTarget);
        }
        
        /** @private
         *  Invokes an event on the current object. This method does not do any bubbling, nor
         *  does it back-up and restore the previous target on the event. The 'dispatchEvent' 
         *  method uses this method internally. */
        public function invokeEvent(event:Event):Boolean
        {
            var listeners:Vector.<Function> = mEventListeners ?
                mEventListeners[event.type] as Vector.<Function> : null;
            var numListeners:int = listeners == null ? 0 : listeners.length;
            
            if (numListeners)
            {
                event.setCurrentTarget(this);
                
                // we can enumerate directly over the vector, because:
                // when somebody modifies the list while we're looping, "addEventListener" is not
                // problematic, and "removeEventListener" will create a new Vector, anyway.
                
                for (var i:int=0; i<numListeners; ++i)
                {
                    var listener:Function = listeners[i] as Function;
                    
                    Debug.assert(listener, "Got unexpected null listener.");

                    var numArgs:int = listener.length;
                    
                    if (numArgs == 0)      listener();
                    else if (numArgs == 1) listener(event);
                    else listener(event, event.data);

                    if (event.stopsImmediatePropagation)
                        return true;
                }
                
                return event.stopsPropagation;
            }
            else
            {
                return false;
            }
        }
        
        /** @private */
        protected function bubbleEvent(event:Event):void
        {
            // we determine the bubble chain before starting to invoke the listeners.
            // that way, changes done by the listeners won't affect the bubble chain.
            
            var chain:Vector.<EventDispatcher>;
            var element:DisplayObject = this as DisplayObject;
            var length:int = 1;
            
            if (sBubbleChains.length > 0)
            { 
                chain = sBubbleChains.pop() as Vector.<EventDispatcher>;
                chain.pushSingle(element);
            }
            else
            {
                chain = new Vector.<EventDispatcher>();
                chain.pushSingle(element);
            }
            
            while ((element = element.parent) != null)
                chain.pushSingle(element);

            for (var i:int=0; i<chain.length; ++i)
            {
                var stopPropagation:Boolean = chain[i].invokeEvent(event);
                if (stopPropagation) break;
            }
            
            chain.length = 0;
            sBubbleChains.pushSingle(chain);
        }
        
        /** Dispatches an event with the given parameters to all objects that have registered 
         *  listeners for the given type. The method uses an internal pool of event objects to 
         *  avoid allocations. */
        public function dispatchEventWith(type:String, bubbles:Boolean=false, data:Object=null):void
        {
            if (bubbles || hasEventListener(type)) 
            {
                var event:Event = Event.fromPool(type, bubbles, data);
                dispatchEvent(event);
                Event.toPool(event);
            }
        }
        
        /** Returns if there are listeners registered for a certain event type. */
        public function hasEventListener(type:String):Boolean
        {
            var listeners:Vector.<Function> = mEventListeners ?
                mEventListeners[type] as Vector.<Function> : null;
            return listeners ? listeners.length != 0 : false;
        }
    }
    
}