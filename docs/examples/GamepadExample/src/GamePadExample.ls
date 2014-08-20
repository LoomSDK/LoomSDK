package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;

    import system.platform.Gamepad;

    public class GamePadExample extends Application
    {
        var buttonSprites = new Vector.<Image>();
        var hatLabel:SimpleLabel;
        var axisLabels = new Vector.<SimpleLabel>();

        var hatText:Dictionary.<int, string> = 
        { 
            Gamepad.HAT_CENTERED: "Center",
            Gamepad.HAT_UP: "Up",
            Gamepad.HAT_RIGHT: "Right",
            Gamepad.HAT_LEFT: "Left", 
            Gamepad.HAT_DOWN: "Down",
            Gamepad.HAT_RIGHTUP: "Right & Up",
            Gamepad.HAT_RIGHTDOWN: "Right & Down",
            Gamepad.HAT_LEFTUP: "Left & Up", 
            Gamepad.HAT_LEFTDOWN: "Left & Down" 
        };

        override public function onTick()
        {
            Gamepad.update();
        }

        override public function run():void
        {

            Gamepad.initialize();
            
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label:SimpleLabel;

            // check whether any gamepads were detected
            if (!Gamepad.numGamepads)
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
                var gamepad =  Gamepad.gamepads[0];

                var x = 150;
                var i = 0;
                buttonSprites.length = gamepad.buttons.length;

                label = new SimpleLabel("assets/Curse-hd.fnt");
                label.text = "Buttons";
                label.x = 20;
                label.y = 150;
                label.scale = .5;
                stage.addChild(label);

                var sprite:Image;

                //setup button sprites
                for (i in gamepad.buttons)
                {
                    sprite =  new Image(Texture.fromAsset("assets/logo.png"));
                    sprite.x = x;
                    sprite.y = 172;
                    sprite.scale = .2;
                    stage.addChild(sprite);
                    buttonSprites[i] = sprite;
                    x += 48;

                    gamepad.buttonEvent += function(button:int, state:Boolean) {

                        if (i != button)
                            return;

                        buttonSprites[button].scale = state ? .3 : .2;                        
                    };
                }

                label = new SimpleLabel("assets/Curse-hd.fnt");
                label.text = "Directional Pad";
                label.x = 20;
                label.y = 90;
                label.scale = .5;
                stage.addChild(label);

                if (gamepad.hats.length)
                {
                    hatLabel = label = new SimpleLabel("assets/Curse-hd.fnt");
                    label.text = "Centered";
                    label.x = 240;
                    label.y = 108;
                    label.scale = .3;
                    stage.addChild(label);

                    gamepad.hatEvent += function(hat:int, state:int) {
                        hatLabel.text = hatText[state];
                    };
                }

                label = new SimpleLabel("assets/Curse-hd.fnt");
                label.text = "Axis";
                label.x = 20;
                label.y = 32;
                label.scale = .5;                
                stage.addChild(label);


                axisLabels.length = gamepad.axis.length;
                x = 240 - (48 * axisLabels.length) / 2;
                for (i in gamepad.axis)
                {
                    label = new SimpleLabel("assets/Curse-hd.fnt");
                    axisLabels[i] = label;
                    label.text = "0";
                    label.x = x;
                    label.y = 50;
                    label.scale = .3;
                    stage.addChild(label);
                    x += 48;

                    gamepad.axisEvent += function(axis:int, state:float) {

                        if (i != axis)
                            return;

                        axisLabels[i].text = (int(state * 100)).toString();                       
                    };

                }

            }
        }
    }
}