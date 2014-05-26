package ui {
	import Board;
	import feathers.controls.Label;
	import feathers.text.BitmapFontTextFormat;
	import loom2d.animation.Transitions;
	import loom2d.textures.TextureSmoothing;
	import loom2d.ui.SimpleLabel;
	import Match;
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
	import system.Number;
	class GameView extends ConfigView {
		
		public var onQuit:ViewCallback;
		public var onTimeout:ViewCallback;
		
		private var dt:Number = 1/60;
		private var t:Number;
		private var juggler:Juggler = new Juggler();
		
		private var w:Number = 0;
		private var h:Number = 0;
		
		private var screenshaker:Shaker;
		private var screenshake:Number;
		
		public var score:int;
		
		public var timeDisplay:SimpleLabel;
		[Bind]
		public var scoreDisplay:SimpleLabel;
		//public var scoreDisplay:Label;
		private var lastDisplay:SimpleLabel;
		private var multiDisplay:SimpleLabel;
		//private var textScale:Number = 0.4;
		private var textScale:Number = 1;
		
		private var last:Number;
		private var multiplier:Number;
		
		private var board:Board;
		//private var particles:ParticleSystem;
		private var particles:PDParticleSystem;
		
		private var explosion:Sound;
		
		private var momentum:Number;
		
		private var soundtrack:Sound;
		private var background:TiledImage2;
		//private var background:ScrollingImage;
		private var bgColor = new Color(0, 0.3*0xFF, 0.3*0xFF);
		private var bgScroll:Number;
		
		private var beatAccumulator:Number = 0;
		private var beatInterval:Number = 1.71425;
		
		function get layoutFile():String {
			return "assets/game.lml";
		}
		
		public function init() {
			
			background = new TiledImage2(Texture.fromAsset("assets/background.png"), 2);
			addChild(background);
			
			super.init();
			
			//particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex", getTexture("assets/explosion.png"));
			//particles = PDParticleSystem.loadLiveSystem("assets/pointer.pex");
			particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex");
			particles.emitterX = 60;
			particles.emitterY = 60;
			juggler.add(particles);
			
			board = new Board(juggler);
			board.onTileClear += tileClear;
			board.onTilesMatched += tilesMatched;
			addChild(board);
			
			//var fontFile = "assets/Curse.fnt";
			//var fontFile = "assets/CourierNew.fnt";
			var fontFile = "assets/kremlin-export.fnt";
			
			timeDisplay = new SimpleLabel(fontFile, 30, 20);
			timeDisplay.scale = textScale;
			timeDisplay.text = "";
			//scoreDisplay.y = 9;
			timeDisplay.y = 0;
			addChild(timeDisplay);
			
			scoreDisplay = new SimpleLabel(fontFile, 30, 20);
			scoreDisplay.scale = textScale;
			scoreDisplay.text = "";
			//scoreDisplay.y = 9;
			scoreDisplay.y = 0;
			addChild(scoreDisplay);
			
			//scoreDisplay.textRendererProperties["textFormat"] = new BitmapFontTextFormat("SourceSansPro", 8*4, 0xFFFF00);
			//scoreDisplay.text = "iashd";
			//scoreDisplay.invalidate();
			
			multiDisplay = new SimpleLabel(fontFile, 40, 20);
			multiDisplay.scale = textScale;
			multiDisplay.text = "";
			//multiDisplay.y = 9;
			multiDisplay.y = 0;
			addChild(multiDisplay);
			
			lastDisplay = new SimpleLabel(fontFile, 40, 20);
			lastDisplay.scale = textScale;
			lastDisplay.text = "";
			//multiDisplay.y = 9;
			lastDisplay.y = 0;
			addChild(lastDisplay);
			
			Texture.fromAsset(fontFile).smoothing = TextureSmoothing.MAX;
			
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
			this.w = w;
			this.h = h;
			background.setSize(w, h);
			updateScore();
			updateMulti();
		}
		
		private function tileClear(x:Number, y:Number, color:Color) {
			explode(x, y, color);
		}
		
		private function tilesMatched(m:Match):void {
			var matchLength = m.end-m.begin+1;
			addScore(matchLength*matchLength);
			if (m.type == null) {
				addScore(100);
				momentum += 30;
				screenshake += 20;
				explosion.setPitch(0.5);
				explosion.play();
			}
			updateScore();
		}
		
		private function addScore(delta:int) {
			var d = Math.ceil(multiplier*delta);
			score += d;
			last = d;
			updateLast();
		}
		
		private function updateScore() {
			scoreDisplay.text = ""+score;
			scoreDisplay.center();
			scoreDisplay.scale = textScale*2;
			scoreDisplay.x = w-scoreDisplay.size.x*textScale;
			juggler.tween(scoreDisplay, 0.5, {
				scale: textScale,
				transition: Transitions.EASE_OUT
			});
		}
		
		private function updateMulti() {
			var newText = "x "+multiplier.toFixed(2);
			if (newText != multiDisplay.text) {
				multiDisplay.text = newText;
				multiDisplay.center();
				//multiDisplay.x = w-multiDisplay.size.x*textScale-40;
				multiDisplay.x = w-multiDisplay.size.x*textScale-15;
			}
		}
		
		private function updateLast() {
			lastDisplay.text = "+"+last;
			lastDisplay.center();
			lastDisplay.x = w-lastDisplay.size.x*textScale-40;
			juggler.removeTweens(lastDisplay);
			lastDisplay.alpha = 1;
			juggler.tween(lastDisplay, 3, {
				alpha: 0,
				transition: Transitions.EASE_IN
			});
		}
		
		private function updateTime() {
			timeDisplay.text = Math.abs(Math.ceil(config.duration - t)).toFixed(2);
			timeDisplay.center();
			timeDisplay.x = 24;
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
			board.freeformMode = config.freeform;
			board.resize(120, 120);
			board.init();
			t = 0;
			beatAccumulator = 0;
			score = 0;
			momentum = 0;
			screenshake = 0;
			bgScroll = 0;
			multiplier = 1;
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
			bgScroll -= momentum*1.5*dt;
			//multiplier = Math.round((1+0.1*momentum)/0.25)*0.25;
			multiplier = Math.round(Math.pow(1+0.1*momentum, 2)/0.5)*0.5;
			updateMulti();
			//soundtrack.setPitch(getPitch(momentum));
			//while (beatAccumulator < t) {
				//screenshake = 2;
				//beatAccumulator += beatInterval;
			//}
			updateTime();
			if (config.duration > 0 && t >= config.duration) {
				onTimeout();
			}
		}
		
		public function render() {
			bgColor.red += ((1-Math.exp(-momentum*0.2))*0xFF-bgColor.red)*0.1;
			background.color = bgColor.toInt();
			background.scrollY = bgScroll;
			board.render();
		}
		
	}
}