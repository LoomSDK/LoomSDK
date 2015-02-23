package com.modestmaps.extras
{
	import com.modestmaps.Map;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.geo.Location;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;	
	
	public class MapScale extends Sprite
	{
		protected var map:Map;
		
		protected var leftField:TextField;
		protected var rightField:TextField;	
		
		protected var offsetX:Number;
		
		public function MapScale(map:Map, offsetX:Number=0):void
		{
			this.map = map;
			
			this.offsetX = offsetX;
	
			leftField = new TextField();
			leftField.defaultTextFormat = new TextFormat('Arial', 10, 0x000000, false, null, null, null, '_blank');
			leftField.mouseEnabled = leftField.selectable = false;
			addChild(leftField);
	
			rightField = new TextField();
			rightField.defaultTextFormat = new TextFormat('Arial', 10, 0x000000, false, null, null, null, '_blank');
			rightField.mouseEnabled = rightField.selectable = false;
			addChild(rightField);					
			
			map.addEventListener(MapEvent.EXTENT_CHANGED, redraw);
			map.addEventListener(MapEvent.STOP_ZOOMING, redraw);
			map.addEventListener(MapEvent.STOP_PANNING, redraw);
			map.addEventListener(MapEvent.RESIZED, onMapResized);
			
			redraw(null);
		}
		
		protected function redraw(event:MapEvent):void
		{
			var pixelWidth:Number = 100;
			
			// pick two points on the map, 150px apart
			var p1:Point = new Point(map.getWidth()/2 - pixelWidth/2, map.getHeight()/2);
			var p2:Point = new Point(map.getWidth()/2 + pixelWidth/2, map.getHeight()/2);
			
			var start:Location = map.pointLocation(p1);
			var end:Location = map.pointLocation(p2);
			
			var barParams:Array = [
				{ radius: Distance.R_MILES, unit: "mile", units: "miles", field: leftField },
				{ radius: Distance.R_KM, unit: "km", units: "km", field: rightField },
			];
			
			graphics.clear();
			for (var i:int = 0; i < barParams.length; i++) {
			
				var d:Number = Distance.approxDistance(start, end, barParams[i].radius);
				
				var metersPerPixel:Number = d / pixelWidth;
				
				// powers of ten, two?
				//var nearestPower:Number = Math.pow(2, Math.round(Math.log(d) / Math.LN2)); 
				var nearestPower:Number = parseFloat(d.toPrecision(1));
				
				var pixels:Number = nearestPower / metersPerPixel;
				
				graphics.lineStyle(0, 0x000000);
				graphics.beginFill(0xffffff);
				graphics.drawRect(0, i*12, pixels, 5);
				
				var decDigits:int = nearestPower < 1 ? 2 : 0;
				var unit:String = nearestPower.toFixed(decDigits) == '1' ? barParams[i].unit : barParams[i].units;
				
				var field:TextField = barParams[i].field;
				
				field.text = nearestPower.toFixed(decDigits) + " " + unit;
				field.width = field.textWidth + 4;
				field.height = field.textHeight + 4;
				
				field.x = pixels + 2;
				field.y = (i*12) + 2.5 - field.height/2;
			}
				
			onMapResized(null);
		}
		
		protected function onMapResized(event:MapEvent):void
		{
			this.x = 15 + offsetX;
			this.y = map.getHeight() - this.height - 6;
		}
	}
}