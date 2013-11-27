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
    import feathers.controls.PanelScreen;
    import feathers.controls.ToggleSwitch;
    import feathers.data.ListCollection;
    import feathers.events.FeathersEventType;
    import data.ListSettings;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]

    public class ListSettingsScreen extends PanelScreen
    {
        public function ListSettingsScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        public var settings:ListSettings;

        private var _list:List;
        private var _backButton:Button;

        private var _isSelectableToggle:ToggleSwitch;
        private var _allowMultipleSelectionToggle:ToggleSwitch;
        private var _hasElasticEdgesToggle:ToggleSwitch;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._isSelectableToggle = new ToggleSwitch();
            this._isSelectableToggle.isSelected = this.settings.isSelectable;
            this._isSelectableToggle.addEventListener(Event.CHANGE, isSelectableToggle_changeHandler);

            this._allowMultipleSelectionToggle = new ToggleSwitch();
            this._allowMultipleSelectionToggle.isSelected = this.settings.allowMultipleSelection;
            this._allowMultipleSelectionToggle.addEventListener(Event.CHANGE, allowMultipleSelectionToggle_changeHandler);

            this._hasElasticEdgesToggle = new ToggleSwitch();
            this._hasElasticEdgesToggle.isSelected = this.settings.hasElasticEdges;
            this._hasElasticEdgesToggle.addEventListener(Event.CHANGE, hasElasticEdgesToggle_changeHandler);

            this._list = new List();
            this._list.isSelectable = false;
            this._list.dataProvider = new ListCollection(
            [
                { label: "isSelectable", accessory: this._isSelectableToggle },
                { label: "allowMultipleSelection", accessory: this._allowMultipleSelectionToggle },
                { label: "hasElasticEdges", accessory: this._hasElasticEdgesToggle },
            ]);
            this._list.layoutData = new AnchorLayoutData(0, 0, 0, 0);
            this._list.clipContent = false;
            //this._list.autoHideBackground = true;
            this.addChild(this._list);

            this._backButton = new Button();
            this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
            this._backButton.label = "Back";
            this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);
            this.headerProperties[ "title" ] = "List Settings";
            this.headerProperties[ "leftItems" ] = [ _backButton ];
            this.backButtonHandler = this.onBackButton;
        }

        private function onBackButton():void
        {
            this.dispatchEventWith(Event.COMPLETE);
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }

        private function isSelectableToggle_changeHandler(event:Event):void
        {
            this.settings.isSelectable = this._isSelectableToggle.isSelected;
        }

        private function allowMultipleSelectionToggle_changeHandler(event:Event):void
        {
            this.settings.allowMultipleSelection = this._allowMultipleSelectionToggle.isSelected;
        }

        private function hasElasticEdgesToggle_changeHandler(event:Event):void
        {
            this.settings.hasElasticEdges = this._hasElasticEdgesToggle.isSelected;
        }
    }
}
