package com.modestmaps.core.painter
{
    import com.modestmaps.core.Tile;
    
    /** 
     *  This post http://lab.polygonal.de/2008/06/18/using-object-pools/
     *  suggests that using Object pools, especially for complex classes like Sprite
     *  is a lot faster than calling new Object().  The suggested implementation
     *  uses a linked list, but to get started with it here I'm using an Array.  
     *  
     *  If anyone wants to try it with a linked list and compare the times,
     *  it seems like it could be worth it :)
     */ 
    public class TilePool 
    {
        protected static const MIN_POOL_SIZE:int = 256;
        protected static const MAX_NEW_TILES:int = 256;
        
        protected var pool:Vector.<Tile> = [];
        protected var tileCreatorFunc:Function;
        
        public function TilePool(tileCreator:Function)
        {
            this.tileCreatorFunc = tileCreator;
        }
    
        public function setTileCreator(tileCreator:Function):void
        {
            this.tileCreatorFunc = tileCreator;
            pool = [];
        }
    
        public function getTile(column:int, row:int, zoom:int):Tile
        {
            if (pool.length < MIN_POOL_SIZE) {
                while (pool.length < MAX_NEW_TILES) {
                    pool.push(tileCreatorFunc());
                }
            }                       
            var tile:Tile = pool.pop() as Tile;
            tile.init(column, row, zoom);
            return tile;
        }
    
        public function returnTile(tile:Tile):void
        {
            tile.destroy();
            pool.push(tile);
        }
        
    }
}