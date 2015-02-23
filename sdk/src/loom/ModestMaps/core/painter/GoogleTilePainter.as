package com.modestmaps.core.painter
{
	import com.google.maps.Map;
	import com.google.maps.interfaces.IMapType;
	import com.google.maps.interfaces.ITileLayer;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.core.Tile;
	import com.modestmaps.core.TweenTile;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.mapproviders.IMapProvider;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class GoogleTilePainter extends EventDispatcher implements ITilePainter
	{
		private var type:IMapType;		
		private var googleMap:Map;
		private var tileClass:Class;
		private var timer:Timer;
		private var cache:Dictionary = new Dictionary();
		
		public function GoogleTilePainter(googleMap:Map, type:IMapType)
		{
			super(null);
			this.type = type;
			this.googleMap = googleMap;
			this.tileClass = TweenTile;
			this.timer = new Timer(250);
			timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
			timer.start();
		}
		
		public function setTileClass(tileClass:Class):void
		{
			this.tileClass = tileClass;
		}
		
		public function setMapProvider(provider:IMapProvider):void
		{
			// nothing
		}
		
		public function getTileFromCache(key:String):Tile
		{
			if (key in cache) {
				var t:Tile = cache[key] as Tile;
				if (isPainted(t)) { 
					return t;
				}
			}
			return null;
		}
		
		public function retainKeysInCache(recentlySeen:Array):void
		{
/*  			var tempCache:Dictionary = new Dictionary();
			for each (var key:String in recentlySeen) {
				if (key in cache) tempCache[key] = cache[key];
			}
			this.cache = tempCache; */
		}
		
		public function createAndPopulateTile(coord:Coordinate, key:String):Tile
		{
 			if (key in cache) {
 				return cache[key] as Tile; 
			}
			
			if (googleMap.getCurrentMapType().getName() != type.getName()) {
				googleMap.setMapType(type);
			} 
			
			var tile:Tile = new tileClass(coord.column, coord.row, coord.zoom);
			tile.name = key;
			
			if (coord.zoom > 1 && coord.zoom <= 19 && coord.row >= 0 && coord.row < Math.pow(2,coord.zoom)) {
				coord = coord.copy();
				while (coord.column < 0) {
					coord.column += Math.pow(2,coord.zoom);
				}
				coord.column %= Math.pow(2,coord.zoom);
				var layers:Array = googleMap.getCurrentMapType().getTileLayers();
				for each (var tileLayer:ITileLayer in layers) {
					var tileImage:DisplayObject = tileLayer.loadTile(new Point(coord.column, coord.row), coord.zoom);
					tile.addChild(tileImage);
				}
				tile.hide();
			}
			
			cache[key] = tile;
			
			return tile;
		}
		
		protected function onTimer(event:Event):void
		{
			var unPaintedGridTile:Boolean = false;
			for each (var tile:Tile in cache) {
				if (tile.parent) {
					if (isPainted(tile)) {
						tile.show();
					}
					else {
						unPaintedGridTile = true;
					}
				}
				else {
					tile.hide();
				}
			}
			if (!unPaintedGridTile) {
				dispatchEvent(new MapEvent(MapEvent.ALL_TILES_LOADED));
			}
		}
		
		public function isPainted(tile:Tile):Boolean
		{
			return tile.numChildren > 0 ? (tile.getChildAt(0) as Object)['loadComplete'] : false;
		}
		
		public function cancelPainting(tile:Tile):void
		{
			while (tile.numChildren) {
				tile.removeChildAt(0);
			}
			delete cache[tile.name];
		}
		
		public function isPainting(tile:Tile):Boolean
		{
			var img:Object = tile.numChildren > 0 ? (tile.getChildAt(0) as Object) : null;  
			return img && img.hasOwnProperty('loadComplete') && !img['loadComplete'];
		}
		
		public function reset():void
		{
			this.cache = new Dictionary();
			dispatchEvent(new MapEvent(MapEvent.BEGIN_TILE_LOADING));
		}
		
		public function getLoaderCacheCount():int
		{
			return 0;
		}
		
		public function getQueueCount():int
		{
			return 0;
		}
		
		public function getRequestCount():int
		{
			return 0;
		}
		
		public function getCacheSize():int
		{
			return 0;
		}
				
	}
}