package loom.modestmaps.core.painter
{
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.core.Tile;
    import loom.modestmaps.core.TileGrid;
    import loom.modestmaps.events.MapEvent;
    import loom.modestmaps.events.MapState;
    import loom.modestmaps.events.MapTileLoad;
    import loom.modestmaps.mapproviders.IMapProvider;
    import loom2d.animation.IAnimatable;
    import loom2d.display.Image;
    import loom2d.Loom2D;
    import loom2d.math.Point;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAsyncLoadCompleteDelegate;
    import loom2d.textures.TextureHTTPFailDelegate;
    import loom2d.textures.TextureSmoothing;
    import system.Number;
    import system.platform.Platform;
    import system.Void;
        
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;
    
    import loom.HTTPRequest;
    import loom.platform.Timer;


    public class TilePainter extends EventDispatcher implements ITilePainter, IAnimatable
    {
        /** number of ms between calls to process the loading queue */
        //public static var ProcessQueueInterval:int = 20;
        
        /** how many Loaders are allowed to be open at once? */
        public static var MaxOpenRequests:int = 8;    // TODO: should this be split into max-new-requests-per-frame, too?            

        /** should downloaded map tile images remain cached on disk? Warning: this could take up a lot of space! */
        public static var CacheTilesOnDisk:Boolean = false;

        public var onTileLoad:MapTileLoad;
        public function getOnTileLoad():MapTileLoad { return onTileLoad; }
        
        protected var provider:IMapProvider;    
        protected var tileGrid:TileGrid;
        protected var tileCache:TileCache;
        protected var tilePool:TilePool;        
        protected var queueFunction:Function;
        
        protected var headQueue:Tile;
        protected var queueCount = 0;
        
        //protected var queueTimer:Timer;

        // per-tile, the array of images we're going to load, which can be empty
        // TODO: document this in IMapProvider, so that provider implementers know
        // they are free to check the bounds of their overlays and don't have to serve
        // millions of 404s
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
            headQueue = null;
            this.tilePool = new TilePool(CreateTile);
            this.tileCache = new TileCache(tilePool);
            
            enable();
        }
        
        private function enable(e:Event = null):void {
            Loom2D.juggler.add(this);
        }
        private function disable(e:Event = null):void {
            Loom2D.juggler.remove(this);
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
        
        public function returnKey(key:String):Tile
        {
            var tile = tileCache.returnKey(key);
            if (tile) {
                cancelPainting(tile);
            } else {
                trace("warn:", key, "was not in cache");
            }
            return tile;
        }
        
        /**
         * Push the provided tile to the head of the loading queue
         * @param tile The Tile to add.
         */
        public function queueAdd(tile:Tile) {
            if (!headQueue) {
                headQueue = tile;
            } else {
                tile.prevQueue = null;
                tile.nextQueue = headQueue;
                headQueue.prevQueue = tile;
                headQueue = tile;
            }
            queueCount++;
        }
        
        /**
         * Remove the provided tile from the loading queue.
         * @param tile The Tile to remove.
         */
        public function queueRemove(tile:Tile) {
            if (tile == headQueue) {
                headQueue = tile.nextQueue;
                if (headQueue) headQueue.prevQueue = null;
            } else {
                var after = tile.nextQueue;
                var before = tile.prevQueue;
                if (after) after.prevQueue = before;
                before.nextQueue = after;
            }
            tile.nextQueue = tile.prevQueue = null;
            queueCount--;
        }
        
        /**
         * Returns true if the provided tile is in the loading queue.
         * @param tile  The Tile to check.
         * @return  true if tile is in queue, otherwise false
         */
        public function queueHas(tile:Tile):Boolean {
            return tile.prevQueue || tile.nextQueue;
        }
        
        public function createAndPopulateTile(coord:Coordinate, key:String):Tile
        {
            if (tileCache.containsKey(key)) trace("Key already in cache", key);
            var tile:Tile = tilePool.getTile(coord.column, coord.row, coord.zoom);
            tile.name = key;
            tile.urls = provider.getTileUrls(coord);
            if (tile.urls && tile.urls.length > 0) {
                queueAdd(tile);
                tile.isPainting = true;
                tile.loadStatus = "load "+tile.urls.length;
            } else {
                tile.loadStatus = "preloaded";
                tile.show();
            }
            tileCache.putTile(tile);
            return tile;            
        }
        
        public function isPainting(tile:Tile):Boolean
        {
            return tile.isPainting;        
        }
    
        public function isPainted(tile:Tile):Boolean
        {
            return tile.isPainted;        
        }
        
        
        private static var texturePool:Vector.<Texture> = new Vector.<Texture>();
        
        public static function getTexture(url:String, onSuccess:TextureAsyncLoadCompleteDelegate, onFailure:TextureHTTPFailDelegate, cacheOnDisk:Boolean, highPriority:Boolean):Texture
        {
            var texture:Texture = null;
            // Debug trace on each new or update texture load
            //trace(texturePool.length > 0 ? "update" : "new", url);
            if (texturePool.length > 0) {
                texture = texturePool.pop();
                texture.updateFromHTTP(url, onSuccess, onFailure, cacheOnDisk, highPriority);
            } else {
                texture = Texture.fromHTTP(url, onSuccess, onFailure, cacheOnDisk, highPriority);
            }
            return texture;
        }
        
        public static function returnTexture(texture:Texture)
        {
            texturePool.push(texture);
            //texture.dispose();
        }
        
        
        public function cancelPainting(tile:Tile):void
        {
            if (queueHas(tile)) {
                queueRemove(tile);
            }
            
            tile.loadStatus = "cancelled";
            
            for (var i:int = openRequests.length - 1; i >= 0; i--) {
                var texture:Texture = openRequests[i];
                if(loaderTiles[texture] != null)
                {
                    loaderTiles[texture].remove(tile);
                    if(loaderTiles[texture].length == 0)
                    {
                        //only delete refs to this texture if no other tiles are trying to load it atm
                        loaderTiles.deleteKey(texture);
                        openRequests.remove(texture);
                        texture.cancelHTTPRequest();
                    }
                }
            }
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
            while (headQueue) queueRemove(headQueue);
            tileCache.clear();
            while (texturePool.length > 0) texturePool.pop().dispose();
        }
        
        /* INTERFACE loom2d.animation.IAnimatable */
        
        public function advanceTime(time:system.Number) {
            processQueue();
        }
        
        private function getHighestPriorityTile():Tile {
            var maxP:Number = -1e9;
            var maxTile:Tile = null;
            var tile = headQueue;
            //trace("priority");
            while (tile) {
                var p:Number = getTilePriority(tile);
                tile.loadPriority = p;
                if (p > maxP) {
                    maxP = p;
                    maxTile = tile;
                }
                tile = tile.nextQueue;
            }
            return maxTile;
        }
        
        private function getTilePriority(tile:Tile):Number
        {
            var dc = (tile.column+0.5)-tileGrid.centerColumn;
            var dr = (tile.row+0.5)-tileGrid.centerRow;
            return tile.zoom*1/(1+(dc*dc+dr*dr));
        }
        
        /** called by the onEnterFrame handler to manage the tileQueue
         *  usual operation is extremely quick, ~1ms or so */
        private function processQueue():void
        {
            verifyFirstRequest();
            if (headQueue && openRequests.length < MaxOpenRequests) {
                
                
                // note that queue is not the same as visible tiles, because things 
                // that have already been loaded are also in visible tiles. if we
                // reuse visible tiles for the queue we'll be loading the same things over and over
                
                var tile:Tile = null;
                
                // process the queue
                do {
                    var next:Boolean = loadNextURLForTile(tile);
                    if (next) tile = getHighestPriorityTile();
                } while (tile && openRequests.length < MaxOpenRequests);
            }

            // you might want to wait for tiles to load before displaying other data, interface elements, etc.
            // these events take care of that for you...
            if (previousOpenRequests == 0 && openRequests.length > 0) {
                onTileLoad(MapState.STARTED);
            }
            else if (previousOpenRequests > 0)
            {
                // if we're finished...
                if (openRequests.length == 0)
                {
                    onTileLoad(MapState.STOPPED);
                }
            }
            
            previousOpenRequests = openRequests.length;
        }
        
        /**
         * Check for hanging open requests with tiles that were timed out or otherwise removed
         */
        private function verifyFirstRequest() {
            if (openRequests.length == 0) return;
            
            var texture:Texture = openRequests[0];
            var valid = false;
            
             //check this texture against all possible tiles that may have requested it
            if(loaderTiles[texture] != null)
            {
                var tileList:Vector.<Tile> = loaderTiles[texture];
                for each (var tile:Tile in tileList) {
                    // Debug trace hanging open request tiles
                    //trace(tileList.length, tile.column, tile.row, tile.zoom, tile.openRequests, tile.urls.length, "W", tile.inWell, "P", tile.isPainting, tile.isPainted, "S", tile.isShowing, "V", tile.isVisible, tile.loadStatus, Platform.getTime()-tile.lastLoad);
                    if (tile.openRequests > 0) {
                        valid = true;
                    }
                }
            }
            
            if (!valid) {
                Debug.print("Invalid request texture detected, removing...");
                onLoadFail(texture);
            }
        }
        
        private function loadNextURLForTile(tile:Tile):Boolean
        {
            if (!tile) return true;
            
            Debug.assert(tile.isPainting, "should be painting "+tile.loadStatus);
            
            tile.lastLoad = Platform.getTime();
            
            // TODO: add urls to Tile?
            var urls:Vector.<String> = tile.urls as Vector.<String>;
            if (urls && urls.length > 0) {
                var url = urls.shift();
                
                // request the texture via HTTP
                var texture:Texture = getTexture(url, onLoadSuccess, onLoadFail, CacheTilesOnDisk, false);
                if (texture == null)
                {
                    tile.loadStatus = "error in texture init";
                }
                // is texture loaded and ready to go?
                else if (texture.isTextureValid())
                {
                    tile.loadStatus = "texture valid";
                    tile.assignTexture(texture);
                }
                else
                {
                    tile.loadStatus = "loading";
                    // need to wait for the texture to finish loading, so put into the request queue
                    if (loaderTiles[texture] == null)
                    {
                        loaderTiles[texture] = [tile];
                        openRequests.pushSingle(texture);
                    }
                    else
                    {
                        loaderTiles[texture].pushSingle(tile);
                    }
                    tile.openRequests++;
                }
            }
            
            if (!urls || urls.length == 0) {
                onTileDone(tile);
                queueRemove(tile);
                tileGrid.tilePainted(tile);
                return true;
            }
            return false;
        }
        
        private function onTileDone(tile:Tile) {
            if (tile.openRequests > 0) return;
            tile.isPainting = false;
            tile.isPainted = true;
        }
        
        private function onLoadSuccess(texture:Texture):void
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
                    tile.openRequests--;
                    onTileDone(tile);
                    tile.loadStatus = "loaded";
                    assignedToTile = true;
                    tile.assignTexture(texture);
                }
                loaderTiles.deleteKey(texture);
            }

            if(!assignedToTile)
            {
                //will get here if reset() or cancelPainting() on a tile is called before the requested 
                //texture has finished loading I think... make sure it's handled properly!           
                returnTexture(texture);
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
                    tile.openRequests--;
                    onTileDone(tile);
                    tile.loadStatus = "failed";
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
            return queueCount;
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
