/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package screens
{
    import feathers.controls.Button;
    import feathers.controls.PanelScreen;
    import feathers.controls.TextInput;
    import feathers.events.FeathersEventType;
    import data.TextInputSettings;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;
    import feathers.system.DeviceCapabilities;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]
    [Event(name="showSettings",type="loom2d.events.Event")]

    public class TextInputScreen extends PanelScreen
    {
        public static const SHOW_SETTINGS:String = "showSettings";

        public function TextInputScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        public var settings:TextInputSettings = new TextInputSettings();
        
        private var _backButton:Button;
        private var _settingsButton:Button;
        private var _input:TextInput;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._input = new TextInput();
            this._input.prompt = "Type Something";
            this._input.displayAsPassword = this.settings.displayAsPassword;
            this._input.maxChars = this.settings.maxChars;
            this._input.isEditable = this.settings.isEditable;
            const inputLayoutData:AnchorLayoutData = new AnchorLayoutData();
            inputLayoutData.horizontalCenter = 0;
            inputLayoutData.verticalCenter = 0;
            this._input.layoutData = inputLayoutData;
            this.addChild(this._input);

            this.headerProperties[ "title" ] = "Text Input";

            if(!DeviceCapabilities.isTablet())
            {
                this._backButton = new Button();
                this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
                this._backButton.label = "Back";
                this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);
                this.headerProperties[ "leftItems" ] = [ this._backButton ];
                this.backButtonHandler = this.onBackButton;
            }

            this._settingsButton = new Button();
            this._settingsButton.label = "Settings";
            this._settingsButton.addEventListener(Event.TRIGGERED, settingsButton_triggeredHandler);

            this.headerProperties[ "rightItems" ] = [ this._settingsButton ];
        }

        private function onBackButton():void
        {
            this.dispatchEventWith(Event.COMPLETE);
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }

        private function settingsButton_triggeredHandler(event:Event):void
        {
            this.dispatchEventWith(SHOW_SETTINGS);
        }
    }
}
