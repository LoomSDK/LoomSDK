package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom.sound.Sound;
    import loom.platform.DolbyAudio;

    /**
     * Demonstrate positional audio playback and Dolby Digital Plus support.
     */
    public class PositionalAudioExample extends Application
    {
        // Store references to sounds so they don't disappear.
        public var mySound:Sound;
        public var mySound2:Sound;

        // Track last time we spawned sounds.
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

            // Cute label.
            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Hello Audio!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

            // Detect and enable Dolby Digital Plus if it's available!
            trace("Dolby Digital Plus available: " + DolbyAudio.supported);
            if(DolbyAudio.supported)
            {
                label.text = "Hello Dolby Audio!";
                DolbyAudio.setProcessingEnabled(true);
            }

            // Load the sounds! If we did load the same sounds more than once,
            // it would only store one copy. But it's nice to reuse them. It
            // avoids sounds stacking, it avoids GC churn, and it makes logic
            // simpler to follow.
            //
            // Sounds support live reload; give it a try!
            mySound = Sound.load("assets/YeeHah.mp3");
            mySound2 = Sound.load("assets/Crush8-Bit.ogg");
        }

        // Run every tick.
        override public function onTick():void
        {
            // Only run this logic if it has been at least a second since last time.
            if(Platform.getTime() - lastTime < 1000)
                return;

            // Update last time with a fudget to get some variety.
            lastTime = Platform.getTime() - 500 * Math.random();

            // Play the sounds at new positions. Note you can retrigger the sounds
            // or you could call Sound.load() and get new ones each time. (However,
            // if you do this you will need to remember to deallocate them with
            // Sound.nativeDelete()).
            mySound.setPosition(100 * Math.random() - 50, 100 * Math.random() - 50, 100 * Math.random() - 50);
            mySound.play();

            mySound2.setPosition(50 * Math.random() - 25, 50 * Math.random() - 25, 50 * Math.random() - 25);
            mySound2.play();
        }
    }
}