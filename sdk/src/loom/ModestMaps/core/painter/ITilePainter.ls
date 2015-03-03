package com.modestmaps.core.painter
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.core.Tile;
	import com.modestmaps.mapproviders.IMapProvider;
	
	import loom2d.events.EventDispatcher;
	
	public interface ITilePainter extends EventDispatcher
	{
//NOTE_24: tileClass only used to support Tile and TweenTile, the latter of which we don't need ATM         
		//function setTileClass(tileClass:Class):void
		function setMapProvider(provider:IMapProvider):void
		function getTileFromCache(key:String):Tile
		function retainKeysInCache(recentlySeen:Vector.<String>):void
		function createAndPopulateTile(coord:Coordinate, key:String):Tile
		function isPainted(tile:Tile):Boolean
		function cancelPainting(tile:Tile):void
		function isPainting(tile:Tile):Boolean
		function reset():void
		function getLoaderCacheCount():int
		function getQueueCount():int
		function getRequestCount():int
		function getCacheSize():int		
	}
}