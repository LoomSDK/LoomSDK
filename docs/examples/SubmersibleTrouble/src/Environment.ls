package
{
	import feathers.display.TiledImage;
	import loom.sound.Listener;
	import loom.sound.Sound;
	import loom.utils.Injector;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.display.Stage;
	import loom2d.events.Event;
	import loom2d.events.Touch;
	import loom2d.events.TouchPhase;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	import loom2d.ui.SimpleLabel;
	
	/**
	 * Simulation of the environment including all
	 * the text, entities and camera movement.
	 */
	public class Environment
	{
		public static const GAMEOVER:String = "gameover";
		
		private var stage:Stage;
		
		/** Simulation delta time */
		private var dt = 1/60;
		
		/** Simulation time */
		private var t = 0;
		
		/** Pixel scaling */
		private var displayScale = 4;
		
		private var maxDepth = 800;
		
		// Camera offsets (for transitions between intro and game)
		private var initOffset = 280;
		private var introOffset = 100;
		private var launchedOffset = 0;
		private var displayOffsetEase = 0.05;
		
		private var mineOffset = 100;
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
		public static const STATE_INIT = 0;
		public static const STATE_LAUNCHED = 1;
		public static const STATE_RETURNING = 2;
		public static const STATE_RETURN = 3;
		public static const STATE_WINNER = 4;
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
			
			display.scale = displayScale;
			stage.addChild(display);
			
			w = stage.stageWidth/displayScale;
			h = stage.stageHeight/displayScale;
			
			var tex:Texture;
			
			sky = new Image(Texture.fromAsset("assets/sky.png"));
			sky.width = w;
			// Water level is at zero, sky is positioned in negative space
			sky.y = -sky.height;
			display.addChild(sky);
			
			display.addChild(mineDisplay);
			
			// Player adds itself to display
			player = new Player(display, maxDepth);
			
			// Blinking up arrow on return
			tex = Texture.fromAsset("assets/arrowUp.png");
			// Smoothing set to NONE to ensure rough pixel look
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
			
			// Title and score text config
			title = getLabel("Submersible Trouble", true, w/2, -85, 0.2);
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
			
			reset();
		}
		
		/**
		 * Helper function for placing labels
		 */
		private function getLabel(txt:String, center:Boolean, x:Number, y:Number, scale:Number):SimpleLabel
		{
			var label = new SimpleLabel("assets/Curse-hd.fnt");
			label.text = txt;
			if (center) label.center();
			label.x = x;
			label.y = y;
			label.scale = scale;
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
			clearMines();
			placeMines();
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
		 * Remove and dispose of all the mines.
		 */
		private function clearMines()
		{
			while (mines.length > 0) {
				var mine:Mine = mines.pop();
				mine.dispose();
			}
		}
		
		/**
		 * Add randomly positioned mines in the sea.
		 */
		private function placeMines()
		{
			for (var i = 0; i < mineNum; i++) {
				addMine(Math.randomRangeInt(0, w), mineOffset+(maxDepth-mineOffset-h)*mineDistribution(i/(mineNum-1)));
			}
		}
		
		/**
		 * Used to determine mine distribution - less dense on top, more dense at bottom.
		 */
		private function mineDistribution(x:Number):Number
		{
			return Math.log(1+x*mineDistributionSharpness)/Math.log(1+mineDistributionSharpness);
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
			state = STATE_LAUNCHED;
		}
		
		public function touched(touch:Touch)
		{
			lastTouch = touch;
			if (touch.phase == TouchPhase.ENDED) lastTouch = null;
		}
		
		private function addMine(x:Number, y:Number)
		{
			var mine = new Mine(mineDisplay, maxDepth, player);
			mine.setPosition(x, y);
			mines.push(mine);
		}
		
		public function tick()
		{
			// Eased camera offset for transitions
			displayOffset += (targetOffset-displayOffset)*displayOffsetEase;
			
			var targetCamera:Number;
			
			// Common core game loop - update entities, check for collisions and end state
			if (state != STATE_INIT) {
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
				case STATE_INIT:
					targetCamera = 0;
					break;
				case STATE_LAUNCHED:
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
			
			// After game over, check if camera returned to initial state and dispatch gameover (allowing for restart)
			if (over && Math.abs(targetCamera-cameraPos) < overCameraThreshold) {
				over = false;
				stage.dispatchEvent(new Event(GAMEOVER));
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
				mine.checkCollisionPlayer(player);
				for (var j = i+1; j < mines.length; j++) {
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
				state = STATE_INIT;
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
			display.y = (displayOffset-cameraPos)*displayScale;
		}
		
	}
}