package ui {
	import feathers.controls.Button;
	import feathers.controls.Check;
	import loom2d.events.Event;
	import loom2d.ui.SimpleButton;
	class ModeView extends DialogView {
		
		[Bind] public var modeTimed:Button;
		[Bind] public var modeUnlimited:Button;
		[Bind] public var modeFreeform:Check;
		
		function get layoutFile():String { return "assets/mode.lml"; }
		
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
			//modeTimed.onClick += pick(function() {
				//config.duration = 0;
			//});
			//modeUnlimited.onClick += pick(function() {
				//config.duration = -1;
			//});
			//var button:Button = new Button();
			//button.padding = 3;
			//button.label = "what";
			//button.x = 30;
			//button.y = 90;
			//this.addChild(button);
			//var check:Check = new Check();
			//check.isSelected = config.freeform;
			//check.label = "FrEeform MODE";
			//check.x = 16;
			//check.y = 90;
			//this.addChild(check);
		}
	}
}