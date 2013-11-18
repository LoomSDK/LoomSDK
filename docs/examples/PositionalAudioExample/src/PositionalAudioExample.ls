package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom.sound.Sound;
    import loom.platform.DolbyAudio;

    public class PositionalAudioExample extends Application
    {
        public var mySound:Sound;
        public var mySound2:Sound;
        public var lastTime:Number = 0;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            stage.addChild(sprite);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Hello Loom!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

            trace("Dolby Digital Plus available: " + DolbyAudio.supported);
            if(DolbyAudio.supported)
                label.text = "Hello Dolby Digital Plus!";

            DolbyAudio.setProcessingEnabled(!DolbyAudio.isProcessingEnabled());
        }

        override public function onTick():void
        {
            if(Platform.getTime() - lastTime < 1000)
                return;

            lastTime = Platform.getTime() - 500 * Math.random();

            mySound = Sound.load("assets/YeeHah.mp3");
            mySound.setPosition(100 * Math.random() - 50, 100 * Math.random() - 50, 100 * Math.random() - 50);
            mySound.play();

            mySound2 = Sound.load("assets/Crush8-Bit.ogg");
            mySound2.setPosition(50 * Math.random() - 25, 50 * Math.random() - 25, 50 * Math.random() - 25);
            mySound2.play();
        }
    }
}