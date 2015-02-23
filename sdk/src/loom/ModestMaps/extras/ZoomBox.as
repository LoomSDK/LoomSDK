package com.modestmaps.extras
{
	import com.modestmaps.Map;
	import com.modestmaps.core.MapExtent;
	import com.modestmaps.geo.Location;
	
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class ZoomBox extends Sprite
	{
		protected var map:Map;
		protected var box:Shape;
		
		protected var p:Point;
		
		public function ZoomBox( map:Map,
								 boxLineThickness:Number=0,
								 boxLineColor:Number=0xff0000,
								 boxFillColor:Number=0xffffff,
								 boxFillAlpha:Number=0.2 )
		{
			this.map = map;
			
			box = new Shape();
			box.graphics.lineStyle(boxLineThickness, boxLineColor, 1, false, LineScaleMode.NONE);
			box.graphics.beginFill(boxFillColor, boxFillAlpha);
			box.graphics.drawRect(0,0,100,100);
			box.graphics.endFill();
			box.visible = false;			
			addChild(box);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		protected function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true, -100);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
	
		protected function onRemovedFromStage(event:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		protected function onMouseDown(event:MouseEvent):void
		{
			if (event.shiftKey) {
				map.grid.mouseEnabled = false;
				p = new Point(stage.mouseX, stage.mouseY);
				p = map.globalToLocal(p);				
				box.x = p.x;
				box.y = p.y;
				box.scaleX = box.scaleY = 0;
				stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				event.stopImmediatePropagation();
			}
		}
		
		protected function onMouseUp(event:Event):void
		{
			box.visible = false;
			
			if (Math.abs(box.scaleX) > 0 && Math.abs(box.scaleY) > 0) {
				var rect:Rectangle = box.getBounds(map);
				
				var nw:Location = map.pointLocation(rect.topLeft);
				var se:Location = map.pointLocation(rect.bottomRight);
				
				// TODO: what happens at the international date line?
				var extent:MapExtent = new MapExtent(nw.lat, se.lat, se.lon, nw.lon);
				map.setExtent(extent);
			}
			
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(Event.MOUSE_LEAVE, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			event.stopImmediatePropagation();
			
			map.grid.mouseEnabled = true;
		}
		
		protected function onMouseMove(event:MouseEvent):void
		{
			var mouseP:Point = map.globalToLocal(new Point(stage.mouseX, stage.mouseY));
			var movement:Point = p.subtract(mouseP);
			box.visible = true;
			box.scaleX = -movement.x / 100;
			box.scaleY = -movement.y / 100;
		} 
	
	}

}