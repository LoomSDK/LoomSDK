/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{
	/**
	 * A toggle associated with a specific group.
	 *
	 * @see ToggleGroup
	 */
	public interface IGroupedToggle extends IToggle
	{
		/**
		 * When the toggle is added to a `ToggleGroup`, the group
		 * will manage the entire group's selection when one of the toggles in
		 * the group changes.
		 *
		 * In the following example, a `Radio` is added to a `ToggleGroup`:
		 *
		 * ~~~as3
		 * var group:ToggleGroup = new ToggleGroup();
		 * group.addEventListener( Event.CHANGE, group_changeHandler );
		 *
		 * var radio:Radio = new Radio();
		 * radio.toggleGroup = group;
		 * this.addChild( radio );
         * ~~~
		 */
		function get toggleGroup():ToggleGroup;

		/**
		 * @private
		 */
		function set toggleGroup(value:ToggleGroup):void;
	}
}
