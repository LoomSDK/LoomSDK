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
		
		private var numControllers:Number = 0;
		
		private var controller:ControllerDisplay;
		
		override public function run():void
		{
			stage.scaleMode = StageScaleMode.LETTERBOX;

			var bg = new Image(Texture.fromAsset("assets/bg.png"));
			bg.width = stage.stageWidth;
			bg.height = stage.stageHeight;
			stage.addChild(bg);

			controller = new ControllerDisplay();
			controller.x = stage.stageWidth / 2;
			controller.y = stage.stageHeight / 2;
			stage.addChild(controller);
			
			debugText = new SimpleLabel("assets/Curse-hd.fnt");
			debugText.text = "DEBUG";
			debugText.scale = 0.4;
			stage.addChild(debugText);
			
			stage.addEventListener(ControllerEvent.AXIS_MOTION, axisMoved);
			stage.addEventListener(ControllerEvent.BUTTON_DOWN, buttonPressed);
			stage.addEventListener(ControllerEvent.BUTTON_UP, buttonReleased);
			stage.addEventListener(ControllerEvent.CONTROLLER_ADDED, controllerAdded);
			stage.addEventListener(ControllerEvent.CONTROLLER_REMOVED, controllerRemoved);
		}
		
		private function axisMoved(e:ControllerEvent) {
			/**
			 * 0 - Left stick right-left
			 * 1 - Left stick down-up
			 * 2 - Right stick right-left
			 * 3 - Right stick down-up
			 * 4 - Left trigger
			 * 5 - Right trigger
			 * */
			controller.axisAction(e.axisID, e.axisValue);
		}
		
		private function buttonPressed(e:ControllerEvent) {
			controller.buttonAction(e.buttonID, true);
		}
		
		private function buttonReleased(e:ControllerEvent) {
			controller.buttonAction(e.buttonID, false);
		}
		
		private function controllerAdded(e:ControllerEvent) {
			debugText.text = "Controllers connected: " + (++numControllers);
		}
		
		private function controllerRemoved(e:ControllerEvent) {
			debugText.text = "Controllers connected: " + (--numControllers);
		}
		
		override public function onTick():Void 
		{
			controller.onTick();
			
			return super.onTick();
		}
	}
}