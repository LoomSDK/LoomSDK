package com.modestmaps.extras {
	
    import com.modestmaps.Map;    import com.modestmaps.events.MapEvent;        import flash.display.Sprite;    import flash.events.Event;    import flash.events.MouseEvent;    import flash.filters.BevelFilter;    import flash.filters.BitmapFilterType;    import flash.filters.DropShadowFilter;    import flash.geom.Point;    import flash.geom.Rectangle;        import gs.TweenLite;    

	/** This is an example of a slider that modifies the zoom level of the given map.
	 * 
	 *  It is provided mainly for ModestMapsSample.as and to test the arbitrary 
	 *  zoom level functionality, but feel free to use it if you like yellow bevels. */ 
    public class ZoomSlider extends Sprite
    {
    	private var map:Map;
    	
    	private var track:Sprite;
    	private var thumb:Sprite;

		private var dragging:Boolean = false;
		private var trackHeight:Number;

		private static const DEFAULT_HEIGHT:Number = 100;
	    	
        public function ZoomSlider(map:Map, trackHeight:Number=DEFAULT_HEIGHT)
        {
            this.map = map;
            this.trackHeight = trackHeight;
            
            map.addEventListener(MapEvent.EXTENT_CHANGED, update);
            map.addEventListener(MapEvent.ZOOMED_BY, update);
            map.addEventListener(MapEvent.STOP_ZOOMING, update);
            map.addEventListener(MapEvent.START_ZOOMING, update);
            
			this.x = 15;
			this.y = 15;

			track = new Sprite();
			track.filters = [ new BevelFilter(4, 45, 0xffffff, 0.2, 0x000000, 0.2, 4, 4, 1, 1, BitmapFilterType.INNER, false) ];
			track.addEventListener(MouseEvent.CLICK, onTrackClick);
			track.buttonMode = track.useHandCursor = true;
			track.graphics.lineStyle(5, 0xd9c588);
			track.graphics.moveTo(0, 0);
			track.graphics.lineTo(0, trackHeight);
			track.graphics.lineStyle(0, 0x000000, 0.2);
/* 			for (var i:int = map.grid.minZoom; i <= map.grid.maxZoom; i++) {
				var tick:Number = trackHeight * (i - map.grid.minZoom) / (map.grid.maxZoom - map.grid.minZoom);
				track.graphics.moveTo(-2, tick);
				track.graphics.lineTo(2, tick);
			} */
			track.x = 5;
			addChild(track);
			
			thumb = new Sprite();
			thumb.filters = [ new BevelFilter(4, 45, 0xffffff, 0.2, 0x000000, 0.2, 0, 0, 1, 1, BitmapFilterType.INNER, false) ];
			thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouse);
			thumb.buttonMode = thumb.useHandCursor = true;
			thumb.graphics.beginFill(0xff8080);
			thumb.graphics.drawCircle(0,0,5);
			thumb.x = 5;
			addChild(thumb);

			filters = [ new DropShadowFilter(1,45,0,1,3,3,.7,2) ];
			
			update();
        }

		private function onTrackClick(event:MouseEvent):void
		{
			var p:Point = globalToLocal(new Point(event.stageX, event.stageY));
			thumb.y = p.y;
			TweenLite.to(map.grid, 0.25, { zoomLevel: Math.round(map.grid.minZoom + (map.grid.maxZoom - map.grid.minZoom) * (1 - proportion)) }); 
		}
        
		private function onThumbMouse(event:Event):void
		{
			if (event.type == MouseEvent.MOUSE_MOVE) {
				proportion = thumb.y / trackHeight;
			}
			else if (event.type == MouseEvent.MOUSE_DOWN) {
				thumb.startDrag(false, new Rectangle(thumb.x, 0, 0, trackHeight));
				dragging = true;
				stage.addEventListener(MouseEvent.MOUSE_UP, onThumbMouse);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onThumbMouse);
				stage.addEventListener(Event.MOUSE_LEAVE, onThumbMouse);
			}
			else if (event.type == MouseEvent.MOUSE_UP || event.type == Event.MOUSE_LEAVE) {
				thumb.stopDrag();
				dragging = false;
				TweenLite.to(map.grid, 0.1, { zoomLevel: Math.round(map.grid.zoomLevel) });
				stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbMouse);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbMouse);
				stage.removeEventListener(Event.MOUSE_LEAVE, onThumbMouse);
			}
			if (event is MouseEvent) {
				MouseEvent(event).updateAfterEvent();
			}
		}

		public function update(event:MapEvent=null):void
		{
			//if (event) trace(event.type, "in ZoomSlider.update");
			if (!dragging) {
				proportion = 1.0 - (map.grid.zoomLevel - map.grid.minZoom) / (map.grid.maxZoom - map.grid.minZoom);
			}
		}
	
		public function get proportion():Number
		{
			return thumb.y / trackHeight;
		}
	
		public function set proportion(prop:Number):void
		{
			if (!dragging) {
				thumb.y = prop * trackHeight;
			}
			else {
				map.grid.zoomLevel = map.grid.minZoom + (map.grid.maxZoom - map.grid.minZoom) * (1.0 - prop);
			}
		}
		
    }
}
