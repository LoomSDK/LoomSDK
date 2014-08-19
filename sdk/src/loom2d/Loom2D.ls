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
	}
}