package ui {
	import extensions.ParticleSystem;
	import extensions.PDParticleSystem;
	import loom.LoomTextAsset;
	import loom.sound.Sound;
	import loom2d.animation.Juggler;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import Board;
	import loom2d.Loom2D;
	import loom2d.math.Color;
	import loom2d.math.Point;
	import system.xml.XMLDocument;
	class GameView extends View {
		
		public var onQuit:ViewCallback;
		
		private var dt:Number = 1/60;
		private var juggler:Juggler = new Juggler();
		
		private var board:Board;
		//private var particles:ParticleSystem;
		private var particles:PDParticleSystem;
		
		private var explosion:Sound;
		
		private var momentum:Number = 0;
		
		public function init() {
			
			//particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex", getTexture("assets/explosion.png"));
			//particles = PDParticleSystem.loadLiveSystem("assets/pointer.pex");
			particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex");
			particles.emitterX = 60;
			particles.emitterY = 60;
			
			board = new Board(juggler);
			board.onTileClear += tileClear;
			addChild(board);
			
			addChild(particles);
			
			explosion = Sound.load("assets/tileExplosion.ogg");
			
			//particles = new ParticleSystem(getTexture("assets/intro.png"), 6, 5, 5);
			//particles = new PDParticleSystem(getTexture("assets/intro.png"));
			//particles = new PDParticleSystem(getTexture("assets/tiles/tile0.png"));
			
			//particles.populate(50);
			//particles.start();
			
			//addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function tileClear(x:Number, y:Number, color:Color) {
			explode(x, y, color);
		}
		
		public function getPitch(x:Number):Number {
			//return 0.8+0.4*(1-Math.exp(-x*0.25));
			return 0.8+0.2*(Math.exp(x*0.08)-1);
			//return 0.8+0.2*x*0.1;
		}
		
		private function explode(x:Number, y:Number, color:Color) {
			particles.emitterX = x;
			particles.emitterY = y;
			particles.startColor = color;
			particles.populate(6, 0);
			explosion.setPitch(getPitch(momentum)+Math.randomRange(-0.1, 0.1));
			explosion.play();
			momentum++;
		}
		
		private function onTouch(e:TouchEvent):void {
			var t:Touch = e.touches[0];
			if (t.phase != TouchPhase.BEGAN) return;
			var p = t.getLocation(this);
			particles.emitterX = p.x;
			particles.emitterY = p.y;
			particles.populate(20, 0);
		}
		
        public function enter(owner:DisplayObjectContainer) {
			super.enter(owner);
			board.resize(120, 120);
			board.init();
			juggler.add(particles);
		}
		
        public function exit() {
			super.exit();
			juggler.remove(particles);
		}
		
		public function tick() {
			juggler.advanceTime(dt);
			board.tick();
			momentum -= momentum*0.2*dt;
		}
		
		public function render() {
			board.render();
		}
		
	}
}