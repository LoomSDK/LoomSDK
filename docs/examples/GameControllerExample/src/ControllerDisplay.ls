package 
{
	import loom.platform.GameController;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.textures.Texture;
	
	/**
	 * Main container for everything that is the standard game controller.
	 * This is where all all the elements are manipulated based on the events that occur in the main class.
	 */
	public class ControllerDisplay extends Sprite
	{
		private var controllerImage:Image;
		private var topLayer:Sprite = new Sprite();
		private var bottomLayer:Sprite = new Sprite();
		private var buttons:Vector.<ControllerButton>;
		private var dPad:Vector.<ControllerButton>;
		private var axes:Vector.<ControllerStick>;
		private var hat:Vector.<ControllerButton>;
		
		private var leftStick:ControllerStick;
		private var rightStick:ControllerStick;
		
		private var leftTrigger:ControllerTrigger;
		private var rightTrigger:ControllerTrigger;
		
		public function ControllerDisplay()
		{
			this.addChild(bottomLayer);
			controllerImage = new Image(Texture.fromAsset("assets/controller/controllerBlank.png"));
			controllerImage.center();
			this.addChild(controllerImage);
			this.addChild(topLayer);

			leftStick  = new ControllerStick(ControllerStick.BUTTON_STICK,  GameController.BUTTON_LEFTSTICK, 314, 332);
			rightStick = new ControllerStick(ControllerStick.BUTTON_STICK, GameController.BUTTON_RIGHTSTICK, 570, 332);

			// Populating array of buttons
			buttons = new Vector.<ControllerButton>();
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, GameController.BUTTON_A,             702, 252));             // 00 A
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, GameController.BUTTON_B,             771, 184));             // 01 B
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, GameController.BUTTON_X,             634, 184));             // 02 X
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, GameController.BUTTON_Y,             702, 116));             // 03 Y
			buttons.push(new ControllerButton(ControllerButton.BUTTON_BACK,     GameController.BUTTON_BACK,          366, 192));             // 04 Back
			buttons.push(new ControllerButton(ControllerButton.BUTTON_GUIDE,    GameController.BUTTON_GUIDE,         442, 147));             // 05 Guide
			buttons.push(new ControllerButton(ControllerButton.BUTTON_START,    GameController.BUTTON_START,         524, 192));             // 06 Start
			buttons.push(leftStick);                                                                                                         // 07 Left Stick
			buttons.push(rightStick);                                                                                                        // 08 Right Stick
			buttons.push(new ControllerButton(ControllerButton.BUTTON_BUMPER,   GameController.BUTTON_LEFTSHOULDER,  153,   8));             // 09 Left Bumper
			buttons.push(new ControllerButton(ControllerButton.BUTTON_BUMPER,   GameController.BUTTON_RIGHTSHOULDER, 673,   8));             // 10 Right Bumper
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT,      GameController.BUTTON_DPAD_UP,       185, 142));             // 11 Up
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT,      GameController.BUTTON_DPAD_DOWN,     185, 227,  Math.PI));   // 12 Down
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT,      GameController.BUTTON_DPAD_LEFT,     142, 180, -Math.PI/2)); // 13 Left
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT,      GameController.BUTTON_DPAD_RIGHT,    227, 190,  Math.PI/2)); // 14 Right
			
			for (var i:int = 0; i < buttons.length; i++) {
				// Add bumpers on a layer that below the base of controller
				if (buttons[i].type == ControllerButton.BUTTON_BUMPER) {
					bottomLayer.addChild(buttons[i]);
					continue;
				}
				// The rest is added above the controller
				topLayer.addChild(buttons[i]);
			}
			
			leftTrigger = new ControllerTrigger();
			topLayer.addChild(leftTrigger);
			rightTrigger = new ControllerTrigger();
			rightTrigger.x = controllerImage.width - rightTrigger.width;
			rightTrigger.scaleX *= -1;
			topLayer.addChild(rightTrigger);
			
			topLayer.x -= 442;
			bottomLayer.x -= 413;
			topLayer.y -= 267;
			bottomLayer.y -= 250;
		}
		
		public function axisAction(axis:int, value:int):void {
			switch(axis) {
				case GameController.AXIS_LEFTX: //Left stick right-left
					leftStick.xValue = value;
					break;
				case GameController.AXIS_LEFTY: //Left stick down-up
					leftStick.yValue = value;
					break;
				case GameController.AXIS_RIGHTX: //Right stick right-left
					rightStick.xValue = value;
					break;
				case GameController.AXIS_RIGHTY: //Right stick down-up
					rightStick.yValue = value;
					break;
				case GameController.AXIS_TRIGGERLEFT:
					leftTrigger.value = value;
					break;
				case GameController.AXIS_TRIGGERRIGHT:
					rightTrigger.value = value;
					break;
			}
		}
		
		public function buttonAction(button:int, pressed:Boolean):void {
			if (button < 0 || button >= buttons.length) return;
			buttons[button].setPressed(pressed);
		}
		
		public function onTick() {
			for (var i:int = 0; i < buttons.length; i++) {
				buttons[i].onTick();
			}
			
			leftTrigger.onTick();
			rightTrigger.onTick();
		}
	}
	
}