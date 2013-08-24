package loom2d.display 
{
	import loom.css.StyleSheet;
	
	import loom2d.events.Event;
	import loom2d.events.EventDispatcher;
	
	import loom.lml.ILMLParent;
	
	import loom2d.math.Point;
	import loom2d.math.Rectangle;
	import loom2d.math.Matrix;
	

    /**
     *  A DisplayObjectContainer represents a collection of display objects.
     *  It is the base class of all display objects that act as a container for other objects. By 
     *  maintaining an ordered list of children, it defines the back-to-front positioning of the 
     *  children within the display tree.
     *  
     *  A container does not a have size in itself. The width and height properties represent the 
     *  extents of its children. Changing those properties will scale all children accordingly.
     *  
     *  As this is an abstract class, you can't instantiate it directly, but have to 
     *  use a subclass instead. The most lightweight container class is "Sprite".
     *  
     *  **Adding and removing children**
     *  
     *  The class defines methods that allow you to add or remove children. When you add a child, 
     *  it will be added at the frontmost position, possibly occluding a child that was added 
     *  before. You can access the children via an index. The first child will have index 0, the 
     *  second child index 1, etc. 
     *  
     *  Adding and removing objects from a container triggers non-bubbling events.
     *  
     *  - `Event.ADDED`: the object was added to a parent.
     *  - `Event.ADDED_TO_STAGE`: the object was added to a parent that is 
     *     connected to the stage, thus becoming visible now.
     *  - `Event.REMOVED`: the object was removed from a parent.
     *  - `Event.REMOVED_FROM_STAGE`: the object was removed from a parent that 
     *     is connected to the stage, thus becoming invisible now.
     *  
     *  Especially the `ADDED_TO_STAGE` event is very helpful, as it allows you to 
     *  automatically execute some logic (e.g. start an animation) when an object is rendered the 
     *  first time.
     *  
     *  @see Sprite
     *  @see DisplayObject
     */
     
    [Native(managed)]     
    public native class DisplayObjectContainer extends DisplayObject implements ILMLParent
    {
        // members
        private var mChildren:Vector.<DisplayObject>;

        /** If depth sorting enabled, direct children will use their depth property to establish draw order. */
        public native function set depthSort(value:Boolean);
        public native function get depthSort():Boolean;

        /** View controls which indexed view the container's children will be drawn into */
        public native function set view(value:int);
        public native function get view():int;

        /**
         * Native implementation for clip rect functionality; this passes the 
         * clip rect to the native rendering code. Render of this container's
         * children will be clipped to the passed screen pixel coordinates.
         */
        protected native function setClipRect(x:int, y:int, width:int, height:int):void;

        /** Helper objects. */
        protected var sHelperPoint:Point = new Point();
        protected static var sBroadcastListeners:Vector.<DisplayObject> = new Vector.<DisplayObject>();
        
        // construction
        
        /** @private */
        public function DisplayObjectContainer()
        {			
			Debug.assert(getType() != DisplayObjectContainer, "DisplayObjectContainer is abstract; please instantiate a subclass like Sprite.");
            
            mChildren = new Vector.<DisplayObject>();
            depthSort = false;
			
        }
        
        /** Disposes the resources of all children. */
        public override function dispose():void
        {
            for (var i:int=mChildren.length-1; i>=0; --i)
                mChildren[i].dispose();
            
            super.dispose();
        }
        
        // child management
        
        /** Adds a child to the container. It will be at the frontmost position. */
        public function addChild(child:DisplayObject):DisplayObject
        {
            addChildAt(child, numChildren);
            return child;
        }
        
        /** Adds a child to the container at a certain index. */
        public function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
			Debug.assert(child, "No child specified.");
			
            var numChildren:int = mChildren.length; 
            
            if (index >= 0 && index <= numChildren)
            {
                child.removeFromParent();
                
                // 'splice' creates a temporary object, so we avoid it if it's not necessary
                if (index == numChildren) mChildren.push(child);
                else                      mChildren.splice(index, 0, child);
                
                child.setParent(this);
                child.dispatchEventWith(Event.ADDED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.ADDED_TO_STAGE);
                    else           child.dispatchEventWith(Event.ADDED_TO_STAGE);
                }

				// Propagate style to children.
				if(_styleSheet)
					child.applyStyle(_styleSheet);

                return child;
            }
            else
            {
				Debug.assert(false, "Invalid child index.");
                //throw new RangeError("Invalid child index");
            }
			
			return null;
        }
        
        /** Removes a child from the container. If the object is not a child, nothing happens. 
         *  If requested, the child will be disposed right away. */
        public function removeChild(child:DisplayObject, dispose:Boolean=false):DisplayObject
        {
            var childIndex:int = getChildIndex(child);
            if (childIndex != -1) removeChildAt(childIndex, dispose);
            return child;
        }
        
        /** Removes a child at a certain index. Children above the child will move down. If
         *  requested, the child will be disposed right away. */
        public function removeChildAt(index:int, dispose:Boolean=false):DisplayObject
        {
            if (index >= 0 && index < numChildren)
            {
                var child:DisplayObject = mChildren[index];
                child.dispatchEventWith(Event.REMOVED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.REMOVED_FROM_STAGE);
                    else           child.dispatchEventWith(Event.REMOVED_FROM_STAGE);
                }
                                
                child.setParent(null);
                index = mChildren.indexOf(child); // index might have changed by event handler
                if (index >= 0) mChildren.splice(index, 1); 
                if (dispose) child.dispose();
                
                return child;
            }
            else
            {
				Debug.assert(false, "Invalid child index");
				return null;
                //throw new RangeError("Invalid child index");
            }
        }
        
        /** Removes a range of children from the container (endIndex included). 
         *  If no arguments are given, all children will be removed. */
        public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
        {
            if (endIndex < 0 || endIndex >= numChildren) 
                endIndex = numChildren - 1;
            
            for (var i:int=endIndex; i>=beginIndex; --i)
                removeChildAt(beginIndex, dispose);
        }
        
        /** Returns a child object at a certain index. */
        public function getChildAt(index:int):DisplayObject
        {
            if (index >= 0 && index < numChildren)
                return mChildren[index];
            else
			{
                //throw new RangeError("Invalid child index");
				Debug.assert(false, "Invalid child index");
				return null;
			}
        }
        
        /** Returns a child object with a certain name (non-recursively). */
        public function getChildByName(name:String):DisplayObject
        {
            var numChildren:int = mChildren.length;
            for (var i:int=0; i<numChildren; ++i)
                if (mChildren[i].name == name) return mChildren[i];

            return null;
        }
        
        /** Returns the index of a child within the container, or "-1" if it is not found. */
        public function getChildIndex(child:DisplayObject):int
        {
            return mChildren.indexOf(child);
        }
        
        /** Moves a child to a certain index. Children at and after the replaced position move up.*/
        public function setChildIndex(child:DisplayObject, index:int):void
        {
            var oldIndex:int = getChildIndex(child);
			Debug.assert(oldIndex != -1, "Not a child of this container.");
            
            if (oldIndex == -1) throw new ArgumentError("Not a child of this container");
            
            mChildren.splice(oldIndex, 1);
            mChildren.splice(index, 0, child);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
        {
            Debug.assert(false, "Untested");
            var index1:int = getChildIndex(child1);
            var index2:int = getChildIndex(child2);
			
			Debug.assert(index1 != -1, "Not a child of this container.");
			Debug.assert(index2 != -1, "Not a child of this container.");
			
            //if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
			
            swapChildrenAt(index1, index2);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildrenAt(index1:int, index2:int):void
        {
            Debug.assert(false, "Untested");
            var child1:DisplayObject = getChildAt(index1);
            var child2:DisplayObject = getChildAt(index2);
            mChildren[index1] = child2;
            mChildren[index2] = child1;

        }
        
        /** Sorts the children according to a given function (that works just like the sort function
         *  of the Vector class). */
        public function sortChildren(compareFunction:Function):void
        {
            mChildren.sort(compareFunction);
        }
        
        /** Determines if a certain object is a child of the container (recursively). */
        public function contains(child:DisplayObject):Boolean
        {
            while (child)
            {
                if (child == this) return true;
                else child = child.parent;
            }
            return false;
        }
        
        /** @inheritDoc */ 
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            
            if (resultRect == null) resultRect = new Rectangle();
            
            var numChildren:int = mChildren.length;
            
            if (numChildren == 0)
            {
                getTargetTransformationMatrix(targetSpace, sHelperMatrix);
				sHelperPoint = sHelperMatrix.transformCoord(0.0, 0.0);
                resultRect.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
            }
            else if (numChildren == 1)
            {
                resultRect = mChildren[0].getBounds(targetSpace, resultRect);
            }
            else
            {
				// LOOM-1272
                //var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                //var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;

				// Seed the bounds.
				mChildren[0].getBounds(targetSpace, resultRect);
				var minX = resultRect.x;
				var maxX = resultRect.right;
				var minY = resultRect.y;
				var maxY = resultRect.bottom;
				
                for (var i:int=1; i<numChildren; ++i)
                {
                    mChildren[i].getBounds(targetSpace, resultRect);
                    minX = minX < resultRect.x ? minX : resultRect.x;
                    maxX = maxX > resultRect.right ? maxX : resultRect.right;
                    minY = minY < resultRect.y ? minY : resultRect.y;
                    maxY = maxY > resultRect.bottom ? maxY : resultRect.bottom;
                }
                
                resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
            }                
            
            return resultRect;
        }
        
        /** @inheritDoc */
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            
            var localX:Number = localPoint.x;
            var localY:Number = localPoint.y;
            
            var _childCount:int = mChildren.length;
            for (var i:int=_childCount-1; i>=0; --i) // front to back!
            {
                var child:DisplayObject = mChildren[i];

                if (!child.hasVisibleArea)
                    continue;
				
                getTargetTransformationMatrix(child, sHelperMatrix);
                sHelperPoint = sHelperMatrix.transformCoord(localX, localY);
                var target:DisplayObject = child.hitTest(sHelperPoint, forTouch);
                
                if (target) return target;
            }
            
            return null;
        }
                
        /** Dispatches an event on all children (recursively). The event must not bubble. */
        public function broadcastEvent(event:Event):void
        {
			Debug.assert(event.bubbles == false, "Broadcast of bubbling events is prohibited.");
            //if (event.bubbles)
            //    throw new ArgumentError("Broadcast of bubbling events is prohibited");
            
            // The event listeners might modify the display tree, which could make the loop crash. 
            // Thus, we collect them in a list and iterate over that list instead.
            // And since another listener could call this method internally, we have to take 
            // care that the static helper vector does not get currupted.
            
            var fromIndex:int = sBroadcastListeners.length;
            getChildEventListeners(this, event.type, sBroadcastListeners);
            var toIndex:int = sBroadcastListeners.length;
            
            for (var i:int=fromIndex; i<toIndex; ++i)
                sBroadcastListeners[i].dispatchEvent(event);
            
            sBroadcastListeners.length = fromIndex;
        }
        
        /** Dispatches an event with the given parameters on all children (recursively). 
         *  The method uses an internal pool of event objects to avoid allocations. */
        public function broadcastEventWith(type:String, data:Object=null):void
        {
            var event:Event = Event.fromPool(type, false, data);
            broadcastEvent(event);
            Event.toPool(event);
        }
        
        private function getChildEventListeners(object:DisplayObject, eventType:String, 
                                                listeners:Vector.<DisplayObject>):void
        {
            var container:DisplayObjectContainer = object as DisplayObjectContainer;
            
            if (object.hasEventListener(eventType))
                listeners.push(object);
            
            if (container)
            {
                var children:Vector.<DisplayObject> = container.mChildren;
                var numChildren:int = children.length;
                
                for (var i:int=0; i<numChildren; ++i)
                    getChildEventListeners(children[i], eventType, listeners);
            }
        }
        
        /** The number of children of this container. */
        public function get numChildren():int { return mChildren.length; }        
 
        /** @inheritDoc */
		public function addLMLChild(id:String, child:Object):void
		{
			Debug.assert(child, "No child provided to addLMLChild.");
			
			var styleSheet:StyleSheet = child as StyleSheet;
			if(styleSheet)
			{
				styleSheet.onUpdate += applyStyle;
				applyStyle(styleSheet);
			}
			else
			{
				var childNode:DisplayObject = child as DisplayObject;
				Debug.assert(childNode, "LML child must be or derive from DisplayObject (" + child + ")");
				addChild(childNode);
			}
		}
		
        /** @inheritDoc */
		public function removeLMLChildren():void
		{
			removeChildren();
		}	
		
        /** @inheritDoc */
		protected function applyStyle(styleSheet:StyleSheet):void
		{
			super.applyStyle(styleSheet);
			
			// Style children
			for (var i = 0; i < numChildren; i++)
				getChildAt(i).applyStyle(styleSheet);
		}
	}	
}