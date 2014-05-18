package ui {
	import loom2d.display.DisplayObjectContainer;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	class ModeView extends View {
		
		public var onPick:ViewCallback;
		
		public function ModeView()
		{
			super();
		}
        public function enter(owner:DisplayObjectContainer) {
			super.enter(owner);
			owner.stage.addEventListener(TouchEvent.TOUCH, touch);
		}
		
		private function touch(e:TouchEvent):void {
			var t:Touch = e.touches[0];
			if (t.phase == TouchPhase.BEGAN) onPick();
		}
		
        public function exit() {
			parent.stage.removeEventListener(TouchEvent.TOUCH, touch);
			super.exit();
		}
	}
}