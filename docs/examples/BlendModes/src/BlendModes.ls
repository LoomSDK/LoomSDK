package
{
    import loom.Application;
    import loom.gameframework.LoomGroup;
    import loom.gameframework.TimeManager;

    import loom2d.math.Point;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.BlendMode;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;


    public class BlendModes extends Application
    {
        private var blendModeLabel:SimpleLabel;
        private var polySprite:Image;
        private var polySpeed:Point = new Point(100, 100);
        private var _lastFrameTime:Number = 0.0;


        override public function run():void
        {
            var timeManager:TimeManager = LoomGroup.rootGroup.getManager(TimeManager) as TimeManager;
            _lastFrameTime = timeManager.platformTime;

            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //entire stage has no blending by default to show parent blendMode inheritence
            stage.blendMode = BlendMode.NONE;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            bg.y = 100;
            bg.color = 0x007f7f7f;
            bg.addEventListener(TouchEvent.TOUCH, cycleBlendMode);
            stage.addChild(bg);
            
            //static sprite
            var bgSprite:Image = new Image(Texture.fromAsset("assets/logo.png"));
            bgSprite.center();
            bgSprite.x = stage.stageWidth / 2;
            bgSprite.y = stage.stageHeight / 2;
            bgSprite.touchable = false;
            bgSprite.blendMode = BlendMode.ERASE;
            stage.addChild(bgSprite);

            //moving sprite
            polySprite = new Image(Texture.fromAsset("assets/logo.png"));
            polySprite.center();
            polySprite.x = stage.stageWidth / 2;
            polySprite.y = stage.stageHeight / 2 + 50;
            polySprite.scale = 0.5;
            polySprite.touchable = false;
            stage.addChild(polySprite);


            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Tap to Cycle Blend Mode!";
            label.x = 20;
            label.y = 0;
            label.scale = 0.4;
            label.touchable = false;
            label.blendMode = BlendMode.NORMAL;
            stage.addChild(label);

            //label to show the current Poly blend mode
            blendModeLabel = new SimpleLabel("assets/Curse-hd.fnt");
            blendModeLabel.text = getBlendLabel(polySprite.blendMode);
            blendModeLabel.x = label.x;
            blendModeLabel.y = label.y + label.height + 10;
            blendModeLabel.scale = 0.4;
            blendModeLabel.touchable = false;
            blendModeLabel.blendMode = BlendMode.NORMAL;
            stage.addChild(blendModeLabel);            
        }


        override public function onTick():void
        {
            ///update the app DT
            var timeManager:TimeManager = LoomGroup.rootGroup.getManager(TimeManager) as TimeManager;
            var dt:Number = (timeManager.platformTime - _lastFrameTime) / 1000;
            _lastFrameTime = timeManager.platformTime;

            //bounce poly around the screen
            polySprite.x += polySpeed.x * dt;
            polySprite.y += polySpeed.y * dt;

            //check for collision with bounds
            //X
            if(polySprite.x >= stage.stageWidth)
            {
                polySprite.x = (2 * stage.stageWidth) - polySprite.x;
                polySpeed.x *= -1.0;
            }
            else if(polySprite.x <= 0)
            {
                polySprite.x = polySprite.x * -1;
                polySpeed.x *= -1.0;
            }

            //Y
            if(polySprite.y >= stage.stageHeight)
            {
                polySprite.y = (2 * stage.stageHeight) - polySprite.y;
                polySpeed.y *= -1.0;
            }
            else if(polySprite.y <= 0)
            {
                polySprite.y = polySprite.y * -1;
                polySpeed.y *= -1.0;
            }
        }


        private function cycleBlendMode(e:TouchEvent)
        {
            var touch:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if(!touch)
            {
                return;
            }

            //increment the blend mode of Poly
            polySprite.blendMode = polySprite.blendMode + 1;
            if(polySprite.blendMode > BlendMode.BELOW)
            {
                polySprite.blendMode = BlendMode.AUTO;
            }

            //update text
            blendModeLabel.text = getBlendLabel(polySprite.blendMode);
        }


        private function getBlendLabel(blendMode:BlendMode):String
        {
            switch(blendMode)
            {
                case BlendMode.AUTO:
                    return "AUTO";
                case BlendMode.NONE:
                    return "NONE";
                case BlendMode.NORMAL:
                    return "NORMAL";
                case BlendMode.ADD:
                    return "ADD";
                case BlendMode.MULTIPLY:
                    return "MULTIPLY";
                case BlendMode.SCREEN:
                    return "SCREEN";
                case BlendMode.ERASE:
                    return "ERASE";
                case BlendMode.BELOW:
                    return "BELOW";
            }
            return "UNKNOWN";
        }
    }
}
