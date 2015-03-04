package com.modestmaps.core.painter
{
	import com.modestmaps.core.Tile;
		
	/** the alreadySeen Dictionary here will contain up to grid.maxTilesToKeep Tiles */
	public class TileCache
	{
		// Tiles we've already seen and fully loaded, by key (.name)
		protected var alreadySeen:Dictionary.<String, Tile>;
		protected var tilePool:TilePool; // for handing tiles back!
		
		public function TileCache(tilePool:TilePool)
		{
			this.tilePool = tilePool;
			alreadySeen = new Dictionary.<String, Tile>();
		}
		
		public function get size():int
		{
            return alreadySeen.length;
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
//NOTE_24: if alreadySeen[key] is null, will this pass? Should maybe be return alreadySeen[key] != null; ?      
			return alreadySeen[key] is Tile;
		}
		
		public function retainKeys(keys:Vector.<String>):void
		{
			for (var key:String in alreadySeen) {
				if (keys.indexOf(key) < 0) {
					tilePool.returnTile(alreadySeen[key] as Tile);
					alreadySeen.deleteKey(key);
				}
			}		
		}
		
		public function clear():void
		{
			for (var key:String in alreadySeen) {
				tilePool.returnTile(alreadySeen[key] as Tile);
			}
			alreadySeen.clear();		
		}
	}
}