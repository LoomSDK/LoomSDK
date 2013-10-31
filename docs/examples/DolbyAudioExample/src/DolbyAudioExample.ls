package dolby.main
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;
    import loom2d.ui.ButtonClickCallback;
    import loom.sound.SimpleAudioEngine;

    import loom.platform.DolbyAudio;


    public class DolbyAudioExample extends Application
    {
        ///private vars
        private var _isProcessingLabel:SimpleLabel;
        private var _curProfileLabel:SimpleLabel;
        private var _musicProfileLabel:SimpleLabel;
        private var _movieProfileLabel:SimpleLabel;
        private var _gameProfileLabel:SimpleLabel;
        private var _voiceProfileLabel:SimpleLabel;
        
        private var _enabledToggle:SimpleButton;
        private var _musicProfileButton:SimpleButton;
        private var _movieProfileButton:SimpleButton;
        private var _gameProfileButton:SimpleButton;
        private var _voiceProfileButton:SimpleButton;


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
                ///start the bg music
                SimpleAudioEngine.sharedEngine().playBackgroundMusic("assets/audio/dolbyaudio.m4a");

                isSupported.text += "Supported!";
                isSupported.x = stage.stageWidth / 2 - 160;
                isSupported.y = stage.stageHeight / 2 - 150;

                ///enabled toggle button
                _enabledToggle = createButton(50, isSupported.y + 90, onEnableToggle);

                ///is processing enabled label
                _isProcessingLabel = createButtonLabel(_enabledToggle, "");

                ///cur profile index label
                _curProfileLabel = new SimpleLabel("assets/Curse-hd.fnt");
                _curProfileLabel.scale = 0.2;
                _curProfileLabel.x = 50;
                _curProfileLabel.y = _enabledToggle.y + 90;
                stage.addChild(_curProfileLabel);

                ///buttons to choose current profile
                var buttonLeft:int = 50;
                if(DolbyAudio.isProfileSupported(DolbyAudio.MUSIC_PROFILE))
                {
                    _musicProfileButton = createButton(buttonLeft, _curProfileLabel.y + 30, onSetMusicProfile);
                    _musicProfileLabel = createButtonLabel(_musicProfileButton, DolbyAudio.MUSIC_PROFILE);
                    buttonLeft += 80;
                }
                if(DolbyAudio.isProfileSupported(DolbyAudio.MOVIE_PROFILE))
                {
                    _movieProfileButton = createButton(buttonLeft, _curProfileLabel.y + 30, onSetMovieProfile);
                    _movieProfileLabel = createButtonLabel(_movieProfileButton, DolbyAudio.MOVIE_PROFILE);
                    buttonLeft += 80;
                }
                if(DolbyAudio.isProfileSupported(DolbyAudio.GAME_PROFILE))
                {
                    _gameProfileButton = createButton(buttonLeft, _curProfileLabel.y + 30, onSetGameProfile);
                    _gameProfileLabel = createButtonLabel(_gameProfileButton, DolbyAudio.GAME_PROFILE);
                    buttonLeft += 80;
                }
                if(DolbyAudio.isProfileSupported(DolbyAudio.VOICE_PROFILE))
                {
                    _voiceProfileButton = createButton(buttonLeft, _curProfileLabel.y + 30, onSetVoiceProfile);
                    _voiceProfileLabel = createButtonLabel(_voiceProfileButton, DolbyAudio.VOICE_PROFILE);
                }
            }
            stage.addChild(isSupported);
        }


        override function onTick():void
        {
            super.onTick();
            if(DolbyAudio.supported)
            {
                ///update some elements that are interactive
                var enabled:Boolean = DolbyAudio.isProcessingEnabled();
                _isProcessingLabel.text = (enabled) ? "Enabled" : "Disabled";

                ///cur profile label
                _curProfileLabel.text = "Current Profile: " + DolbyAudio.getSelectedProfile();
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
            label.touchable = false;
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
        private function onSetMusicProfile()
        {
           DolbyAudio.setProfile(DolbyAudio.MUSIC_PROFILE);
        }
        private function onSetMovieProfile()
        {
           DolbyAudio.setProfile(DolbyAudio.MOVIE_PROFILE);
        }
        private function onSetGameProfile()
        {
           DolbyAudio.setProfile(DolbyAudio.GAME_PROFILE);
        }
        private function onSetVoiceProfile()
        {
           DolbyAudio.setProfile(DolbyAudio.VOICE_PROFILE);
        }
    }
}
  