/*
 * $Id$
 */

package loom.modestmaps.events
{
    import loom.modestmaps.core.*;
    import loom.modestmaps.mapproviders.IMapProvider;
    
    import loom2d.events.Event;
    
    import loom2d.math.Point;

    public class MapEvent extends Event
    {
        public static const INITIALIZED:String = 'mapInitialized';
        public static const CHANGED:String = 'mapChanged';
        
        public static const START_ZOOMING:String = 'startZooming';
        public static const STOP_ZOOMING:String = 'stopZooming';
        public var zoomLevel:Number;

        public static const ZOOMED_BY:String = 'zoomedBy';
        public var zoomDelta:Number;
        
        public static const START_PANNING:String = 'startPanning';
        public static const STOP_PANNING:String = 'stopPanning';

        public static const PANNED:String = 'panned';
        public var panDelta:Point;
        
        public static const RESIZED:String = 'resized';
        public var newSize:Point;
                
        public static const COPYRIGHT_CHANGED:String = 'copyrightChanged';
        public var newCopyright:String;

        public static const BEGIN_EXTENT_CHANGE:String = 'beginExtentChange';
        public var oldExtent:MapExtent;
        
        public static const EXTENT_CHANGED:String = 'extentChanged';
        public var newExtent:MapExtent;
        
        public static const MAP_PROVIDER_CHANGED:String = 'mapProviderChanged';
        public var newMapProvider:IMapProvider;

        public static const BEGIN_TILE_LOADING:String = 'beginTileLoading';
        public static const ALL_TILES_LOADED:String = 'alLTilesLoaded';

        /** listen out for this if you want to be sure map is in its final state before reprojecting markers etc. */
        public static const RENDERED:String = 'rendered';

        public function MapEvent(type:String)
        {
            super(type, true);
        }


        public static function Panned(px:Number, py:Number) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(PANNED);
            mEvent.panDelta.x = px;
            mEvent.panDelta.y = py;
            return mEvent;
        }

        public static function ZoomedBy(zPrev:Number, zNew:Number) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(ZOOMED_BY);
            mEvent.zoomDelta = zNew - zPrev;
            mEvent.zoomLevel = zNew;
            return mEvent;
        }

        public static function BeginExtentChange(extent:MapExtent) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(BEGIN_EXTENT_CHANGE);
            mEvent.oldExtent = extent;
            return mEvent;
        }

        public static function ExtentChanged(extent:MapExtent) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(EXTENT_CHANGED);
            mEvent.newExtent = extent;
            return mEvent;
        }

        public static function StartZooming(z:Number) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(START_ZOOMING);
            mEvent.zoomLevel = z;
            return mEvent;
        }

        public static function StopZooming(zPrev:Number, zNew:Number) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(STOP_ZOOMING);
            mEvent.zoomDelta = zNew - zPrev;
            mEvent.zoomLevel = zNew;
            return mEvent;
        }

        public static function Resized(sx:Number, sy:Number) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(RESIZED);
            mEvent.newSize.x = sx;
            mEvent.newSize.y = sy;
            return mEvent;
        }

        public static function CopyrightChanged(copyright:String) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(COPYRIGHT_CHANGED);
            mEvent.newCopyright = copyright;
            return mEvent;
        }

        public static function MapProviderChanged(provider:IMapProvider) : MapEvent
        {
            var mEvent:MapEvent = new MapEvent(MAP_PROVIDER_CHANGED);
            mEvent.newMapProvider = provider;
            return mEvent;
        }
        
        override public function clone():Event
        {
            return new MapEvent(this.type);
        }
    }
}
