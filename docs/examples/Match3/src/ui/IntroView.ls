package ui {
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.events.TouchEvent;
	import loom2d.textures.Texture;
	class IntroView extends View {
		
		public var onStart:ViewCallback;
		
		public function init() {
			var display = new Image(Texture.fromAsset("assets/intro.png"));
			display.center();
			display.x = 60;
			display.y = 60;
			addChild(display);
		}
		
        public function enter(owner:DisplayObjectContainer) {
			super.enter(owner);
			addEventListener(TouchEvent.TOUCH, touch);
		}
		
		private function touch(e:TouchEvent):void {
			onStart();
		}
		
        public function exit() {
			removeEventListener(TouchEvent.TOUCH, touch);
			super.exit();
		}
	}
}