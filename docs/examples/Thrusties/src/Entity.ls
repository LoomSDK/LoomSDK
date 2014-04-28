package
{
	import loom2d.math.Point;
	
	/**
	 * Base entity class for the simple physics engine.
	 * Uses velocity verlet for motion integration.
	 */
	public class Entity
	{
		/** Position */
		protected var p:Point = new Point();
		
		/** Velocity */
		protected var v:Point = new Point();
		
		/** Old acceleration - used for integration */
		private var oa:Point = new Point();
		
		/** Acceleration */
		protected var a:Point = new Point();
		
		public function Entity() {}
		
		public function tick(dt:Number)
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
		
		public function render() {}
		
	}
}