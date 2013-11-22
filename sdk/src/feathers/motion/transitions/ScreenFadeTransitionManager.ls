/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.motion.transitions
{
    import feathers.controls.ScreenNavigator;

    import loom2d.animation.Transitions;
    import loom2d.animation.Tween;
    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;

    /**
     * A transition for `ScreenNavigator` that fades out the old
     * screen and fades in the new screen.
     *
     * @see feathers.controls.ScreenNavigator
     */
    public class ScreenFadeTransitionManager
    {
        /**
         * Constructor.
         */
        public function ScreenFadeTransitionManager(navigator:ScreenNavigator)
        {
            if(!navigator)
            {
                throw new ArgumentError("ScreenNavigator cannot be null.");
            }
            this.navigator = navigator;
            this.navigator.transition = this.onTransition;
        }

        /**
         * The `ScreenNavigator` being managed.
         */
        protected var navigator:ScreenNavigator;

        /**
         * @private
         */
        protected var _activeTransition:Tween;

        /**
         * @private
         */
        protected var _savedOtherTarget:DisplayObject;

        /**
         * @private
         */
        protected var _savedCompleteHandler:Function;
        
        /**
         * The duration of the transition, measured in seconds.
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
         * The function passed to the `transition` property of the
         * `ScreenNavigator`.
         */
        protected function onTransition(oldScreen:DisplayObject, newScreen:DisplayObject, onComplete:Function):void
        {
            if(!oldScreen && !newScreen)
            {
                throw new ArgumentError("Cannot transition if both old screen and new screen are null.");
            }

            if(this._activeTransition)
            {
                this._savedOtherTarget = null;
                this._activeTransition.advanceTime(this._activeTransition.totalTime);
                this._activeTransition = null;
            }

            if(this.skipNextTransition)
            {
                this.skipNextTransition = false;
                this._savedCompleteHandler = null;
                if(newScreen)
                {
                    newScreen.x = 0;
                    newScreen.alpha = 1;
                }
                if(onComplete != null)
                {
                    onComplete.call();
                }
                return;
            }
            
            this._savedCompleteHandler = onComplete;
            
            if(newScreen)
            {
                newScreen.alpha = 0;
                if(oldScreen) //oldScreen can be null, that's okay
                {
                    oldScreen.alpha = 1;
                }
                this._savedOtherTarget = oldScreen;
                this._activeTransition = new Tween(newScreen, this.duration, this.ease);
                this._activeTransition.fadeTo(1);
                this._activeTransition.delay = this.delay;
                this._activeTransition.onUpdate = activeTransition_onUpdate;
                this._activeTransition.onComplete = activeTransition_onComplete;
                Loom2D.juggler.add(this._activeTransition);
            }
            else //we only have the old screen
            {
                oldScreen.alpha = 1;
                this._activeTransition = new Tween(oldScreen, this.duration, this.ease);
                this._activeTransition.fadeTo(0);
                this._activeTransition.delay = this.delay;
                this._activeTransition.onComplete = activeTransition_onComplete;
                Loom2D.juggler.add(this._activeTransition);
            }
        }
        
        /**
         * @private
         */
        protected function activeTransition_onUpdate():void
        {
            if(this._savedOtherTarget)
            {
                const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
                this._savedOtherTarget.alpha = 1 - newScreen.alpha;
            }
        }
        
        /**
         * @private
         */
        protected function activeTransition_onComplete():void
        {
            this._savedOtherTarget = null;
            this._activeTransition = null;
            if(this._savedCompleteHandler != null)
            {
                this._savedCompleteHandler.call();
            }
        }
    }
}