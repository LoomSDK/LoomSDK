package ui {
	import game.GameConfig;
	import loom.lml.LML;
	import loom.lml.LMLDocument;
	class ConfigView extends View {
		
		public var config:GameConfig;
		public var onPick:ViewCallback;
		
		function get layoutFile():String { return null; }
		
		public function init() {
			if (layoutFile != null) {
				var doc:LMLDocument = LML.bind(layoutFile, this);
				doc.onLMLCreated += created;
				doc.apply();
			}
		}
		
		protected function created():void {}
		
		protected function pick(setup:Function):Function {
			return function() {
				setup();
				onPick();
			};
		}
	}
}