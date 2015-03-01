package com.modestmaps.core.painter
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.core.Tile;
	import com.modestmaps.mapproviders.IMapProvider;
	
	// PORTNOTE: There isn't an event dispacher interface in loom, using the eventdispacher class instead
	//import flash.events.IEventDispatcher;
	import loom2d.events.EventDispatcher;
	
	public interface ITilePainter extends EventDispatcher
	{
		// PORTNOTE: the flash class Class doens't seem to have a loomscript equivalent. Possibly look into reflection?
		//function setTileClass(tileClass:Class):void
		function setMapProvider(provider:IMapProvider):void
		function getTileFromCache(key:String):Tile
		// PORTNOTE: Assuming the keys here are strings
		//function retainKeysInCache(recentlySeen:Array):void
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