package ui {
	import Board;
	import feathers.display.TiledImage2;
	import extensions.PDParticleSystem;
	import game.Shaker;
	import loom.sound.Sound;
	import loom2d.animation.Juggler;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.math.Color;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	class GameView extends View {
		
		public var onQuit:ViewCallback;
		
		private var dt:Number = 1/60;
		private var t:Number = 0;
		private var juggler:Juggler = new Juggler();
		
		private var screenshaker:Shaker;
		private var screenshake:Number = 0;
		
		private var board:Board;
		//private var particles:ParticleSystem;
		private var particles:PDParticleSystem;
		
		
		private var explosion:Sound;
		
		private var momentum:Number = 0;
		
		private var soundtrack:Sound;
		private var background:TiledImage2;
		//private var background:ScrollingImage;
		private var bgColor = new Color(0, 0.3*0xFF, 0.3*0xFF);
		private var bgScroll:Number = 0;
		
		private var beatAccumulator:Number = 0;
		private var beatInterval:Number = 1.71425;
		
		public function init() {
			
			//particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex", getTexture("assets/explosion.png"));
			//particles = PDParticleSystem.loadLiveSystem("assets/pointer.pex");
			particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex");
			particles.emitterX = 60;
			particles.emitterY = 60;
			juggler.add(particles);
			
			background = new TiledImage2(Texture.fromAsset("assets/background.png"), 2);
			addChild(background);
			
			board = new Board(juggler);
			board.onTileClear += tileClear;
			addChild(board);
			
			screenshaker = new Shaker(board);
			screenshaker.start(juggler);
			
			addChild(particles);
			
			//soundtrack = Sound.load("assets/contemplation 2.ogg");
			//soundtrack.setLooping(true);
			
			explosion = Sound.load("assets/tileExplosion.ogg");
			
			//particles = new ParticleSystem(getTexture("assets/intro.png"), 6, 5, 5);
			//particles = new PDParticleSystem(getTexture("assets/intro.png"));
			//particles = new PDParticleSystem(getTexture("assets/tiles/tile0.png"));
			
			//particles.populate(50);
			//particles.start();
			
			//addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function resize(w:Number, h:Number) {
			background.setSize(w, h);
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
			screenshake += 0.25;
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
			t = 0;
			beatAccumulator = 0;
			//soundtrack.play();
			//stage.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent) {
				//var t:Touch = e.touches[0];
				//background.setScroll(t.globalX, t.globalY);
			//});
		}
		
        public function exit() {
			super.exit();
			//soundtrack.stop();
		}
		
		public function tick() {
			t += dt;
			juggler.advanceTime(dt);
			board.tick();
			screenshaker.strength = screenshake;
			screenshake -= screenshake*6*dt;
			if (Math.abs(screenshake) < 0.1) screenshake = 0;
			momentum -= momentum*0.2*dt;
			bgScroll += momentum*1.5*dt;
			//soundtrack.setPitch(getPitch(momentum));
			//while (beatAccumulator < t) {
				//screenshake = 2;
				//beatAccumulator += beatInterval;
			//}
		}
		
		public function render() {
			bgColor.red += ((1-Math.exp(-momentum*0.2))*0xFF-bgColor.red)*0.1;
			background.color = bgColor.toInt();
			background.scrollY = bgScroll;
			board.render();
		}
		
	}
}