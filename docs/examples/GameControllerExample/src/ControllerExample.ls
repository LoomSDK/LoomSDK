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
	public class GameControllerExample extends Application
	{
		private var controllerData:SimpleLabel;
		private var sprite:Image;
		private var controllers:Vector.<GameController>;

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
			controllerData.scale = 0.4;
			stage.addChild(controllerData);

			stage.addEventListener(GameControllerEvent.CONTROLLER_ADDED, controllerAdded);
			stage.addEventListener(GameControllerEvent.CONTROLLER_REMOVED, controllerRemoved);
			
			controllers = new Vector.<GameController>();
			for (var i:uint = 0; i < GameController.numControllers; i++) {
				addDevice(i);
			}
			
			displayControllerNum();
		}

		private function axisMoved(axis:int = -1, value:Number = 0, raw:int = 0) {
			this.controller.axisAction(axis, value);
		}

		private function buttonAction(button:int = -1, pressed:Boolean = false) {
			controller.buttonAction(button, pressed);
		}

		private function controllerAdded(e:GameControllerEvent) {
			addDevice(e.controllerID);
			displayControllerNum();
		}

		private function controllerRemoved(e:GameControllerEvent) {
			cleanDevices();
			displayControllerNum();
			removeDevice(e.controllerID);
		}
		
		private function addDevice(index:int = -1):GameController {
			if (index >= GameController.numControllers) return null;
			var c:GameController = GameController.getGameController(index);
			for (var i:uint = 0; i < controllers.length; i++) {
				if (controllers[i] == c) {
					return c;
				}
			}
			
			c.onButtonEvent += buttonAction;
			c.onAxisMoved += axisMoved;
			controllers.push(c);
			
			return c;
		}
		
		private function removeDevice(index:int = 0):Boolean {
			if (index < 0 || index >= controllers.length) return false;
			controllers[index].onButtonEvent -= buttonAction;
			controllers[index].onAxisMoved -= axisMoved;
			controllers.remove(controllers[index]);
			
			return true;
		}

		private function cleanDevices():int {
			var removed:int = 0;
			
			for (var i:uint = 0; i < controllers.length; i++) {
				if (controllers[i].isConnected() == false) {
					removeDevice(i);
					removed++;
				}
			}
			
			return removed;
		}

		private function displayControllerNum() {
			var cc:String = "";
			for (var i:uint = 0; i < controllers.length; i++) {
				if (cc.length > 0) cc += ", ";
				cc += "{" + controllers[i].getID() + "} " + controllers[i].name + "";
			}
			controllerData.text = "Controllers connected: " + cc;
		}

		override public function onTick():Void 
		{
			controller.onTick();
			return super.onTick();
		}
	}
}