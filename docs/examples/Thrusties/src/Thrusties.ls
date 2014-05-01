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
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleLabel;
	import system.Void;
	
	/**
	* Main entry class that mostly just handles initialization and events.
	*/
	public class Thrusties extends Application
	{
		private var bg:TiledImage;
		private var environment:Environment;
		
		override public function run():void
		{
			// Responsive stage size
			stage.scaleMode = StageScaleMode.NONE;
			
			// Tiled background image
			bg = new TiledImage(Texture.fromAsset("assets/bg.png"), 2);
			stage.addChild(bg);
			
			// Triggers on touch start, move and end
			stage.addEventListener(TouchEvent.TOUCH, touched);
			
			stage.addEventListener(Event.RESIZE, resized);
			resized();
			
			environment = new Environment(stage);
		}
		
		private function resized(e:Event = null):void
		{
			bg.width = stage.stageWidth;
			bg.height = stage.stageHeight;
		}
		
		private function touched(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			environment.touched(touch.getLocation(stage));
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