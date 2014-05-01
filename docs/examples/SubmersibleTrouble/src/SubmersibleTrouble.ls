package
{
	import feathers.display.TiledImage;
	import loom.Application;
	import loom.physics.Physics;
	import loom.physics.PhysicsBall;
	import loom.utils.Injector;
	import loom2d.display.Stage;
	import loom2d.display.StageScaleMode;
	import loom2d.display.Image;
	import loom2d.events.Event;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleLabel;
	import system.Void;
	
	/**
	*/
	public class SubmersibleTrouble extends Application
	{
		
		private static const STATE_INIT = 0;
		private static const STATE_GAME = 1;
		private static const STATE_OVER = 2;
		
		private var state:Number = STATE_INIT;
		
		private var environment:Environment;
		
		override public function run():void
		{
			// Responsive stage size
			stage.scaleMode = StageScaleMode.LETTERBOX;
			
			// Triggers on touch start, move and end
			stage.addEventListener(TouchEvent.TOUCH, touched);
			
			stage.addEventListener(Event.RESIZE, resized);
			resized();
			
			environment = new Environment(stage);
			stage.addEventListener(Environment.GAMEOVER, gameover);
			
			//switchState(STATE_GAME);
		}
		
		private function resized(e:Event = null):void
		{
		}
		
		private function touched(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			
			switch (touch.phase) {
				case TouchPhase.BEGAN:
					switch (state) {
						case STATE_INIT: switchState(STATE_GAME); break;
					}
			}
			
			if (state == STATE_GAME) {
				environment.touched(touch);
			}
		}
		
		private function gameover(e:Event):void {
			switchState(STATE_INIT);
		}
		
		public function switchState(newState:Number)
		{
			stateExit(state);
			state = newState;
			stateEnter(state);
		}
		
		private function stateExit(state:Number) {
			switch (state) {
				case STATE_INIT:
					break;
			}
		}
		
		private function stateEnter(state:Number) {
			switch (state) {
				case STATE_GAME:
					environment.launch();
					break;
			}
		}
		
		
		override public function onTick()
		{
			environment.tick();
			return super.onTick();
		}
		
		override public function onFrame()
		{
			environment.render();
			return super.onFrame();
		}
		
	}
}