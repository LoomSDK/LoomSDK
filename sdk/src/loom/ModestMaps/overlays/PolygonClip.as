package com.modestmaps.overlays
{
	import com.modestmaps.Map;
	
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;

	/** 
	 *  PolygonClip extends MarkerClip to take the bounds of the marker into account when showing/hiding,
	 *  and to trigger a redraw of content that needs scaling.
	 *  
	 *  To trigger the redraw, markers must implement the Redrawable interface provided in this package.
	 *  
	 *  See PolygonMarker for an example, but if you need multi-geometries, complex styling, holes etc., 
	 *  you'll need to write your own for the moment.
	 *  
	 */
	public class PolygonClip extends MarkerClip
	{
		public function PolygonClip(map:Map)
		{
			super(map);
			this.scaleZoom = true;
			this.markerSortFunction = null
		}

		override protected function markerInBounds(marker:DisplayObject, w:Number, h:Number):Boolean
		{
   			var rect:Rectangle = new Rectangle(-w, -h, w*3, h*3);
			return rect.intersects(marker.getBounds(map));
		}
		
		override public function updateClip(marker:DisplayObject):Boolean
		{
			// we need to redraw this marker before MarkerClip.updateClip so that markerInBounds will be correct
			if (marker is Redrawable) {
				Redrawable(marker).redraw();
			}
			return super.updateClip(marker);
		}
		
	}
}