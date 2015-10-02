package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;

    import loom.platform.GameController;

    public class GamePadExample extends Application
    {
        var buttonSprites = new Vector.<Image>();
        var hatLabel:SimpleLabel;
        var axisLabels = new Vector.<SimpleLabel>();

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label:SimpleLabel;

            // check whether any gamepads were detected
            if (GameController.numControllers == 0)
            {
                label = new SimpleLabel("assets/Curse-hd.fnt", 320, 240);
                label.text = "No Gamepad Detected!";
                label.x = 240;
                label.y = 240;
                label.scale = .5;
                stage.addChild(label);                
            }
            else
            {
                var gamepad:GameController = GameController.getGameController();

                var x = 150;
                var i = 0;
                buttonSprites.length = GameController.BUTTON_MAX;

                label = new SimpleLabel("assets/Curse-hd.fnt");
                label.text = "Buttons";
                label.x = 20;
                label.y = 90;
                label.scale = .5;
                stage.addChild(label);

                var sprite:Image;

                //setup button sprites
                for (i = 0; i < GameController.BUTTON_MAX; i++)
                {
                    sprite =  new Image(Texture.fromAsset("assets/logo.png"));
                    sprite.x = x;
                    sprite.y = 112;
                    sprite.scale = .2;
                    stage.addChild(sprite);
                    buttonSprites[i] = sprite;
                    x += 48;

                    gamepad.onButtonEvent += function(button:int, state:Boolean) {

                        if (i < 0 || i >= GameController.BUTTON_MAX)
                            return;

                        buttonSprites[button].scale = state ? .3 : .2;                        
                    };
                }

                label = new SimpleLabel("assets/Curse-hd.fnt");
                label.text = "Axis";
                label.x = 20;
                label.y = 32;
                label.scale = .5;                
                stage.addChild(label);


                //axisLabels.length = GameController.AXIS_MAX;
                x = 240 - (48 * axisLabels.length) / 2;
                for (i = 0; i < GameController.AXIS_MAX; i++)
                {
                    label = new SimpleLabel("assets/Curse-hd.fnt");
                    axisLabels.push(label);
                    label.text = "0";
                    label.x = x;
                    label.y = 50;
                    label.scale = .3;
                    stage.addChild(label);
                    x += 48;

                    gamepad.onAxisMoved += function(axis:int, state:float) {

                        if (i < 0 && i >= GameController.AXIS_MAX)
                            return;

                        axisLabels[axis].text = (int(GameController.convertAxis(state) * 100)).toString();
                    };

                }

            }
        }
    }
}