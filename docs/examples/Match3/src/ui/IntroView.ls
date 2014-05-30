package ui {
	import feathers.controls.Label;
	import loom2d.animation.Juggler;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.textures.Texture;
	class IntroView extends ConfigView {
		
		public var onStart:ViewCallback;
		
		[Bind] public var title:Label;
		private var juggler:Juggler = new Juggler();
		private var h:Number;
		
		function get layoutFile():String { return "assets/intro.lml"; }
		
		public function init() {
			super.init();
			title.nameList.add("title");
			title.text = "KrUSH\nBLOkk";
		}
		
		public function resize(w:Number, h:Number) {
			super.resize(w, h);
			this.h = h;
			title.setSize(w, NaN);
			title.validate();
		}
		
        public function enter(owner:DisplayObjectContainer) {
			super.enter(owner);
			stage.addEventListener(TouchEvent.TOUCH, touch);
		}
		
		public function tick() {
			super.tick();
			juggler.advanceTime(1/60);
			title.y = (h-title.height)/2-20+Math.sin(juggler.elapsedTime*0.8)*4;
		}
		
		private function touch(e:TouchEvent):void {
			if (e.touches[0].phase == TouchPhase.BEGAN) onStart();
		}
		
        public function exit() {
			stage.removeEventListener(TouchEvent.TOUCH, touch);
			super.exit();
		}
	}
}