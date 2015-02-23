package com.modestmaps.core.painter
{
	import com.modestmaps.core.Tile;
	
	public class TileQueue
	{
		// Tiles we want to load:
		protected var queue:Array;
		
		public function TileQueue()
		{
			queue = [];
		}
		
		public function get length():Number 
		{
			return queue.length;
		}
	
		public function contains(tile:Tile):Boolean
		{
			return queue.indexOf(tile) >= 0;
		}
	
		public function remove(tile:Tile):void
		{
			var index:int = queue.indexOf(tile); 
			if (index >= 0) { 
				queue.splice(index, 1);
			}
		}
		
		public function push(tile:Tile):void
		{
			queue.push(tile);
		}
		
		public function shift():Tile
		{
			return queue.shift() as Tile;
		}
		
		public function sortTiles(callback:Function):void
		{
			queue = queue.sort(callback);
		}
		
		public function retainAll(tiles:Array):Array
		{
			var removed:Array = [];
			for (var i:int = queue.length-1; i >= 0; i--) {
				var tile:Tile = queue[i] as Tile;
				if (tiles.indexOf(tile) < 0) {
					removed.push(tile);
					queue.splice(i,1);
				} 
			}
			return removed;
		}
		
		public function clear():void
		{
			queue = [];
		}
	}
}