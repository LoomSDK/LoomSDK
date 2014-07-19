package
{
	import feathers.display.TiledImage;
	import loom.Application;
	import loom.gameframework.TimeManager;
	import loom.physics.Physics;
	import loom.physics.PhysicsBall;
	import loom.utils.Injector;
	import loom2d.display.Stage;
	import loom2d.display.StageScaleMode;
	import loom2d.display.Image;
	import loom2d.events.Event;
	import loom2d.events.KeyboardEvent;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleLabel;
	import system.Void;
	
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