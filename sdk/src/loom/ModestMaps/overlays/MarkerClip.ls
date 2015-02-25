package com.modestmaps.overlays
{
	import com.modestmaps.Map;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.events.MarkerEvent;
	import com.modestmaps.geo.Location;
	import com.modestmaps.mapproviders.IMapProvider;
	import loom2d.core.TouchMarker;
	
	import loom2d.display.DisplayObject;
	import loom2d.display.Sprite;
	import loom2d.events.Event;
	// PORTNOTE: Using touch events in place of mouse events because loom is missing them
	//import flash.events.MouseEvent;
	import loom2d.events.TouchEvent;
	import loom2d.math.Point;
	// PORTNOTE: Dictionary is a built in variable type in loomscript
	//import flash.utils.Dictionary;
	// PORTNOTE: loom doesn't contain matching classes for clearTimeout and setTimeout
	//import flash.utils.clearTimeout;
	//import flash.utils.setTimeout;

    [Event(name="markerRollOver",    type="com.modestmaps.events.MarkerEvent")]
    [Event(name="markerRollOut",     type="com.modestmaps.events.MarkerEvent")]
    [Event(name="markerClick",       type="com.modestmaps.events.MarkerEvent")]
	public class MarkerClip extends Sprite
	{
		public static const DEFAULT_ZOOM_TOLERANCE:int = 4;
		
	    protected var map:Map;
	    
	    protected var drawCoord:Coordinate;
	    
		// PORTNOTE: This seems to be used as a dictionary of type displayobject and location 
	    //protected var locations:Dictionary = new Dictionary();
	    protected var locations:Dictionary.<DisplayObject, Location>;
	    // PORTNOTE: This seems to be used as a dictionary of displayobject and coordinate
		//protected var coordinates:Dictionary = new Dictionary();
	    protected var coordinates:Dictionary.<DisplayObject, Coordinate>;
		// PORTNOTE: This seems to be used as an array of display objects
	    //protected var markers:Array = []; // all markers
	    protected var markers:Vector.<DisplayObject>; // all markers
	    // PORTNOTE: This seems to be used as a dictionary of string and displayobject
		//protected var markersByName:Object = {};
	    protected var markersByName:Dictionary.<String, DisplayObject>;

        /** enable this if you want intermediate zooming steps to
         * stretch your graphics instead of reprojecting the points
         * it's useful for polygons, but for points 
         * it looks worse and probably isn't faster, but there it is :) */
        public var scaleZoom:Boolean = false;
        
        /** if autoCache is true, we turn on cacheAsBitmap while panning, but off while zooming */
        public var autoCache:Boolean = true;
        
        /** if scaleZoom is true, this is how many zoom levels you
         * can zoom by before things will be reprojected regardless */
        public var zoomTolerance:Number = DEFAULT_ZOOM_TOLERANCE; 
        
        // enable this if you want marker locations snapped to pixels
        public var snapToPixels:Boolean = false;
        
        // the function used to sort the markers array before re-ordering them
        // on the z plane (by child index)
        public var markerSortFunction:Function = sortMarkersByYPosition;

		// the projection of the current map's provider
		// if this changes we need to recache coordinates
		protected var previousGeometry:String;

		// setting this.dirty = true will redraw an MapEvent.RENDERED
		protected var _dirty:Boolean;

        /**
         * This is the function provided to markers.sort() in order to determine which
         * markers should go in front of the others. The default behavior is to place
         * markers further down on the screen (with higher y values) frontmost. You
         * can modify this behavior by specifying a different value for
         * MarkerClip.markerSortFunction
         */
        public static function sortMarkersByYPosition(a:DisplayObject, b:DisplayObject):int
        {
            var diffY:Number = a.y - b.y;
            return (diffY > 0) ? 1 : (diffY < 0) ? -1 : 0;
        }
		
	    public function MarkerClip(map:Map)
	    {
	    	// client code can listen to mouse events on this clip
	    	// to get all events bubbled up from the markers
			// PORTNOTE: There isn;t any support for mouse related stuff in loom
// TODO_AHMED: Investigate the missing mouse stuff in relation to touch controls
	    	//buttonMode = false;
	    	//mouseEnabled = false;
	    	//mouseChildren = true;
	    		    	
	    	this.map = map;
// TODO_AHMED: Reimplement these lines when map class is complete
	    	this.x = map.getWidth() / 2;
	    	this.y = map.getHeight() / 2;
// TODO_AHMED: Reimplement this when map class is complete
	    	previousGeometry = map.getMapProvider().geometry();

			map.addEventListener(MapEvent.START_ZOOMING, onMapStartZooming);
	        map.addEventListener(MapEvent.STOP_ZOOMING, onMapStopZooming);
	        map.addEventListener(MapEvent.ZOOMED_BY, onMapZoomedBy);
	        map.addEventListener(MapEvent.START_PANNING, onMapStartPanning);
	        map.addEventListener(MapEvent.STOP_PANNING, onMapStopPanning);
	        map.addEventListener(MapEvent.PANNED, onMapPanned);
	        map.addEventListener(MapEvent.RESIZED, onMapResized);
	        map.addEventListener(MapEvent.EXTENT_CHANGED, onMapExtentChanged);
	        map.addEventListener(MapEvent.RENDERED, updateClips);
	        map.addEventListener(MapEvent.MAP_PROVIDER_CHANGED, onMapProviderChanged);

			// these were previously in Map, but now MarkerEvents bubble it makes more sense to have them here
// TODO_AHMED: Find repacements for mouseevents
			/*addEventListener( MouseEvent.CLICK, onMarkerClick );
			addEventListener( MouseEvent.ROLL_OVER, onMarkerRollOver, true );		
			addEventListener( MouseEvent.ROLL_OUT, onMarkerRollOut, true );*/	

	        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        public function getMarkerCount():int
        {
        	return markers.length;
        }
        
        override public function set x(value:Number):void
        {
            super.x = snapToPixels ? Math.round(value) : value;
        }
        
        override public function set y(value:Number):void
        {
            super.y = snapToPixels ? Math.round(value) : value;
        }
        
        protected function onAddedToStage(event:Event):void
        {
	        //addEventListener(Event.RENDER, updateClips);
        	
        	dirty = true;
        	updateClips();
	        
	        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	        addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	        
        }

        protected function onRemovedFromStage(event:Event):void
        {
	        //removeEventListener(Event.RENDER, updateClips);
	        
	        removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	        
	        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        public function attachMarker(marker:DisplayObject, location:Location):void
	    {
	        if (markers.indexOf(marker) == -1)
	        {
    	        locations[marker] = location.clone();
// TODO_AHMED: Reimplement next line when map class is complete
    	        coordinates[marker] = map.getMapProvider().locationCoordinate(location);
    	        markersByName[marker.name] = marker;
    	        markers.push(marker);
    	        
    	        var added:Boolean = updateClip(marker);
    	        
    	        if (added) {
    	        	requestSort(true);
    	        }
    	    }
	    }
	    
	    protected function markerInBounds(marker:DisplayObject, w:Number, h:Number):Boolean
	    {
	        return marker.x > -w / 2 && marker.x < w / 2 &&
	               marker.y > -h / 2 && marker.y < h / 2;
	    }
	    
	    public function getMarker(id:String):DisplayObject
	    {
	        return markersByName[id] as DisplayObject;
	    }
	    
	    public function getMarkerLocation( marker:DisplayObject ) : Location {
	    	return locations[marker];
	    }
	    
	    public function hasMarker(marker:DisplayObject):Boolean
	    {
	        return markers.indexOf(marker) != -1;
	    }
	    
	    public function setMarkerLocation(marker:DisplayObject, location:Location):void
	    {
	        locations[marker] = new Location(location.lat, location.lon);
// TODO_AHMED: Reimplement the next line when map class is complete
	        coordinates[marker] = map.getMapProvider().locationCoordinate(location);
	        sortMarkers();
	        dirty = true;
	    }
	    
	    public function removeMarker(id:String):void
	    {
	    	var marker:DisplayObject = getMarker(id);
	    	if (marker)
	    	{
	    		removeMarkerObject(marker);
    	    }
	    }
	    
	    public function removeMarkerObject(marker:DisplayObject):void
	    {
	    	if (this.contains(marker)) {
	    		removeChild(marker);
	    	}
	    	var index:int = markers.indexOf(marker);
	    	if (index >= 0) {
	    		markers.splice(index,1);
	    	}
			// PORTNOTE: Delete keyword isn't implemented in loomscript
	    	//delete locations[marker];
	    	//delete coordinates[marker];
	    	//delete markersByName[marker.name];
			locations.deleteKey(marker);
			coordinates.deleteKey(marker);
			markersByName.deleteKey(marker.name);
	    }

		// removeAllMarkers was implemented on trunk
		// meanwhile clearMarkers arrived in the tweening branch
		// let's go with the body from clearMarkers because it's shorter	    
	    public function removeAllMarkers():void
	    {
	    	while (markers.length > 0) {
	    		var marker:DisplayObject = markers.pop();
	    		removeMarkerObject(marker);
	    	}
	    }
	        
	    public function updateClips(event:Event=null):void
	    {
	    	if (!dirty) {
	    		return;
	    	}
	    	
// TODO_AHMED: Reimplement when map class is complete
	    	var center:Coordinate = map.grid.centerCoordinate;
	    	
	    	if (center.equalTo(drawCoord)) {
	    		dirty = false;
	    		return;
	    	}
	    	
	    	drawCoord = center.copy();
	    	
	    	this.x = map.getWidth() / 2;
	    	this.y = map.getHeight() / 2;    	
	    	
	        if (scaleZoom) {
	            scaleX = scaleY = 1.0;
	        }	    	
	    	
	        var doSort:Boolean = false;
	    	for each (var marker:DisplayObject in markers)
	    	{
	    	    doSort = updateClip(marker) || doSort; // wow! bad things did happen when this said doSort ||= updateClip(marker);
	    	}

            if (doSort) {
            	requestSort(true); 
            }
            
	    	dirty = false;
	    }
	    
	    /** call this if you've made a change to the underlying map geometry such that
	      * provider.locationCoordinate(location) will return a different coordinate */
	    public function resetCoordinates():void
	    {
// TODO_AHMED: Reimplement when map class is complete
	    	var provider:IMapProvider = map.getMapProvider();
	    	// I wish Array.map didn't require three parameters!
	    	for each (var marker:DisplayObject in markers) {
				coordinates[marker] = provider.locationCoordinate(locations[marker]);
	    	}
	    	dirty = true;
	    }
	    
	    protected var sortTimer:uint;	        
	    
	    protected function requestSort(updateOrder:Boolean=false):void
	    {
        	// use a timer so we don't do this every single frame, otherwise
        	// sorting markers and applying depths pretty much doubles the 
        	// time to run updateClips 
// TODO_AHMED: Do something about the missing clearTimeout and setTimeout classes
         	/*if (sortTimer) {
        		clearTimeout(sortTimer);
        	}
        	sortTimer = setTimeout(sortMarkers, 50, updateOrder);*/
     	}	    
	    
	    public function sortMarkers(updateOrder:Boolean=false):void
	    {
			// only sort if we have a function:	        
            if (updateOrder && markerSortFunction != null)
	        {
				// PORTNOTE: Using loomscript's built in array sorting instead
	            //markers = markers.sort(markerSortFunction, Array.NUMERIC);
// TODO_AHMED: Make sure the marker sorting works correctly
	            markers.sort(markerSortFunction);
	        }
	        // apply depths to maintain the order things were added in
	        var index:uint = 0;
	        for each (var marker:DisplayObject in markers)
	        {
	            if (contains(marker))
	            {
	                setChildIndex(marker, Math.min(index, numChildren - 1));
	                index++;
	            }
	        }
	    }

		/** returns true if the marker was added to the stage, so that updateClips or attachMarker can sort the markers */ 
	    public function updateClip(marker:DisplayObject):Boolean
	    {	    	
    	    if (marker.visible)
    	    {
		    	// this method previously used the location of the marker
		    	// but map.locationPoint hands off to grid to grid.coordinatePoint
		    	// in the end so we may as well cache the first step
// TODO_AHMED: Reimplement this when the map class is complete
		        var point:Point = map.grid.coordinatePoint(coordinates[marker], this);
	            marker.x = snapToPixels ? Math.round(point.x) : point.x;
	            marker.y = snapToPixels ? Math.round(point.y) : point.y;

		        var w:Number = map.getWidth() * 2;
		        var h:Number = map.getHeight() * 2;
	            
    	        if (markerInBounds(marker, w, h))
    	        {
    	            if (!contains(marker))
    	            {
    	                addChild(marker);
    	                // notify the caller that we've added something and need to sort markers
    	                return true;
    	            }
    	        }
    	        else if (contains(marker))
    	        {
    	            removeChild(marker);
    	            // only need to sort if we've added something
    	            return false;
    	        }
            }
            
            return false;            
	    }
	    
	    ///// Events....

	    protected function onMapExtentChanged(event:MapEvent):void
	    {
			dirty = true;	    	
	    }
	    
	    protected function onMapPanned(event:MapEvent):void
	    {
	    	if (drawCoord) {
// TODO_AHMED: Reimplement this when the map class is complete
		        var p:Point = map.grid.coordinatePoint(drawCoord);
		        this.x = p.x;
	    	    this.y = p.y;
	    	}
	    	else {
	    		dirty = true;
	    	}
	    }
	    
	    protected function onMapZoomedBy(event:MapEvent):void
	    {
			// PORTNOTE: cacheAsBitmap is a flash sprite function
// TODO_AHMED: Potential performance boost here
	    	//if (autoCache) cacheAsBitmap = false;
// TODO:AHMED: Reimplement when map class is complete
	        if (scaleZoom && drawCoord) {
	        	if (Math.abs(map.grid.zoomLevel - drawCoord.zoom) < zoomTolerance) {
    	        	scaleX = scaleY = Math.pow(2, map.grid.zoomLevel - drawCoord.zoom);
    	     	}
    	     	else {
    	     		dirty = true;	
    	     	}
	        }
	        else { 
		        dirty = true;
	        }
	    }

	    protected function onMapStartPanning(event:MapEvent):void
	    {
	    	// optimistically, we set this to true in case we're just moving
			// PORTNOTE: cacheAsBitmap is a flash sprite member variable
		    //if (autoCache) cacheAsBitmap = true;
	    }
	    
	    protected function onMapStartZooming(event:MapEvent):void
	    {
	    	// overrule onMapStartPanning if there's scaling involved
			// PORTNOTE: cacheAsBitmap is a flash sprite member variable
	        //if (autoCache) cacheAsBitmap = false;
	    }
	    
	    protected function onMapStopPanning(event:MapEvent):void
	    {
	    	// tidy up
			// PORTNOTE: cacheAsBitmap is a flash sprite member variable
	    	//if (autoCache) cacheAsBitmap = false;
		    dirty = true;
	    }
	    
	    protected function onMapStopZooming(event:MapEvent):void
	    {
	        dirty = true;
	    }
	    
	    protected function onMapResized(event:MapEvent):void
	    {
// TODO_AHMED: Reimplement when map class is complete
	        x = map.getWidth() / 2;
	        y = map.getHeight() / 2;
	        dirty = true;
	        updateClips(); // force redraw because flash seems stingy about it
	    }
	    
	    
	    protected function onMapProviderChanged(event:MapEvent):void
	    {
// TODO_AHMED: Reimplement when map class is comlete
	    	var mapProvider:IMapProvider = map.getMapProvider();	
	    	if (mapProvider.geometry() != previousGeometry)
			{
	        	resetCoordinates();
	        	previousGeometry = mapProvider.geometry();
	        }
	    }
	    
	    ///// Invalidations...
	    
		protected function set dirty(d:Boolean):void
		{
			// PORTNOTE: The stage class doesn't seem to have an invalidate function, seems to be very flash specific judging by the docs
			// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/Stage.html

			/*_dirty = d;
			if (d) {
				//if (stage) stage.invalidate();
			}*/
		}
		
		protected function get dirty():Boolean
		{
			return _dirty;
		}

		////// Marker Events...

		/**
	    * Dispatches MarkerEvent.CLICK when a marker is clicked.
	    * 
	    * The MarkerEvent includes a reference to the marker and its location.
	    *
	    * @see com.modestmaps.events.MarkerEvent.MARKER_CLICK
	    */
// TODO_AHMED: Do something about the missing mouse event
	    protected function onMarkerClick(event:TouchEvent):void
        {
        	var marker:DisplayObject = event.target as DisplayObject;
        	var location:Location = getMarkerLocation( marker );
        	dispatchEvent( new MarkerEvent( MarkerEvent.MARKER_CLICK, marker, location, true) );
        }
        
		/**
	    * Dispatches MarkerEvent.ROLL_OVER
	    * 
	    * The MarkerEvent includes a reference to the marker and its location.
	    *
	    * @see com.modestmaps.events.MarkerEvent.MARKER_ROLL_OVER
	    */
// TODO_AHMED: Do something about the missing mouse event
        protected function onMarkerRollOver(event:TouchEvent):void
        {
        	var marker:DisplayObject = event.target as DisplayObject;
        	var location:Location = getMarkerLocation( marker );
        	dispatchEvent( new MarkerEvent( MarkerEvent.MARKER_ROLL_OVER, marker, location, true) );
        }
        
        /**
	    * Dispatches MarkerEvent.ROLL_OUT
	    * 
	    * The MarkerEvent includes a reference to the marker and its location.
	    *
	    * @see com.modestmaps.events.MarkerEvent.MARKER_ROLL_OUT
	    */
// TODO_AHMED: Do something about the missing mouse event
        protected function onMarkerRollOut(event:TouchEvent):void
        {
            var marker:DisplayObject = event.target as DisplayObject;
            var location:Location = getMarkerLocation( marker );
        	dispatchEvent( new MarkerEvent( MarkerEvent.MARKER_ROLL_OUT, marker, location, true) );
        }		
	}
	
}