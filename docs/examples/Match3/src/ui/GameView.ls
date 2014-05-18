package ui {
	import extensions.ParticleSystem;
	import extensions.PDParticleSystem;
	import loom.LoomTextAsset;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import Board;
	import loom2d.Loom2D;
	import loom2d.math.Point;
	import system.xml.XMLDocument;
	class GameView extends View {
		
		public var onQuit:ViewCallback;
		
		private var board:Board;
		//private var particles:ParticleSystem;
		private var particles:PDParticleSystem;
		
		public function init() {
			board = new Board();
			addChild(board);
			
			//particles = new ParticleSystem(getTexture("assets/intro.png"), 6, 5, 5);
			//particles = new PDParticleSystem(getTexture("assets/intro.png"));
			//particles = new PDParticleSystem(getTexture("assets/tiles/tile0.png"));
			
			particles = PDParticleSystem.loadLiveSystem("assets/particle.pex", getTexture("assets/tiles/tile0.png"));
			particles.emitterX = 60;
			particles.emitterY = 60;
			addChild(particles);
			//particles.populate(50);
			particles.start();
			
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onTouch(e:TouchEvent):void {
			var t:Touch = e.touches[0];
			var p = t.getLocation(this);
			particles.emitterX = p.x;
			particles.emitterY = p.y;
		}
		
        public function enter(owner:DisplayObjectContainer) {
			super.enter(owner);
			board.resize(120, 120);
			Loom2D.juggler.add(particles);
		}
		
        public function exit() {
			super.exit();
			Loom2D.juggler.remove(particles);
		}
		
		public function tick() {
			board.tick();
			
		}
		
		public function render() {
			board.render();
		}
		
	}
}