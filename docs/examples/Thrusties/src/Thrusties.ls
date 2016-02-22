package
{
    import feathers.display.TiledImage;
    import loom.Application;
	import loom.gameframework.TimeManager;
	import loom.sound.Listener;
    import loom2d.display.StageScaleMode;
    import loom2d.events.Event;
	import loom2d.events.KeyboardEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.textures.Texture;
	
	import unittest.Assert;
	
	/**
	* Main entry class that mostly just handles initialization and events.
	*/
	public class Thrusties extends Application
	{
		private var bg:TiledImage;
		private var environment:Environment;
		
		// Gets injected automatically before run() is called
		[Inject] private var timeManager:TimeManager;
		
		override public function run():void
		{
			// Responsive stage size
			stage.scaleMode = StageScaleMode.NONE;
			
			SplashLoader.init(stage, timeManager, load);
		}
		
		private function load():void
		{
			// Tiled background image
			bg = new TiledImage(Texture.fromAsset("assets/bg.png"), 2);
			stage.addChild(bg);
			
			// Triggers on touch start, move and end
			stage.addEventListener(TouchEvent.TOUCH, touched);
			
			stage.addEventListener(KeyboardEvent.BACK_PRESSED, back);
			
			// Handle app pausing
			applicationActivated += onActivated;
			applicationDeactivated += onDeactivated;
			
			stage.addEventListener(Event.RESIZE, resized);
			resized();
			
			environment = new Environment(stage);
			
			var demo = new Help(environment);
			stage.addChild(demo);
			demo.run();
		}
		
        [Test]
        function thrusty() {
            Assert.isTrue(false, "YAY, FAILED IN A GOOD WAY!!!");
        }
		
		/**
		 * Exits the application when the back button is pressed
		 */
		private function back(e:KeyboardEvent):void 
		{
			Process.exit(0);
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
		
		private function resized(e:Event = null):void
		{
			bg.width = stage.stageWidth;
			bg.height = stage.stageHeight;
		}
		
		private function touched(e:TouchEvent):void
		{
			if (environment) environment.touched(e);
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