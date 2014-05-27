package ui {
	import feathers.controls.Button;
	import loom2d.display.Image;
	import loom2d.events.Event;
	import loom2d.textures.Texture;
	class ConfirmView extends ConfigView {
		
		public var onYes:ViewCallback;
		public var onNo:ViewCallback;
		
		private var background:Image;
		
		[Bind] var quit:Button;
		[Bind] var yes:Button;
		[Bind] var no:Button;
		
		function get layoutFile():String { return "assets/confirm.lml"; }
		
		public function created() {
			//background = new TiledImage(Texture.fromAsset("assets/background.png"), 2);
			background = new Image(Texture.fromAsset("assets/dialogColor.png"));
			addChildAt(background, 0);
			
			var q = 0;
			var labels:Vector.<String> = [
				"Quit?",
				"no touching",
				"i am serious",
				"i am going",
				"to krush you",
				"with blokks",
				"stop",
				"it",
				"right",
				"now",
				".",
				"..",
				"...",
				"...",
				"...",
				"Fine",
				"do it",
				"then",
				"if",
				"that",
				"is",
				"your",
				"fetish",
				"",
				"",
				"",
			];
			quit.addEventListener(Event.TRIGGERED, function(e:Event) {
				quit.label = labels[(++q)%labels.length];
			});
			
			yes.addEventListener(Event.TRIGGERED, function(e:Event) {
				onYes();
			});
			no.addEventListener(Event.TRIGGERED, function(e:Event) {
				onNo();
			});
			
		}
		
		public function resize(w:Number, h:Number) {
			super.resize(w, h);
			background.width = w;
			background.height = h;
			//background.setSize(w, h);
		}
		
	}
}