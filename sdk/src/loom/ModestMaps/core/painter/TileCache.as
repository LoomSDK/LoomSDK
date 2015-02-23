package com.modestmaps.core.painter
{
	import com.modestmaps.core.Tile;
	
	import flash.utils.Dictionary;
		
	/** the alreadySeen Dictionary here will contain up to grid.maxTilesToKeep Tiles */
	public class TileCache
	{
		// Tiles we've already seen and fully loaded, by key (.name)
		protected var alreadySeen:Dictionary;
		protected var tilePool:TilePool; // for handing tiles back!
		
		public function TileCache(tilePool:TilePool)
		{
			this.tilePool = tilePool;
			alreadySeen = new Dictionary();
		}
		
		public function get size():int
		{
			var alreadySeenCount:int = 0;
			for (var key:* in alreadySeen) {
				alreadySeenCount++;
			}
			return alreadySeenCount;		
		}
		
		public function putTile(tile:Tile):void
		{
			alreadySeen[tile.name] = tile;
		}
		
		public function getTile(key:String):Tile
		{
			return alreadySeen[key] as Tile;
		}
		
		public function containsKey(key:String):Boolean
		{
			return alreadySeen[key] is Tile;
		}
		
		public function retainKeys(keys:Array):void
		{
			for (var key:String in alreadySeen) {
				if (keys.indexOf(key) < 0) {
					tilePool.returnTile(alreadySeen[key] as Tile);
					delete alreadySeen[key];
				}
			}		
		}
		
		public function clear():void
		{
			for (var key:String in alreadySeen) {
				tilePool.returnTile(alreadySeen[key] as Tile);
				delete alreadySeen[key];
			}
			alreadySeen = new Dictionary();		
		}
	}
}