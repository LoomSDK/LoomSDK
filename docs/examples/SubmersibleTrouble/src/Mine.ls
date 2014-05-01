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
	
	public class Mine extends Entity {
		
		public static const STATE_IDLE = 0;
		public static const STATE_WARN = 1;
		public static const STATE_SEEK = 2;
		public static const STATE_EXPLODING = 3;
		public static const STATE_EXPLODED = 4;
		public var state = STATE_IDLE;
		
		private var display = new Sprite();
		private var body:Image;
		private var bodyActive:Image;
		private var explosion:MovieClip;
		private var explosionSound:Sound;
		private var explosionStart:Number;
		private var explosionStagger:Number;
		
		private var maxDepth:Number;
		private var player:Player;
		
		public function Mine(container:DisplayObjectContainer, maxDepth:Number, player:Player) {
			this.maxDepth = maxDepth;
			this.player = player;
			
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
			
			explosion = new Explosion("assets/mineExplosion.png", 6);
			display.addChild(explosion);
			
			explosionSound = Sound.load("assets/mineExplosion.ogg");
			explosionSound.setPitch(1+Math.randomRange(-0.1, 0.1));
		}
		
		public function dispose() {
			display.parent.removeChild(display);
			body.dispose();
			bodyActive.dispose();
			explosion.dispose();
			explosionSound.deleteNative();
		}
		
		public function setPosition(x:Number, y:Number)
		{
			p.x = x;
			p.y = y;
		}
		
		public function getDepth():Number {
			return p.y;
		}
		
		public function checkCollisionMine(mine:Mine) {
			if (state == STATE_EXPLODING || state == STATE_EXPLODED) return;
			if (mine.state == STATE_EXPLODED) return;
			if (checkCollision(mine)) {
				explode();
				mine.explode(0.2);
			}
		}
		
		public function checkCollisionPlayer(player:Player) {
			if (state == STATE_EXPLODING || state == STATE_EXPLODED) return;
			if (player.state == Player.STATE_EXPLODED) return;
			if (checkCollision(player)) {
				explode();
				player.explode();
			}
		}
		
		public function explode(offset:Number = 0) {
			state = STATE_EXPLODING;
			explosionStagger = offset+Math.randomRange(0, 0.2);
			explosionStart = Number.MIN_VALUE;
		}
		
		private function exploded() {
			state = STATE_EXPLODED;
			explosion.visible = false;
		}
		
		override public function tick(t:Number, dt:Number) {
			var delta = player.p.subtract(p);
			var dist = delta.length;
			switch (state) {
				case STATE_IDLE:
					if (dist < 60) state = STATE_WARN;
					break;
				case STATE_WARN:
					if (dist > 70) state = STATE_IDLE;
					if (dist < 30) state = STATE_SEEK;
					break;
				case STATE_SEEK:
					
					var thrust:Point = delta.clone();
					thrust.normalize(thrust.length*10);
					if (thrust.length > 120) thrust.normalize(120);
					a.offset(thrust.x, thrust.y);
					
					if (dist > 40) state = STATE_WARN;
					break;
				case STATE_EXPLODING:
					if (explosionStart == Number.MIN_VALUE) explosionStart = t;
					if (t-explosionStart > explosionStagger) {
						explosionStart = Number.MAX_VALUE;
						explosion.visible = true;
						body.visible = bodyActive.visible = false;
						explosion.play();
						explosionSound.play();
					}
					if (explosionStart == Number.MAX_VALUE) explosion.advanceTime(dt);
					if (explosion.isComplete) exploded();
					break;
			}
			drag(dt, DRAG_WATER);
			super.tick(t, dt);
		}
		
		override public function render(t:Number) {
			display.x = p.x;
			display.y = p.y;
			switch (state) {
				case STATE_IDLE:
					bodyActive.alpha = 0;
					break;
				case STATE_WARN:
					bodyActive.alpha = Math.clamp((Math.sin(t*Math.PI*5)+1)*0.5, 0, 1);
					break;
				case STATE_SEEK:
					bodyActive.alpha = Math.clamp((Math.sin(t*Math.PI*30)+1)*0.5, 0, 1);
					break;
			}
			body.alpha = Math.clamp(1-getDepth()/maxDepth, 0.4, 1);
			super.render(t);
		}
		
	}
	
}