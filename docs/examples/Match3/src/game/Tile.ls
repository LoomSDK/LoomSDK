package  {
	import loom2d.animation.Juggler;
	import loom2d.animation.Transitions;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.Loom2D;
	import loom2d.math.Color;
	import loom2d.textures.Texture;
	
	public delegate Drop(tile:Tile):Void;
	
	public class Tile {
		
		private var juggler:Juggler;
		
		public static var IDLE = 0;
		public static var CLEARED = 1;
		public static var DROPPING = 2;
		public var state = IDLE;
		
		public var onDrop:Drop;
		
		public var type:int;
		public var tx:int;
		public var ty:int;
		public var tw:int;
		public var th:int;
		
		private var display:Image;
		
		public function Tile(juggler:Juggler, container:DisplayObjectContainer, tx:int, ty:int, tw:int, th:int) {
			this.juggler = juggler;
			this.tx = tx;
			this.ty = ty;
			this.tw = tw;
			this.th = th;
			display = new Image();
			resetPosition();
			container.addChild(display);
		}
		
		public function resetPosition() {
			Loom2D.juggler.removeTweens(display);
			display.x = (tx+0.5)*tw;
			display.y = getDisplayY(ty);
		}
		
		public function debugDisable() {
			display.rotation += 5;
		}
		
		public function select() {
			display.scale = 1.2;
		}
		
		public function deselect() {
			display.scale = 1;
		}
		
		public function transitionalTileY():Number {
			return display.y/tw-0.5;
		}
		
		private function getDisplayY(ty:Number):Number {
			return (ty+0.5)*th;
		}
		
		//public function dropFrom(y:int) {
		public function dropFrom(y:Number) {
			state = DROPPING;
			display.y = getDisplayY(y);
			//display.y = y;
			//display.rotation = Math.PI/4;
			//var delta = ty-y;
			var delta = ty-y;
			juggler.tween(display, delta*0.3, {
			//Loom2D.juggler.tween(display, delta, {
			//Loom2D.juggler.tween(display, delta*0.1, {
				y: getDisplayY(ty),
				//rotation: 0,
				transition: Transitions.EASE_OUT_BOUNCE,
				//transition: Transitions.EASE_IN_OUT,
				//transition: Transitions.EASE_IN,
				onComplete: dropComplete
			});
		}
		
		private function dropComplete() {
			state = IDLE;
			onDrop(this);
		}
		
		public function clear() {
			reset(-1);
		}
		
		public function getColor():Color {
			// TODO fix instances
			return Color.fromInt(getTypeColor(type));
		}
		
		private function getTypeColor(type:int):uint {
			var typeColors:Vector.<Number> = new <Number>[
				0xBF0C43,
				0xF9BA15,
				0x8EAC00,
				0x127A97,
				0x452B72,
				0xE5DDCB,
				0x689B8D,
			];
			return type == -1 ? 0x818181 : typeColors[type];
		}
		
		public function reset(type:int, texture:Texture = null) {
			this.type = type;
			
			if (type == -1) {
				display.visible = false;
				//display.rotation = Math.PI/4;
				state = CLEARED;
				return;
			}
			
			state = IDLE;
			
			display.rotation = 0;
			
			display.visible = true;
			display.texture = texture;
			display.center();
			
			display.color = getTypeColor(type);
		}
		
		private function setColor(color:Number) {
			display.color = color;
		}
		
	}
	
}