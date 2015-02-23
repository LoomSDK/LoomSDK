package com.modestmaps.overlays
{
	/**
	 * Polyline class that takes polyline data and draws it in the given style.
	 * 
	 * Polylines can be added using:
	 * 
	 * <pre>
	 *  var polylineClip:PolylineClip = new PolylineClip(map);
	 *  map.addChild(polylineClip);
	 *  
	 *  var polyline:Polyline = new Polyline('poly-id-1', [ new Location(10,10), new Location (20,20) ]);
	 *  polylineClip.addPolyline(polyline);
	 * </pre>
	 * 
	 * @see PolylineClip
	 * 
	 * Originally contributed by simonoliver.
	 * 
	 */
	public class Polyline
	{
		public var id:String;
		public var locationsArray:Array;
		public var lineThickness:Number;
		public var lineColor:Number;
		public var lineAlpha:Number;
		public var pixelHinting:Boolean;
		public var scaleMode:String;
		public var caps:String;
		public var joints:String;
		public var miterLimit:Number;
			
		public function Polyline(id:String, 
								 locationsArray:Array,
								 lineThickness:Number=3, 
								 lineColor:Number=0xFF0000, 
								 lineAlpha:Number=1, 
								 pixelHinting:Boolean=false, 
								 scaleMode:String="normal", 
								 caps:String=null, 
								 joints:String=null, 
								 miterLimit:Number=3)
		{
			this.id = id;
			this.locationsArray = locationsArray;
			this.lineThickness = lineThickness;
			this.lineColor = lineColor;
			this.lineAlpha = lineAlpha;
			this.pixelHinting = pixelHinting;
			this.scaleMode = scaleMode;
			this.caps = caps;
			this.joints = joints;
			this.miterLimit = miterLimit;
		}
	}
}