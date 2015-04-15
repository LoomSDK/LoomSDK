/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.events.Event;

    /**
     * Watches a container on the display list. As new display objects are
     * added, and if they match a specific type, they will be passed to initializer
     * functions to set properties, call methods, or otherwise modify them.
     * Useful for initializing skins and styles on UI controls.
     *
     * In the example below, the `buttonInitializer()` function
     * will be called when a `Button` is added to the display list:
     *
     * ~~~as3
     * setInitializerForClass(Button, buttonInitializer);
     * ~~~
     *
     * However, initializers are not called for subclasses. If a
     * `Check` is added to the display list (`Check`
     * extends `Button`), the `buttonInitializer()`
     * function will not be called. This important restriction allows subclasses
     * to have different skins, for instance.
     *
     * You can target a specific subclass with the same initializer function
     * without adding it for all subclasses:
     *
     * ~~~as3
     * setInitializerForClass(Button, buttonInitializer);
     * setInitializerForClass(Check, buttonInitializer);
     * ~~~
     *
     * In this case, `Button` and `Check` will trigger
     * the `buttonInitializer()` function, but `Radio`
     * (another subclass of `Button`) will not.
     *
     * You can target a class and all of its subclasses, using a different
     * function. This is recommended only when you are absolutely sure that
     * no subclasses will need a separate initializer.
     *
     * ~~~as3
     * setInitializerForClassAndSubclasses(Button, buttonInitializer);
     * ~~~
     *
     * In this case, `Button`, `Check`, `Radio`
     * and every other subclass of `Button` (including any subclasses
     * that you create yourself) will trigger the `buttonInitializer()`
     * function.
     */
    public class DisplayListWatcher
    {
        /**
         * Constructor.
         *
         * @param topLevelContainer        The root display object to watch (not necessarily Starling's root object)
         */
        public function DisplayListWatcher(topLevelContainer:DisplayObjectContainer)
        {
            this.root = topLevelContainer;
            this.root.addEventListener(Event.ADDED, addedHandler);
        }

        /**
         * The minimum base class required before the AddedWatcher will check
         * to see if a particular display object has any initializers.
         */
        public var requiredBaseClass:Type = IFeathersControl;

        /**
         * Determines if only the object added should be processed or if its
         * children should be processed recursively.
         */
        public var processRecursively:Boolean = true;

        /**
         * @private
         * Tracks the objects that have been initialized. Uses weak keys so that
         * the tracked objects can be garbage collected.
         */
        protected var initializedObjects:Dictionary.<Object, Boolean> = new Dictionary.<Object, Boolean>(true);

        /**
         * @private
         */
        protected var _initializeOnce:Boolean = true;

        /**
         * Determines if objects added to the display list are initialized only
         * once or every time that they are re-added.
         */
        public function get initializeOnce():Boolean
        {
            return this._initializeOnce;
        }

        /**
         * @private
         */
        public function set initializeOnce(value:Boolean):void
        {
            if(this._initializeOnce == value)
            {
                return;
            }
            this._initializeOnce = value;
            if(value)
            {
                this.initializedObjects = new Dictionary.<Object, Boolean>(true);
            }
            else
            {
                this.initializedObjects = null;
            }
        }

        /**
         * The root of the display list that is watched for added children.
         */
        protected var root:DisplayObjectContainer;

        /**
         * @private
         */
        protected var _initializerNoNameTypeMap = new Dictionary.<Type, Function>(true);

        /**
         * @private
         */
        protected var _initializerNameTypeMap = new Dictionary.<Type, Dictionary.<String, Function>>(true);

        /**
         * @private
         */
        protected var _initializerSuperTypeMap = new Dictionary.<Type, Function>(true);

        /**
         * @private
         */
        protected var _initializerSuperTypes:Vector.<Type> = new <Type>[];

        /**
         * @private
         */
        protected var _excludedObjects:Vector.<DisplayObject>;

        /**
         * Stops listening to the root and cleans up anything else that needs to
         * be disposed. If a `DisplayListWatcher` is extended for a
         * theme, it should also dispose textures and other assets.
         */
        public function dispose():void
        {
            if(this.root)
            {
                this.root.removeEventListener(Event.ADDED, addedHandler);
                this.root = null;
            }
            if(this._excludedObjects)
            {
                this._excludedObjects.length = 0;
                this._excludedObjects = null;
            }
            for(var key:Object in this.initializedObjects)
            {
                // delete this.initializedObjects[key];
                this.initializedObjects[key] = null;
            }
            for(key in this._initializerNameTypeMap)
            {
                // delete this._initializerNameTypeMap[key];
                this._initializerNameTypeMap[key] = null;
            }
            for(key in this._initializerNoNameTypeMap)
            {
                // delete this._initializerNoNameTypeMap[key];
                this._initializerNoNameTypeMap[key] = null;
            }
            for(key in this._initializerSuperTypeMap)
            {
                // delete this._initializerSuperTypeMap[key];
                this._initializerSuperTypeMap[key] = null;
            }
            this._initializerSuperTypes.length = 0;
        }

        /**
         * Excludes a display object, and all if its children (if any) from
         * being watched.
         */
        public function exclude(target:DisplayObject):void
        {
            if(!this._excludedObjects)
            {
                this._excludedObjects = new <DisplayObject>[];
            }
            this._excludedObjects.push(target);
        }

        /**
         * Determines if an object is excluded from being watched.
         */
        public function isExcluded(target:DisplayObject):Boolean
        {
            if(!this._excludedObjects)
            {
                return false;
            }

            const objectCount:int = this._excludedObjects.length;
            for(var i:int = 0; i < objectCount; i++)
            {
                var object:DisplayObject = this._excludedObjects[i];
                if(object is DisplayObjectContainer)
                {
                    if(DisplayObjectContainer(object).contains(target))
                    {
                        return true;
                    }
                }
                else if(object == target)
                {
                    return true;
                }
            }
            return false;
        }

        /**
         * Sets the initializer for a specific class.
         */
        public function setInitializerForClass(type:Type, initializer:Function, withName:String = null):void
        {
            if(!withName)
            {
                this._initializerNoNameTypeMap[type] = initializer;
                return;
            }
            var nameTable:Dictionary.<String, Function> = _initializerNameTypeMap[type];
            if(!nameTable)
            {
                _initializerNameTypeMap[type] = nameTable = new Dictionary.<String, Function>();
            }
            nameTable[withName] = initializer;
        }

        /**
         * Sets an initializer for a specific class and any subclasses. This
         * option can potentially hurt performance, so use sparingly.
         */
        public function setInitializerForClassAndSubclasses(type:Type, initializer:Function):void
        {
            const index:int = this._initializerSuperTypes.indexOf(type);
            if(index < 0)
            {
                this._initializerSuperTypes.push(type);
            }
            this._initializerSuperTypeMap[type] = initializer;
        }

        /**
         * If an initializer exists for a specific class, it will be returned.
         */
        public function getInitializerForClass(type:Type, withName:String = null):Function
        {
            if(!withName)
            {
                return this._initializerNoNameTypeMap[type] as Function;
            }
            const nameTable:Dictionary.<String, Function> = _initializerNameTypeMap[type];
            if(!nameTable)
            {
                return null;
            }
            return nameTable[withName];
        }

        /**
         * If an initializer exists for a specific class and its subclasses, the initializer will be returned.
         */
        public function getInitializerForClassAndSubclasses(type:Type):Function
        {
            return this._initializerSuperTypeMap[type];
        }

        /**
         * If an initializer exists for a specific class, it will be removed
         * completely.
         */
        public function clearInitializerForClass(type:Type, withName:String = null):void
        {
            if(!withName)
            {
                //delete this._initializerNoNameTypeMap[type];
                this._initializerNoNameTypeMap[type] = null;
                return;
            }

            const nameTable:Dictionary.<String, Function> = _initializerNameTypeMap[type];
            if(!nameTable)
            {
                return;
            }

            //delete nameTable[withName];
            nameTable[withName] = null;
            return;
        }

        /**
         * If an initializer exists for a specific class and its subclasses, the
         * initializer will be removed completely.
         */
        public function clearInitializerForClassAndSubclasses(type:Type):void
        {
            //delete this._initializerSuperTypeMap[type];
            this._initializerSuperTypeMap[type] = null;
            const index:int = this._initializerSuperTypes.indexOf(type);
            if(index >= 0)
            {
                this._initializerSuperTypes.splice(index, 1);
            }
        }

        /**
         * @private
         */
        protected function processAllInitializers(target:DisplayObject):void
        {
            const superTypeCount:int = this._initializerSuperTypes.length;
            for(var i:int = 0; i < superTypeCount; i++)
            {
                var type:Type = this._initializerSuperTypes[i];
                if(target is type)
                {
                    this.applyAllStylesForTypeFromMaps(target, type, this._initializerSuperTypeMap);
                }
            }
            type = target.getType();
            this.applyAllStylesForTypeFromMaps(target, type, this._initializerNoNameTypeMap, this._initializerNameTypeMap);
        }

        /**
         * @private
         */
        protected function applyAllStylesForTypeFromMaps(target:DisplayObject, type:Type, map:Dictionary.<Type, Function>, nameMap:Dictionary.<Type, Dictionary.<String, Function>> = null):void
        {
            var initializer:Function;
            if(nameMap)
            {
                const nameTable:Dictionary.<String, Function> = nameMap[type];
                if(nameTable && target is IFeathersControl)
                {
                    const uiControl:IFeathersControl = IFeathersControl(target);
                    for(var name:String in nameTable)
                    {
                        if(!uiControl.nameList.contains(name))
                            continue;

                        initializer = nameTable[name];

                        if(initializer == null)
                            continue;

                        Debug.assert(target, "Trying to run initialize without target.");
                        initializer(target);
                        (uiControl as FeathersControl).invalidate();
                        return;
                    }
                }
            }

            initializer = map[type];
            if(initializer != null)
            {
                Debug.assert(target, "Trying to run initialize without target.");
                initializer.call(this, target);
                if(uiControl as FeathersControl)
                    (uiControl as FeathersControl).invalidate();
            }
        }

        /**
         * @private
         */
        protected function addObject(target:DisplayObject):void
        {
            //trace("considering " + target.toString() + " " + requiredBaseClass.getFullName() + " ");
            const targetAsRequiredBaseClass:DisplayObject = (target as IFeathersControl) as DisplayObject;
            if(targetAsRequiredBaseClass)
            {
                //trace(" - passed base class ");
                const isInitialized:Boolean = this._initializeOnce
                    && this.initializedObjects[targetAsRequiredBaseClass];

                if(!isInitialized)
                {
                    //trace("  - was not init'ed");
                    if(this.isExcluded(target))
                    {
                        //trace("   - excluded");
                        return;
                    }

                    this.initializedObjects[targetAsRequiredBaseClass] = true;
                    this.processAllInitializers(target);
                }
            }

            if(this.processRecursively)
            {
                //trace("  recursive process");
                const targetAsContainer:DisplayObjectContainer = target as DisplayObjectContainer;
                if(targetAsContainer)
                {
                    const childCount:int = targetAsContainer.numChildren;
                    for(var i:int = 0; i < childCount; i++)
                    {
                        var child:DisplayObject = targetAsContainer.getChildAt(i);
                        this.addObject(child);
                    }
                }
            }

            //trace("DONE");
        }

        /**
         * @private
         */
        protected function addedHandler(event:Event):void
        {
            //trace("Saw added object!");
            this.addObject(event.target as DisplayObject);
        }
    }
}
