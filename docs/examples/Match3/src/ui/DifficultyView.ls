package ui {
	import feathers.controls.Button;
	import game.GameConfig;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.events.Event;
	import loom2d.textures.Texture;
	import loom2d.ui.SimpleButton;
	class DifficultyView extends DialogView {
		
		//[Bind] public var modeLeisurely:SimpleButton;
		//[Bind] public var modeStandard:SimpleButton;
		//[Bind] public var modeBeast:SimpleButton;
		[Bind] public var modeLeisurely:Button;
		[Bind] public var modeStandard:Button;
		[Bind] public var modeBeast:Button;
		
		function get layoutFile():String { return "assets/difficulty.lml"; }
		
		public function created() {
			
			//modeLeisurely.width = 70;
			//modeLeisurely.defaultIcon = new Image(Texture.fromAsset("assets/ui/iconLeisurely.png"));
			//modeLeisurely.iconPosition = Button.ICON_POSITION_RIGHT;
			
			items.push(modeLeisurely);
			items.push(modeStandard);
			items.push(modeBeast);
			
			initButton(modeLeisurely, "assets/ui/iconLeisurely.png", pick(function() {
				config.diffLabel = modeLeisurely.label;
				config.duration = 60*5;
			}));
			initButton(modeStandard, "assets/ui/iconStandard.png", pick(function() {
				config.diffLabel = modeStandard.label;
				config.duration = 60*2;
			}));
			initButton(modeBeast, "assets/ui/iconBeast.png", pick(function() {
				config.diffLabel = modeBeast.label;
				config.duration = 30;
			}));
		}
		
		public function initButton(b:Button, icon:String, onClick:Function) {
			b.paddingLeft = 25;
			b.defaultLabelProperties["width"] = 55;
			b.width = 60;
			b.defaultIcon = new Image(Texture.fromAsset(icon));
			b.iconPosition = Button.ICON_POSITION_RIGHT;
			b.addEventListener(Event.TRIGGERED, onClick);
		}
		
	}
}