/*
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 */

package com.modestmaps.core
{
	import gs.TweenLite;
	
	public class TweenTile extends Tile
	{
		public static var FADE_TIME:Number = 0.25;
				
		public function TweenTile(col:int, row:int, zoom:int)
		{
			super(col, row, zoom);
		} 

		override public function hide():void
		{
			// *** don't *** kill the tweens when hiding
			// it seems there's a harmless bug where hide might get called after show
			// if there's a tween running it will correct it though :)
			//TweenLite.killTweensOf(this);
			this.alpha = 0;
		}
		
		override public function show():void 
		{
			if (alpha < 1) {
				TweenLite.to(this, FADE_TIME, { alpha: 1 });
			}
		}		

		override public function showNow():void 
		{
			TweenLite.killTweensOf(this);
			this.alpha = 1;
		}		

		override public function destroy():void 
		{
			TweenLite.killTweensOf(this);
			super.destroy();
		}		
				
	}

}
