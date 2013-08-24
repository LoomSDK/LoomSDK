/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.events
{
	/**
	 * Event `type` constants for Feathers controls. This class is
	 * not a subclass of `loom2d.events.Event` because these
	 * constants are meant to be used with `dispatchEventWith()` and
	 * take advantage of the Starling's event object pooling. The object passed
	 * to an event listener will be of type `loom2d.events.Event`.
	 */
	public class FeathersEventType
	{
		/**
		 * The `FeathersEventType.INITIALIZE` event type is meant to
		 * be used when an `IFeathersControl` has finished running
		 * its `initialize()` function.
		 */
		public static const INITIALIZE:String = "initialize";

		/**
		 * The `FeathersEventType.RESIZE` event type is meant to
		 * be used when an `IFeathersControl` has resized.
		 */
		public static const RESIZE:String = "resize";

		/**
		 * The `FeathersEventType.ENTER` event type is meant to
		 * be used when the enter key has been pressed in an input control.
		 */
		public static const ENTER:String = "enter";

		/**
		 * The `FeathersEventType.CLEAR` event type is a generic
		 * event type for when something is "cleared".
		 */
		public static const CLEAR:String = "clear";

		/**
		 * The `FeathersEventType.SCROLL_START` event type is used
		 * when a control starts scrolling in either direction as a result of
		 * either user interaction or animation.
		 */
		public static const SCROLL_START:String = "scrollStart";

		/**
		 * The `FeathersEventType.SCROLL_COMPLETE` event type is used
		 * when a control finishes scrolling in either direction as a result of
		 * either user interaction or animation.
		 */
		public static const SCROLL_COMPLETE:String = "scrollComplete";

		/**
		 * The `FeathersEventType.BEGIN_INTERACTION` event type is
		 * used by many UI controls where a drag or other interaction happens
		 * over time. An example is a `Slider` control where the
		 * user touches the thumb to begin dragging.
		 */
		public static const BEGIN_INTERACTION:String = "beginInteraction";

		/**
		 * The `FeathersEventType.END_INTERACTION` event type is
		 * used by many UI controls where a drag or other interaction happens
		 * over time. An example is a `Slider` control where the
		 * user stops touching the thumb after dragging.
		 *
		 * Depending on the control, the result of the interaction may
		 * continue after the interaction ends. For instance, a `Scroller`
		 * may be "thrown", and the scrolling will continue animating after the
		 * user has finished interacting with it.
		 */
		public static const END_INTERACTION:String = "endInteraction";

		/**
		 * The `FeathersEventType.TRANSITION_START` event type is
		 * used by the `ScreenNavigator` to indicate when a
		 * transition between screens begins.
		 */
		public static const TRANSITION_START:String = "transitionStart";

		/**
		 * The `FeathersEventType.TRANSITION_COMPLETE` event type is
		 * used by the `ScreenNavigator` to indicate when a
		 * transition between screens ends.
		 */
		public static const TRANSITION_COMPLETE:String = "transitionComplete";

		/**
		 * The `FeathersEventType.FOCUS_IN` event type is used by
		 * Feathers components to indicate when they have received focus.
		 */
		public static const FOCUS_IN:String = "focusIn";

		/**
		 * The `FeathersEventType.FOCUS_OUT` event type is used by
		 * Feathers components to indicate when they have lost focus.
		 */
		public static const FOCUS_OUT:String = "focusOut";

		/**
		 * The `FeathersEventType.RENDERER_ADD` event type is used by
		 * Feathers components with item renderers to indicate when a new
		 * renderer has been added. This event type is meant to be used with
		 * virtualized layouts where only a limited set of renderers will be
		 * created for a data provider that may include a larger number of items.
		 */
		public static const RENDERER_ADD:String = "rendererAdd";

		/**
		 * The `FeathersEventType.RENDERER_REMOVE` event type is used
		 * by Feathers controls with item renderers to indicate when a renderer
		 * is removed. This event type is meant to be used with virtualized
		 * layouts where only a limited set of renderers will be created for
		 * a data provider that may include a larger number items.
		 */
		public static const RENDERER_REMOVE:String = "rendererRemove";

		/**
		 * The `FeathersEventType.ERROR` event type is used by
		 * Feathers controls when an error occurs that can be caught and
		 * safely ignored.
		 */
		public static const ERROR:String = "error";

		/**
		 * The `FeathersEventType.LAYOUT_DATA_CHANGE` event type is
		 * used by Feathers controls when their layout data has changed.
		 */
		public static const LAYOUT_DATA_CHANGE:String = "layoutDataChange";
	}
}
