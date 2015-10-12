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
    import system.platform.Path;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.events.Touch;

    public class SoundExample extends Application
    {

        private var label:SimpleLabel;

        private var sounds:Vector.<Sound>;
        private var soundNames:Vector.<String>;
        private var soundIndex:Number;

        private function loadSound(fileName:String, payload:Object):void
        {
            var sound = Sound.load(fileName);
            sounds.push(sound);
            soundNames.push(fileName);

            soundIndex = 0;
        }

        private function loadSounds():void
        {
            sounds = new Vector.<Sound>;
            soundNames = new Vector.<String>;

            Path.walkFiles("assets/sounds", loadSound);
        }

        private function playSound():void
        {
            label.text = soundNames[soundIndex];

            if (!sounds[soundIndex].isNull())
            {
                sounds[soundIndex].play();
                label.alpha = 1.0;
            }
            else
            {
                label.alpha = 0.5;
            }

            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
        }

        private function stopSound():void
        {
            if (sounds[soundIndex].isPlaying())
            {
                sounds[soundIndex].stop();
            }
        }

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // A bit bigger stage so filenames are visible.
            stage.stageWidth = 1024;
            stage.stageHeight = 768;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);

            label = new SimpleLabel("assets/Curse-hd.fnt");
            stage.addChild(label);

            stage.addEventListener(TouchEvent.TOUCH, onTouch);

            loadSounds();
            playSound();
        }

        private function onTouch(e:TouchEvent):void
        {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;

            stopSound();

            soundIndex = (soundIndex + 1) % (sounds.length - 1);

            playSound();
        }
    }
}