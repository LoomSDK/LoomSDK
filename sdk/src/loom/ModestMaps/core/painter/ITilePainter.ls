package loom.modestmaps.core.painter
{
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.core.Tile;
    import loom.modestmaps.events.MapTileLoad;
    import loom.modestmaps.mapproviders.IMapProvider;
    
    import loom2d.events.EventDispatcher;
    
    public interface ITilePainter extends EventDispatcher
    {
        function getOnTileLoad():MapTileLoad;
        function setTileCreator(tileCreator:Function):void
        function setMapProvider(provider:IMapProvider):void
        function getTileFromCache(key:String):Tile
        function retainKeysInCache(recentlySeen:Vector.<String>):void
        function createAndPopulateTile(coord:Coordinate, key:String):Tile
        function isPainted(tile:Tile):Boolean
        function cancelPainting(tile:Tile):void
        function isPainting(tile:Tile):Boolean
        function reset():void
        function getQueueCount():int
        function getRequestCount():int
        function getCacheSize():int     
    }
}