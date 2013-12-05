/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package screens
{
    import feathers.controls.Button;
    import feathers.controls.ButtonGroup;
    import feathers.controls.Header;
    import feathers.controls.PanelScreen;
    import feathers.data.ListCollection;
    import feathers.events.FeathersEventType;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;
    import feathers.system.DeviceCapabilities;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]

    public class ButtonGroupScreen extends PanelScreen
    {
        public function ButtonGroupScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        private var _backButton:Button;
        private var _buttonGroup:ButtonGroup;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._buttonGroup = new ButtonGroup();
            this._buttonGroup.dataProvider = new ListCollection(
            [
                { label: "One", triggered: button_triggeredHandler },
                { label: "Two", triggered: button_triggeredHandler },
                { label: "Three", triggered: button_triggeredHandler },
                { label: "Four", triggered: button_triggeredHandler },
            ]);
            const buttonGroupLayoutData:AnchorLayoutData = new AnchorLayoutData();
            buttonGroupLayoutData.horizontalCenter = 0;
            buttonGroupLayoutData.verticalCenter = 0;
            this._buttonGroup.layoutData = buttonGroupLayoutData;
            this.addChild(this._buttonGroup);

            this.headerProperties[ "title" ] = "Button Group";

            if(!DeviceCapabilities.isTablet())
            {
                this._backButton = new Button();
                this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
                this._backButton.label = "Back";
                this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);
                this.headerProperties[ "leftItems" ] = [ this._backButton ];
                this.backButtonHandler = this.onBackButton;
            }
        }

        private function onBackButton():void
        {
            this.dispatchEventWith(Event.COMPLETE);
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }

        private function button_triggeredHandler(event:Event):void
        {
            const button:Button = Button(event.currentTarget);
            trace(button.label + " triggered.");
        }
    }
}
