/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.motion.transitions
{
    import feathers.controls.IScreen;
    import feathers.controls.ScreenNavigator;

    import loom2d.animation.Transitions;
    import loom2d.animation.Tween;
    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;

    /**
     * A transition for `ScreenNavigator` that fades out the old
     * screen and slides in the new screen from an edge. The slide starts from
     * the right or left, depending on if the manager determines that the
     * transition is a push or a pop.
     *
     * Whether a screen change is supposed to be a push or a pop is
     * determined automatically. The manager generates an identifier from the
     * fully-qualified class name of the screen, and if present, the
     * `screenID` defined by `IScreen` instances. If the
     * generated identifier is present on the stack, a screen change is
     * considered a pop. If the token is not present, it's a push. Screen IDs
     * should be tailored to this behavior to avoid false positives.
     *
     * If your navigation structure requires explicit pushing and popping, a
     * custom transition manager is probably better.
     *
     * @see feathers.controls.ScreenNavigator
     */
    public class OldFadeNewSlideTransitionManager
    {
        /**
         * Constructor.
         */
        public function OldFadeNewSlideTransitionManager(navigator:ScreenNavigator, quickStackScreenClass:Type = null, quickStackScreenID:String = null)
        {
            if(!navigator)
            {
                Debug.assert("ScreenNavigator cannot be null.");
            }
            this.navigator = navigator;
            var quickStack:String;
            if(quickStackScreenClass)
            {
                quickStack = quickStackScreenClass.getFullName();
            }
            if(quickStack && quickStackScreenID)
            {
                quickStack += "~" + quickStackScreenID;
            }
            if(quickStack)
            {
                this._stack.push(quickStack);
            }
            this.navigator.transition = this.onTransition;
        }

        /**
         * The `ScreenNavigator` being managed.
         */
        protected var navigator:ScreenNavigator;

        /**
         * @private
         */
        protected var _stack:Vector.<String> = new <String>[];

        /**
         * @private
         */
        protected var _activeTransition:Tween;

        /**
         * @private
         */
        protected var _savedCompleteHandler:Function;

        /**
         * @private
         */
        protected var _savedOtherTarget:DisplayObject;
        
        /**
         * The duration of the transition.
         */
        public var duration:Number = 0.25;

        /**
         * A delay before the transition starts, measured in seconds. This may
         * be required on low-end systems that will slow down for a short time
         * after heavy texture uploads.
         */
        public var delay:Number = 0.1;
        
        /**
         * The easing function to use.
         */
        public var ease:Object = Transitions.EASE_OUT;

        /**
         * Determines if the next transition should be skipped. After the
         * transition, this value returns to `false`.
         */
        public var skipNextTransition:Boolean = false;
        
        /**
         * Removes all saved classes from the stack that are used to determine
         * which side of the `ScreenNavigator` the new screen will
         * slide in from.
         */
        public function clearStack():void
        {
            this._stack.length = 0;
        }
        
        /**
         * The function passed to the `transition` property of the
         * `ScreenNavigator`.
         */
        protected function onTransition(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function):void
        {
            if(this._activeTransition)
            {
                Loom2D.juggler.remove(this._activeTransition);
                this._activeTransition = null;
                this._savedOtherTarget = null;
            }

            if(!oldScreen || this.skipNextTransition)
            {
                this.skipNextTransition = false;
                this._savedCompleteHandler = null;
                if(newScreen)
                {
                    newScreen.x = 0;
                }
                if(onComplete != null)
                {
                    onComplete.call();
                }
                return;
            }
            
            this._savedCompleteHandler = onComplete;
            
            if(!newScreen)
            {
                oldScreen.x = 0;
                this._activeTransition = new Tween(oldScreen, this.duration, this.ease);
                this._activeTransition.fadeTo(0);
                this._activeTransition.delay = this.delay;
                this._activeTransition.onComplete = activeTransition_onComplete;
                Loom2D.juggler.add(this._activeTransition);
                return;
            }
            var newScreenClassAndID:String = newScreen.getTypeName();
            if(newScreen is IScreen)
            {
                newScreenClassAndID += "~" + IScreen(newScreen).screenID;
            }
            var stackIndex:int = this._stack.indexOf(newScreenClassAndID);
            if(stackIndex < 0)
            {
                var oldScreenClassAndID:String = oldScreen.getTypeName();
                if(oldScreen is IScreen)
                {
                    oldScreenClassAndID += "~" + IScreen(oldScreen).screenID;
                }
                this._stack.push(oldScreenClassAndID);
                oldScreen.x = 0;
                newScreen.x = this.navigator.width;
            }
            else
            {
                this._stack.length = stackIndex;
                oldScreen.x = 0;
                newScreen.x = -this.navigator.width;
            }
            newScreen.alpha = 1;
            this._savedOtherTarget = oldScreen;
            this._activeTransition = new Tween(newScreen, this.duration, this.ease);
            this._activeTransition.animate("x", 0);
            this._activeTransition.delay = this.delay;
            this._activeTransition.onUpdate = activeTransition_onUpdate;
            this._activeTransition.onComplete = activeTransition_onComplete;
            Loom2D.juggler.add(this._activeTransition);
        }
        
        /**
         * @private
         */
        protected function activeTransition_onUpdate():void
        {
            if(this._savedOtherTarget)
            {
                this._savedOtherTarget.alpha = 1 - this._activeTransition.currentTime / this._activeTransition.totalTime;
            }
        }
        
        /**
         * @private
         */
        protected function activeTransition_onComplete():void
        {
            this._activeTransition = null;
            this._savedOtherTarget = null;
            if(this._savedCompleteHandler != null)
            {
                this._savedCompleteHandler.call();
            }
        }
    }
}