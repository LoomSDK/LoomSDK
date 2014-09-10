package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
	
	/**
	 * Main entry point that handles general game state
	 * with an example of a simple state machine.
	 */
	public class SubmersibleTrouble extends Application
	{
		
		private static const STATE_INIT = 0;
		private static const STATE_GAME = 1;
		private var state:Number = STATE_INIT;
		
		private var environment:Environment;
		
		override public function run():void
		{
			// Scale stage with black borders
			stage.scaleMode = StageScaleMode.LETTERBOX;
			
			// Triggers on touch start, move and end
			stage.addEventListener(TouchEvent.TOUCH, touched);
			
			environment = new Environment(stage);
			stage.addEventListener(Environment.GAMEOVER, gameover);
		}
		
		private function touched(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			switch (state) {
				case STATE_INIT:
					if (touch.phase == TouchPhase.BEGAN) switchState(STATE_GAME);
					break;
				case STATE_GAME:
					environment.touched(touch);
					break;
			}
		}
		
		private function gameover(e:Event):void
		{
			switchState(STATE_INIT);
		}
		
		public function switchState(newState:Number)
		{
			stateExit(state);
			state = newState;
			stateEnter(state);
		}
		
		private function stateExit(state:Number) {}
		
		private function stateEnter(state:Number)
		{
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