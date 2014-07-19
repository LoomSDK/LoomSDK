package
{
	import feathers.display.TiledImage;
	import loom.platform.Mobile;
	import loom.sound.Listener;
	import loom.sound.Sound;
	import loom.utils.Injector;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.display.Stage;
	import loom2d.events.Event;
	import loom2d.events.KeyboardEvent;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.Loom2D;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	import loom2d.ui.SimpleButton;
	import loom2d.ui.SimpleLabel;
	
	/**
	 * Simulation of the environment including all
	 * the text, entities and camera movement.
	 */
	public class Environment
	{
		
		private var stage:Stage;
		
		/** Simulation delta time */
		private var dt = 1/60;
		
		/** Simulation time */
		private var t = 0;
		
		// Target content width/height;
		// the view is scaled to contain these
		private var contentWidth = 480;
		private var contentHeight = 480;
		
		/** Pixel scaling */
		private var pixelScale = 4;
		
		/** The return depth point */
		private var maxDepth = 800;
		
		// Camera offsets (for transitions between intro and game)
		private var creditsOffset = 750;
		private var initOffset = 280;
		private var introOffset = 100;
		private var launchedOffset = 0;
		private var displayOffsetEase = 0.05;
		
		/** Scrolling speed for credits */
		private var creditsSpeed = 8;
		
		/** The depth at which the instructions get hidden */
		private var instructionHidingDepth = 300;
		
		/** Mine depth offset */
		private var mineOffset = 150;
		private var mineNum = 50;
		private var mineDistributionSharpness = 5;
		
		/** Player launch speed at game start */
		private var launchSpeed = 120;
		
		/** Delay between reaching bottom and starting to return */
		private var returnDelay = 2;
		
		private var cameraEase = 0.02;
		private var maxCameraSpeed = 5;
		/**
		 * When the returning camera after explosion reaches the initial 
		 * camera position within this threshold, the game is reset.
		 */
		private var overCameraThreshold = 50;
		
		private var display:Sprite = new Sprite();
		private var displayOffset:Number = initOffset;
		private var targetOffset:Number;
		private var cameraPos:Number = 0;
		
		// Visible stage size in scaled display units
		private var w:Number;
		private var h:Number;
		
		/* Indicates that the game is over, but the camera is still returning */
		private var over:Boolean = false;
		
		/** Set to game time when the bottom is reached */
		private var returnStartTime:Number;
		
		/**
		 * Last touch received, stored so the target can be
		 * updated every tick based on camera movement.
		 */
		private var lastTouch:Touch;
		
		// General game state machine states
		public static const STATE_INIT      = 0;
		public static const STATE_LAUNCHED  = 1;
		public static const STATE_RETURNING = 2;
		public static const STATE_RETURN    = 3;
		public static const STATE_EXPLODED  = 4;
		public static const STATE_WINNER    = 5;
		public static const STATE_CREDITS   = 6;
		public var state:Number;
		
		// Entities
		private var player:Player;
		private var mines:Vector.<Mine> = new Vector.<Mine>();
		
		// Graphics
		private var sky:Image;
		private var sea:Image;
		private var seaTiled:TiledImage;
		private var mineDisplay:Sprite = new Sprite();
		private var arrowUp:Image;
		private var title:SimpleLabel;
		private var credits:Image;
		private var creditsBtn:SimpleButton;
		private var instructions:Image;
		private var scoreTime:SimpleLabel;
		private var scoreMines:SimpleLabel;
		private var winnerTitle:SimpleLabel;
		
		// Sound
		private var ambience:Sound;
		private var winnerSound:Sound;
		private var warning:Sound;
		
		public function Environment(stage:Stage)
		{
			this.stage = stage;
			
			stage.addEventListener(Event.RESIZE, resize);
			resize();
			
			stage.addEventListener(KeyboardEvent.BACK_PRESSED, back);
			
			// Triggers on touch start, move and end
			display.addEventListener(TouchEvent.TOUCH, touched);
			
			stage.addChild(display);
			
			w = contentWidth/pixelScale;
			h = contentHeight/pixelScale;
			
			var tex:Texture;
			
			sky = new Image(Texture.fromAsset("assets/sky.png"));
			sky.width = w;
			// Water level is at zero, sky is positioned in negative space
			sky.y = -sky.height;
			display.addChild(sky);
			
			// Stars behind credits
			tex = Texture.fromAsset("assets/stars.png");
			tex.smoothing = TextureSmoothing.NONE;
			var stars = new Image(tex);
			stars.scale = w/stars.width;
			display.addChild(stars);
			
			// Credits
			tex = Texture.fromAsset("assets/credits.png");
			credits = new Image(tex);
			credits.scale = contentWidth/credits.width/pixelScale;
			credits.y = -400-credits.height;
			display.addChild(credits);
			stars.y = credits.y-h;
			
			// Instructions
			tex = Texture.fromAsset("assets/instructions.png");
			// Smoothing set to NONE to ensure rough pixel look
			tex.smoothing = TextureSmoothing.NONE;
			instructions = new Image(tex);
			instructions.scale = w/instructions.width;
			instructions.y = 60;
			display.addChild(instructions);
			
			
			display.addChild(mineDisplay);
			
			// Player adds itself to display
			player = new Player(display, maxDepth);
			
			// Blinking up arrow on return
			tex = Texture.fromAsset("assets/arrowUp.png");
			tex.smoothing = TextureSmoothing.NONE;
			arrowUp = new Image(tex);
			arrowUp.center();
			arrowUp.x = w/2;
			display.addChild(arrowUp);
			
			// Sea background gradient
			tex = Texture.fromAsset("assets/sea.png");
			tex.smoothing = TextureSmoothing.NONE;
			sea = new Image(tex);
			sea.width = w;
			sea.alpha = 0.5;
			display.addChild(sea);
			
			// Tiled sea detail
			tex = Texture.fromAsset("assets/seaTiled.png");
			tex.smoothing = TextureSmoothing.NONE;
			seaTiled = new TiledImage(tex, 1);
			seaTiled.width = w;
			// Extend until the max depth plus some extra screens for good measure
			seaTiled.height = maxDepth+h*2;
			display.addChild(seaTiled);
			
			// Credits button
			creditsBtn = new SimpleButton();
			creditsBtn.upImage = "assets/info.png";
			creditsBtn.onClick = showCredits;
			creditsBtn.scale = 1.2/pixelScale;
			creditsBtn.x = w - 14;
			creditsBtn.alpha = 0.5;
			display.addChild(creditsBtn);
			
			// Title and score text config
			title = getLabel("Submersible Trouble", true, w/2, -85, 0.2, 0.8);
			scoreTime  = getLabel("", false, 10, -47, 0.1);
			scoreMines = getLabel("", false, 10, -35, 0.1);
			winnerTitle = getLabel("WINNER!", true, w/2, -62, 0.15);
			winnerTitle.visible = false;
			
			ambience = Sound.load("assets/ObservingTheStar.ogg");
			ambience.setLooping(true);
			// Used to effectively disable sound positioning for this sound
			ambience.setListenerRelative(false);
			ambience.play();
			
			winnerSound = Sound.load("assets/winner.ogg");
			winnerSound.setListenerRelative(false);
			
			warning = Sound.load("assets/warning.ogg");
			warning.setListenerRelative(false);
			
			placeMines();
			reset();
		}
		
		/**
		 * Exits the application when the back button is pressed
		 */
		private function back(e:KeyboardEvent):void 
		{
			switch (state) {
				case STATE_INIT:
				case STATE_WINNER:
					Process.exit(0);
					break;
				case STATE_CREDITS:
					hideCredits();
					break;
				default:
					gameover();
			}
		}
		
		/**
		 * Scale stage so it's contained within stage
		 */
		private function resize(e:Event = null)
		{
			stage.scale = stage.stageWidth / contentWidth * pixelScale;
		}
		
		/**
		 * Helper function for placing labels
		 */
		private function getLabel(txt:String, center:Boolean, x:Number, y:Number, scale:Number, alpha:Number = 1):SimpleLabel
		{
			var label = new SimpleLabel("assets/Curse-hd.fnt");
			label.text = txt;
			if (center) label.center();
			label.x = x;
			label.y = y;
			label.scale = scale;
			label.alpha = alpha;
			display.addChild(label);
			return label;
		}
		
		/**
		 * Reset all the game state
		 */
		public function reset()
		{
			t = 0;
			lastTouch = null;
			resetMines();
			arrowUp.visible = false;
			targetOffset = introOffset;
			resetPlayer();
			state = STATE_INIT;
			render();
		}
		
		/**
		 * Reset player and reposition it, unless it's after winning,
		 * in which case it should naturally come back to original position.
		 * This is done to avoid unpleasant visible player teleportation.
		 */
		public function resetPlayer()
		{
			if (state == STATE_WINNER) {
				player.reset(false);
			} else {
				player.reset();
				player.setPosition(w/2, 0);
			}
			player.setTarget(new Point(w/2, h/2));
		}
		
		/**
		 * Reset all the mines
		 */
		private function resetMines() 
		{
			for (var i = 0; i < mines.length; i++) {
				var mine = mines[i];
				mine.reset();
				mine.setPosition(Math.randomRangeInt(0, w), mineOffset+(maxDepth-mineOffset-h)*mineDistribution(i/(mineNum-1)));
			}
		}
		
		/**
		 * Add randomly positioned mines in the sea.
		 */
		private function placeMines()
		{
			for (var i = 0; i < mineNum; i++) {
				var mine = new Mine(mineDisplay, maxDepth, player);
				mine.setPosition(w/2, maxDepth);
				mines.push(mine);
			}
		}
		
		/**
		 * Used to determine mine distribution - less dense on top, more dense at bottom.
		 */
		private function mineDistribution(x:Number):Number
		{
			return Math.log(1+x*mineDistributionSharpness)/Math.log(1+mineDistributionSharpness);
		}
		
		private function showCredits() 
		{
			Mobile.allowScreenSleep(false);
			state = STATE_CREDITS;
			targetOffset = creditsOffset;
		}
		
		private function hideCredits()
		{
			targetOffset = introOffset;
			state = STATE_INIT;
			Mobile.allowScreenSleep(false);
		}
		
		private function disableCredits() 
		{
			creditsBtn.touchable = false;
			Loom2D.juggler.tween(creditsBtn, 0.2, {
				alpha: 0
			});
		}
		
		private function enableCredits() 
		{
			creditsBtn.touchable = true;
			Loom2D.juggler.tween(creditsBtn, 1, {
				alpha: 1
			});
		}
		
		
		/**
		 * Launch player from initial state and begin the game.
		 */
		public function launch()
		{
			reset();
			targetOffset = launchedOffset;
			player.setVelocity(0, launchSpeed);
			player.launch();
			instructions.visible = true;
			state = STATE_LAUNCHED;
			disableCredits();
		}
		
		private function touched(e:TouchEvent)
		{
			var touch = e.getTouch(display);
			switch (state) {
				case STATE_INIT:
				case STATE_WINNER:
					if (touch.phase == TouchPhase.BEGAN) {
						launch();
						touched(e);
					}
					break;
				case STATE_CREDITS:
					hideCredits();
					break;
				default:
					lastTouch = touch;
					if (touch.phase == TouchPhase.ENDED) lastTouch = null;
			}
		}
		
		public function tick()
		{
			// Eased camera offset for transitions
			displayOffset += (targetOffset-displayOffset)*displayOffsetEase;
			
			var targetCamera:Number;
			
			// Common core game loop - update entities, check for collisions and end state
			if (state != STATE_INIT && state != STATE_EXPLODED && state != STATE_CREDITS) {
				if (state != STATE_WINNER && state != STATE_RETURNING && lastTouch) {
					var loc:Point = lastTouch.getLocation(display);
					player.setTarget(loc);
				}
				entityTick();
				checkCollisions();
				if (player.state == Player.STATE_EXPLODED) {
					gameover();
				}
			}
			
			// State-specific behavior for camera and transitioning between states
			switch (state) {
				case STATE_CREDITS:
					if (targetOffset > creditsOffset-credits.height-50) {
						targetOffset -= creditsSpeed*dt;
					} else {
						hideCredits();
					}
					break;
				case STATE_INIT:
				case STATE_EXPLODED:
					targetCamera = 0;
					break;
				case STATE_LAUNCHED:
					// Hide instructions after diving a certain depth
					if (player.getDepth() > instructionHidingDepth && instructions.visible) {
						instructions.visible = false;
					}
					// Transition to returning state if player reaches bottom
					if (player.getDepth() > maxDepth) {
						state = STATE_RETURNING;
						returnStartTime = t;
						arrowUp.y = player.getDepth()+50;
						arrowUp.visible = true;
						warning.play();
					}
					// Set camera target to center on the player with some compensation based on speed
					targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1;
					break;
				case STATE_RETURNING:
					// Blink return arrow
					arrowUp.alpha = 0.25+0.75*0.5*(Math.sin(t*Math.PI*5)+1);
					// Transition to actual forced return rush
					if (t-returnStartTime > returnDelay) {
						state = STATE_RETURN;
						player.state = Player.STATE_RETURN;
						arrowUp.visible = false;
					}
					targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1;
					break;
				case STATE_RETURN:
					if (player.getDepth() < h) {
						gameover(true);
					}
					// Have some more leading for the increased rush and player speed
					targetCamera = player.getDepth()-h/2+player.getDepthSpeed()*1.2;
					break;
				case STATE_WINNER:
					targetCamera = 0;
					break;
			}
			
			// Eased camera movement
			cameraPos += Math.clamp((targetCamera-cameraPos)*cameraEase, -maxCameraSpeed, maxCameraSpeed);
			
			// After game over, check if camera returned to initial state and allow for restart
			if (over && Math.abs(targetCamera-cameraPos) < overCameraThreshold) {
				over = false;
				enableCredits();
				if (state != STATE_WINNER) state = STATE_INIT;
			}
			
			t += dt;
		}
		
		private function entityTick()
		{
			var mine:Mine;
			for each (mine in mines) {
				mine.tick(t, dt);
			}
			player.tick(t, dt);
		}
		
		private function checkCollisions()
		{
			var mine:Mine;
			for (var i = 0; i < mines.length; i++) {
				mine = mines[i];
				if (mine.sleeping) continue;
				mine.checkCollisionPlayer(player);
				for (var j = 0; j < mines.length; j++) {
					if (i == j) continue;
					mine.checkCollisionMine(mines[j]);
				}
			}
		}
		
		private function gameover(winner:Boolean = false)
		{
			over = true;
			setScores();
			targetOffset = introOffset;
			winnerTitle.visible = winner;
			if (winner) {
				state = STATE_WINNER;
				player.state = Player.STATE_WINNER;
				player.setTarget(new Point(w/2, 0));
				winnerSound.play();
			} else {
				state = STATE_EXPLODED;
				resetPlayer();
			}
		}
		
		/**
		 * Set score labels to current state
		 */
		private function setScores()
		{
			var explodedMines = 0;
			for each (var mine:Mine in mines) {
				if (mine.state == Mine.STATE_EXPLODED || mine.state == Mine.STATE_EXPLODING) explodedMines++;
			}
			
			scoreTime.text = "Time                                  " + getFormattedTime(t);
			scoreMines.text = "Mines exploded      " + explodedMines;
		}
		
		/**
		 * Format time in seconds to mm:ss.nnn (minutes, seconds, milliseconds)
		 */
		private function getFormattedTime(t:Number):String
		{
			var ms = t*1000;
			var sec = t;
			var min = t/60;
			return pad(Math.floor(min))+":"+pad(Math.floor(sec)%60)+"."+pad(Math.floor(ms)%1000, 3);
		}
		
		/**
		 * Simple number padding function.
		 */
		private function pad(x:Number, n:Number = 2):String
		{
			var s:String = ""+x;
			while (s.length < n) {
				s = "0"+s;
			}
			return s;
		}
		
		/**
		 * Render entities and move display based on camera position.
		 */
		public function render()
		{
			for each (var mine:Mine in mines) {
				mine.render(t);
			}
			player.render(t);
			
			var center = (stage.stageHeight/stage.scale-contentHeight/pixelScale)/2;
			display.y = (displayOffset-cameraPos)+center;
		}
		
	}
}