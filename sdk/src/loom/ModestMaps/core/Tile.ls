/*
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 */

package com.modestmaps.core
{
	//import flash.display.Bitmap;
	import loom2d.display.DisplayObject;
	//import flash.display.Loader;
	import loom2d.display.Sprite;
	
	public class Tile extends Sprite
	{		
		public static var count:int = 0;
		
		// not a coordinate, because it's very important these are ints
		public var zoom:int;
		public var row:int;
		public var column:int;
				
		public function Tile(column:int, row:int, zoom:int)
		{
			init(column, row, zoom);
			
//LUKE_SAYS: Might not be needed            
			// otherwise you'll get seams between tiles :(
			// PORTNOTE: cacheAsBitmap isn't a part of loom, it's an optimisation function for flash for mobile.
			//this.cacheAsBitmap = false;
			
			trace("TILE CONSTRUCTOR WAS CALLED");
			
			count++;
		} 
		
		/** override this in a subclass and call grid.setTileClass if you want to draw on your tiles */
	    public function init(column:int, row:int, zoom:int):void
	    {
			this.zoom = zoom;
			this.row = row;
			this.column = column;			
			hide();
	    }        

		/** once TileGrid is done with a tile, it will call destroy and possibly reuse it later */
	    public function destroy():void
	    {
	    	while (numChildren > 0) {
	    		var child:DisplayObject = removeChildAt(0);
				
				// PORTNOTE: not a part of loom, hope we don't have to use it!
	    		//if (child is Loader) {
	    		//	try {
	    		//		Loader(child).unload();
	    		//	}
	    		//	catch (error:Error) {
	    				// meh
	    		//	}
	    		}
			
//LUKE_SAYS: Might not be needed            
// TODO_AHMED: find equiuvalents to graphics class
	    	//graphics.clear();
	    }        
		
		public function isShowing():Boolean
		{
			return this.alpha == 1.0;
		}
		
		public function showNow():void
		{
			this.alpha = 1.0;
		}
		
		public function show():void 
		{
			this.alpha = 1.0;
			// if you want to do something when the tile is ready then override 
			// this method and override Map.createTile to use your subclass 
		}
		
		public function hide():void
		{
			this.alpha = 0.0;
		}
		
		public function paintError(w:Number=256, h:Number=256):void
		{
		    // length of 'X' side, padding from edge, weight of 'X' symbol
		    var size:uint = 32;
		    var padding:uint = 4;
		    var weight:uint = 4;
//LUKE_SAYS: Might not be needed            
//TODO_AHMED: Find equivalents for graphics class
		    /*with (graphics)
			{
				clear();		        
			
				beginFill(0x808080);
				drawRect(0, 0, w, h);

		        moveTo(0, 0);
		        beginFill(0x444444, 1);
		        lineTo(size, 0);
		        lineTo(size, size);
		        lineTo(0, size);
		        lineTo(0, 0);
		        endFill();
		        
		        moveTo(weight+padding, padding);
		        beginFill(0x888888, 1);
		        lineTo(padding, weight+padding);
		        lineTo(size-weight-padding, size-padding);
		        lineTo(size-padding, size-weight-padding);
		        lineTo(weight+padding, padding);
		        endFill();
		        
		        moveTo(size-weight-padding, padding);
		        beginFill(0x888888, 1);
		        lineTo(size-padding, weight+padding);
		        lineTo(weight+padding, size-padding);
		        lineTo(padding, size-weight-padding);
		        lineTo(size-weight-padding, padding);
		        endFill();
		    };*/	
		}
		
		
	}

}
