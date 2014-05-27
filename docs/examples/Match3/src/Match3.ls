package
{
	import game.GameConfig;
	import loom.Application;
	import loom2d.display.Sprite;
	import loom2d.display.StageScaleMode;
	import loom2d.events.Event;
	import loom2d.text.BitmapFont;
	import loom2d.text.TextField;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	import ui.ConfigView;
	import ui.IntroView;
	import ui.ModeView;
	import ui.DifficultyView;
	import ui.GameView;
	import ui.Theme;
	import ui.View;
	
	public class Match3 extends Application
	{
		
		public var config:GameConfig = new GameConfig();
		
		private var intro = new IntroView();
		private var mode = new ModeView();
		private var difficulty = new DifficultyView();
		private var game = new GameView();
		
		private var display:Sprite = new Sprite();
		private var currentView:View;
		
		private var contentWidth = 450;
		private var contentHeight = 580;
		private var pixelScale = 4;
		
		override public function run():void
		{
			// No scaling for stage
			stage.scaleMode = StageScaleMode.NONE;
			
			TextureSmoothing.defaultSmoothing = TextureSmoothing.NONE;
			
			TextField.registerBitmapFont(BitmapFont.load("assets/kremlin-export.fnt"), "SourceSansPro");
			TextField.registerBitmapFont(BitmapFont.load("assets/kremlin-export.fnt"), "SourceSansProSemibold");
			new Theme();
			
			config.reset();
			
			var views:Vector.<View> = new <View>[intro, mode, difficulty, game];
			for each (var view:View in views) {
				if (view is ConfigView) (view as ConfigView).config = config;
				view.init();
			}
			
			intro.onStart += function() { switchView(mode); };
			mode.onPick += function() {
				if (config.duration == -1) {
					switchView(game);
				} else {
					switchView(difficulty);
				}
			};
			difficulty.onPick += function() {
				switchView(game);
			};
			game.onQuit += function() {
				trace("QUIT! "+game.score);
				switchView(intro);
			};
			game.onTimeout += function() {
				trace("TIMEOUT! "+game.score);
				switchView(intro);
			};
			
			stage.addChild(display);
			
			stage.addEventListener(Event.RESIZE, resize);
			
			//switchView(intro);
			//switchView(mode);
			//switchView(difficulty);
			switchView(game);
		}
		
		private function resize(e:Event = null):void {
			if (stage.stageWidth/stage.stageHeight < contentWidth/contentHeight) {
				display.scale = Math.max(1, Math.floor(pixelScale*stage.stageWidth/contentWidth));
			} else {
				display.scale = Math.max(1, Math.floor(pixelScale*stage.stageHeight/contentHeight));
			}
			var w = stage.stageWidth/display.scale;
			var h = stage.stageHeight/display.scale;
			currentView.resize(w, h);
		}
		
		private function switchView(newView:View) {
			if (currentView) currentView.exit();
			currentView = newView;
			currentView.enter(display);
			resize();
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