package
{
	import loom.Application;
	import loom.platform.GameController;
	import loom2d.display.StageScaleMode;
	import loom2d.display.Image;
	import loom2d.events.GameControllerEvent;
	import loom2d.events.Event;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleLabel;
	import system.Void;

	/**
	 * Main application class containing all event interactions.
	 * The demo mimics game controller interaction on screen.
	 */
	public class ControllerExample extends Application
	{
		private var controllerData:SimpleLabel;
		private var sprite:Image;
		private var gc:GameController;

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

			controllerData = new SimpleLabel("assets/Curse-hd.fnt");
			displayControllerNum();
			controllerData.scale = 0.4;
			stage.addChild(controllerData);

			stage.addEventListener(GameControllerEvent.AXIS_MOTION, axisMoved);
			stage.addEventListener(GameControllerEvent.BUTTON_DOWN, buttonPressed);
			stage.addEventListener(GameControllerEvent.BUTTON_UP, buttonReleased);
			stage.addEventListener(GameControllerEvent.CONTROLLER_ADDED, controllerAdded);
			stage.addEventListener(GameControllerEvent.CONTROLLER_REMOVED, controllerRemoved);
		}

		private function axisMoved(e:GameControllerEvent) {
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

		private function buttonPressed(e:GameControllerEvent) {
			controller.buttonAction(e.buttonID, true);
		}

		private function buttonReleased(e:GameControllerEvent) {
			controller.buttonAction(e.buttonID, false);
		}

		private function controllerAdded(e:GameControllerEvent) {
			displayControllerNum();
		}

		private function controllerRemoved(e:GameControllerEvent) {
			displayControllerNum();
		}

		private function displayControllerNum() {
			controllerData.text = "Controllers connected: " + GameController.numDevices();
		}

		override public function onTick():Void 
		{
			controller.onTick();
			return super.onTick();
		}
	}
}