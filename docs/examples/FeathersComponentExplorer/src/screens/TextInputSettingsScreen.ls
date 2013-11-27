/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package screens
{
    import feathers.controls.Button;
    import feathers.controls.List;
    import feathers.controls.NumericStepper;
    import feathers.controls.PanelScreen;
    import feathers.controls.ToggleSwitch;
    import feathers.data.ListCollection;
    import feathers.events.FeathersEventType;
    import data.TextInputSettings;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]

    public class TextInputSettingsScreen extends PanelScreen
    {
        public function TextInputSettingsScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        public var settings:TextInputSettings;

        private var _list:List;
        private var _backButton:Button;
        private var _isEditableToggle:ToggleSwitch;
        private var _displayAsPasswordToggle:ToggleSwitch;
        private var _maxCharsStepper:NumericStepper;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._isEditableToggle = new ToggleSwitch();
            this._isEditableToggle.isSelected = this.settings.isEditable;
            this._isEditableToggle.addEventListener(Event.CHANGE, isEditableToggle_changeHandler);

            this._displayAsPasswordToggle = new ToggleSwitch();
            this._displayAsPasswordToggle.isSelected = this.settings.displayAsPassword;
            this._displayAsPasswordToggle.addEventListener(Event.CHANGE, displayAsPasswordToggle_changeHandler);

            this._maxCharsStepper = new NumericStepper();
            this._maxCharsStepper.minimum = 0;
            //this is completely arbitrary. maxChars may be larger.
            this._maxCharsStepper.maximum = 99;
            this._maxCharsStepper.step = 1;
            this._maxCharsStepper.value = this.settings.maxChars;
            this._maxCharsStepper.addEventListener(Event.CHANGE, maxCharsStepper_changeHandler);

            this._list = new List();
            this._list.isSelectable = false;
            this._list.dataProvider = new ListCollection(
            [
                { label: "isEditable", accessory: this._isEditableToggle },
                { label: "displayAsPassword", accessory: this._displayAsPasswordToggle },
                { label: "maxChars", accessory: this._maxCharsStepper },
            ]);
            this._list.layoutData = new AnchorLayoutData(0, 0, 0, 0);
            this._list.clipContent = false;
            //this._list.autoHideBackground = true;
            this.addChild(this._list);

            this._backButton = new Button();
            this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
            this._backButton.label = "Back";
            this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);

            this.headerProperties[ "title" ] = "Text Input Settings";
            this.headerProperties[ "leftItems" ] = [ this._backButton ];
            this.backButtonHandler = this.onBackButton;
        }

        private function onBackButton():void
        {
            this.dispatchEventWith(Event.COMPLETE);
        }

        private function isEditableToggle_changeHandler(event:Event):void
        {
            this.settings.isEditable = this._isEditableToggle.isSelected;
        }

        private function displayAsPasswordToggle_changeHandler(event:Event):void
        {
            this.settings.displayAsPassword = this._displayAsPasswordToggle.isSelected;
        }

        private function maxCharsStepper_changeHandler(event:Event):void
        {
            this.settings.maxChars = this._maxCharsStepper.value;
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }
    }
}
