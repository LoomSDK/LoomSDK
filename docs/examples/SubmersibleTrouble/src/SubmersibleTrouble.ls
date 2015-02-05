package
{
    import loom.Application;
	import loom.gameframework.TimeManager;
	import loom.sound.Listener;
    import loom2d.display.StageScaleMode;
    import loom2d.events.Event;
	import loom2d.events.KeyboardEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
	
	/**
	 * Main entry point that handles general game events and setup.
	 */
	public class SubmersibleTrouble extends Application
	{
		private var environment:Environment;
		
		// Gets injected automatically before run() is called
		[Inject] private var timeManager:TimeManager;
		
		override public function run():void
		{
			// No scaling for stage for custom scaling logic in Environment
			stage.scaleMode = StageScaleMode.NONE;
			SplashLoader.init(stage, timeManager, load);
			
			// Handle app pausing
			applicationActivated += onActivated;
			applicationDeactivated += onDeactivated;
			
		}

		/**
		* Mute sounds when the app is paused
		*/
		private function onDeactivated():void
		{
			Listener.setGain(0);
		}
		
		/**
		* Unmute sounds when the app is resumed
		*/
		private function onActivated():void
		{
			Listener.setGain(1);
		}
		
		private function load():void {
			environment = new Environment(stage);
		}
		
		override public function onTick()
		{
			if (environment) environment.tick();
			return super.onTick();
		}
		
		override public function onFrame()
		{
			if (environment) environment.render();
			return super.onFrame();
		}
		
	}
}