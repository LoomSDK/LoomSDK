package
{
	import loom.sound.Listener;
	import loom.sound.Sound;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.MovieClip;
	import loom2d.display.Sprite;
	import loom2d.Loom2D;
	import loom2d.math.Color;
	import loom2d.math.Point;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	
	/**
	 * Player (submersible) state, control and simulation.
	 */
	public class Player extends Entity
	{
		// Player state machine
		public static const STATE_FOLLOW = 0;
		public static const STATE_RETURN = 1;
		public static const STATE_EXPLODING = 2;
		public static const STATE_EXPLODED = 3;
		public static const STATE_WINNER = 4;
		public var state:Number;
		
		/** Passed in from environment */
		private var maxDepth:Number;
		
		// Graphics
		private var display = new Sprite();
		private var submersible = new Sprite();
		private var body:Image;
		private var bodyTinted:Image;
		private var lights:Image;
		
		private var target:Point = new Point();
		
		private var thrustMax:Number = 150;
		private var thrust:Point = new Point();
		
		/** The depth at which the lights get turned on */
		private var lightDepth:Number = 400;
		/** Avoids rapid switching of lights */
		private var lightHysteresis:Number = 40;
		private var lightsEnabled:Boolean;
		private var lightSwitchTime:Number;
		private var lightSwitchOnDuration:Number = 3;
		private var lightSwitchOffDuration:Number = 0.5;
		private var lightSwitchOnSound:Sound;
		
		private var explosion:MovieClip;
		private var explosionSound:Sound;
		
		private var engineSound:Sound;
		private var engineActivity:Number = 0;
		
		private var dive:Sound;
		
		public function Player(container:DisplayObjectContainer, maxDepth:Number)
		{
			this.maxDepth = maxDepth;
			
			// Used for collision checks
			bounds.setTo(-3, -3, 8, 4);
			
			container.addChild(display);
			
			display.addChild(submersible);
			
			var tex:Texture;
			
			// Main body
			tex = Texture.fromAsset("assets/submersible.png");
			tex.smoothing = TextureSmoothing.NONE;
			body = new Image(tex);
			body.center();
			submersible.addChild(body);
			
			// Tinted body faded in for better effect at depth
			tex = Texture.fromAsset("assets/submersibleDeep.png");
			tex.smoothing = TextureSmoothing.NONE;
			bodyTinted = new Image(tex);
			bodyTinted.center();
			submersible.addChild(bodyTinted);
			
			// Overlay for lights
			tex = Texture.fromAsset("assets/submersibleLights.png");
			tex.smoothing = TextureSmoothing.NONE;
			lights = new Image(tex);
			lights.center();
			lights.y += 4;
			submersible.addChild(lights);
			
			lightSwitchOnSound = Sound.load("assets/lightsSwitchOn.ogg");
			lightSwitchOnSound.setListenerRelative(false);
			
			explosion = new Explosion("assets/submersibleExplosion.png");
			display.addChild(explosion);
			
			explosionSound = Sound.load("assets/submersibleExplosion.ogg");
			explosionSound.setListenerRelative(false);
			
			engineSound = Sound.load("assets/submersibleEngine.ogg");
			engineSound.setLooping(true);
			engineSound.play();
			engineSound.setPitch(0);
			engineSound.setListenerRelative(false);
			
			// Water splash/whoosh used on launch
			dive = Sound.load("assets/dive.ogg");
			dive.setListenerRelative(false);
			
			// Required for the positions to work as specified
			Listener.setOrientation(0, 0, -1, 0, 1, 0);
			
			reset();
		}
		
		/**
		 * Reset player state
		 * @param	position	If true, also reset positioning.
		 */
		public function reset(position:Boolean = true)
		{
			if (position) p.x = p.y = v.x = v.y = a.x = a.y = 0;
			lightsEnabled = false;
			lightSwitchTime = Number.MAX_VALUE;
			lights.alpha = 0;
			submersible.visible = true;
			state = STATE_FOLLOW;
		}
		
		public function launch()
		{
			dive.play();
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
		
		public function getDepthSpeed():Number
		{
			return v.y;
		}
		
		public function setVelocity(x:Number, y:Number)
		{
			v.x = x;
			v.y = y;
		}
		
		public function setTarget(t:Point)
		{
			target = t;
		}
		
		public function explode()
		{
			if (state == STATE_EXPLODING) return;
			state = STATE_EXPLODING;
			explosion.visible = true;
			explosion.play();
			explosionSound.play();
			submersible.visible = false;
			explosion.visible = true;
		}
		
		/**
		 * Called after the explosion is finished.
		 */
		public function exploded()
		{
			state = STATE_EXPLODED;
			explosion.visible = false;
			explosion.stop();
		}
		
		override public function tick(t:Number, dt:Number)
		{
			// Air behavior
			if (p.y < 0) {
				// Gravity while in the air
				a.y += 50;
				drag(dt, DRAG_AIR);
			} else {
				
				var depth = getDepth();
				
				// Light switching and animation
				var lightSwitchDelta = t-lightSwitchTime;
				if (depth > lightDepth+lightHysteresis) {
					if (!lightsEnabled) {
						lightSwitchTime = t;
						lightsEnabled = true;
						lightSwitchOnSound.play();
					}
					if (lightSwitchDelta < lightSwitchOnDuration) {
						lights.alpha = lightSwitchOn(lightSwitchDelta/lightSwitchOnDuration);
					} else {
						lights.alpha = 1;
					}
				} else if (depth < lightDepth-lightHysteresis) {
					if (lightsEnabled) {
						lightSwitchTime = t;
						lightsEnabled = false;
					}
					if (lightSwitchDelta < lightSwitchOffDuration) {
						lights.alpha = lightSwitchOff(lightSwitchDelta/lightSwitchOffDuration);
					} else {
						lights.alpha = 0;
					}
				}
				
				// Propulsion based on current state
				var delta = target.subtract(p);
				thrust.x = thrust.y = 0;
				if (state == STATE_FOLLOW || state == STATE_RETURN || state == STATE_WINNER) {
					switch (state) {
						case STATE_FOLLOW:
							// Only move if far enough away from target
							if (delta.length > 10) {
								thrust = delta;
								thrust.normalize(thrust.length*10);
							}
							// Limit to maximum thrust
							if (thrust.length > thrustMax) thrust.normalize(thrustMax);
							break;
						case STATE_RETURN:
							// Forced return with faster speeds
							thrust.offset(delta.x*5, -thrustMax*1.5);
							break;
						case STATE_WINNER:
							// Autoreturn to initial position after winning
							thrust.offset(delta.x*2, -Math.clamp(getDepth(), 0, thrustMax)*2);
							break;
					}
					// Eased engine activity number used for pitching engine sounds
					engineActivity += (thrust.length/thrustMax-engineActivity)*0.05;
					// Add thrust to acceleration
					a.offset(thrust.x, thrust.y);
				}
				
				drag(dt, DRAG_WATER);
			}
			
			// Explosion animation
			switch (state) {
				case STATE_EXPLODING:
					explosion.advanceTime(dt);
					if (explosion.isComplete) exploded();
					break;
			}
			
			engineSound.setPitch(engineActivity);
			// Decay activity, so it doesn't keep playing when it's not kept up.
			engineActivity *= 0.9;
			
			super.tick(t, dt);
			
			placeListener();
		}
		
		/**
		 * Function with some initial spikes emulating flourescent light
		 * flickering and then gradual fade in.
		 */
		private function lightSwitchOn(x:Number):Number
		{
			return (Math.sin(x*Math.PI*10)*5-4) * // Flicker
			       Math.clamp(Math.sin(x*Math.PI+Math.PI/2)*5, 0, 1) + // Flicker attenuation
			       Math.clamp(Math.sin(x*Math.PI*1.3-Math.PI*0.8), 0, 1)
			;
		}
		
		/**
		 * Function of gradual fade out.
		 */
		private function lightSwitchOff(x:Number):Number
		{
			return Math.sin(x*Math.PI/2+Math.PI/2);
		}
		
		override public function render(t:Number)
		{
			display.x = p.x;
			display.y = p.y;
			bodyTinted.alpha = Math.clamp(getDepth()/maxDepth, 0, 0.9);
			super.render(t);
		}
		
	}
}