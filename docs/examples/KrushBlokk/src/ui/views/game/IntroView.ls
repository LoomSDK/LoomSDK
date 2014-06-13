package ui.views.game {
	import system.platform.Platform;
	import ui.views.ConfigView;
	import feathers.controls.Label;
	import loom2d.animation.Juggler;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.textures.Texture;
	import ui.views.ViewCallback;
	
	/**
	 * Simple intro screen view.
	 */
	class IntroView extends ConfigView
	{
		public var onStart:ViewCallback;
		
		[Bind] public var title:Label;
		private var h:Number;
		
		function get layoutFile():String { return "intro.lml"; }
		
		public function init()
		{
			super.init();
			title.nameList.add("title");
		}
		
		public function resize(w:Number, h:Number)
		{
			super.resize(w, h);
			this.h = h;
			title.width = w;
		}
		
        public function enter(owner:DisplayObjectContainer)
		{
			super.enter(owner);
			stage.addEventListener(TouchEvent.TOUCH, touch);
		}
		
		public function tick()
		{
			super.tick();
			// Gentle up and down sway animation
			title.y = (h-title.height)/2-20+Math.sin(Platform.getTime()/1000*0.8)*4;
		}
		
		private function touch(e:TouchEvent)
		{
			if (e.touches[0].phase == TouchPhase.BEGAN) onStart();
		}
		
        public function exit()
		{
			stage.removeEventListener(TouchEvent.TOUCH, touch);
			super.exit();
		}
	}
}