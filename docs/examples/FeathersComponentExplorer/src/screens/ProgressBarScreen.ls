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
    import feathers.controls.ProgressBar;
    import feathers.events.FeathersEventType;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;
    import feathers.system.DeviceCapabilities;

    import loom2d.animation.Tween;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.Loom2D;

    [Event(name="complete",type="loom2d.events.Event")]

    public class ProgressBarScreen extends PanelScreen
    {
        public function ProgressBarScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        private var _backButton:Button;
        private var _progress:ProgressBar;

        private var _progressTween:Tween;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._progress = new ProgressBar();
            this._progress.minimum = 0;
            this._progress.maximum = 1;
            this._progress.value = 0;
            const progressLayoutData:AnchorLayoutData = new AnchorLayoutData();
            progressLayoutData.horizontalCenter = 0;
            progressLayoutData.verticalCenter = 0;
            this._progress.layoutData = progressLayoutData;
            this.addChild(this._progress);

            this.headerProperties[ "title" ] = "Progress Bar";

            if(!DeviceCapabilities.isTablet())
            {
                this._backButton = new Button();
                this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
                this._backButton.label = "Back";
                this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);
                this.headerProperties[ "leftItems" ] = [ this._backButton ];
                this.backButtonHandler = this.onBackButton;
            }

            this._progressTween = new Tween(this._progress, 5);
            this._progressTween.animate("value", 1);
            this._progressTween.repeatCount = int.MAX_VALUE;
            
            Loom2D.juggler.add(this._progressTween);
        }

        private function onBackButton():void
        {
            if(this._progressTween)
            {
                Loom2D.juggler.remove(this._progressTween);
                this._progressTween = null;
            }
            this.dispatchEventWith(Event.COMPLETE);
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }
    }
}
