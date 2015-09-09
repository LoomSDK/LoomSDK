package 
{
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;
    
    /**
     * ...
     * @author Tadej
     */
    public class ControllerDisplay extends Sprite
    {
        private var controllerImage:Image;
        private var topLayer:Sprite = new Sprite();
        private var bottomLayer:Sprite = new Sprite();
        private var buttons:Vector.<ControllerButton>;
        private var dPad:Vector.<ControllerButton>;
        private var axes:Vector.<ControllerAxis>;
        private var hat:Vector.<ControllerButton>;
        
        private var leftStick:ControllerAxis;
        private var rightStick:ControllerAxis;
        
        public function ControllerDisplay()
        {
            this.addChild(bottomLayer);
            controllerImage = new Image(Texture.fromAsset("assets/controller/controllerBlank.png"));
            //controllerImage = new Image(Texture.fromAsset("assets/controller/PSX Gamepad.png"));
            controllerImage.center();
            this.addChild(controllerImage);
            this.addChild(topLayer);
            
            buttons = new Vector.<ControllerButton>();
            buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 0, 702, 252)); // A
            buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 1, 771, 184)); // B
            buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 2, 634, 184)); // X
            buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 3, 702, 116)); // Y
            buttons.push(new ControllerButton(ControllerButton.BUTTON_BUMPER,   4, 153,   8)); // LB
            buttons.push(new ControllerButton(ControllerButton.BUTTON_BUMPER,   5, 673,   8)); // RB
            buttons.push(new ControllerButton(ControllerButton.BUTTON_BACK,     6, 366, 192)); // Back
            buttons.push(new ControllerButton(ControllerButton.BUTTON_START,    7, 524, 192)); // Start
            
            leftStick = new ControllerAxis(ControllerAxis.BUTTON_STICK, 8, 314, 332);
            rightStick = new ControllerAxis(ControllerAxis.BUTTON_STICK, 9, 570, 332);
            
            buttons.push(leftStick);
            buttons.push(rightStick);
            
            dPad = new Vector.<ControllerButton>();
            dPad.push(new ControllerButton(ControllerButton.BUTTON_HAT, 1, 185, 142)); // Up
            dPad.push(new ControllerButton(ControllerButton.BUTTON_HAT, 2, 227, 190, Math.PI/2)); // Right
            dPad.push(new ControllerButton(ControllerButton.BUTTON_HAT, 4, 185, 227, Math.PI)); // Down
            dPad.push(new ControllerButton(ControllerButton.BUTTON_HAT, 8, 142, 180, -Math.PI/2)); // Left
            
            for (var i:int = 0; i < buttons.length; i++) {
                if (buttons[i].type == ControllerButton.BUTTON_BUMPER) {
                    bottomLayer.addChild(buttons[i]);
                    continue;
                }
                topLayer.addChild(buttons[i]);
            }
            
            for (i = 0; i < dPad.length; i++) {
                topLayer.addChild(dPad[i]);
            }
            
            //topLayer.addChild(leftStick);
            
            topLayer.x -= 442;
            bottomLayer.x -= 413;
            topLayer.y -= 267;
            bottomLayer.y -= 250;
        }
        
        public function axisAction(axis:int, value:int):void {
            switch(axis) {
                case 0: //left-right left stick
                    leftStick.xValue = value;
                    break;
                case 1: //up-down left stick
                    leftStick.yValue = value;
                    break;
                case 2: //triggers
                    
                    break;
                case 3: //up-down right stick
                    rightStick.yValue = value;
                    break;
                case 4: //left-right right stick
                    rightStick.xValue = value;
                    break;
            }
        }
        
        public function buttonAction(button:int, pressed:Boolean):void {
            if (button < 0 || button >= buttons.length) return;
            buttons[button].setPressed(pressed);
        }
        
        public function hatAction(hat:int, value:int):void {
            for (var i:int = 0; i < dPad.length; i++) {
                dPad[i].setPressed(false);
            }
            
            switch(value) {
                case 1:
                    dPad[0].setPressed(true);
                    break;
                case 2:
                    dPad[1].setPressed(true);
                    break;
                case 4:
                    dPad[2].setPressed(true);
                    break;
                case 8:
                    dPad[3].setPressed(true);
                    break;
                case 3:
                    dPad[0].setPressed(true);
                    dPad[1].setPressed(true);
                    break;
                case 6:
                    dPad[1].setPressed(true);
                    dPad[2].setPressed(true);
                    break;
                case 12:
                    dPad[2].setPressed(true);
                    dPad[3].setPressed(true);
                    break;
                case 9:
                    dPad[0].setPressed(true);
                    dPad[3].setPressed(true);
                    break;
            }
        }
        
        public function onTick() {
            for (var i:int = 0; i < buttons.length; i++) {
                buttons[i].onTick();
            }
            for (i = 0; i < dPad.length; i++) {
                dPad[i].onTick();
            }
        }
    }
    
}