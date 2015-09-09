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
		
		/*private var leftTrigger:Number;
		private var rightTrigger:Number;*/
		private var leftTrigger:ControllerTrigger;
		private var rightTrigger:ControllerTrigger;
		
		public function ControllerDisplay()
		{
			this.addChild(bottomLayer);
			controllerImage = new Image(Texture.fromAsset("assets/controller/controllerBlank.png"));
			controllerImage.center();
			this.addChild(controllerImage);
			this.addChild(topLayer);

			leftStick = new ControllerAxis(ControllerAxis.BUTTON_STICK, 7, 314, 332);
			rightStick = new ControllerAxis(ControllerAxis.BUTTON_STICK, 8, 570, 332);
			
			buttons = new Vector.<ControllerButton>();
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 0, 702, 252));			// 00 A
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 1, 771, 184));			// 01 B
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 2, 634, 184));			// 02 X
			buttons.push(new ControllerButton(ControllerButton.BUTTON_STANDARD, 3, 702, 116));			// 03 Y
			buttons.push(new ControllerButton(ControllerButton.BUTTON_BACK,     4, 366, 192));			// 04 Back
			buttons.push(new ControllerButton(ControllerButton.BUTTON_GUIDE,    5, 442, 147));			// 05 Guide
			buttons.push(new ControllerButton(ControllerButton.BUTTON_START,	6, 524, 192));			// 06 Start
			buttons.push(leftStick);																	// 07 Left Stick
			buttons.push(rightStick);																	// 08 Right Stick
			buttons.push(new ControllerButton(ControllerButton.BUTTON_BUMPER,   9, 153,   8));			// LB
			buttons.push(new ControllerButton(ControllerButton.BUTTON_BUMPER,   10, 673,   8));			// RB
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT, 11, 185, 142));				// Up
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT, 12, 185, 227, Math.PI));		// Down
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT, 13, 142, 180, -Math.PI/2));	// Left
			buttons.push(new ControllerButton(ControllerButton.BUTTON_HAT, 14, 227, 190, Math.PI/2));	// Right
			
			for (var i:int = 0; i < buttons.length; i++) {
				if (buttons[i].type == ControllerButton.BUTTON_BUMPER) {
					bottomLayer.addChild(buttons[i]);
					continue;
				}
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
				case 0: //Left stick right-left
					leftStick.xValue = value;
					break;
				case 1: //Left stick down-up
					leftStick.yValue = value;
					break;
				case 2: //Right stick right-left
					rightStick.xValue = value;
					break;
				case 3: //Right stick down-up
					rightStick.yValue = value;
					break;
				case 4: //Left trigger
					//leftTrigger = value;
					leftTrigger.value = value;
					break;
				case 5: //Right trigger
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