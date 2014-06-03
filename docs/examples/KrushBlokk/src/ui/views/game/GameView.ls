package ui.views.game {
	import Board;
	import extensions.PDParticleSystem;
	import feathers.controls.Button;
	import feathers.controls.Label;
	import game.Shaker;
	import loom.sound.Sound;
	import loom2d.animation.Juggler;
	import loom2d.animation.Transitions;
	import loom2d.display.DisplayObject;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.Display.OffsetTiledImage;
	import loom2d.display.Sprite;
	import loom2d.events.Event;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.math.Color;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	import Match;
	import ui.views.ConfigView;
	import ui.views.ViewCallback;
	
	/**
	 * View responsible for general game logic shown while the timer is running.
	 * Handles everything except the actual match-3 board logic.
	 */
	class GameView extends ConfigView
	{
		public var onQuit:ViewCallback;
		public var onTimeout:ViewCallback;
		
		// Quick and simple state machine for easier overal game state control
		private static const STATE_GAME   = 0;
		private static const STATE_QUIT   = 1;
		private static const STATE_ENDING = 2;
		private var state = STATE_GAME;
		
		/** Delta time, how long each game tick lasts */
		private var dt:Number = 1/60;
		private var t:Number;
		
		/** Custom juggler used for most animations, enables easy pausing */
		private var juggler:Juggler = new Juggler();
		
		private var screenshaker:Shaker;
		private var screenshake:Number;
		
		/** Contained view, so it can be displayed on top of game */
		private var confirmView:ConfirmView;
		
		public var score:int;
		
		// User interface from LML
		[Bind] public var esc:Button;
		[Bind] public var timeDisplay:Label;
		[Bind] public var lastDisplay:Label;
		[Bind] public var multiDisplay:Label;
		[Bind] public var scoreDisplay:Label;
		
		private var textScale:Number = 1;
		
		/** Last added score */
		private var last:Number;
		/** Score multiplier */
		private var multiplier:Number;
		/** Represents the apparent momentum of the game as swapping speed increases */
		private var momentum:Number;
		
		/** Contains relatively positioned game stuff */
		private var field:Sprite = new Sprite();
		
		/** Contains all actual board logic and interaction */
		private var board:Board;
		
		/** Tiled scrolling background */
		//private var background:TiledImage2;
		private var background:OffsetTiledImage;
		private var bgColor = new Color(0, 0.3*0xFF, 0.3*0xFF);
		private var bgScroll:Number;
		
		/** Particle system for explosions */
		private var particles:PDParticleSystem;
		
		// Sounds
		private var explosion:Sound;
		private var soundtrack:Sound;
		
		function get layoutFile():String { return "assets/game.lml"; }
		
		public function init()
		{
			//background = new TiledImage2(Texture.fromAsset("assets/background.png"), 2);
			background = new OffsetTiledImage(Texture.fromAsset("assets/background.png"), 2);
			addChild(background);
			
			super.init();
			
			esc.addEventListener(Event.TRIGGERED, confirmQuit);
			
			confirmView = new ConfirmView();
			confirmView.onYes += confirmYes;
			confirmView.onNo += confirmNo;
			confirmView.init();
			
			board = new Board(juggler);
			board.onTileCleared += tileCleared;
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
			
			particles = PDParticleSystem.loadLiveSystem("assets/explosion.pex");
			particles.emitterX = 60;
			particles.emitterY = 60;
			juggler.add(particles);
			field.addChild(particles);
			
			addChild(field);
			
			//soundtrack = Sound.load("assets/contemplation 2.ogg");
			//soundtrack.setLooping(true);
			
			explosion = Sound.load("assets/tileExplosion.ogg");
		}
		
		/** Some additional label setup */
		private function initDisplay(display:Label)
		{
			display.nameList.add("light");
			field.addChild(display);
		}
		
		
		// Quit confirmation screen
		private function confirmQuit(e:Event)
		{
			showConfirm();
			state = STATE_QUIT;
		}
		private function showConfirm()
		{
			confirmView.enter(this);
		}
		private function hideConfirm()
		{
			confirmView.exit();
		}
		private function confirmYes()
		{
			onQuit();
		}
		private function confirmNo()
		{
			hideConfirm();
			state = STATE_GAME;
		}
		
		
		public function resize(w:Number, h:Number)
		{
			confirmView.resize(w, h);
			esc.width = 30;
			esc.x = w-esc.width;
			background.setSize(w, h);
			//background.x = 10; background.y = 10; background.setSize(w-20, h-20);
			field.x = (w-board.contentWidth)/2;
			field.y = h-board.contentHeight-10;
			updateDisplay();
		}
		
		private function tileCleared(x:Number, y:Number, color:Color)
		{
			explode(x, y, color);
			momentum++;
		}
		
		private function tilesMatched(m:Match)
		{
			if (state == STATE_ENDING) return;
			
			// Score based on the length of the match sequence squared
			var matchLength = m.end-m.begin+1;
			addScore(matchLength*matchLength);
			
			// For a special match, add a big score and large shake
			if (m.type == null) {
				addScore(100);
				momentum += 30;
				screenshake += 20;
				explosion.setPitch(0.5);
				explosion.play();
			}
			
			updateScore();
		}
		
		private function addScore(delta:int)
		{
			var d = Math.ceil(multiplier*delta);
			score += d;
			last = d;
			updateLast();
		}
		
		
		
		// Label text update and positioning
		
		/** Helper function for label positioning */
		private function positionRight(d:DisplayObject, offset:Number)
		{
			d.x = 5+board.contentWidth-d.width-offset;
			d.y = -10;
		}
		
		private function updateDisplay()
		{
			updateScore();
			updateMulti();
			updateLast();
			updateTime();
		}
		
		private function updateScore()
		{
			var newText = ""+score;
			if (newText != scoreDisplay.text) {
				scoreDisplay.text = ""+score;
				// Explicit call to validate, so the text size is correct before positioning
				scoreDisplay.validate();
			}
			positionRight(scoreDisplay, 5);
			scoreDisplay.scale = textScale*2;
			juggler.tween(scoreDisplay, 0.5, {
				scale: textScale,
				transition: Transitions.EASE_OUT_ELASTIC
			});
		}
		
		private function updateMulti()
		{
			var newText = "x "+multiplier.toFixed(2);
			if (newText != multiDisplay.text) {
				multiDisplay.text = newText;
				multiDisplay.validate();
			}
			positionRight(multiDisplay, 35);
		}
		
		private function updateLast()
		{
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
		
		private function updateTime()
		{
			var newText = Math.abs(Math.ceil(config.duration - t)).toFixed(0);
			if (newText != timeDisplay.text) {
				timeDisplay.text = newText;
				timeDisplay.validate();
			}
			positionRight(timeDisplay, 85);
		}
		
		
		
		/**
		 * Curve for translating an unbounded value to a pitch
		 */
		private function getPitch(x:Number):Number
		{
			return 0.8+0.2*(Math.exp(x*0.08)-1);
		}
		
		/**
		 * Run explosion effect at the given position with the given color
		 */
		private function explode(x:Number, y:Number, color:Color)
		{
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
			screenshake += 0.25;
		}
		
		/**
		 * Begin game
		 */
        public function enter(owner:DisplayObjectContainer)
		{
			super.enter(owner);
			state = STATE_GAME;
			hideConfirm();
			
			// Set config options
			board.freeformMode = config.freeform;
			board.reset();
			
			// Reset state
			t = 0;
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
		
        public function exit()
		{
			super.exit();
			particles.clear();
			//soundtrack.stop();
		}
		
		public function tick()
		{
			// Do not process ticks after quitting
			if (state == STATE_QUIT) return;
			
			t += dt;
			juggler.advanceTime(dt);
			
			screenshaker.strength = screenshake;
			
			// Decays
			screenshake -= screenshake*6*dt;
			if (Math.abs(screenshake) < 0.1) screenshake = 0;
			momentum -= momentum*0.2*dt;
			
			// Scroll based on momentum
			bgScroll -= momentum*1.5*dt;
			
			// Do not process multiplier or time while in end animation
			if (state == STATE_ENDING) return;
			
			multiplier = Math.round(Math.pow(1+0.1*momentum, 2)/0.5)*0.5;
			updateMulti();
			//soundtrack.setPitch(getPitch(momentum));
			updateTime();
			if (config.duration > 0 && t >= config.duration) {
				end();
			}
		}
		
		private function end()
		{
			state = STATE_ENDING;
			// Animate board ending
			board.end();
		}
		
		private function boardEnded()
		{
			onTimeout();
		}
		
		public function render()
		{
			// Tint the background based on current momentum
			bgColor.red += ((1-Math.exp(-momentum*0.2))*0xFF-bgColor.red)*0.1;
			background.color = bgColor.toInt();
			// Render scroll
			background.scrollY = bgScroll;
		}
		
	}
}