package com.modestmaps.overlays
{
	import com.modestmaps.Map;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.core.MapExtent;
	import com.modestmaps.core.TileGrid;
	import com.modestmaps.geo.Location;
	import com.modestmaps.mapproviders.IMapProvider;
	
	import flash.display.BitmapData;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;

	public class PolygonMarker extends Sprite implements Redrawable
	{
		protected var map:Map;
		protected var provider:IMapProvider;
		protected var drawZoom:Number;
		
		public var zoomTolerance:Number = 4;
		
		public var locations:Array;
		protected var coordinates:Array; // cached after converting locations with the map provider
		public var extent:MapExtent;
		public var location:Location;
		
		public var line:Boolean = true;
		public var lineThickness:Number = 0;
		public var lineColor:uint = 0xffffff;
		public var lineAlpha:Number = 1;
		public var linePixelHinting:Boolean = false;
		public var lineScaleMode:String = LineScaleMode.NONE;
		public var lineCaps:String = null;
		public var lineJoints:String = null; 
		public var lineMiterLimit:Number = 3; 		

		public var autoClose:Boolean = true;

		public var fill:Boolean = true;
		public var fillColor:uint = 0xff0000;
		public var fillAlpha:Number = 0.2;
		
		public var bitmapFill:Boolean = false;
		public var bitmapData:BitmapData = null;
		public var bitmapMatrix:Matrix = null;
		public var bitmapRepeat:Boolean = false;
		public var bitmapSmooth:Boolean = false;
				
		/** 
		 * Creates a polygon from the given array (or array of arrays) of Locations.
		 * 
		 * The polygon will use the given map to project the locations, and should be added to an
		 * instance of PolygonClip, which will add and remove it from the stage and position it
		 * as required.
		 * 
		 * If an array of arrays of Locations is given, the first array will be drawn as the outer
		 * ring of the polygon, and subsequent arrays will be treated as holes if they overlap it.
		 * 
		 */
		public function PolygonMarker(map:Map, locations:Array, autoClose:Boolean=true)
		{
			this.map = map;
			this.provider = map.getMapProvider();
			this.mouseEnabled = false;
			this.autoClose = autoClose;

			if (locations && locations.length > 0)
			{
				if (locations.length > 0 && locations[0] is Location)
				{
					locations = [ locations ];
				}
				if (locations[0].length > 0 && locations[0] is Array)
				{
					this.locations = [ locations[0] ];
					this.extent = MapExtent.fromLocations(locations[0]);
					this.location = locations[0][0] as Location;
					this.coordinates = [ locations[0].map(l2c) ];
					
					for each (var hole:Array in locations.slice(1))
					{
						addHole(hole);
					}
				}
			}
		}
		
		public function addHole(hole:Array):void
		{
			this.locations.push(hole);
			this.extent.encloseExtent(MapExtent.fromLocations(hole));
			this.coordinates.push(hole.map(l2c));	
			updateGraphics();
		}
		
		protected function l2c(l:Location, ...rest):Coordinate
		{
			return provider.locationCoordinate(l);
		}
	
		public function redraw(event:Event=null):void
		{	
			if (event && drawZoom && Math.abs(map.grid.zoomLevel-drawZoom) < zoomTolerance) {
				scaleX = scaleY = Math.pow(2, map.grid.zoomLevel-drawZoom);
			}
			else {
				updateGraphics();
			}
		}
		
		public function updateGraphics():void
		{	
			var grid:TileGrid = map.grid;
			
			drawZoom = grid.zoomLevel;
			scaleX = scaleY = 1;
			
			graphics.clear();
			if (line) {
				graphics.lineStyle(lineThickness, lineColor, lineAlpha, linePixelHinting, lineScaleMode, lineCaps, lineJoints, lineMiterLimit);
			}
			else {
				graphics.lineStyle();
			}
			if (fill) {
				if (bitmapFill && bitmapData) {
					graphics.beginBitmapFill(bitmapData, bitmapMatrix, bitmapRepeat, bitmapSmooth);
				} 
				else {
					graphics.beginFill(fillColor, fillAlpha);
				}
			}
			
			if (location) {
				var firstPoint:Point = grid.coordinatePoint(coordinates[0][0]);
				for each (var ring:Array in coordinates) {
					var ringPoint:Point = grid.coordinatePoint(ring[0]);
					graphics.moveTo(ringPoint.x-firstPoint.x, ringPoint.y-firstPoint.y);
					var p:Point;
					for each (var coord:Coordinate in ring.slice(1)) {
						p = grid.coordinatePoint(coord);
						graphics.lineTo(p.x-firstPoint.x, p.y-firstPoint.y);
					}
		 			if (autoClose && !ringPoint.equals(p)) {
						graphics.lineTo(ringPoint.x-firstPoint.x, ringPoint.y-firstPoint.y);
					}
				}
			}
			
			if (fill) {
				graphics.endFill();
			}
		}
				
	}
}