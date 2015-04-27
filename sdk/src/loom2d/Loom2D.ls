package loom2d
{
	import loom2d.display.Stage;
	import loom2d.animation.Juggler;

	/** 
	 * Loom2D is a hardware accelerated 2D graphics library based on Starling by Gamua.
	 *
	 * The Loom2D class contains a few globals used by the Loom2D library. It's most
	 * convenient for the `juggler` field which is used to access the Juggler, which 
	 * controls time driven logic.
	 */
	public class Loom2D
	{
		/**
		 * Reference to the active Loom2D Stage.
		 */
		public static var stage:Stage;

		/**
		 * Reference to the current Juggler, which controls time driven logic.
		 */
		public static var juggler:Juggler = new Juggler();

		/**
		 * Set this at startup to control the display scale factor, for 
		 * instance on HiDPI devices. It sets how many native pixels a Loom2D 
		 * unit corresponds to.
		 */
		public static var contentScaleFactor:Number = 1;
		
		public static function execute(func:Function, ...args):void
		{
			if (func != null)
			{
				var i:int;
				var maxNumArgs:int = func.length;

				for (i=args.length; i<maxNumArgs; ++i)
					args[i] = null;

				// In theory, the 'default' case would always work,
				// but we want to avoid the 'slice' allocations.

				switch (maxNumArgs)
				{
					case 0:  func(); break;
					case 1:  func(args[0]); break;
					case 2:  func(args[0], args[1]); break;
					case 3:  func(args[0], args[1], args[2]); break;
					case 4:  func(args[0], args[1], args[2], args[3]); break;
					case 5:  func(args[0], args[1], args[2], args[3], args[4]); break;
					case 6:  func(args[0], args[1], args[2], args[3], args[4], args[5]); break;
					case 7:  func(args[0], args[1], args[2], args[3], args[4], args[5], args[6]); break;
					default: func.apply(null, args.slice(0, maxNumArgs)); break;
				}
			}
		}
	}
}