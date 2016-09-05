package loom2d.display
{
    import loom2d.Loom2D;

    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;

    import loom.lml.ILMLNode;
    import loom.css.Style;
    import loom.css.StyleSheet;
    import loom.css.StyleApplicator;

    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.math.Matrix;

    /**
     *  The DisplayObject class is the base class for all objects that are rendered on the
     *  screen.
     *
     *  **The Display Tree**
     *
     *  In Starling, all displayable objects are organized in a display tree. Only objects that
     *  are part of the display tree will be displayed (rendered).
     *
     *  The display tree consists of leaf nodes (Image, Quad) that will be rendered directly to
     *  the screen, and of container nodes (subclasses of "DisplayObjectContainer", like "Sprite").
     *  A container is simply a display object that has child nodes - which can, again, be either
     *  leaf nodes or other containers.
     *
     *  At the base of the display tree, there is the Stage, which is a container, too. When you
     *  use Application as the base class for your Loom application, a Stage instance is automatically
     *  created for you.
     *
     *  A display object has properties that define its position in relation to its parent
     *  (x, y), as well as its rotation and scaling factors (scaleX, scaleY). Use the
     *  `alpha` and `visible` properties to make an object translucent or
     *  invisible.
     *
     *  Every display object may be the target of touch events. If you don't want an object to be
     *  touchable, you can disable the "touchable" property. When it's disabled, neither the object
     *  nor its children will receive any more touch events.
     *
     *  **Transforming coordinates**
     *
     *  Within the display tree, each object has its own local coordinate system. If you rotate
     *  a container, you rotate that coordinate system - and thus all the children of the
     *  container.
     *
     *  Sometimes you need to know where a certain point lies relative to another coordinate
     *  system. That's the purpose of the method `getTransformationMatrix`. It will
     *  create a matrix that represents the transformation of a point in one coordinate system to
     *  another.
     *
     *  **Subclassing**
     *
     *  Since DisplayObject is an abstract class, you cannot instantiate it directly, but have
     *  to use one of its subclasses instead. There are already a lot of them available, and most
     *  of the time they will suffice.
     *
     *  However, you can create custom subclasses as well. That way, you can create an object
     *  with a custom render function. You will need to implement the following methods when you
     *  subclass DisplayObject:
     *
     * ~~~as3
     * function render(support:RenderSupport, parentAlpha:Number):void
     * function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
     * ~~~
     *
     *  Have a look at the Quad class for a sample implementation of the 'getBounds' method.
     *  Currently, this implementation is backed by Cocos2DX - but in an upcoming release we will
     *  move to a more direct rendering API.
     *
     *  @see DisplayObjectContainer
     *  @see Sprite
     *  @see Stage
     */

    [Native(managed)]
    public native class DisplayObject extends EventDispatcher implements ILMLNode
    {
        static protected var _globalStageGeneration = 0;
        
		protected var _ignoreHitTestAlpha:Boolean;
        protected var _styleSheet:StyleSheet;
        protected var _styleName:String;
        protected var _styleApplicator:StyleApplicator;
        protected var _cachedStage:Stage = null;
        protected var _cachedStageGeneration = -1;

        protected function get styleApplicator():StyleApplicator
        {
            if(!_styleApplicator)
                _styleApplicator = new StyleApplicator();
            return _styleApplicator;
        }

        // todo: move this to pooling
        public native function DisplayObject();

        // members

        /** The x coordinate of the object relative to the local coordinates of the parent. */
        public native function set x(value:float);
        public native function get x():float;

        /** The y coordinate of the object relative to the local coordinates of the parent. */
        public native function set y(value:float);
        public native function get y():float;

        /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
        public native function set pivotX(value:float);
        public native function get pivotX():float;

        /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
        public native function set pivotY(value:float);
        public native function get pivotY():float;

        /** The horizontal scale factor. '1' means no scale, negative values flip the object. */
        public native function set scaleX(value:float);
        public native function get scaleX():float;

        /** The vertical scale factor. '1' means no scale, negative values flip the object. */
        public native function set scaleY(value:float);
        public native function get scaleY():float;

        /** The horizontal skew angle in radians. */
        public native function set skewX(value:float);
        public native function get skewX():float;

        /** The vertical skew angle in radians. */
        public native function set skewY(value:float);
        public native function get skewY():float;

        /** The rotation of the object in radians, (In Loom2D, all angles are measured
         *  in radians.) */
        public native function set rotation(value:float);
        public native function get rotation():float;

        /** The opacity of the object, 0 = transparent, 1 = opaque. */
        public native function set alpha(value:float);
        public native function get alpha():float;

        /** The blend mode determines how the object is blended with the objects underneath.
         *   @default BlendMode.AUTO
         *   @see loom2d.display.BlendMode */
        public native function set blendMode(value:BlendMode);
        public native function get blendMode():BlendMode;

        /** Enables or disables blending. If set to false, there will be no blending and there may be performance gains. */
        public native function set blendEnabled(value:Boolean);
        public native function get blendEnabled():Boolean;

        /** The visibility of the object, An invisible object will be untouchable. */
        public native function set visible(value:Boolean);
        public native function get visible():Boolean;

        /** Indicates if this object (and its children) will receive touch events. */
        public native function set touchable(value:Boolean);
        public native function get touchable():Boolean;
        
        /**
         * If true, the untransformed contents get cached into a texture at render time.
         * The contents remain static until you turn off caching or use `invalidateBitmapCache`
         * to update the cache manually.
         */
        public native function set cacheAsBitmap(value:Boolean);
        public native function get cacheAsBitmap():Boolean;
        
        /**
         * Update the cached texture before the next render.
         * This function has no effect if `cacheAsBitmap` is turned off.
         */
        public native function invalidateBitmapCache();

        /** The name of the display object (default: null). Used by 'getChildByName()' of
         *  display object containers. */
        public native function set name(value:String);
        public native function get name():String;
        
        /** This can be used if you wish to have a DisplayObject with zero alpha still respond to hit tests */
        public function set ignoreHitTestAlpha(value:Boolean) { _ignoreHitTestAlpha = value; }
        public function get ignoreHitTestAlpha():Boolean { return _ignoreHitTestAlpha; };

        // cached parent so that we don't marshal a managed instance every property access
        private var parentCached:DisplayObjectContainer;

        /** Access to the native parent field */
        protected native function set _parent(value:DisplayObjectContainer);

        public function get parent():DisplayObjectContainer
        {
            return parentCached;
        }

        // should not set this directly
        public function set parent(value:DisplayObjectContainer)
        {
            // tell native about new parent
            _parent = value;
            parentCached = value;
        }

        /** If depthSort is enabled on parent, this will be used to establish draw order. 
            Higher values are drawn closer. Matching values have undefined order. */
        public native function set depth(value:float);
        public native function get depth():float;

        // TODO: once we move children of DisplayObjectContainer to native code
        // look at flowing valid to children
        protected native function set valid(value:Boolean);
        protected native function get valid():Boolean;

        /**
         * Classes which derive directly from DisplayObject can specify a
         * custom render method to call by adding it to this delegate
         * Example:
         *
         * ~~~as3
         * public native class MyRenderer extends DisplayObject {
         *    ⇥public function MyRenderer() {
         *    ⇥   ⇥// register our custom render method
         *    ⇥   ⇥customRender += render;
         *    ⇥}
         *
         *    ⇥// renderer implemented in native code for
         *    ⇥// full access to bgfx, etc
         *    ⇥private native function render();
         * }
         * ~~~
         *
         */
        protected native var customRender:NativeDelegate;

        /* delegate that can be set up to be called prior to normal DisplayObject rendering */
        protected native var onRender:NativeDelegate;

        protected var mUseHandCursor:Boolean;

        protected var _transformationMatrix = new Matrix();
        public native function getTargetTransformationMatrix(targetSpace:DisplayObject, resultMatrix:Matrix):void;

        // TODO: Resurrect filters? LOOM-1328
        //protected var mFilter:FragmentFilter;

        /** Helper objects. */
        private static var sAncestors:Vector.<DisplayObject> = new Vector.<DisplayObject>();
        protected static var sHelperRect:Rectangle = new Rectangle();
        protected static var sHelperMatrix:Matrix  = new Matrix();

        /** Override in children to setup/initialize state  */
        protected function validate():void
        {

        }


        /** Center the DisplayObject's pivot point using the width and height. This centers this 
        object about its own origin based on its width and height. */
        public function center():void
        {
            if (!valid)
                validate();

            pivotX = width / scaleX / 2;
            pivotY = height / scaleY / 2;
        }

        /** Disposes all resources of the display object.
          * GPU buffers are released, event listeners are removed, filters are disposed. */
        public function dispose():void
        {
            //if (mFilter) mFilter.dispose();
            removeEventListeners();
            Loom2D.juggler.delayCall( deleteNative, 0.01 );
        }

        /** Removes the object from its parent, if it has one. */
        public function removeFromParent(dispose:Boolean=false):void
        {
            if (parent) parent.removeChild(this, dispose);
        }


        /** Returns a rectangle that completely encloses the object as it appears in another
         *  coordinate system. If you pass a 'resultRectangle', the result will be stored in this
         *  rectangle instead of creating a new object. */
        public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            //throw new AbstractMethodError("Method needs to be implemented in subclass");
            Debug.assert(false, "Method needs to be implemented in subclass " + getTypeName() + " " + name );
            return null;
        }

        /** Returns the object that is found topmost beneath a point in local coordinates, or nil if
         *  the test fails. If "forTouch" is true, untouchable and invisible objects will cause
         *  the test to fail. */
        public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
            if (forTouch && (!visible || !touchable)) return null;

            if(!hasVisibleArea) return null;

            // otherwise, check bounding box
            if (getBounds(this, sHelperRect).containsPoint(localPoint)) return this;
            else return null;
        }

        /** Transforms a point from the local coordinate system to global (stage) coordinates.*/
        public function localToGlobal(localPoint:Point):Point
        {
            getTargetTransformationMatrix(base, sHelperMatrix);
            return sHelperMatrix.transformCoord(localPoint.x, localPoint.y);
        }

        /** Transforms a point from global (stage) coordinates to the local coordinate system. */
        public function globalToLocal(globalPoint:Point):Point
        {
            getTargetTransformationMatrix(base, sHelperMatrix);
            sHelperMatrix.invert();
            return sHelperMatrix.transformCoord(globalPoint.x, globalPoint.y);
        }

        /** Indicates if an object occupies any visible area. (Which is the case when its 'alpha',
         *  'scaleX' and 'scaleY' values are not zero, and its 'visible' property is enabled.) */
        public function get hasVisibleArea():Boolean
        {
            return (ignoreHitTestAlpha || alpha > 0.0) && visible && (scaleX != 0.0) && (scaleY != 0.0);
        }

        // internal methods

        /** @private */
        public function setParent(value:DisplayObjectContainer):void
        {
            // check for a recursion
            var ancestor:DisplayObject = value;
            while (ancestor != this && ancestor != null)
                ancestor = ancestor.parent;

            _globalStageGeneration++;
            
            Debug.assert(ancestor != this, "An object cannot be added as a child to itself or one " +
                                        "of its children (or children's children, etc.)");

            parent = value;
        }

        // helpers

        // properties

        /** The transformation matrix of the object relative to its parent.
         *
         *  If you assign a custom transformation matrix, Starling will try to figure out
         *  suitable values for `x, y, scaleX, scaleY,` and `rotation`.
         *  However, if the matrix was created in a different way, this might not be possible.
         *  In that case, Starling will apply the matrix, but not update the corresponding
         *  properties.
         *
         *  @returns CAUTION: not a copy, but the actual object! */

        public native function get transformationMatrix():Matrix;
        public native function set transformationMatrix(matrix:Matrix):void;

        /** Indicates if the mouse cursor should transform into a hand while it's over the sprite.
         *  @default false */
/*        public function get useHandCursor():Boolean { return mUseHandCursor; }
        public function set useHandCursor(value:Boolean):void
        {
            if (value == mUseHandCursor) return;
            mUseHandCursor = value;

            if (mUseHandCursor)
                addEventListener(TouchEvent.TOUCH, onTouch);
            else
                removeEventListener(TouchEvent.TOUCH, onTouch);
        }

        private function onTouch(event:TouchEvent):void
        {
            Mouse.cursor = event.interactsWith(this) ? MouseCursor.BUTTON : MouseCursor.AUTO;
        } */

        /** The bounds of the object relative to the local coordinates of the parent. */
        public function get bounds():Rectangle
        {
            return getBounds(parent);
        }

        /** The width of the object in pixels. */
        public function get width():Number { return getBounds(parent, sHelperRect).width; }
        public function set width(value:Number):void
        {
            // this method calls 'this.scaleX' instead of changing mScaleX directly.
            // that way, subclasses reacting on size changes need to override only the scaleX method.

            scaleX = 1.0;
            var actualWidth:Number = width;
            if (actualWidth != 0.0) scaleX = value / actualWidth;
        }

        /** The height of the object in pixels. */
        public function get height():Number
        {
            return getBounds(parent, sHelperRect).height;
        }

        public function set height(value:Number):void
        {
            scaleY = 1.0;
            var actualHeight:Number = height;
            if (actualHeight != 0.0) scaleY = value / actualHeight;
        }

        /** General scale factor. '1' means no scale, negative values flip the object. Use this
         *  when setting scaleX/scaleY explicitly is too verbose. */
        public native function set scale(value:Number):void;

        // gets the average of scaleX and scaleY
        public native function get scale():Number;


        /** The filter that is attached to the display object. The starling.filters
         *  package contains several classes that define specific filters you can use.
         *  Beware that you should NOT use the same filter on more than one object (for
         *  performance reasons). */
        /*public function get filter():FragmentFilter { return mFilter; }
        public function set filter(value:FragmentFilter):void { mFilter = value; } */


        /** The topmost object in the display tree the object is part of. */
        public function get base():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.parent) currentObject = currentObject.parent;
            return currentObject;
        }

        /** The root object the display object is connected to (ie: an instance of the class
         *  that was passed to the Starling constructor), or null if the object is not connected
         *  to the stage. */
        public function get root():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.parent)
            {
                if (currentObject.parent is Stage) return currentObject;
                else currentObject = currentObject.parent;
            }

            return null;
        }

        /** The stage the display object is connected to, or null if it is not connected
         *  to the stage. */
        public function get stage():Stage
        {
            if (_cachedStageGeneration != _globalStageGeneration) {
                var p = this;
                while (p.parentCached && !p._cachedStage) {
                    p = p.parentCached;
                }
                _cachedStage = p.parentCached ? p._cachedStage : p as Stage;
                _cachedStageGeneration = _globalStageGeneration;
            }
            return _cachedStage;
        }

        /**
         * Handle LML node initialization.
         * @param   id
         */
        public function initializeLMLNode(id:String):void
        {
            // Nothing required here; subclasses may want it.
        }

        /**
         * Pre-initialize the LML node.
         * @param   id
         */
        public function preinitializeLMLNode(id:String):void
        {
            name = id;
        }

        /**
         * The style name used by the CSS system.
         */
        public function get styleName():String
        {
            return _styleName;
        }

        public function set styleName(value:String):void
        {
            var names:Vector.<String> = value.split(" ");
            _styleName = "";
            for (var i = 0; i < names.length; i++)
            {
                var name = names[i];
                if (name && name.length > 0)
                {
                    if (_styleName.length > 0)
                        _styleName += " ";
                    _styleName += "#" + name;
                }
            }
            if(_styleSheet)
                applyStyle(_styleSheet);
        }

        /**
         * Helper function to apply a StyleSheet to this instance.
         * @param   styleSheet Style sheet to apply.
         */
        protected function applyStyle(styleSheet:StyleSheet):void
        {
            _styleSheet = styleSheet;

            var styleString = this.getType().getFullName();

            if(_styleName)
                styleString += " " + _styleName;

            if(name)
                styleString += " ." + name;

            // lookup styles based on stylename
            var style = _styleSheet.getStyle(styleString);

            // apply style
            styleApplicator.applyStyle(this, style);
        }
    }
}
