/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.motion.transitions
{
	import feathers.controls.ScreenNavigator;
	import feathers.controls.TabBar;

	import loom2d.animation.Transitions;
	import loom2d.animation.Tween;
	import loom2d.Loom2D;
	import loom2d.display.DisplayObject;
	import loom2d.events.Event;

	/**
	 * Slides new screens from the left or right depending on the old and new
	 * selected index values of a TabBar control.
	 *
	 * @see feathers.controls.ScreenNavigator
	 * @see feathers.controls.TabBar
	 */
	public class TabBarSlideTransitionManager
	{
		/**
		 * Constructor.
		 */
		public function TabBarSlideTransitionManager(navigator:ScreenNavigator, tabBar:TabBar)
		{
			if(!navigator)
			{
				throw new ArgumentError("ScreenNavigator cannot be null.");
			}
			this.navigator = navigator;
			this.tabBar = tabBar;
			this._oldIndex = tabBar.selectedIndex;
			this.tabBar.addEventListener(Event.CHANGE, tabBar_changeHandler);
			this.navigator.transition = this.onTransition;
		}

		/**
		 * The `ScreenNavigator` being managed.
		 */
		protected var navigator:ScreenNavigator;

		/**
		 * The `TabBar` that controls the navigation.
		 */
		protected var tabBar:TabBar;

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
		 * @private
		 */
		protected var _oldScreen:DisplayObject;

		/**
		 * @private
		 */
		protected var _newScreen:DisplayObject;

		/**
		 * @private
		 */
		protected var _oldIndex:int;

		/**
		 * @private
		 */
		protected var _isFromRight:Boolean = true;

		/**
		 * @private
		 */
		protected var _isWaitingOnTabBarChange:Boolean = true;

		/**
		 * @private
		 */
		protected var _isWaitingOnTransitionChange:Boolean = true;

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
			this._oldScreen = oldScreen;
			this._newScreen = newScreen;
			this._savedCompleteHandler = onComplete;

			if(!this._isWaitingOnTabBarChange)
			{
				this.transitionNow();
			}
			else
			{
				this._isWaitingOnTransitionChange = false;
			}
		}

		/**
		 * @private
		 */
		protected function transitionNow():void
		{
			if(this._activeTransition)
			{
				this._savedOtherTarget  = null;
				Loom2D.juggler.remove(this._activeTransition);
				this._activeTransition = null;
			}

			if(!this._oldScreen || !this._newScreen || this.skipNextTransition)
			{
				this.skipNextTransition = false;
				const savedCompleteHandler:Function = this._savedCompleteHandler;
				this._savedCompleteHandler = null;
				if(this._oldScreen)
				{
					this._oldScreen.x = 0;
				}
				if(this._newScreen)
				{
					this._newScreen.x = 0;
				}
				if(savedCompleteHandler != null)
				{
					savedCompleteHandler.call();
				}
			}
			else
			{
				this._oldScreen.x = 0;
				var activeTransition_onUpdate:Function;
				if(this._isFromRight)
				{
					this._newScreen.x = this.navigator.width;
					activeTransition_onUpdate = this.activeTransitionFromRight_onUpdate;
				}
				else
				{
					this._newScreen.x = -this.navigator.width;
					activeTransition_onUpdate = this.activeTransitionFromLeft_onUpdate;
				}
				this._savedOtherTarget = this._oldScreen;
				this._activeTransition = new Tween(this._newScreen, this.duration, this.ease);
				this._activeTransition.animate("x", 0);
				this._activeTransition.delay = this.delay;
				this._activeTransition.onUpdate = activeTransition_onUpdate;
				this._activeTransition.onComplete = activeTransition_onComplete;
				Loom2D.juggler.add(this._activeTransition);
			}

			this._oldScreen = null;
			this._newScreen = null;
			this._isWaitingOnTabBarChange = true;
			this._isWaitingOnTransitionChange = true;
		}

		/**
		 * @private
		 */
		protected function activeTransitionFromRight_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
				this._savedOtherTarget.x = newScreen.x - this.navigator.width;
			}
		}

		/**
		 * @private
		 */
		protected function activeTransitionFromLeft_onUpdate():void
		{
			if(this._savedOtherTarget)
			{
				const newScreen:DisplayObject = DisplayObject(this._activeTransition.target);
				this._savedOtherTarget.x = newScreen.x + this.navigator.width;
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

		/**
		 * @private
		 */
		protected function tabBar_changeHandler(event:Event):void
		{
			var newIndex:int = this.tabBar.selectedIndex;
			this._isFromRight = newIndex > this._oldIndex;
			this._oldIndex = newIndex;

			if(!this._isWaitingOnTransitionChange)
			{
				this.transitionNow();
			}
			else
			{
				this._isWaitingOnTabBarChange = false;
			}
		}
	}
}