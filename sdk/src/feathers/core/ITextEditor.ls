/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
	import loom2d.math.Point;
	import loom.platform.LoomKeyboardType;

	/**
	 * Dispatched when the text property changes.
	 */
	[Event(name="change",type="loom2d.events.Event")]

	/**
	 * Dispatched when the user presses the Enter key while the editor has focus.
	 *
	 * @eventType feathers.events.FeathersEventType.ENTER
	 */
	[Event(name="enter",type="loom2d.events.Event")]

	/**
	 * Dispatched when the text editor receives focus.
	 *
	 * @eventType feathers.events.FeathersEventType.FOCUS_IN
	 */
	[Event(name="focusIn",type="loom2d.events.Event")]

	/**
	 * Dispatched when the text editor loses focus.
	 *
	 * @eventType feathers.events.FeathersEventType.FOCUS_OUT
	 */
	[Event(name="focusOut",type="loom2d.events.Event")]

	/**
	 * Handles the editing of text.
	 *
	 * @see feathers.controls.TextInput
	 * @see http://wiki.starling-framework.org/feathers/text-editors
	 */
	public interface ITextEditor extends IFeathersControl
	{
		/**
		 * The text displayed by the editor.
		 */
		function get text():String;

		/**
		 * @private
		 */
		function set text(value:String):void;

		/**
		 * Determines if the entered text will be masked so that it cannot be
		 * seen, such as for a password input.
		 */
		function get displayAsPassword():Boolean;

		/**
		 * @private
		 */
		function set displayAsPassword(value:Boolean):void;

		/**
		 * The maximum number of characters that may be entered.
		 */
		function get maxChars():int;

		/**
		 * @private
		 */
		function set maxChars(value:int):void;

		/**
		 * Limits the set of characters that may be entered.
		 */
		function get restrict():String;

		/**
		 * @private
		 */
		function set restrict(value:String):void;

		/**
		 * Determines if the text is editable.
		 */
		function get isEditable():Boolean;

		/**
		 * @private
		 */
		function set isEditable(value:Boolean):void;

		/**
		 * Determines the type of keyboard opened when focus is gained.
		 */
		function get keyboardType():LoomKeyboardType;

		/**
		 * @private
		 */
		function set keyboardType(value:LoomKeyboardType):void;

		/**
		 * Determines if the owner should call `setFocus()` on
		 * `TouchPhase.ENDED` or on `TouchPhase.BEGAN`.
		 * This is a hack because `StageText` doesn't like being
		 * assigned focus on `TouchPhase.BEGAN`. In general, most
		 * text editors should simply return `false`.
		 *
		 * @see #setFocus()
		 */
		function get setTouchFocusOnEndedPhase():Boolean;

		/**
		 * Gives focus to the text editor. Includes an optional position which
		 * may be used by the text editor to determine the cursor position. The
		 * position may be outside of the editors bounds.
		 */
		function setFocus():void;

		/**
		 * Removes focus from the text editor.
		 */
		function clearFocus():void;

		/**
		 * Sets the range of selected characters. If both values are the same,
		 * the text insertion position is changed and nothing is selected.
		 */
		function selectRange(startIndex:int, endIndex:int):void;

		/**
		 * Measures the text's bounds (without a full validation, if
		 * possible).
		 */
		function measureText():Point;
	}
}
