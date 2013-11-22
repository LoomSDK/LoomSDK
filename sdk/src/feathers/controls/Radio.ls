/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.IGroupedToggle;
    import feathers.core.ToggleGroup;

    import system.errors.IllegalOperationError;

    import loom2d.events.Event;

    [Exclude(name="isToggle",kind="property")]

    /**
     * A toggleable control that exists in a set that requires a single,
     * exclusive toggled item.
     *
     * In the following example, a set of radios are created, along with a
     * toggle group to group them together:
     *
     * ~~~as3
     * var group:ToggleGroup = new ToggleGroup();
     * group.addEventListener( Event.CHANGE, group_changeHandler );
     *
     * var radio1:Radio = new Radio();
     * radio1.label = "One";
     * radio1.toggleGroup = group;
     * this.addChild( radio1 );
     *
     * var radio2:Radio = new Radio();
     * radio2.label = "Two";
     * radio2.toggleGroup = group;
     * this.addChild( radio2 );
     *
     * var radio3:Radio = new Radio();
     * radio3.label = "Three";
     * radio3.toggleGroup = group;
     * this.addChild( radio3 );
         * ~~~
     *
     * @see http://wiki.starling-framework.org/feathers/radio
     * @see feathers.core.ToggleGroup
     */
    public class Radio extends Button implements IGroupedToggle
    {
        /**
         * If a `Radio` has not been added to a `ToggleGroup`,
         * it will automatically be added to this group. If the Radio's
         * `toggleGroup` property is set to a different group, it
         * will be automatically removed from this group, if required.
         */
        public static const defaultRadioGroup:ToggleGroup = new ToggleGroup();

        /**
         * Constructor.
         */
        public function Radio()
        {
            super.isToggle = true;
            this.addEventListener(Event.ADDED_TO_STAGE, radio_addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, radio_removedFromStageHandler);
        }

        /**
         * @private
         */
        override public function set isToggle(value:Boolean):void
        {
            throw IllegalOperationError("Radio isToggle must always be true.");
        }

        /**
         * @private
         */
        protected var _toggleGroup:ToggleGroup;

        /**
         * @inheritDoc
         */
        public function get toggleGroup():ToggleGroup
        {
            return this._toggleGroup;
        }

        /**
         * @private
         */
        public function set toggleGroup(value:ToggleGroup):void
        {
            if(this._toggleGroup == value)
            {
                return;
            }
            if(!value && this.stage)
            {
                value = defaultRadioGroup;
            }
            if(this._toggleGroup && this._toggleGroup.hasItem(this))
            {
                this._toggleGroup.removeItem(this);
            }
            this._toggleGroup = value;
            if(!this._toggleGroup.hasItem(this))
            {
                this._toggleGroup.addItem(this);
            }
        }

        /**
         * @private
         */
        protected function radio_addedToStageHandler(event:Event):void
        {
            if(!this._toggleGroup)
            {
                this.toggleGroup = defaultRadioGroup;
            }
        }

        /**
         * @private
         */
        protected function radio_removedFromStageHandler(event:Event):void
        {
            if(this._toggleGroup == defaultRadioGroup)
            {
                this._toggleGroup.removeItem(this);
            }
        }
    }
}
