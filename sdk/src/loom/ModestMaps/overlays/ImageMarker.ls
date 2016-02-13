package loom.modestmaps.overlays
{
	import loom.modestmaps.Map;
	import loom2d.display.Image;
	import loom2d.events.TouchEvent;
	import loom2d.textures.Texture;
	

    /** Simple Marker type that just display an image at a location and can be removed
     *  via a double-tap
     */
	public class ImageMarker extends Image
	{
		private var map:Map;
		
		public function ImageMarker(_map:Map, _name:String, _texture:Texture):void
		{
			super(_texture);
			this.name = _name;
			pivotX += width/2;
			pivotY += height;
			addEventListener(TouchEvent.TOUCH, markerTapped);
			map = _map;
		}
		
		private function markerTapped(event:TouchEvent):void
		{
			var touches = event.getTouches(this);
			if (touches.length > 0 && touches[0].tapCount == 2)
			{
				map.removeMarker(this.name);
			}
		}
	}
}
