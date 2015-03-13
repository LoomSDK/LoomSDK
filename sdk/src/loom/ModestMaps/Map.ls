/**
 * vim:et sts=4 sw=4 cindent:
 * @ignore
 *
 * @author migurski
 * @author darren
 * @author tom
 *
 * com.modestmaps.Map is the base class and interface for Modest Maps.
 *
 * @description Map is the base class and interface for Modest Maps.
 * 				Correctly attaching an instance of this Sprite subclass 
 * 				should result in a pannable map. Controls and event 
 * 				handlers must be added separately.
 *
 * @usage <code>
 *          import com.modestmaps.Map;
 *          import com.modestmaps.geo.Location;
 *          import com.modestmaps.mapproviders.BlueMarbleMapProvider;
 *          ...
 *          var map:Map = new Map(640, 480, true, new BlueMarbleMapProvider());
 *          addChild(map);
 *        </code>
 *
 */
package com.modestmaps
{
	import com.modestmaps.core.*;
	import com.modestmaps.events.*;
	import com.modestmaps.geo.*;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.mapproviders.microsoft.MicrosoftProvider;
	import com.modestmaps.overlays.MarkerClip;
	import loom2d.display.Stage;
	
	import loom2d.display.DisplayObject;
	import loom2d.display.Sprite;
	import loom2d.events.Event;
	import loom2d.math.Matrix;
	import loom2d.math.Point;
	import loom2d.math.Rectangle;
	import loom.gameframework.TimeManager;
	
    [Event(name="startZooming",      type="com.modestmaps.events.MapEvent")]
    [Event(name="stopZooming",       type="com.modestmaps.events.MapEvent")]
    [Event(name="zoomedBy",          type="com.modestmaps.events.MapEvent")]
    [Event(name="startPanning",      type="com.modestmaps.events.MapEvent")]
    [Event(name="stopPanning",       type="com.modestmaps.events.MapEvent")]
    [Event(name="panned",            type="com.modestmaps.events.MapEvent")]
    [Event(name="resized",           type="com.modestmaps.events.MapEvent")]
    [Event(name="mapProviderChanged",type="com.modestmaps.events.MapEvent")]
    [Event(name="beginExtentChange", type="com.modestmaps.events.MapEvent")]
    [Event(name="extentChanged",     type="com.modestmaps.events.MapEvent")]
    [Event(name="beginTileLoading",  type="com.modestmaps.events.MapEvent")]
    [Event(name="allTilesLoaded",    type="com.modestmaps.events.MapEvent")]
    [Event(name="rendered",          type="com.modestmaps.events.MapEvent")]
    [Event(name="markerRollOver",    type="com.modestmaps.events.MarkerEvent")]
    [Event(name="markerRollOut",     type="com.modestmaps.events.MarkerEvent")]
    [Event(name="markerClick",       type="com.modestmaps.events.MarkerEvent")]
    public class Map extends Sprite
	{
	    protected var mapWidth:Number;
	    protected var mapHeight:Number;
	    protected var __draggable:Boolean = true;
	
	    /** das grid */
	    public var grid:TileGrid;
	
		/** markers are attached here */
		public var markerClip:MarkerClip;
		
	    /** Who do we get our Map urls from? How far can we pan? */
	    protected var mapProvider:IMapProvider;
	
		/** fraction of width/height to pan panLeft, panRight, panUp, panDown
		 * @default 0.333333333  
		 */
		public var panFraction:Number = 0.333333333;

        //NOTE_24: Added a static Stage because Actionscript Sprites all have their parent stage, whereas Loom does not
		public static var MapStage:Stage;
		
        /**
	    * Initialize the map: set properties, add a tile grid, draw it.
	    * Default extent covers the entire globe, (+/-85, +/-180).
	    *
	    * @param    Width of map, in pixels.
	    * @param    Height of map, in pixels.
	    * @param    Whether the map can be dragged or not.
	    * @param    Desired map provider, e.g. Blue Marble.
	    * @param    Either a MapExtent or a Location and zoom (comma separated)
	    *
	    * @see com.modestmaps.core.TileGrid
	    */
	    public function Map(width:Number, height:Number, draggable:Boolean, mapProvider:IMapProvider, mapStage:Stage, ... rest)
	    {
			if (!mapProvider) 
			{
				trace("No map provider specified for the map. Defaulting to Microsoft");
				mapProvider = new MicrosoftProvider(MicrosoftProvider.ROAD, true, MicrosoftProvider.MIN_ZOOM, MicrosoftProvider.MAX_ZOOM);
			}
			
            //save that static Stage
			MapStage = mapStage;
			
			// TODO getter/setter for this that disables interaction in TileGrid
			__draggable = draggable;

			// don't call setMapProvider here
			// the extent calculations are all squirrely
	        this.mapProvider = mapProvider;
			
			// initialize the grid (so point/location/coordinate functions should be valid after this)
			grid = new TileGrid(width, height, draggable, mapProvider);
			grid.addEventListener(Event.CHANGE, onExtentChanged);
	        addChild(grid);

	        setSize(width, height);

//TODO_24: not adding the MarkerClip just yet until other things start working...            
			//markerClip = new MarkerClip(this);
			//addChild(markerClip);

			// if rest was passed in from super constructor in a subclass,
			// it will be an array...
			if (rest && rest.length > 0 && rest[0] is Vector.<Object>) {
				rest = rest[0] as Vector.<Object>;
			}
			// (doing that is OK because none of the arguments we're expecting are Arrays)
			
			// look at ... rest arguments for MapExtent or Location/zoom	        
        	if (rest && rest.length > 0 && rest[0] is MapExtent) {
        		setExtent(rest[0] as MapExtent);
        	}
        	else if (rest && rest.length > 1 && rest[0] is Location && rest[1] is Number) {
        		setCenterZoom(rest[0] as Location, rest[1] as Number);
        	}
        	else {
        		// use the whole world as a default
        		var extent:MapExtent = new MapExtent(85, -85, 180, -180);
        		
        		// but adjust to fit the mapprovider's outer limits if there are any: 
         		var l1:Location = mapProvider.coordinateLocation(mapProvider.outerLimits()[0]);
        		var l2:Location = mapProvider.coordinateLocation(mapProvider.outerLimits()[1]);

				if (!isNaN(l1.lat) && Math.abs(l1.lat) != Number.POSITIVE_INFINITY) {
					extent.north = l1.lat;
				}        		
				if (!isNaN(l2.lat) && Math.abs(l2.lat) != Number.POSITIVE_INFINITY) {
					extent.south = l2.lat;
				}        		
				if (!isNaN(l1.lon) && Math.abs(l1.lon) != Number.POSITIVE_INFINITY) {
					extent.west = l1.lon;
				}        		
				if (!isNaN(l2.lon) && Math.abs(l2.lon) != Number.POSITIVE_INFINITY) {
					extent.east = l2.lon;
				}
				
        		setExtent(extent);
        	}
        	
            //NOTE: not porting DebugField for now at least...
        	//addChild(grid.debugField);
        }

        /**
	    * Based on an array of locations, determine appropriate map
	    * bounds using calculateMapExtent(), and inform the grid of
	    * tile coordinate and point by calling grid.resetTiles().
	    * Resulting map extent will ensure that all passed locations
	    * are visible.
	    *
	    * @param extent the minimum area to fit inside the map view
	    *
	    * @see com.modestmaps.Map#calculateMapExtent
	    * @see com.modestmaps.core.TileGrid#resetTiles
	    */
	    public function setExtent(extent:MapExtent):void
	    {
	    	//trace('applying extent', extent);
	        onExtentChanging();
	        // tell grid what the rock is cooking
	        grid.resetTiles(locationsCoordinate( [ extent.northWest, extent.southEast ] ));
	        onExtentChanged();
	    }
	    
	   /**
	    * Based on a location and zoom level, determine appropriate initial
	    * tile coordinate and point using calculateMapCenter(), and inform
	    * the grid of tile coordinate and point by calling grid.resetTiles().
	    *
	    * @param    Location of center.
	    * @param    Desired zoom level.
	    *
	    * @see com.modestmaps.Map#calculateMapExtent
	    * @see com.modestmaps.core.TileGrid#resetTiles
	    */
	    public function setCenterZoom(location:Location, zoom:Number):void
	    {
	        if (zoom == grid.zoomLevel) {
	            setCenter(location);
	        }
	        else {
	        	onExtentChanging();
	        	zoom = Math.min(Math.max(zoom, grid.minZoom), grid.maxZoom);
    	        // tell grid what the rock is cooking
    	        grid.resetTiles(mapProvider.locationCoordinate(location).zoomTo(zoom));
    	        onExtentChanged();
    	    }
	    }
	   
        /**
         * Based on a zoom level, determine appropriate initial
         * tile coordinate and point using calculateMapCenter(), and inform
         * the grid of tile coordinate and point by calling grid.resetTiles().
         *
         * @param    Desired zoom level.
         *
         * @see com.modestmaps.Map#calculateMapExtent
         * @see com.modestmaps.core.TileGrid#resetTiles
         */
        public function setZoom(zoom:Number):void
        {
			if (zoom != grid.zoomLevel) {
				// TODO: if grid enforces this in enforceBounds, do we need to do it here too?
				grid.zoomLevel = Math.min(Math.max(zoom, grid.minZoom), grid.maxZoom);
			}
        }

		public function extentCoordinate(extent:MapExtent):Coordinate
		{
			return locationsCoordinate([ extent.northWest, extent.southEast ]);
		}
                
		public function locationsCoordinate(locations:Vector.<Location>, fitWidth:Number=0, fitHeight:Number=0):Coordinate
		{
			if (!fitWidth) fitWidth = mapWidth;
			if (!fitHeight) fitHeight = mapHeight;
			
	        var TL:Coordinate = mapProvider.locationCoordinate(locations[0].normalize());
	        var BR:Coordinate = TL.copy();
	        
	        // get outermost top left and bottom right coordinates to cover all locations
	        for (var i:int = 1; i < locations.length; i++)
			{
				var coordinate:Coordinate = mapProvider.locationCoordinate(locations[i].normalize());
	            TL.row = Math.min(TL.row, coordinate.row);
				TL.column = Math.min(TL.column, coordinate.column);
				TL.zoom = Math.min(TL.zoom, coordinate.zoom);
	            BR.row = Math.max(BR.row, coordinate.row);
				BR.column = Math.max(BR.column, coordinate.column);
				BR.zoom = Math.max(BR.zoom, coordinate.zoom);
	        }
	        
	        // multiplication factor between horizontal span and map width
	        var hFactor:Number = (BR.column - TL.column) / (fitWidth / mapProvider.tileWidth);
	        
	        // multiplication factor expressed as base-2 logarithm, for zoom difference
	        var hZoomDiff:Number = Math.log(hFactor) / Math.LN2;
	        
	        // possible horizontal zoom to fit geographical extent in map width
	        var hPossibleZoom:Number = TL.zoom - Math.ceil(hZoomDiff);
	        
	        // multiplication factor between vertical span and map height
	        var vFactor:Number = (BR.row - TL.row) / (fitHeight / mapProvider.tileHeight);
	        
	        // multiplication factor expressed as base-2 logarithm, for zoom difference
	        var vZoomDiff:Number = Math.log(vFactor) / Math.LN2;
	        
	        // possible vertical zoom to fit geographical extent in map height
	        var vPossibleZoom:Number = TL.zoom - Math.ceil(vZoomDiff);
	        
	        // initial zoom to fit extent vertically and horizontally
	        // additionally, make sure it's not outside the boundaries set by provider limits
	        var initZoom:Number = Math.min(hPossibleZoom, vPossibleZoom);
	        initZoom = Math.min(initZoom, mapProvider.outerLimits()[1].zoom);
	        initZoom = Math.max(initZoom, mapProvider.outerLimits()[0].zoom);
	
	        // coordinate of extent center
	        var centerRow:Number = (TL.row + BR.row) / 2;
	        var centerColumn:Number = (TL.column + BR.column) / 2;
	        var centerZoom:Number = (TL.zoom + BR.zoom) / 2;
	        var centerCoord:Coordinate = (new Coordinate(centerRow, centerColumn, centerZoom)).zoomTo(initZoom);
	        
	        return centerCoord;
		}

	   /*
	    * Return a MapExtent for the current map view.
	    * TODO: MapExtent needs adapting to deal with non-rectangular map projections
	    *
	    * @return   MapExtent object
	    */
	    public function getExtent():MapExtent
	    {
	        var extent:MapExtent = new MapExtent(0, 0, 0, 0);
	        
	        if(!mapProvider) {
	        	throw new Error("WHOAH, no mapProvider in getExtent!");
	        }
	
	        extent.northWest = mapProvider.coordinateLocation(grid.topLeftCoordinate);
	        extent.southEast = mapProvider.coordinateLocation(grid.bottomRightCoordinate);
	        return extent;
	    }
	
	   /*
	    * Return the current center location and zoom of the map.
	    *
	    * @return   Array of center and zoom: [center location, zoom number].
	    */
	    public function getCenterZoom():Vector.<Object>
	    {
	        return [ mapProvider.coordinateLocation(grid.centerCoordinate), grid.zoomLevel ];
	    }

	   /*
	    * Return the current center location of the map.
	    *
	    * @return center Location
	    */
	    public function getCenter():Location
	    {
	        return mapProvider.coordinateLocation(grid.centerCoordinate);
	    }

	   /*
	    * Return the current zoom level of the map.
	    *
	    * @return   zoom number
	    */
	    public function getZoom():int
	    {
	        return Math.floor(grid.zoomLevel);
	    }

	
	   /**
	    * Set new map size, dispatch MapEvent.RESIZED. 
	    * The MapEvent includes the newSize.
	    *
	    * @param w New map width.
	    * @param h New map height.
	    *
	    * @see com.modestmaps.events.MapEvent.RESIZED
	    */
	    public function setSize(w:Number, h:Number):void
	    {
	        if (w != mapWidth || h != mapHeight)
	        {
    	        mapWidth = w;
    	        mapHeight = h;
    
    	        // mask out out of bounds marker remnants
    	        clipRect = new Rectangle(0,0,mapWidth,mapHeight);
				
            	grid.resizeTo(new Point(mapWidth, mapHeight));
            	
    	        dispatchEvent(new MapEvent(MapEvent.RESIZED, this.getSize()));
    	    }	        
	    }
	
	   /**
	    * Get map size.
	    *
	    * @return   Array of [width, height].
	    */
	    public function getSize():Vector.<Number> /*Number*/
	    {
	        var size:/*Number*/Vector.<Number> = [mapWidth, mapHeight];
	        return size;
	    }
	    
	    public function get size():Point
	    {
	        return new Point(mapWidth, mapHeight);
	    }
	    
	    public function set size(value:Point):void
	    {
	        setSize(value.x, value.y);
	    }

	   /** Get map width. */
	    public function getWidth():Number
	    {
	        return mapWidth;
	    }

	   /** Get map height. */
	    public function getHeight():Number
	    {
	        return mapHeight;
	    }
	
	   /**
	    * Get a reference to the current map provider.
	    *
	    * @return   Map provider.
	    *
	    * @see com.modestmaps.mapproviders.IMapProvider
	    */
	    public function getMapProvider():IMapProvider
	    {
	        return mapProvider;
	    }
	
	   /**
	    * Set a new map provider, repainting tiles and changing bounding box if necessary.
	    *
	    * @param   Map provider.
	    *
	    * @see com.modestmaps.mapproviders.IMapProvider
	    */
//TODO_24: Test that we can swap poviders on the fly OK        
	    public function setMapProvider(newProvider:IMapProvider):void
	    {
	        var previousGeometry:String;
	        if (mapProvider)
	        {
	        	previousGeometry = mapProvider.geometry();
	        }
	    	var extent:MapExtent = getExtent();

	        mapProvider = newProvider;
	        if (grid)
	        {
	        	grid.setMapProvider(mapProvider);
	        }
	        
	        if (mapProvider.geometry() != previousGeometry)
			{
	        	setExtent(extent);
	        }
	        
        	// among other things this will notify the marker clip that its cached coordinates are invalid
	        dispatchEvent(new MapEvent(MapEvent.MAP_PROVIDER_CHANGED, [newProvider]));
	    }
	    
	   /**
	    * Get a point (x, y) for a location (lat, lon) in the context of a given clip.
	    *
	    * @param    Location to match.
	    * @param    Movie clip context in which returned point should make sense.
	    *
	    * @return   Matching point.
	    */
	    public function locationPoint(location:Location, context:DisplayObject=null):Point
	    {
	        var coord:Coordinate = mapProvider.locationCoordinate(location);
	        return grid.coordinatePoint(coord, context);
	    }
	    
	   /**
	    * Get a location (lat, lon) for a point (x, y) in the context of a given clip.
	    *
	    * @param    Point to match.
	    * @param    Movie clip context in which passed point should make sense.
	    *
	    * @return   Matching location.
	    */
	    public function pointLocation(point:Point, context:DisplayObject=null):Location
	    {
	        var coord:Coordinate = grid.pointCoordinate(point, context);
	        return mapProvider.coordinateLocation(coord);
	    }


	   /** Pan up by 1/3 (or panFraction) of the map height. */
	    public function panUp(event:Event=null):void
	    {
	    	panBy(0, mapHeight*panFraction);
	    }      
	
	   /** Pan down by 1/3 (or panFraction) of the map height. */
	    public function panDown(event:Event=null):void
	    {
	    	panBy(0, -mapHeight*panFraction);
	    }

	   	/** Pan left by 1/3 (or panFraction) of the map width. */	    
	    public function panLeft(event:Event=null):void
	    {
	    	panBy((mapWidth*panFraction), 0);
	    }      
	
	   	/** Pan left by 1/3 (or panFraction) of the map width. */	    
	    public function panRight(event:Event=null):void
	    {
	    	panBy(-(mapWidth*panFraction), 0);
	    }
	    
	    public function panBy(px:Number, py:Number):void
	    {
	    	if (!grid.panning && !grid.zooming) {
		    	grid.prepareForPanning();
		    	grid.tx += px;
		    	grid.ty += py;
	    	    grid.donePanning();
	    	}
	    }

		/** zoom in, keeping the requested point in the same place */
        public function zoomInAbout(targetPoint:Point, duration:Number=-1):void
        {
            zoomByAbout(1, targetPoint, duration);
        }

		/** zoom out, keeping the requested point in the same place */
        public function zoomOutAbout(targetPoint:Point, duration:Number=-1):void
        {
            zoomByAbout(-1, targetPoint, duration);
        }
        
		/** zoom in or out by zoomDelta, keeping the requested point in the same place */
        public function zoomByAbout(zoomDelta:Number, targetPoint:Point, duration:Number=-1):void
        {
         	grid.zoomByAbout(zoomDelta, targetPoint, duration);
        }
        
        public function getRotation():Number
        {
        	var m:Matrix = grid.getMatrix();
    		var px:Point = m.deltaTransformCoord(0, 1);
			return Math.atan2(px.y, px.x);
        }
        
		/** rotate to angle (radians), keeping the requested point in the same place */
        public function setRotation(angle:Number, targetPoint:Point):void
        {
        	var rotation:Number = getRotation();
			rotateByAbout(angle - rotation, targetPoint);        	
        }
        
        public function rotateByAbout(angle:Number, targetPoint:Point):void
        {
			grid.rotateByAbout(angle, targetPoint);
        }        
	    
		/** zoom in and put the given location in the center of the screen, or optionally at the given targetPoint */
		public function panAndZoomIn(location:Location, targetPoint:Point):void
		{
			panAndZoomBy(2, location, targetPoint);
		}

		/** zoom out and put the given location in the center of the screen, or optionally at the given targetPoint */		
        public function panAndZoomOut(location:Location, targetPoint:Point):void
        {
			panAndZoomBy(0.5, location, targetPoint);
        }

		/** zoom in or out by sc, moving the given location to the requested target */ 
        public function panAndZoomBy(sc:Number, location:Location, targetPoint:Point, duration:Number=-1):void
        {
			var p:Point = locationPoint(location);
			
			grid.prepareForZooming();
			grid.prepareForPanning();
			
			var m:Matrix = grid.getMatrix();
			
			m.translate(-p.x, -p.y);
			m.scale(sc, sc);
			m.translate(targetPoint.x, targetPoint.y);
			
			grid.setMatrix(m);
			
			grid.donePanning();
			grid.doneZooming();
        }
				
	    /** put the given location in the middle of the map */
		public function setCenter(location:Location):void
		{
			onExtentChanging();
			// tell grid what the rock is cooking
			grid.resetTiles(mapProvider.locationCoordinate(location).zoomTo(grid.zoomLevel));
			onExtentChanged();
		}

	   /**
	    * Zoom in by one zoom level (to 200%) immediately,
	    * rounding up to the nearest zoom level if we're currently between zooms.
	    *  
	    * <p>Triggers MapEvent.START_ZOOMING and MapEvent.STOP_ZOOMING events.</p>
	    * 
	    * @param event an optional event so that zoomIn can directly function as an event listener.
	    */
	    public function zoomIn(event:Event=null):void
	    {
	    	zoomBy(1);
	    }

	   /**
	    * Zoom out by one zoom level (to 50%) immediately, 
	    * rounding down to the nearest zoom level if we're currently between zooms.
	    *  
	    * <p>Triggers MapEvent.START_ZOOMING and MapEvent.STOP_ZOOMING events.</p>
	    * 
	    * @param event an optional event so that zoomOut can directly function as an event listener.
	    */
	    public function zoomOut(event:Event=null):void
	    {
	    	zoomBy(-1);
	    }

		/**
		 * Adds dir to grid.zoomLevel, and rounds up or down to the nearest whole number.
		 * Used internally by zoomIn and zoomOut (keeping it DRY, as they say)
		 * and overridden by TweenMap for animation.
		 * 
		 * <p>grid.zoomLevel calls the grid.scale setter for us 
    	 * which will call grid.prepareForZooming if we didn't already 
    	 * and grid.doneZooming after modifying the zoom level.</p>
    	 * 
    	 * <p>Animating/tweening grid.scale fires START_ZOOMING, and STOP_ZOOMING 
    	 * MapEvents unless you call grid.prepareForZooming first. Be sure
    	 * to also call grid.stopZooming at the end of your animation.
    	 *
    	 * @param dir the direction of zoom, generally 1 for zooming in, or -1 for zooming out
    	 * 
    	 */ 
	    protected function zoomBy(dir:int):void
	    {
	    	if (!grid.panning) {
		    	var target:Number = dir < 0 ? Math.floor(grid.zoomLevel+dir) : Math.ceil(grid.zoomLevel+dir);
		    	grid.zoomLevel = Math.min(Math.max(grid.minZoom, target), grid.maxZoom);
		    }
	    } 
	    
	   /**
	    * Add a marker at the given location (lat, lon)
	    *
	    * @param    Location of marker.
	    * @param	optionally, a sprite (where sprite.name=id) that will always be in the right place
	    */
	    public function putMarker(location:Location, marker:DisplayObject=null):void
	    {
	        markerClip.attachMarker(marker, location);
	    }

		/**
		 * Get a marker with the given id if one was created.
		 *
		 * @param    ID of marker, opaque string.
		 */
		public function getMarker(id:String):DisplayObject
		{
			return markerClip.getMarker(id);
		}

	   /**
	    * Remove a marker with the given id.
	    *
	    * @param    ID of marker, opaque string.
	    */
	    public function removeMarker(id:String):void
	    {
	        markerClip.removeMarker(id); // also calls grid.removeMarker
	    }
	    
		public function removeAllMarkers():void {
			markerClip.removeAllMarkers();
		}
		
	   /**
	    * Dispatches MapEvent.EXTENT_CHANGED when the map is recentered.
	    * The MapEvent includes the new extent.
	    * 
	    * TODO: dispatch this on resize?
	    * TODO: should we move Map to com.modestmaps.core so that this could be made internal instead of public?
	    *
	    * @see com.modestmaps.events.MapEvent.EXTENT_CHANGED
	    */
	    protected function onExtentChanged(event:Event=null):void
	    {
	    	if (hasEventListener(MapEvent.EXTENT_CHANGED)) {
		        dispatchEvent(new MapEvent(MapEvent.EXTENT_CHANGED, [getExtent()]));
		    }
	    }

	   /**
	    * Dispatches MapEvent.BEGIN_EXTENT_CHANGE when the map is about to be resized.
	    * The MapEvent includes the current.
	    *
	    * @see com.modestmaps.events.MapEvent.BEGIN_EXTENT_CHANGE
	    */
	    protected function onExtentChanging():void
	    {
	    	if (hasEventListener(MapEvent.BEGIN_EXTENT_CHANGE)) {
	        	dispatchEvent(new MapEvent(MapEvent.BEGIN_EXTENT_CHANGE, [getExtent()]));
	     	}
	    }



        //NOTE_TEC: Loom doesn't support MouseWheel input at this time
		// private var previousWheelEvent:Number = 0;
		// private var minMouseWheelInterval:Number = 100;
		
		// public function onMouseWheel(event:MouseEvent):void
		// {
		// 	if (getTimer() - previousWheelEvent > minMouseWheelInterval) {
		// 		if (event.delta > 0) {
		// 			zoomInAbout(new Point(mouseX, mouseY), 0);
		// 		}
		// 		else if (event.delta < 0) {
		// 			zoomOutAbout(new Point(mouseX, mouseY), 0);
		// 		}
		// 		previousWheelEvent = getTimer(); 
		// 	}
		// }
	}
}

