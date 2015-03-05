package com.modestmaps.overlays
{
	import loom2d.events.Event;
	
	/** used by PolygonClip to trigger a redraw when zoom levels have changed substantially */
	public interface Redrawable
	{
		function redraw(event:Event=null):void;
	}
}