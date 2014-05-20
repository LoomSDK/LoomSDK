package game {
	import loom2d.animation.IAnimatable;
	import loom2d.animation.Juggler;
	import loom2d.display.DisplayObject;
	
	public class Shaker implements IAnimatable {
		
		private var shakee:DisplayObject;
		private var origX:Number;
		private var origY:Number;
		private var juggler:Juggler;
		
		public var strength:Number = 1;
		
		public function Shaker(shakee:DisplayObject) {
			this.shakee = shakee;
		}
		
		public function start(juggler:Juggler) {
			this.juggler = juggler;
			origX = shakee.x;
			origY = shakee.y;
			juggler.add(this);
		}
		
		public function advanceTime(time:Number) {
			shakee.x = origX+Math.randomRange(-strength, strength);
			shakee.y = origY+Math.randomRange(-strength, strength);
		}
		
		public function stop() {
			if (juggler) {
				juggler.remove(this);
				juggler = null;
				shakee.x = origX;
				shakee.y = origY;
			}
		}
		
	}
	
}