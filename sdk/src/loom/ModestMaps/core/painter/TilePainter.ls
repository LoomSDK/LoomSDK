package loom.modestmaps.core.painter
{
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.core.Tile;
    import loom.modestmaps.core.TileGrid;
    import loom.modestmaps.events.MapEvent;
    import loom.modestmaps.mapproviders.IMapProvider;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;
        
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
    
    import loom.HTTPRequest;
    import loom.platform.Timer;


    public class TilePainter extends EventDispatcher implements ITilePainter
    {
        /** number of ms between calls to process the loading queue */
        public static var ProcessQueueInterval:int = 20;
        
        /** how many Loaders are allowed to be open at once? */
        public static var MaxOpenRequests:int = 8;    // TODO: should this be split into max-new-requests-per-frame, too?            

        /** should downloaded map tile images remain cached on disk? Warning: this could take up a lot of space! */
        public static var CacheTilesOnDisk:Boolean = false;

        protected var provider:IMapProvider;    
        protected var tileGrid:TileGrid;
        protected var tileQueue:TileQueue;
        protected var tileCache:TileCache;
        protected var tilePool:TilePool;        
        protected var queueFunction:Function;
        protected var queueTimer:Timer;

        // per-tile, the array of images we're going to load, which can be empty
        // TODO: document this in IMapProvider, so that provider implementers know
        // they are free to check the bounds of their overlays and don't have to serve
        // millions of 404s
        protected var layersNeeded:Dictionary.<String, Vector.<String>> = {};
        protected var loaderTiles:Dictionary.<Texture, Vector.<Tile>> = {};
    
        // open requests
        protected var openRequests:Vector.<Texture> = [];
    
        // keeping track for dispatching MapEvent.ALL_TILES_LOADED and MapEvent.BEGIN_TILE_LOADING
        protected var previousOpenRequests:int = 0;

        public function TilePainter(tileGrid:TileGrid, provider:IMapProvider, queueFunction:Function)
        {
            super();
            
            this.tileGrid = tileGrid;
            this.provider = provider;
            this.queueFunction = queueFunction;
    
            // TODO: pass all these into the constructor so they can be shared, swapped out or overridden
            this.tileQueue = new TileQueue();
            this.tilePool = new TilePool(CreateTile);
            this.tileCache = new TileCache(tilePool);

            //NOTE_TEC: Seems like the original MMaps code (before the AS3 port) was calling 'processQueue' 
            //      on the ENTER_FRAME event, not every 200ms... good/bad?
            queueTimer = new Timer(ProcessQueueInterval);
            queueTimer.onComplete = processQueue;
            queueTimer.repeats = true;

            // TODO: this used to be called onAddedToStage, is this bad?
            queueTimer.start();
        }

        /* The default Tile creation function used by the TilePool */
        protected function CreateTile():Tile
        {
            return new Tile(0, 0, 0);
        }        

        /** The classes themselves serve as factories!
         * 
         * @param tileCreator Function that will instantiate and return a Tile object e.g. Tile, TweenTile, etc.
         * 
         * @see http://norvig.com/design-patterns/img013.gif  
         */ 
        public function setTileCreator(tileCreator:Function):void
        {
            // assign the new class, which creates a new pool array
            tilePool.setTileCreator(tileCreator);
        }
        
        public function setMapProvider(provider:IMapProvider):void
        {
            this.provider = provider;
            // TODO: clear various things, no doubt?        
        }
        
        public function getTileFromCache(key:String):Tile
        {
            return tileCache.getTile(key);
        }
        
        public function retainKeysInCache(recentlySeen:Vector.<String>):void
        {
            tileCache.retainKeys(recentlySeen);             
        }
        
        public function createAndPopulateTile(coord:Coordinate, key:String):Tile
        {
            var tile:Tile = tilePool.getTile(coord.column, coord.row, coord.zoom);
            tile.name = key;
            var urls:Vector.<String> = provider.getTileUrls(coord);
            if (urls && urls.length > 0) {
                // keep a local copy of the URLs so we don't have to call this twice:
                layersNeeded[tile.name] = urls;
                tileQueue.push(tile);
            }
            else {
                // trace("no urls needed for that tile", tempCoord);
                tile.show();
            }
            return tile;            
        }
    
        public function isPainted(tile:Tile):Boolean
        {
            return !layersNeeded[tile.name];        
        }
        
        public function cancelPainting(tile:Tile):void
        {
            if (tileQueue.contains(tile)) {
                tileQueue.remove(tile);
            }

            for (var i:int = openRequests.length - 1; i >= 0; i--) {
                var texture:Texture = openRequests[i];
                if(loaderTiles[texture] != null)
                {
                    loaderTiles[texture].remove(tile);
                    if(loaderTiles[texture].length == 0)
                    {
                        //only delete refs to this texture if nothing else is using it
                        loaderTiles.deleteKey(texture);
                        openRequests.remove(texture);
                        texture.cancelHTTPRequest();
                    }
                }
            }
            if (!tileCache.containsKey(tile.name)) {
                tilePool.returnTile(tile);
            }
            layersNeeded.deleteKey(tile.name);
        }
        
        public function isPainting(tile:Tile):Boolean
        {
            return layersNeeded[tile.name] == null;     
        }
    
        public function reset():void
        {
            for each (var texture:Texture in openRequests) {
                texture.cancelHTTPRequest();
                if(loaderTiles[texture] != null)
                {
                    var tileList:Vector.<Tile> = loaderTiles[texture];
                    for each (var tile:Tile in tileList) {
                        if (!tileCache.containsKey(tile.name)) {
                            tilePool.returnTile(tile);
                        }
                    }
                    loaderTiles.deleteKey(texture);
                }
            }
            openRequests.clear();
            layersNeeded.clear();
            tileQueue.clear();
            tileCache.clear();                  
        }
    
        private function loadNextURLForTile(tile:Tile):void
        {
            // TODO: add urls to Tile?
            var urls:Vector.<String> = layersNeeded[tile.name] as Vector.<String>;
            if (urls && urls.length > 0) {
                var url = urls.shift();

                //request the texture via HTTP
                var texture:Texture = Texture.fromHTTP(url, onLoadEnd, onLoadFail, CacheTilesOnDisk, false);
                if(texture == null)
                {
                    tile.paintError();
                    return;
                }

                //is texture loaded and ready to go?
                if(texture.isTextureValid())
                {
                    tile.assignTexture(texture);
                    loadNextURLForTile(tile);
                }
                else
                {
                    //need to wait for the texture to finish loading, so put into the request queue
                    if(loaderTiles[texture] == null)
                    {
                        loaderTiles[texture] = [tile];
                        openRequests.pushSingle(texture);
                    }
                    else
                    {
                        loaderTiles[texture].pushSingle(tile);
                    }

//TODO_24: we're unable to click on empty BG of the painter where there are no Images... 
//should we always have an Image(null) on a tile by default?
                }
            }
            else if (urls && urls.length == 0) {
                tileGrid.tilePainted(tile);
                tileCache.putTile(tile);
                layersNeeded.deleteKey(tile.name);
            }           
        }   
    
        /** called by the onEnterFrame handler to manage the tileQueue
         *  usual operation is extremely quick, ~1ms or so */
        private function processQueue(timer:Timer):void
        {
            if (openRequests.length < MaxOpenRequests && tileQueue.length > 0) {
    
                // prune queue for tiles that aren't visible
                var removedTiles:Vector.<Tile> = tileQueue.retainAll(tileGrid.getVisibleTiles());
                
//TODO_24: removedTiles is always empty, so we are never doing early removals of tiles 
//that may have been queued up for URL requests but should be removed early due to no longer being visible                
                // keep layersNeeded tidy:
                for each (var removedTile:Tile in removedTiles) {
                    this.cancelPainting(removedTile);
                }
                
                // note that queue is not the same as visible tiles, because things 
                // that have already been loaded are also in visible tiles. if we
                // reuse visible tiles for the queue we'll be loading the same things over and over
    
                // sort queue by distance from 'center'
                tileQueue.sortTiles(queueFunction);
    
                // process the queue
                while (openRequests.length < MaxOpenRequests && tileQueue.length > 0) {
                    var tile:Tile = tileQueue.shift();
                    // if it's still on the stage:
                    if (tile.parent) {
                        loadNextURLForTile(tile);
                    }
                }
            }

            // you might want to wait for tiles to load before displaying other data, interface elements, etc.
            // these events take care of that for you...
            if (previousOpenRequests == 0 && openRequests.length > 0) {
                dispatchEvent(new MapEvent(MapEvent.BEGIN_TILE_LOADING, []));
            }
            else if (previousOpenRequests > 0)
            {
                // if we're finished...
                if (openRequests.length == 0)
                {
                    dispatchEvent(new MapEvent(MapEvent.ALL_TILES_LOADED, []));
                }
            }
            
            previousOpenRequests = openRequests.length;
        }
    
        private function onLoadEnd(texture:Texture):void
        {
            // tidy up the request monitor
            // TODO: this used to be called onAddedToStage, is this bad?
            openRequests.remove(texture);

            //check this texture against all possible tiles that may have requested it
            var assignedToTile:Boolean = false;
            if(loaderTiles[texture] != null)
            {
                var tileList:Vector.<Tile> = loaderTiles[texture];
                for each (var tile:Tile in tileList) {
                    //add the texture to the tile
                    assignedToTile = true;
                    tile.assignTexture(texture);
                    loadNextURLForTile(tile);
                }
                loaderTiles.deleteKey(texture);
            }

            if(!assignedToTile)
            {
                //will get here if reset() or cancelPainting() on a tile is called before the requested 
                //texture has finished loading I think... make sure it's handled properly!           
                texture.dispose();
            }
        }

        private function onLoadFail(texture:Texture):void
        {
            // tidy up the request monitor
            openRequests.remove(texture);

            //check this texture against all possible tiles that may have requested it
            if(loaderTiles[texture] != null)
            {
                var tileList:Vector.<Tile> = loaderTiles[texture];
                for each (var tile:Tile in tileList) {
                    Console.print("ERROR: Failed to load map tile texture via HTTP for tile: " + tile.name);
                    tile.paintError();
                }
                loaderTiles.deleteKey(texture);
            }

            //NOTE_TEC: Do we want to try to reload it somehow? Or just let it be an 'error' and let 
            //it auto-request when the tile is flagged as dirty again after scrolling/zooming?
        }
        
        public function getQueueCount():int
        {
            return tileQueue.length;
        }
        
        public function getRequestCount():int
        {
            return openRequests.length;
        }
        
        public function getCacheSize():int
        {
            return tileCache.size;
        }       
    }
}
