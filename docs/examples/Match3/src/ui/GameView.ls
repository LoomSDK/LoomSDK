package ui {
	import Board;
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.core.ITextRenderer;
	import feathers.text.BitmapFontTextFormat;
	import feathers.text.BitmapFontTextRenderer;
	import loom2d.animation.Transitions;
	import loom2d.display.DisplayObject;
	import loom2d.display.Sprite;
	import loom2d.events.Event;
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
	class GameView extends ConfigView {
		
		public var onQuit:ViewCallback;
		public var onTimeout:ViewCallback;
		
		private static const STATE_GAME   = 0;
		private static const STATE_QUIT   = 1;
		private static const STATE_ENDING = 2;
		private var state = STATE_GAME;
		
		private var dt:Number = 1/60;
		private var t:Number;
		private var juggler:Juggler = new Juggler();
		
		private var w:Number = 0;
		private var h:Number = 0;
		
		private var screenshaker:Shaker;
		private var screenshake:Number;
		
		private var confirmView:ConfirmView;
		
		public var score:int;
		
		[Bind] public var esc:Button;
		[Bind] public var timeDisplay:Label;
		[Bind] public var lastDisplay:Label;
		[Bind] public var multiDisplay:Label;
		[Bind] public var scoreDisplay:Label;
		
		//private var textScale:Number = 0.4;
		private var textScale:Number = 1;
		
		private var last:Number;
		private var multiplier:Number;
		
		private var field:Sprite = new Sprite();
		private var board:Board;
		//private var particles:ParticleSystem;
		private var particles:PDParticleSystem;
		
		private var explosion:Sound;
		
		private var momentum:Number;
		
		private var soundtrack:Sound;
		private var background:TiledImage2;
		//private var background:OffsetTiledImage;
		private var bgColor = new Color(0, 0.3*0xFF, 0.3*0xFF);
		private var bgScroll:Number;
		
		private var beatAccumulator:Number = 0;
		private var beatInterval:Number = 1.71425;
		
		function get layoutFile():String {
			return "assets/game.lml";
		}
		
		public function init() {
			
			background = new TiledImage2(Texture.fromAsset("assets/background.png"), 2);
			//background = new OffsetTiledImage(Texture.fromAsset("assets/background.png"), 2);
			addChild(background);
			
			super.init();
			
			esc.addEventListener(Event.TRIGGERED, confirmQuit);
			confirmView = new ConfirmView();
			confirmView.onYes += confirmYes;
			confirmView.onNo += confirmNo;
			confirmView.init();
			
			//particles = PDParticleSystem.loadLiveSystem("assets/pointer.pex");
			particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex");
			particles.emitterX = 60;
			particles.emitterY = 60;
			juggler.add(particles);
			
			board = new Board(juggler);
			board.onTileClear += tileClear;
			board.onTilesMatched += tilesMatched;
			board.onEnded += boardEnded;
			board.init();
			field.addChild(board);
			
			initDisplay(timeDisplay);
			initDisplay(lastDisplay);
			initDisplay(multiDisplay);
			initDisplay(scoreDisplay);
			
			screenshaker = new Shaker(board);
			screenshaker.start(juggler);
			
			field.addChild(particles);
			
			addChild(field);
			
			addChild(confirmView);
			
			//soundtrack = Sound.load("assets/contemplation 2.ogg");
			//soundtrack.setLooping(true);
			
			explosion = Sound.load("assets/tileExplosion.ogg");
			
		}
		
		
		private function initDisplay(display:Label) {
			display.nameList.add("light");
			field.addChild(display);
		}
		
		private function confirmQuit(e:Event):void {
			showConfirm();
			state = STATE_QUIT;
		}
		private function showConfirm() {
			confirmView.visible = true;
		}
		private function hideConfirm() {
			confirmView.visible = false;
		}
		private function confirmYes():void {
			onQuit();
		}
		private function confirmNo():void {
			hideConfirm();
			state = STATE_GAME;
		}
		
		public function resize(w:Number, h:Number) {
			this.w = w;
			this.h = h;
			confirmView.resize(w, h);
			esc.width = 30;
			esc.x = w-esc.width;
			background.setSize(w, h);
			//field.x = (w-s)/2;
			field.x = (w-board.contentWidth)/2;
			field.y = h-board.contentHeight-10;
			updateDisplay();
		}
		
		private function tileClear(x:Number, y:Number, color:Color) {
			explode(x, y, color);
		}
		
		private function tilesMatched(m:Match):void {
			if (state == STATE_ENDING) return;
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
		
		private function positionRight(d:DisplayObject, offset:Number) {
			d.x = 5+board.contentWidth-d.width-offset;
			d.y = -10;
		}
		
		private function updateDisplay() {
			updateScore();
			updateMulti();
			updateLast();
			updateTime();
		}
		
		private function updateScore() {
			var newText = ""+score;
			if (newText != scoreDisplay.text) {
				scoreDisplay.text = ""+score;
				scoreDisplay.validate();
			}
			positionRight(scoreDisplay, 5);
			scoreDisplay.scale = textScale*2;
			juggler.tween(scoreDisplay, 0.5, {
				scale: textScale,
				transition: Transitions.EASE_OUT_ELASTIC
			});
		}
		
		private function updateMulti() {
			var newText = "x "+multiplier.toFixed(2);
			if (newText != multiDisplay.text) {
				multiDisplay.text = newText;
				multiDisplay.validate();
				//multiDisplay.center();
				//multiDisplay.x = w-multiDisplay.size.x*textScale-40;
				//multiDisplay.x = w-multiDisplay.size.x*textScale-15;
				//multiDisplay.y = h-w-multiDisplay.size.y*textScale;
			}
			positionRight(multiDisplay, 35);
		}
		
		private function updateLast() {
			var newText = "+"+last;
			if (newText != lastDisplay.text) {
				lastDisplay.text = newText;
				lastDisplay.validate();
			}
			juggler.removeTweens(lastDisplay);
			lastDisplay.alpha = 1;
			juggler.tween(lastDisplay, 3, {
				alpha: 0,
				transition: Transitions.EASE_IN
			});
			lastDisplay.x = multiDisplay.x-lastDisplay.width-2;
			lastDisplay.y = multiDisplay.y;
		}
		
		private function updateTime() {
			var newText = Math.abs(Math.ceil(config.duration - t)).toFixed(0);
			if (newText != timeDisplay.text) {
				timeDisplay.text = newText;
				timeDisplay.validate();
			}
			positionRight(timeDisplay, 85);
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
			if (state == STATE_ENDING) {
				explosion.setPitch(1+Math.randomRange(-0.1, 0.1));
			} else {
				explosion.setPitch(getPitch(momentum)+Math.randomRange(-0.1, 0.1));
			}
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
			state = STATE_GAME;
			hideConfirm();
			board.freeformMode = config.freeform;
			board.reset();
			t = 0;
			beatAccumulator = 0;
			score = 0;
			momentum = 0;
			screenshake = 0;
			bgScroll = 0;
			multiplier = 1;
			updateDisplay();
			//soundtrack.play();
			//stage.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent) {
				//var t:Touch = e.touches[0];
				//background.setScroll(t.globalX, t.globalY);
			//});
		}
		
        public function exit() {
			super.exit();
			particles.clear();
			//soundtrack.stop();
		}
		
		public function tick() {
			if (state == STATE_QUIT) return;
			
			t += dt;
			juggler.advanceTime(dt);
			screenshaker.strength = screenshake;
			screenshake -= screenshake*6*dt;
			if (Math.abs(screenshake) < 0.1) screenshake = 0;
			momentum -= momentum*0.2*dt;
			bgScroll -= momentum*1.5*dt;
			
			if (state == STATE_ENDING) return;
			
			multiplier = Math.round(Math.pow(1+0.1*momentum, 2)/0.5)*0.5;
			updateMulti();
			//soundtrack.setPitch(getPitch(momentum));
			//while (beatAccumulator < t) {
				//screenshake = 2;
				//beatAccumulator += beatInterval;
			//}
			updateTime();
			if (config.duration > 0 && t >= config.duration) {
				end();
			}
		}
		
		private function end() {
			state = STATE_ENDING;
			board.end();
		}
		
		private function boardEnded():void {
			onTimeout();
		}
		
		public function render() {
			bgColor.red += ((1-Math.exp(-momentum*0.2))*0xFF-bgColor.red)*0.1;
			background.color = bgColor.toInt();
			background.scrollY = bgScroll;
			board.render();
		}
		
	}
}