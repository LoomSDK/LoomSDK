package  {
	import loom.sound.Sound;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.MovieClip;
	import loom2d.display.Sprite;
	import loom2d.math.Point;
	import loom2d.math.Rectangle;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	
	/**
	 * Mine state, AI and simulation.
	 */
	public class Mine extends Entity {
		// Mine state machine
		public static const STATE_IDLE = 0;
		public static const STATE_WARN = 1;
		public static const STATE_SEEK = 2;
		public static const STATE_EXPLODING = 3;
		public static const STATE_EXPLODED = 4;
		public var state:int;
		
		// Required references
		private var maxDepth:Number;
		private var player:Player;
		
		// Graphics
		private var display = new Sprite();
		private var body:Image;
		private var bodyActive:Image;
		private var explosion:MovieClip;
		private var explosionSound:Sound;
		// Used to delay explosions by a bit for a more pleasant effect.
		private var explosionStart:Number;
		private var explosionStagger:Number;
		
		private var beep:Sound;
		private var beepDelay:Number;
		private var beepCount:Number;
		
		// Class properties to avoid instantiation every tick
		private var delta:Point;
		private var thrust:Point;
		
		// Sleeping mines aren't checked for collisions and aren't simulated
		public var sleeping:Boolean;
		
		public function Mine(container:DisplayObjectContainer, maxDepth:Number, player:Player) {
			this.maxDepth = maxDepth;
			this.player = player;
			
			// Used for collision checks
			bounds.setTo(-1, -1, 3, 3);
			
			container.addChild(display);
			
			var tex:Texture;
			
			tex = Texture.fromAsset("assets/mine.png");
			tex.smoothing = TextureSmoothing.NONE;
			body = new Image(tex);
			body.center();
			display.addChild(body);
			
			tex = Texture.fromAsset("assets/mineActive.png");
			tex.smoothing = TextureSmoothing.NONE;
			bodyActive = new Image(tex);
			bodyActive.center();
			display.addChild(bodyActive);
			
			explosion = new Explosion("assets/mineExplosion.png");
			display.addChild(explosion);
			
			explosionSound = Sound.load("assets/mineExplosion.ogg");
			beep = Sound.load("assets/beep.ogg");
			
			reset();
		}
		
		public function reset()
		{
			beep.stop();
			beepDelay = 0;
			beepCount = 0;
			sleeping = false;
			state = STATE_IDLE;
			resetPhysics();
			body.visible = true;
			explosion.stop();
			explosion.currentFrame = 0;
			explosion.visible = false;
			explosionSound.stop();
			explosionSound.setPitch(1+Math.randomRange(-0.1, 0.1));
		}
		
		public function setPosition(x:Number, y:Number)
		{
			p.x = x;
			p.y = y;
		}
		
		public function getDepth():Number
		{
			return p.y;
		}
		
		/** Check for collisions against another mine and explode if necessary. */
		public function checkCollisionMine(mine:Mine)
		{
			if (state == STATE_EXPLODING || state == STATE_EXPLODED) return;
			if (mine.state == STATE_EXPLODED) return;
			if (checkCollision(mine)) {
				explode();
				mine.explode(0.2);
			}
		}
		
		/** Check for collisions against the player and explode if necessary. */
		public function checkCollisionPlayer(player:Player)
		{
			if (state == STATE_EXPLODING || state == STATE_EXPLODED) return;
			if (player.state == Player.STATE_EXPLODED) return;
			if (checkCollision(player)) {
				explode();
				player.explode();
			}
		}
		
		/**
		 * Explode with a small random delay (with an offset).
		 */
		public function explode(offset:Number = 0)
		{
			state = STATE_EXPLODING;
			explosionStagger = offset+Math.randomRange(0, 0.2);
			explosionStart = Number.MIN_VALUE;
		}
		
		/**
		 * Called after the explosion is finished.
		 */
		private function exploded()
		{
			state = STATE_EXPLODED;
			explosion.visible = false;
		}
		
		override public function tick(t:Number, dt:Number)
		{
			delta = player.p.subtract(p);
			
			/** Distance from player */
			var dist = delta.length;
			
			/*
			 * Mine AI based on current state, handles:
			 * - state transitions
			 * - beeping
			 * - thrust towards player
			 */
			switch (state) {
				case STATE_IDLE:
					sleeping = true;
					if (dist < 60) state = STATE_WARN;
					break;
				case STATE_WARN:
					sleeping = true;
					if (dist > 70) state = STATE_IDLE;
					if (dist < 30) state = STATE_SEEK;
					beepDelay = 0.5;
					break;
				case STATE_SEEK:
					sleeping = false;
					if (dist > 40) state = STATE_WARN;
					beepDelay = 0.1;
					
					thrust = delta;
					thrust.normalize(thrust.length*10);
					
					var maxSeekThrust = 120;
					if (thrust.length > maxSeekThrust) thrust.normalize(maxSeekThrust);
					a.offset(thrust.x, thrust.y);
					
					break;
				case STATE_EXPLODING:
					sleeping = false;
					beepDelay = 0.05;
					// Waits for explosion delay
					if (explosionStart == Number.MIN_VALUE) explosionStart = t;
					if (t-explosionStart > explosionStagger) {
						explosionStart = Number.MAX_VALUE;
						explosion.visible = true;
						body.visible = bodyActive.visible = false;
						explosion.play();
						explosionSound.play();
						placeSound(explosionSound);
					}
					// Explosion animation
					if (explosionStart == Number.MAX_VALUE) explosion.advanceTime(dt);
					if (explosion.isComplete) exploded();
					break;
				case STATE_EXPLODED:
					sleeping = true;
					// Exploded mines don't need to do anything else
					return;
			}
			// Boop, beep, beep!
			if (state == STATE_SEEK || state == STATE_WARN) {
				beepCount -= dt;
				if (beepCount < 0) {
					beep.play();
					// Set volume and pitch based on distance from player
					beep.setGain(1-dist/60);
					beep.setPitch(1.3-dist/60);
					placeSound(beep);
					beepCount = beepDelay;
				}
			}
			// Mine shouldn't sleep while moving
			if (v.lengthSquared > 1) sleeping = false;
			if (!sleeping) {
				drag(dt, DRAG_WATER);
				super.tick(t, dt);
			}
		}
		
		override public function render(t:Number)
		{
			display.x = p.x;
			display.y = p.y;
			// Visual beeping indicator
			switch (state) {
				case STATE_WARN:
					bodyActive.visible = true;
					bodyActive.alpha = Math.clamp(beepCount/beepDelay, 0, 1);
					break;
				case STATE_SEEK:
					bodyActive.visible = true;
					bodyActive.alpha = Math.clamp(beepCount/beepDelay, 0, 1);
					break;
				default:
					bodyActive.visible = false;
			}
			// Fades out body with depth, so it's harder to see, but doesn't affect indicator (bodyActive)
			if (!sleeping) body.alpha = Math.clamp(1-getDepth()/maxDepth, 0.4, 1);
			super.render(t);
		}
		
	}
}