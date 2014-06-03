package ui.views.game {
	import feathers.controls.Button;
	import loom2d.display.Image;
	import loom2d.events.Event;
	import loom2d.textures.Texture;
	import ui.views.DialogView;
	
	/**
	 * Difficulty selection screen view displayed after picking
	 * the timed mode in ModeView.
	 */
	class DifficultyView extends DialogView
	{
		[Bind] public var modeLeisurely:Button;
		[Bind] public var modeStandard:Button;
		[Bind] public var modeBeast:Button;
		
		function get layoutFile():String { return "assets/difficulty.lml"; }
		
		public function created()
		{
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
		
		/**
		 * Creates a feathers button with the provided icon and trigger handler.
		 */
		public function initButton(b:Button, icon:String, onTouch:Function)
		{
			b.paddingLeft = 25;
			b.defaultLabelProperties["width"] = 55;
			b.width = 60;
			b.defaultIcon = new Image(Texture.fromAsset(icon));
			b.iconPosition = Button.ICON_POSITION_RIGHT;
			b.addEventListener(Event.TRIGGERED, onTouch);
		}
		
	}
}