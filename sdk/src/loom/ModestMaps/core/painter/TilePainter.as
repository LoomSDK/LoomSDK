package com.modestmaps.core.painter
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.core.Tile;
	import com.modestmaps.core.TileGrid;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.mapproviders.IMapProvider;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	public class TilePainter extends EventDispatcher implements ITilePainter
	{
		protected static const DEFAULT_CACHE_LOADERS:Boolean = false;  // !!! only enable this if you have crossdomain permissions to access Loader content
		protected static const DEFAULT_SMOOTH_CONTENT:Boolean = false; // !!! only enable this if you have crossdomain permissions to access Loader content
		protected static const DEFAULT_MAX_LOADER_CACHE_SIZE:int = 0;  // !!! suggest 256 or so
		protected static const DEFAULT_MAX_OPEN_REQUESTS:int = 4;      // TODO: should this be split into max-new-requests-per-frame, too?

		///////////// BEGIN OPTIONS

		/** set this to true to enable bitmap smoothing on tiles - requires crossdomain.xml permissions so won't work online with most providers */
		public static var smoothContent:Boolean = DEFAULT_SMOOTH_CONTENT;
		
		/** how many Loaders are allowed to be open at once? */
		public static var maxOpenRequests:int = DEFAULT_MAX_OPEN_REQUESTS;
		
		/** with tile providers that you have crossdomain.xml support for, 
		 *  it's possible to avoid extra requests by reusing bitmapdata. enable cacheLoaders to try and do that */
		public static var cacheLoaders:Boolean = DEFAULT_CACHE_LOADERS;
		public static var maxLoaderCacheSize:int = DEFAULT_MAX_LOADER_CACHE_SIZE;
		
		///////////// END OPTIONS
	
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
		protected var layersNeeded:Object = {};
		protected var loaderTiles:Dictionary = new Dictionary(true);
	
		// open requests
		protected var openRequests:Array = [];
	
		// keeping track for dispatching MapEvent.ALL_TILES_LOADED and MapEvent.BEGIN_TILE_LOADING
		protected var previousOpenRequests:int = 0;

		// loader cache is shared across map instances, hence this is static for the time being	
		protected static var loaderCache:Object = {};
		protected static var cachedUrls:Array = [];

		public function TilePainter(tileGrid:TileGrid, provider:IMapProvider, queueFunction:Function)
		{
			super(null);
			
			this.tileGrid = tileGrid;
			this.provider = provider;
			this.queueFunction = queueFunction;
	
			// TODO: pass all these into the constructor so they can be shared, swapped out or overridden
			this.tileQueue = new TileQueue();
			this.tilePool = new TilePool(Tile);
			this.tileCache = new TileCache(tilePool);
			queueTimer = new Timer(200);
	
			queueTimer.addEventListener(TimerEvent.TIMER, processQueue);		
			
			// TODO: this used to be called onAddedToStage, is this bad?
			queueTimer.start();
		}

		/** The classes themselves serve as factories!
		 * 
		 * @param tileClass e.g. Tile, TweenTile, etc.
		 * 
		 * @see http://norvig.com/design-patterns/img013.gif  
		 */ 
		public function setTileClass(tileClass:Class):void
		{
			// assign the new class, which creates a new pool array
			tilePool.setTileClass(tileClass);
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
		
		public function retainKeysInCache(recentlySeen:Array):void
		{
			tileCache.retainKeys(recentlySeen); 			
		}
		
		public function createAndPopulateTile(coord:Coordinate, key:String):Tile
		{
			var tile:Tile = tilePool.getTile(coord.column, coord.row, coord.zoom);
			tile.name = key;
			var urls:Array = provider.getTileUrls(coord);
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
				var loader:Loader = openRequests[i] as Loader;
				if (loader.name == tile.name) {
					loaderTiles[loader] = null;
					delete loaderTiles[loader];
				}
			}
			if (!tileCache.containsKey(tile.name)) {
				tilePool.returnTile(tile);
			}
			delete layersNeeded[tile.name];
		}
		
		public function isPainting(tile:Tile):Boolean
		{
			return layersNeeded[tile.name] == null;		
		}
	
		public function reset():void
		{
			for each (var loader:Loader in openRequests) {
				var tile:Tile = loaderTiles[loader] as Tile;
				loaderTiles[loader] = null;
				delete loaderTiles[loader];
				if (!tileCache.containsKey(tile.name)) {
					tilePool.returnTile(tile);
				}
				try {
					// la la I can't hear you
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoadEnd);
					loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
					loader.close();
				}
				catch (error:Error) {
					// close often doesn't work, no biggie
				}
			}
			openRequests = [];
			
			for (var key:String in layersNeeded) {
				delete layersNeeded[key];
			}
			layersNeeded = {};
			
			tileQueue.clear();
					
			tileCache.clear();					
		}
	
		private function loadNextURLForTile(tile:Tile):void
		{
			// TODO: add urls to Tile?
			var urls:Array = layersNeeded[tile.name] as Array;
			if (urls && urls.length > 0) {
				var url:* = urls.shift();
				if (cacheLoaders && (url is String) && loaderCache[url]) {
					var original:Bitmap = loaderCache[url] as Bitmap;
					var bitmap:Bitmap = new Bitmap(original.bitmapData); 
					tile.addChild(bitmap);
					loadNextURLForTile(tile);
				}
				else {
					//trace("requesting", url);
					var tileLoader:Loader = new Loader();
					loaderTiles[tileLoader] = tile;
					tileLoader.name = tile.name;
					try {
						if (cacheLoaders || smoothContent) {
							// check crossdomain permissions on tiles if we plan to access their bitmap content
							tileLoader.load((url is URLRequest) ? url : new URLRequest(url), new LoaderContext(true));
						}
						else {
							tileLoader.load((url is URLRequest) ? url : new URLRequest(url));
						}
						tileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadEnd, false, 0, true);
						tileLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError, false, 0, true);
						openRequests.push(tileLoader);
					}
					catch(error:Error) {
						tile.paintError();
					}
				}
			}
			else if (urls && urls.length == 0) {
				tileGrid.tilePainted(tile);
				tileCache.putTile(tile);
				delete layersNeeded[tile.name];
			}			
		}	
	
		/** called by the onEnterFrame handler to manage the tileQueue
		 *  usual operation is extremely quick, ~1ms or so */
		private function processQueue(event:TimerEvent=null):void
		{
			if (openRequests.length < maxOpenRequests && tileQueue.length > 0) {
	
				// prune queue for tiles that aren't visible
				var removedTiles:Array = tileQueue.retainAll(tileGrid.getVisibleTiles());
				
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
				while (openRequests.length < maxOpenRequests && tileQueue.length > 0) {
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
				dispatchEvent(new MapEvent(MapEvent.BEGIN_TILE_LOADING));
			}
			else if (previousOpenRequests > 0)
			{
				// TODO: a custom event for load progress rather than overloading bytesloaded?
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, previousOpenRequests - openRequests.length, previousOpenRequests))
	
			    // if we're finished...
			    if (openRequests.length == 0)
			    {
			    	dispatchEvent(new MapEvent(MapEvent.ALL_TILES_LOADED));
				}
			}
			
			previousOpenRequests = openRequests.length;
		}
	
		private function onLoadEnd(event:Event):void
		{
			var loader:Loader = (event.target as LoaderInfo).loader;
			
			if (cacheLoaders && !loaderCache[loader.contentLoaderInfo.url]) {
				//trace('caching content for', loader.contentLoaderInfo.url);
				try {
					var content:Bitmap = loader.content as Bitmap;
					loaderCache[loader.contentLoaderInfo.url] = content;
					cachedUrls.push(loader.contentLoaderInfo.url);
					if (cachedUrls.length > maxLoaderCacheSize) {
						delete loaderCache[cachedUrls.shift()];
					}
				}
				catch (error:Error) {
					// ???
				}
			}
			
			if (smoothContent) {
				try {
					var smoothContent:Bitmap = loader.content as Bitmap;
					smoothContent.smoothing = true;
				}
				catch (error:Error) {
					// ???
				}
			}			
	
			// tidy up the request monitor
			var index:int = openRequests.indexOf(loader);
			if (index >= 0) {
				openRequests.splice(index,1);
			}
			
			var tile:Tile = loaderTiles[loader] as Tile;
			if (tile) { 
				tile.addChild(loader);
				loadNextURLForTile(tile);
			}
			else {
				// we've loaded an image, but its parent tile has been removed
				// so we'll have to throw it away
			}
			
			loaderTiles[loader] = null;
			delete loaderTiles[loader];
		}
	
		private function onLoadError(event:IOErrorEvent):void
		{
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;
			for (var i:int = openRequests.length-1; i >= 0; i--) {
				var loader:Loader = openRequests[i] as Loader;
				if (loader.contentLoaderInfo == loaderInfo) {
					openRequests.splice(i,1);
					delete layersNeeded[loader.name];
					var tile:Tile = loaderTiles[loader] as Tile;
					if (tile) {
						tile.paintError(provider.tileWidth, provider.tileHeight);
						tileGrid.tilePainted(tile);
						loaderTiles[loader] = null;
						delete loaderTiles[loader];
					}				
				}
			}
		}
		
		public function getLoaderCacheCount():int
		{
			return cachedUrls.length;		
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
