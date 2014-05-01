package  {
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
	
	public class Player extends Entity {
		
		public static const STATE_FOLLOW = 0;
		public static const STATE_EXPLODING = 1;
		public static const STATE_EXPLODED = 2;
		public var state:Number;
		
		private var maxDepth:Number;
		
		private var display = new Sprite();
		private var submersible = new Sprite();
		private var body:Image;
		private var bodyTinted:Image;
		private var lights:Image;
		
		private var target:Point = new Point();
		
		private var lightDepth:Number = 400;
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
		
		public function Player(container:DisplayObjectContainer, maxDepth:Number) {
			this.maxDepth = maxDepth;
			
			bounds.setTo(-3, -3, 8, 4);
			
			container.addChild(display);
			
			display.addChild(submersible);
			
			var tex:Texture;
			
			tex = Texture.fromAsset("assets/submersible.png");
			tex.smoothing = TextureSmoothing.NONE;
			body = new Image(tex);
			body.center();
			submersible.addChild(body);
			
			tex = Texture.fromAsset("assets/submersibleDeep.png");
			tex.smoothing = TextureSmoothing.NONE;
			bodyTinted = new Image(tex);
			bodyTinted.center();
			submersible.addChild(bodyTinted);
			
			tex = Texture.fromAsset("assets/submersibleLights.png");
			tex.smoothing = TextureSmoothing.NONE;
			lights = new Image(tex);
			lights.center();
			lights.y += 4;
			submersible.addChild(lights);
			
			lightSwitchOnSound = Sound.load("assets/lightsSwitchOn.ogg");
			
			explosion = new Explosion("assets/submersibleExplosion.png", 12);
			display.addChild(explosion);
			
			explosionSound = Sound.load("assets/submersibleExplosion.ogg");
			
			engineSound = Sound.load("assets/submersibleEngine.ogg");
			engineSound.setLooping(true);
			engineSound.play();
			engineSound.setPitch(0);
			
			reset();
		}
		
		public function reset() {
			p.x = p.y = v.x = v.y = a.x = a.y = 0;
			lightsEnabled = false;
			lightSwitchTime = Number.MAX_VALUE;
			lights.alpha = 0;
			submersible.visible = true;
			state = STATE_FOLLOW;
		}
		
		public function setPosition(x:Number, y:Number)
		{
			p.x = x;
			p.y = y;
		}
		
		public function getDepth():Number {
			return p.y;
		}
		
		public function getDepthSpeed():Number {
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
		
		public function explode() {
			if (state == STATE_EXPLODING) return;
			state = STATE_EXPLODING;
			explosion.visible = true;
			explosion.play();
			explosionSound.play();
			submersible.visible = false;
			explosion.visible = true;
		}
		
		public function exploded() {
			state = STATE_EXPLODED;
			explosion.visible = false;
			explosion.stop();
			
			//state = STATE_FOLLOW;
			//body.visible = bodyTinted.visible = true;
		}
		
		override public function tick(t:Number, dt:Number) {
			
			if (p.y < 0) {
				a.y += 50;
				drag(dt, DRAG_AIR);
			} else {
				
				var depth = getDepth();
				
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
				
				if (state == STATE_FOLLOW) {
					var delta = target.subtract(p);
					if (delta.length > 10) {
						var thrust:Point = delta.clone();
						thrust.normalize(thrust.length*10);
						if (thrust.length > 150) thrust.normalize(150);
						engineActivity += (thrust.length/150-engineActivity)*0.025;
						a.offset(thrust.x, thrust.y);
					}
				}
				
				drag(dt, DRAG_WATER);
			}
			
			switch (state) {
				case STATE_EXPLODING:
					explosion.advanceTime(dt);
					if (explosion.isComplete) exploded();
					break;
			}
			
			engineSound.setPitch(engineActivity);
			engineActivity *= 0.9;
			
			super.tick(t, dt);
		}
		
		private function lightSwitchOn(x:Number):Number {
			return (Math.sin(x*Math.PI*10)*5-4) * // flicker
			       Math.clamp(Math.sin(x*Math.PI+Math.PI/2)*5, 0, 1) + // flicker attenuation
			       Math.clamp(Math.sin(x*Math.PI*1.3-Math.PI*0.8), 0, 1)
			;
		}
		
		private function lightSwitchOff(x:Number):Number {
			return Math.sin(x*Math.PI/2+Math.PI/2);
		}
		
		override public function render(t:Number) {
			display.x = p.x;
			display.y = p.y;
			bodyTinted.alpha = Math.clamp(getDepth()/maxDepth, 0, 0.9);
			//body.alpha = Math.clamp(1-getDepth()/maxDepth, 0.1, 1);
			super.render(t);
		}
		
	}
	
}