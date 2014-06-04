package ui.views.game {
	import ui.views.DialogView;
	import feathers.controls.Button;
	import feathers.controls.Check;
	import loom2d.events.Event;
	import loom2d.ui.SimpleButton;
	
	/**
	 * Mode dialog view for picking game config options.
	 */
	class ModeView extends DialogView {
		
		[Bind] public var modeTimed:Button;
		[Bind] public var modeUnlimited:Button;
		[Bind] public var modeFreeform:Check;
		
		function get layoutFile():String { return "mode.lml"; }
		
		public function created() {
			items.push(modeTimed);
			items.push(modeUnlimited);
			items.push(modeFreeform);
			modeTimed.addEventListener(Event.TRIGGERED, pick(function(e:Event) {
				config.freeform = modeFreeform.isSelected;
				config.duration = 0;
				config.modeLabel = modeTimed.label;
			}));
			modeUnlimited.addEventListener(Event.TRIGGERED, pick(function(e:Event) {
				config.freeform = modeFreeform.isSelected;
				config.duration = -1;
				config.modeLabel = modeUnlimited.label;
			}));
		}
	}
}