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
            queue.sort(callback) as Vector.<Tile>;
        }
        
        public function retainAll(tiles:Vector.<Tile>):Vector.<Tile>
        {
            var removed:Vector.<Tile> = [];
            var collapsedIndex = 0;
            var i:int = 0;
            var tile:Tile;
            for (i = 0; i < queue.length; i++) {
                tile = queue[i] as Tile;
                if (tiles.indexOf(tile) < 0) {
                    removed.pushSingle(tile);
                } else {
                    if (i != collapsedIndex) queue[collapsedIndex] = tile;
                    collapsedIndex++;
                }
            }
            queue.length -= removed.length;
            return removed;
        }
        
        public function clear():void
        {
            queue.clear();
        }
    }
}