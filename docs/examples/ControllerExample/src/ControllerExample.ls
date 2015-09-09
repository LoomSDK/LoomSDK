package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.events.ControllerEvent;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.Void;

    public class ControllerExample extends Application
    {
        private var debugText:SimpleLabel;
        private var sprite:Image;
        
        private var xLeftStick:Number = 0;
        private var xLeftMax:Number = Number.MIN_VALUE;
        private var xLeftMin:Number = Number.MAX_VALUE;
        private var yLeftStick:Number = 0;
        private var triggers:Number = 0;
        private var xRightStick:Number = 0;
        private var yRightStick:Number = 0;
        
        private var lsIndicator:StickIndicator;
        private var rsIndicator:StickIndicator;
        
        private var controller:ControllerDisplay;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);

            controller = new ControllerDisplay();
            controller.x = stage.stageWidth / 2;
            controller.y = stage.stageHeight / 2;
            stage.addChild(controller);
            
            sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 - 120;
            stage.addChild(sprite);
            
            debugText = new SimpleLabel("assets/Curse-hd.fnt");
            debugText.text = "DEBUG";
            /*debugText.center();
            debugText.x = stage.stageWidth / 2;
            debugText.y = stage.stageHeight / 2 - 100;*/
            debugText.scale = 0.4;
            stage.addChild(debugText);
            
            stage.addEventListener(ControllerEvent.AXIS_MOTION, axisMoved);
            stage.addEventListener(ControllerEvent.BUTTON_DOWN, buttonPressed);
            stage.addEventListener(ControllerEvent.BUTTON_UP, buttonReleased);
            stage.addEventListener(ControllerEvent.HAT_MOTION, hatMoved);
            //sprite.addEventListener(TouchEvent.TOUCH, followPointer);
        }
        
        /*private function followPointer(e:TouchEvent) {
            var t:Touch = e.getTouch(this.stage);
            //this.debugText.text = "x: " + t.globalX + " | y: " + t.globalY;
            sprite.x = t.globalX;
            sprite.y = t.globalY;
        }*/
        
        private function axisMoved(e:ControllerEvent) {
            switch(e.axisID) {
                case 2: //triggers
                    triggers = e.axisValue;
                    if (triggers < 0) {
                        triggers = - (triggers / ( -32768));
                    } else {
                        triggers /= 32767;
                    }
                    break;
                default:
                    controller.axisAction(e.axisID, e.axisValue);
            }
        }
        
        private function hatMoved(e:ControllerEvent) {
            controller.hatAction(e.hatID, e.hatValue);
        }
        
        private function buttonPressed(e:ControllerEvent) {
            controller.buttonAction(e.buttonID, true);
        }
        
        private function buttonReleased(e:ControllerEvent) {
            controller.buttonAction(e.buttonID, false);
        }
        
        override public function onTick():Void 
        {
            this.debugText.text = "x: " + sprite.x + " | y: " + sprite.y;
            
            sprite.rotation = Math.PI * triggers;
            
            controller.onTick();
            
            return super.onTick();
        }
    }
}