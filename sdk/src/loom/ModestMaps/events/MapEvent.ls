/*
 * $Id$
 */

package com.modestmaps.events
{
	import com.modestmaps.core.*;
	import com.modestmaps.mapproviders.IMapProvider;
	
	//import flash.events.Event;
	import loom2d.events.Event;
	
	//import flash.geom.Point;
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
		// PORTNOTE: Assuming this is an array of number
	    //public var newSize:Array;
	    public var newSize:Vector.<Tile>;
	    	    
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

		public function MapEvent(type:String, ...rest)
		{
			super(type, true, true);
			
			//TODO_KEVIN, double casting to be optimized
			switch(type) {
				case PANNED:
					if (rest.length > 0 && rest[0] is Point) {
						panDelta = rest[0] as Point;
					}
					break;
				case ZOOMED_BY:
					if (rest.length > 0 && rest[0] is Number) {
						zoomDelta = rest[0] as Number;
					}
					break;
				case EXTENT_CHANGED:
	    			if (rest.length > 0 && rest[0] is MapExtent) {
	    				newExtent = rest[0] as MapExtent;
	    			}
					break;	    	    
				case START_ZOOMING:
				case STOP_ZOOMING:
					if (rest.length > 0 && rest[0] is Number) {
						zoomLevel = rest[0] as Number;
					}
					break;					
	    		case RESIZED:
					//PORTNOTE: Array -> Vector.<Tile>
	    			if (rest.length > 0 && rest[0] is Vector.<Tile>) {
	    				newSize = rest[0] as Vector.<Number>;
	    			}
					break;	    	    
				case COPYRIGHT_CHANGED:
	    			if (rest.length > 0 && rest[0] is String) {
	    				newCopyright = rest[0] as String;
	    			}
					break;	    	    
				case BEGIN_EXTENT_CHANGE:
	    			if (rest.length > 0 && rest[0] is MapExtent) {
	    				oldExtent = rest[0] as MapExtent;
	    			}
					break;	    	    
				case MAP_PROVIDER_CHANGED:
	    			if (rest.length > 0 && rest[0] is IMapProvider) {
	    				newMapProvider = rest[0] as IMapProvider;
	    			}
			}
			
		}
		
		override public function clone():Event
		{
			return new MapEvent(this.type, []);
		}
	}
}
