package game {
	import loom.sound.Sound;
	import loom2d.animation.IAnimatable;
	import loom2d.animation.Juggler;
	import loom2d.display.DisplayObject;
	
	/**
	 * Nifty class that shakes (randomly offsets the position of)
	 * the provided DisplayObject with a certain strength.
	 */
	public class Shaker implements IAnimatable
	{
		public var strength:Number = 1;
		
		private var shakee:DisplayObject;
		private var origX:Number;
		private var origY:Number;
		private var juggler:Juggler;
		private var shaking:Sound;
		
		public function Shaker(shakee:DisplayObject, sound:Sound = null)
		{
			this.shakee = shakee;
			if (sound) {
				shaking = sound;
				shaking.setLooping(true);
			}
		}
		
		public function start(juggler:Juggler)
		{
			stop(false);
			this.juggler = juggler;
			origX = shakee.x;
			origY = shakee.y;
			juggler.add(this);
			if (shaking) shaking.play();
		}
		
		public function advanceTime(time:Number)
		{
			shakee.x = origX+Math.randomRange(-strength, strength);
			shakee.y = origY+Math.randomRange(-strength, strength);
		}
		
		public function stop(resetPosition:Boolean = true)
		{
			if (juggler) {
				juggler.remove(this);
				juggler = null;
				if (resetPosition) {
					shakee.x = origX;
					shakee.y = origY;
				}
			}
			if (shaking) shaking.stop();
		}
		
	}
}