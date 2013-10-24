package dolby.main
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;
    import loom2d.ui.ButtonClickCallback;

    import loom.platform.DolbyAudio;


    public class DolbyAudioExample extends Application
    {
        ///private vars
        private var _isProcessingLabel:SimpleLabel;
        private var _curProfileLabel:SimpleLabel;
        private var _profileLabel0:SimpleLabel;
        private var _profileLabel1:SimpleLabel;
        private var _profileLabel2:SimpleLabel;
        private var _profileLabel3:SimpleLabel;
        
        private var _enabledToggle:SimpleButton;
        private var _setProfile0:SimpleButton;
        private var _setProfile1:SimpleButton;
        private var _setProfile2:SimpleButton;
        private var _setProfile3:SimpleButton;


        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg:Image = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);

            ///is Dolby Audio supported?
            var isSupported:SimpleLabel = new SimpleLabel("assets/Curse-hd.fnt");
            isSupported.text = "Dolby Audio ";
            isSupported.scale = 0.5;
            if(!DolbyAudio.supported)
            {
                isSupported.text += "Not Supported!";
                isSupported.x = stage.stageWidth / 2 - 180;
                isSupported.y = stage.stageHeight / 2 - 100;
            }
            else
            {
                isSupported.text += "Supported!";
                isSupported.x = stage.stageWidth / 2 - 160;
                isSupported.y = stage.stageHeight / 2 - 150;

                ///private ID label
                var privateID:int = DolbyAudio.privateProfileID;
                var label:SimpleLabel = new SimpleLabel("assets/Curse-hd.fnt");
                label.scale = 0.2;
                label.x = 50;
                label.y = isSupported.y + 80;
                label.text = "Private Profile ID: " + privateID.toString();
                stage.addChild(label);

                ///enabled toggle button
                _enabledToggle = createButton(50, label.y + 40, onEnableToggle);

                ///is processing enabled label
                _isProcessingLabel = createButtonLabel(_enabledToggle, "");

                ///cur profile index label
                _curProfileLabel = new SimpleLabel("assets/Curse-hd.fnt");
                _curProfileLabel.touchable = true;
                _curProfileLabel.scale = 0.2;
                _curProfileLabel.x = 50;
                _curProfileLabel.y = _enabledToggle.y + 80;
                stage.addChild(_curProfileLabel);

                ///buttons to choose current profile
                var numProfiles:int = DolbyAudio.getNumProfiles();
                if(numProfiles > 0)
                {
                    _setProfile0 = createButton(50, _curProfileLabel.y + 30, onSetProfile0);
                    _profileLabel0 = createButtonLabel(_setProfile0, DolbyAudio.getProfileName(0));
                    if(numProfiles > 1)
                    {
                        _setProfile1 = createButton(_setProfile0.x + 80, _curProfileLabel.y + 30, onSetProfile1);
                        _profileLabel1 = createButtonLabel(_setProfile1, DolbyAudio.getProfileName(1));
                        if(numProfiles > 2)
                        {
                            _setProfile2 = createButton(_setProfile1.x + 80, _curProfileLabel.y + 30, onSetProfile2);
                            _profileLabel2 = createButtonLabel(_setProfile2, DolbyAudio.getProfileName(2));
                            if(numProfiles > 3)
                            {
                                _setProfile3 = createButton(_setProfile2.x + 80, _curProfileLabel.y + 30, onSetProfile3);
                                _profileLabel3 = createButtonLabel(_setProfile3, DolbyAudio.getProfileName(3));
                            }
                        }
                    }
                }
            }
            stage.addChild(isSupported);
        }


        override function onTick():void
        {
            if(DolbyAudio.supported)
            {
                ///update some elements that are interactive
                var enabled:Boolean = DolbyAudio.isProcessingEnabled();
                _isProcessingLabel.text = (enabled) ? "Enabled" : "Disabled";

                ///cur profile label
                var curProfile:int = DolbyAudio.getSelectedProfile();
                _curProfileLabel.text = "Current Profile: " + DolbyAudio.getProfileName(curProfile) + "(" + curProfile.toString() + ")";
            }
        }


        private function createButton(x:int, y:int, cb:ButtonClickCallback):SimpleButton
        {
            var button:SimpleButton = new SimpleButton();
            button.scale = 0.25;
            button.x = x;
            button.y = y;
            button.upImage = "assets/up.png";
            button.downImage = "assets/down.png";
            button.onClick += cb;
            stage.addChild(button);

            return button;
        }

        private function createButtonLabel(button:SimpleButton, text:String):SimpleLabel
        {
            var label:SimpleLabel = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = text;
            label.scale = 0.2;
            label.x = button.x + 8;
            label.y = button.y + 16;
            stage.addChild(label);   

            return label;         
        }


        private function onEnableToggle()
        {
            DolbyAudio.setProcessingEnabled(!DolbyAudio.isProcessingEnabled());
        }
        private function onSetProfile0()
        {
           DolbyAudio.setProcessingProfile(0);
        }
        private function onSetProfile1()
        {
           DolbyAudio.setProcessingProfile(1);
        }
        private function onSetProfile2()
        {
           DolbyAudio.setProcessingProfile(2);
        }
        private function onSetProfile3()
        {
           DolbyAudio.setProcessingProfile(3);
        }
    }
}
  