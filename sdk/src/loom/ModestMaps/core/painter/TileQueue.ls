package com.modestmaps.core.painter
{
	import com.modestmaps.core.Tile;
	
	public class TileQueue
	{
		// Tiles we want to load:
		// PORTNOTE: Assuming the array is a vector of tiles
		//protected var queue:Array;
		protected var queue:Vector.<Tile>;
		
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
			// PORTNOTE: The vector class implents sorting using objects like myVector.sort(Vector.CASEINSENSITIVE | Vector.DESCENDING), simply using the defualt behaviour
			//queue = queue.sort(callback);
			queue.sort();
		}
		
		// PORTNOTE: the original function returned a generic array, my assumtion is that it really wants to return an array of tiles
		//public function retainAll(tiles:Array):Array
		public function retainAll(tiles:Vector.<Tile>):Vector.<Tile>
		{
			var removed:Vector.<Tile> = [];
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