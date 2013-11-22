/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.core.IFeathersControl;
    import feathers.events.FeathersEventType;

    import system.errors.IllegalOperationError;
    import loom2d.math.Rectangle;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.ResizeEvent;
    import loom2d.Loom2D;

    /**
     * Dispatched when the active screen changes.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Dispatched when the current screen is removed and there is no active
     * screen.
     *
     * @eventType feathers.events.FeathersEventType.CLEAR
     */
    [Event(name="clear",type="loom2d.events.Event")]

    /**
     * Dispatched when the transition between screens begins.
     *
     * @eventType feathers.events.FeathersEventType.TRANSITION_START
     */
    [Event(name="transitionStart",type="loom2d.events.Event")]

    /**
     * Dispatched when the transition between screens has completed.
     *
     * @eventType feathers.events.FeathersEventType.TRANSITION_COMPLETE
     */
    [Event(name="transitionComplete",type="loom2d.events.Event")]

    /**
     * A "view stack"-like container that supports navigation between screens
     * (any display object) through events.
     *
     * @see http://wiki.starling-framework.org/feathers/screen-navigator
     * @see http://wiki.starling-framework.org/feathers/transitions
     * @see feathers.controls.ScreenNavigatorItem
     */
    public class ScreenNavigator extends FeathersControl
    {
        /**
         * The screen navigator will auto size itself to fill the entire stage.
         *
         * @see #autoSizeMode
         */
        public static const AUTO_SIZE_MODE_STAGE:String = "stage";

        /**
         * The screen navigator will auto size itself to fit its content.
         *
         * @see #autoSizeMode
         */
        public static const AUTO_SIZE_MODE_CONTENT:String = "content";

        /**
         * @private
         */
        protected static var SIGNAL_TYPE:Type;

        /**
         * The default transition function.
         */
        protected static function defaultTransition(oldScreen:DisplayObject, newScreen:DisplayObject, completeCallback:Function):void
        {
            //in short, do nothing
            if(completeCallback)
                completeCallback();
        }
        
        public var autoDisposeScreens:Boolean = true;

        /**
         * Constructor.
         */
        public function ScreenNavigator()
        {
            super();
            /*if(!SIGNAL_TYPE)
            {
                try
                {
                    SIGNAL_TYPE = Class(getDefinitionByName("org.osflash.signals.ISignal"));
                }
                catch(error:Error)
                {
                    //signals not being used
                }
            } */
            this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
        }

        /**
         * @private
         */
        protected var _activeScreenID:String;

        /**
         * The string identifier for the currently active screen.
         */
        public function get activeScreenID():String
        {
            return this._activeScreenID;
        }

        /**
         * @private
         */
        protected var _activeScreen:DisplayObject;

        /**
         * A reference to the currently active screen.
         */
        public function get activeScreen():DisplayObject
        {
            return this._activeScreen;
        }

        /**
         * @private
         */
        protected var _clipContent:Boolean = false;

        /**
         * Determines if the navigator's content should be clipped to the width
         * and height.
         */
        public function get clipContent():Boolean
        {
            return this._clipContent;
        }

        /**
         * @private
         */
        public function set clipContent(value:Boolean):void
        {
            if(this._clipContent == value)
            {
                return;
            }
            this._clipContent = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * A function that is called when the `ScreenNavigator` is
         * changing screens that is intended to display a transition effect and
         * to notify the `ScreenNavigator` when the effect is
         * finished.
         *
         * The function should have the following signature:

         * `function(oldScreen:DisplayObject, newScreen:DisplayObject, completeCallback:Function):void`

         *
         * Either of the `oldScreen` and `newScreen`
         * arguments may be `null`, but never both. The
         * `oldScreen` argument will be `null` when the
         * first screen is displayed or when a new screen is displayed after
         * clearing the screen. The `newScreen` argument will
         * be null when clearing the screen.
         *
         * The `completeCallback` function _must_ be called
         * when the transition effect finishes. It takes zero arguments and
         * returns nothing. In other words, it has the following signature:
         *
         * `function():void`
         *
         * In the future, it may be possible for a transition to cancel
         * itself. If this happens, the `completeCallback` may begin
         * accepting arguments, but they will have default values and existing
         * uses of `completeCallback` should continue to work.
         *
         * @see #showScreen()
         * @see #clearScreen()
         * @see http://wiki.starling-framework.org/feathers/transitions
         */
        public var transition:Function = defaultTransition;

        /**
         * @private
         */
        protected var _screens:Dictionary.<String, ScreenNavigatorItem> = new Dictionary.<String, ScreenNavigatorItem>();

        /**
         * @private
         */
        protected var _screenEvents:Dictionary.<String, Object> = new Dictionary.<String, Object>();

        /**
         * @private
         */
        protected var _transitionIsActive:Boolean = false;

        /**
         * @private
         */
        protected var _previousScreenInTransitionID:String;

        /**
         * @private
         */
        protected var _previousScreenInTransition:DisplayObject;

        /**
         * @private
         */
        protected var _nextScreenID:String = null;

        /**
         * @private
         */
        protected var _clearAfterTransition:Boolean = false;

        /**
         * @private
         */
        protected var _autoSizeMode:String = AUTO_SIZE_MODE_STAGE;

        /**
         * Determines how the screen navigator will set its own size when its
         * dimensions (width and height) aren't set explicitly.
         *
         * @see #AUTO_SIZE_MODE_STAGE
         * @see #AUTO_SIZE_MODE_CONTENT
         */
        public function get autoSizeMode():String
        {
            return this._autoSizeMode;
        }

        /**
         * @private
         */
        public function set autoSizeMode(value:String):void
        {
            if(this._autoSizeMode == value)
            {
                return;
            }
            this._autoSizeMode = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * Displays a screen and returns a reference to it. If a previous
         * transition is running, the new screen will be queued, and no
         * reference will be returned.
         */
        public function showScreen(id:String):DisplayObject
        {
            var startTime = Platform.getTime();

            if(!this._screens[id])
            {
                throw new IllegalOperationError("Screen with id '" + id + "' cannot be shown because it has not been defined.");
            }

            if(this._activeScreenID == id)
            {
                return this._activeScreen;
            }

            if(this._transitionIsActive)
            {
                this._nextScreenID = id;
                this._clearAfterTransition = false;
                return null;
            }

            this._previousScreenInTransition = this._activeScreen;
            this._previousScreenInTransitionID = this._activeScreenID;
            if(this._activeScreen)
            {
                this.clearScreenInternal(false);
            }
            
            this._transitionIsActive = true;

            const item:ScreenNavigatorItem = ScreenNavigatorItem(this._screens[id]);
            this._activeScreen = item.getScreen();
            if(this._activeScreen is IScreen)
            {
                const screen:IScreen = IScreen(this._activeScreen);
                screen.screenID = id;
                screen.owner = this;
            }
            this._activeScreenID = id;

            const events:Dictionary.<String, Object> = item.events;
            const savedScreenEvents:Dictionary.<String, Object> = {};
            for(var eventName:String in events)
            {
                //var signal:Object = this._activeScreen.hasOwnProperty(eventName) ? (this._activeScreen[eventName] as SIGNAL_TYPE) : null;
                var eventAction:Object = events[eventName];
                if(eventAction is Function)
                {
                    //if(signal)
                    //{
                    //    signal.add(eventAction as Function);
                    //}
                    //else
                    //{
                        this._activeScreen.addEventListener(eventName, eventAction as Function);
                    //}
                }
                else if(eventAction is String)
                {
                    //if(signal)
                    //{
                    //    var eventListener:Function = this.createScreenSignalListener(eventAction as String, signal);
                    //    signal.add(eventListener);
                    //}
                    //else
                    //{
                        var eventListener:Function = this.createScreenEventListener(eventAction as String);
                        this._activeScreen.addEventListener(eventName, eventListener);
                    //}
                    savedScreenEvents[eventName] = eventListener;
                }
                else
                {
                    throw new TypeError("Unknown event action defined for screen:" + eventAction.toString());
                }
            }

            this._screenEvents[id] = savedScreenEvents;

            this.addChild(this._activeScreen);

            this.invalidate(INVALIDATION_FLAG_SELECTED);
            if(!VALIDATION_QUEUE.isValidating)
            {
                //force a COMPLETE validation of everything
                //but only if we're not already doing that...
                VALIDATION_QUEUE.process();
            }

            this.dispatchEventWith(FeathersEventType.TRANSITION_START);
            this.transition.call(null, this._previousScreenInTransition, this._activeScreen, transitionComplete);

            this.dispatchEventWith(Event.CHANGE);

            trace("Switched screen in " + (Platform.getTime() - startTime) + "ms");
            //VM.getExecutingVM().dumpManagedNatives();

            return this._activeScreen;
        }

        /**
         * Removes the current screen, leaving the `ScreenNavigator`
         * empty.
         */
        public function clearScreen():void
        {
            if(this._transitionIsActive)
            {
                this._nextScreenID = null;
                this._clearAfterTransition = true;
                return;
            }

            this.clearScreenInternal(true);
            this.dispatchEventWith(FeathersEventType.CLEAR);
        }

        /**
         * @private
         */
        protected function clearScreenInternal(displayTransition:Boolean):void
        {
            if(!this._activeScreen)
            {
                //no screen visible.
                return;
            }

            const item:ScreenNavigatorItem = ScreenNavigatorItem(this._screens[this._activeScreenID]);
            const events:Dictionary.<String, Object> = item.events;
            const savedScreenEvents:Dictionary.<String, Object> = this._screenEvents[this._activeScreenID] as Dictionary.<String, Object>;
            for(var eventName:String in events)
            {
                var signal:Object = this._activeScreen.hasOwnProperty(eventName) ? (this._activeScreen[eventName] as SIGNAL_TYPE) : null;
                var eventAction:Object = events[eventName];
                if(eventAction is Function)
                {
                    /*if(signal)
                    {
                        signal.remove(eventAction as Function);
                    }
                    else
                    {*/
                        this._activeScreen.removeEventListener(eventName, eventAction as Function);
                    //}
                }
                else if(eventAction is String)
                {
                    var eventListener:Function = savedScreenEvents[eventName] as Function;
                    /*if(signal)
                    {
                        signal.remove(eventListener);
                    }
                    else
                    {*/
                        this._activeScreen.removeEventListener(eventName, eventListener);
                    //}
                }
            }

            if(displayTransition)
            {
                this._transitionIsActive = true;
                this._previousScreenInTransition = this._activeScreen;
                this._previousScreenInTransitionID = this._activeScreenID;
            }
            this._screenEvents[this._activeScreenID] = null;
            this._activeScreen = null;
            this._activeScreenID = null;
            if(displayTransition)
            {
                this.transition.call(null, this._previousScreenInTransition, null, transitionComplete);
            }
            this.invalidate(INVALIDATION_FLAG_SELECTED);
        }

        /**
         * Registers a new screen by its identifier.
         */
        public function addScreen(id:String, item:ScreenNavigatorItem):void
        {
            if(this._screens[id] != null)
            {
                throw new IllegalOperationError("Screen with id '" + id + "' already defined. Cannot add two screens with the same id.");
            }

            this._screens[id] = item;
        }

        /**
         * Removes an existing screen using its identifier.
         */
        public function removeScreen(id:String):void
        {
            if(this._screens[id] == null)
            {
                throw new IllegalOperationError("Screen '" + id + "' cannot be removed because it has not been added.");
            }
            //delete this._screens[id];
            this._screens[id] = null;
        }

        /**
         * Removes all screens.
         */
        public function removeAllScreens():void
        {
            this.clearScreen();
            for(var id:String in this._screens)
            {
                //delete this._screens[id];
                this._screens[id] = null;
            }
        }

        /**
         * Determines if the specified screen identifier has been added.
         */
        public function hasScreen(id:String):Boolean
        {
            return this._screens[id] != null;
        }

        /**
         * Returns the `ScreenNavigatorItem` instance with the
         * specified identifier.
         */
        public function getScreen(id:String):ScreenNavigatorItem
        {
            if(this._screens[id] == null)
            {
                return ScreenNavigatorItem(this._screens[id]);
            }
            return null;
        }

        /**
         * Returns a list of the screen identifiers that have been added.
         */
        public function getScreenIDs(result:Vector.<String> = null):Vector.<String>
        {
            if(!result)
            {
                result = new <String>[];
            }

            for(var id:String in this._screens)
            {
                result.push(id);
            }
            return result;
        }

        /**
         * @private
         */
        override public function dispose():void
        {
            this.clearScreenInternal(false);
            super.dispose();
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const selectionInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SELECTED);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(sizeInvalid || selectionInvalid)
            {
                if(this._activeScreen)
                {
                    this._activeScreen.width = this.actualWidth;
                    this._activeScreen.height = this.actualHeight;
                }
            }

            if(stylesInvalid || sizeInvalid)
            {
                if(this._clipContent)
                {
                    var clipRect:Rectangle = this.clipRect;
                    if(!clipRect)
                    {
                        clipRect = new Rectangle();
                    }
                    clipRect.width = this.actualWidth;
                    clipRect.height = this.actualHeight;
                    this.clipRect = clipRect;
                }
                else
                {
                    this.clipRect = null;
                }
            }
        }

        /**
         * @private
         */
        protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }

            if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT &&
                this._activeScreen is IFeathersControl)
            {
                IFeathersControl(this._activeScreen).validate();
            }

            var newWidth:Number = this.explicitWidth;
            if(needsWidth)
            {
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    newWidth = this._activeScreen ? this._activeScreen.width : 0;
                }
                else
                {
                    newWidth = this.stage.stageWidth;
                }
            }

            var newHeight:Number = this.explicitHeight;
            if(needsHeight)
            {
                if(this._autoSizeMode == AUTO_SIZE_MODE_CONTENT)
                {
                    newHeight = this._activeScreen ? this._activeScreen.height : 0;
                }
                else
                {
                    newHeight = this.stage.stageHeight;
                }
            }

            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function transitionComplete():void
        {
            this._transitionIsActive = false;
            if(this._previousScreenInTransition)
            {
                const item:ScreenNavigatorItem = this._screens[this._previousScreenInTransitionID];
                
                if ( item )
                {
                    const canBeDisposed:Boolean = autoDisposeScreens && (item.screen is DisplayObject);
                    if(this._previousScreenInTransition is IScreen)
                    {
                        const screen:IScreen = IScreen(this._previousScreenInTransition);
                        screen.screenID = null;
                        screen.owner = null;
                    }

                    trace("*** REMOVING CHILD " + _previousScreenInTransition + " canBeDisposed=" + canBeDisposed);
                    this.removeChild(this._previousScreenInTransition, false);

                    if(canBeDisposed)
                    {
                        Loom2D.juggler.delayCall(function(item:DisplayObject):void {
                            item.dispose();
                            trace("Cleaned up old screen");
                            }, 0.1, this._previousScreenInTransition);
                    }
                }
                
                this._previousScreenInTransition = null;
                this._previousScreenInTransitionID = null;
            }

            if(this._clearAfterTransition)
            {
                this.clearScreen();
            }
            else if(this._nextScreenID)
            {
                this.showScreen(this._nextScreenID);
            }

            this._nextScreenID = null;
            this._clearAfterTransition = false;
            
            this.dispatchEventWith(FeathersEventType.TRANSITION_COMPLETE);
        }

        /**
         * @private
         */
        protected function createScreenEventListener(screenID:String):Function
        {
            const self:ScreenNavigator = this;
            const eventListener:Function = function(event:Event):void
            {
                self.showScreen(screenID);
            };

            return eventListener;
        }

        /**
         * @private
         */
        protected function createScreenSignalListener(screenID:String, signal:Object):Function
        {
            const self:ScreenNavigator = this;
            Debug.assert(false, "Signals are not supported.");
            /*if(signal.valueClasses.length == 1)
            {
                //shortcut to avoid the allocation of the rest array
                var signalListener:Function = function(arg0:Object):void
                {
                    self.showScreen(screenID);
                };
            }
            else
            {
                signalListener = function(...rest:Array):void
                {
                    self.showScreen(screenID);
                };
            }
            return signalListener;
            */

            return null;
        }

        /**
         * @private
         */
        protected function addedToStageHandler(event:Event):void
        {
            this.stage.addEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
        }

        /**
         * @private
         */
        protected function removedFromStageHandler(event:Event):void
        {
            this.stage.removeEventListener(ResizeEvent.RESIZE, stage_resizeHandler);
        }

        /**
         * @private
         */
        protected function stage_resizeHandler(event:ResizeEvent):void
        {
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }
    }

}