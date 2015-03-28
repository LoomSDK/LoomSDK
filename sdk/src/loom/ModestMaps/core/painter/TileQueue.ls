package loom.modestmaps.core.painter
{
    import loom.modestmaps.core.Tile;
    
    public class TileQueue
    {
        // Tiles we want to load:
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
            queue.remove(tile); 
        }
        
        public function push(tile:Tile):void
        {
            queue.pushSingle(tile);
        }
        
        public function shift():Tile
        {
            return queue.shift() as Tile;
        }
        
        public function sortTiles(callback:Function):void
        {
            queue = queue.sort(callback) as Vector.<Tile>;
        }
        
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
            queue.clear();
        }
    }
}