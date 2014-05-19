package
{
	import loom.Application;
	import loom2d.display.Sprite;
	import loom2d.display.StageScaleMode;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	import ui.IntroView;
	import ui.ModeView;
	import ui.GameView;
	import ui.View;
	
	public class Match3 extends Application
	{
		
		private var intro = new IntroView();
		private var mode = new ModeView();
		private var game = new GameView();
		
		private var display:Sprite = new Sprite();
		private var currentView:View;
		
		override public function run():void
		{
			// Scale stage with black borders
			stage.scaleMode = StageScaleMode.LETTERBOX;
			
			TextureSmoothing.defaultSmoothing = TextureSmoothing.NONE;
			
			var views:Vector.<View> = new <View>[intro, mode, game];
			for each (var view:View in views) {
				view.init();
			}
			
			intro.onStart += function() { switchView(mode); };
			mode.onPick += function() { switchView(intro); };
			
			display.scale = 4;
			stage.addChild(display);
			
			//switchView(intro);
			switchView(game);
		}
		
		private function switchView(newView:View) {
			if (currentView) currentView.exit();
			currentView = newView;
			currentView.enter(display);
		}
		
		override public function onTick()
		{
			currentView.tick();
			return super.onTick();
		}
		
		override public function onFrame()
		{
			currentView.render();
			return super.onFrame();
		}
		
	}
}