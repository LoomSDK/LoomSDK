package
{
    import loom.Application;
    import loom.sound.Sound;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.Void;

    public class SoundExample extends Application
    {
        private var background:Sound;
        private var laser:Sound;
        private var laser2:Sound;
        private var tickNum:int = 0;
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
            label.text = "Hello Sound!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);
            
            laser = Sound.load("assets/laser.ogg");
            laser.setGain(0.4);
            
            laser2 = Sound.load("assets/laser2.ogg");
            laser2.setGain(0.4);
            
            // See LICENSE for copyright information
            background = Sound.load("assets/battleThemeA.mp3");
            background.setGain(0.2);
            background.setLooping(true);
            background.play();
        }
        
        override public function onTick() {
            if (tickNum%Math.randomRangeInt(20, 30) == 0) laser.play();
            if (tickNum%Math.randomRangeInt(20, 30) == 0) laser2.play();
            tickNum++;
            return super.onTick();
        }
    }
}