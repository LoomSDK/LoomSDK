package
{
	import loom.sound.Listener;
	import loom.sound.Sound;
	import loom2d.math.Point;
	import loom2d.math.Rectangle;
	
	/**
	 * Base entity class for the simple physics engine.
	 * Uses velocity verlet for motion integration.
	 */
	public class Entity
	{
		/** Position */
		protected var p:Point;
		
		/** Velocity */
		protected var v:Point;
		
		/** Old acceleration - used for integration */
		private var oa:Point;
		
		/** Acceleration */
		protected var a:Point;
		
		protected var bounds:Rectangle = new Rectangle();
		
		protected static const DRAG_AIR = 0.01;
		protected static const DRAG_WATER = 0.05;
		protected static const SOUND_SCALE = 0.15;
		
		public function Entity() {}
		
		/** Set sound position and velocity to entity position and velocity */
		protected function placeSound(sound:Sound)
		{
			sound.setPosition(p.x*SOUND_SCALE, 0, p.y*SOUND_SCALE);
			sound.setVelocity(v.x*SOUND_SCALE, 0, v.y*SOUND_SCALE);
		}
		
		/** Set listener position and velocity to entity position and velocity */
		protected function placeListener()
		{
			Listener.setPosition(p.x*SOUND_SCALE, 0, p.y*SOUND_SCALE);
			Listener.setVelocity(v.x*SOUND_SCALE, 0, v.y*SOUND_SCALE);
		}
		
		/**
		 * Entity-entity collision check based on bounds AABB, returns true if they intersect.
		 */
		public function checkCollision(entity:Entity):Boolean
		{
			return p.x+bounds.right  > entity.p.x+entity.bounds.left  &&
			       p.x+bounds.left   < entity.p.x+entity.bounds.right &&
				   p.y+bounds.bottom > entity.p.y+entity.bounds.top   &&
			       p.y+bounds.top    < entity.p.y+entity.bounds.bottom;
		}
		
		/**
		 * Adds drag as acceleration.
		 */
		public function drag(dt:Number, coefficient:Number)
		{
			var amount = -coefficient/dt;
			a.offset(amount*v.x, amount*v.y);
		}
		
		public function tick(t:Number, dt:Number)
		{
			// Velocity verlet integration
			p.x += v.x*dt+0.5*oa.x*dt*dt;
			p.y += v.y*dt+0.5*oa.y*dt*dt;
			v.x += (a.x+oa.x)*0.5*dt;
			v.y += (a.y+oa.y)*0.5*dt;
			// Set the current acceleration as old acceleration and reset it
			oa.x = a.x;
			oa.y = a.y;
			a.x = 0;
			a.y = 0;
		}
		
		public function render(t:Number) {}
		
	}
}