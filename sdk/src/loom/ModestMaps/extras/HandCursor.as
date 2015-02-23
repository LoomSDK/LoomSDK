package com.modestmaps.extras
{
	import com.modestmaps.Map;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.ui.Mouse;
	
	public class HandCursor extends Sprite
	{
		[Embed(source='hand.png')]
		private var HandUp:Class;

		[Embed(source='hand_down.png')]
		private var HandDown:Class;
		
		private var map:Map;
		private var enabled:Boolean = false;
		private var hand:Sprite;
		private var handup:Bitmap;
		private var handdown:Bitmap;

		private var callbacks:Array = [];
		
		public function HandCursor(map:Map)
		{
			this.map = map;
			
			mouseEnabled = false
			cacheAsBitmap = true;
			mouseChildren = false;

			hand = new Sprite();
			
			handup = new HandUp() as Bitmap;
			hand.addChild(handup);
			handdown = new HandDown() as Bitmap;

			hand.x -= hand.width/2;
			hand.y -= hand.height/2;
			hand.visible = false;	
			addChild(hand);
			
			filters = [ new DropShadowFilter(1,45,0,1,3,3,.7,2) ];
		
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);		
		}
		
		public function onAddedToStage(event:Event):void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.CLICK, onMouseClick);
			stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);

	        map.grid.addEventListener(MouseEvent.ROLL_OVER, enable);
	        map.grid.addEventListener(MouseEvent.ROLL_OUT, disable);			
		}
		public function onRemovedFromStage(event:Event):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.removeEventListener(MouseEvent.CLICK, onMouseClick);
			stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave);

	        map.grid.removeEventListener(MouseEvent.ROLL_OVER, enable);
	        map.grid.removeEventListener(MouseEvent.ROLL_OUT, disable);			
		}
		
		public function onMouseLeave(event:Event):void 
		{
			if (enabled) {
				hand.visible = false;
			}
		}
		
		public function onMouseMove(event:MouseEvent):void 
		{
			if (enabled && !hand.visible) {
				hand.visible = true;
			}
			x = event.localX;
			y = event.localY;
		}


		public function onMouseUp(event:MouseEvent):void
		{
			if (enabled) {
				Mouse.hide();
				callNextFrame(Mouse.hide);
			}
			hand.removeChild(handdown);
			hand.addChild(handup);
		}
		public function onMouseClick(event:MouseEvent):void
		{
			if (enabled) {
				Mouse.hide();
				callNextFrame(Mouse.hide);
			}
		}
		public function onMouseDown(event:MouseEvent):void
		{
			if (enabled) {
				Mouse.hide();
				callNextFrame(Mouse.hide);
			}
			if (hand.contains(handup)) {
				hand.removeChild(handup);
				hand.addChild(handdown);
			}
		}
		
		public function enable(event:Event=null):void
		{
			Mouse.hide();
			callNextFrame(Mouse.hide);			
			hand.visible = true;
			enabled = true;			
		}
		public function disable(event:Event=null):void
		{
			Mouse.show();			
			callNextFrame(Mouse.show);			
			hand.visible = false;
			enabled = false;			
		}

		private function callNextFrame(callback:Function):void
		{
			if (!hasEventListener(Event.ENTER_FRAME)) {
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			callbacks.push(callback);
		}
		
		private function onEnterFrame(event:Event):void
		{
			while (callbacks.length > 0) {
				var callback:Function = callbacks.shift() as Function;
				callback();
			}
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
	}
}