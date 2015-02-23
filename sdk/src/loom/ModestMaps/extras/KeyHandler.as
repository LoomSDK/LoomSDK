package com.modestmaps.extras
{
	import com.modestmaps.Map;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	public class KeyHandler
	{
		public var map:Map;
		
		public function KeyHandler(map:Map)
		{
			this.map = map;
			map.grid.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			map.grid.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
		}
		
		public function onKey(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.LEFT) {
				map.panLeft();
			}
			else if (event.keyCode == Keyboard.RIGHT) {
				map.panRight();
			}
			else if (event.keyCode == Keyboard.UP) {
				map.panUp();
			}
			else if (event.keyCode == Keyboard.DOWN) {
				map.panDown();
			}
			else {
				var char:String = String.fromCharCode(event.charCode);
				if (char == '+') {
					map.zoomIn();
				}
				else if (char == '-') {
					map.zoomOut();
				}
			}
		}
		
		public function onClick(event:Event):void
		{
			map.grid.focusRect = false;
			map.stage.focus = map.grid;
		}
	}
}