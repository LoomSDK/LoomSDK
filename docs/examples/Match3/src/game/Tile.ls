package  {
	import game.Shaker;
	import loom.sound.Sound;
	import loom2d.animation.Juggler;
	import loom2d.animation.Transitions;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.Loom2D;
	import loom2d.math.Color;
	import loom2d.textures.Texture;
	
	public delegate Cleared(tile:Tile):Void;
	public delegate Drop(tile:Tile):Void;
	
	public class Tile {
		
		public static const SWAP_TIME = 0.3;
		
		private var juggler:Juggler;
		
		public static const IDLE     = 0;
		public static const SWAPPING = 1;
		public static const CLEARING = 2;
		public static const CLEARED  = 3;
		public static const DROPPING = 4;
		public var state = IDLE;
		
		public var onDrop:Drop;
		public var onClear:Cleared;
		
		public var type:int;
		public var tx:int;
		public var ty:int;
		public var tw:int;
		public var th:int;
		
		public var lastColor:Color;
		
		private var display:Image;
		private var shaker:Shaker;
		
		public function Tile(juggler:Juggler, container:DisplayObjectContainer, tx:int, ty:int, tw:int, th:int) {
			this.juggler = juggler;
			this.tx = tx;
			this.ty = ty;
			this.tw = tw;
			this.th = th;
			display = new Image();
			shaker = new Shaker(display, Sound.load("assets/shaking.ogg"));
			resetPosition();
			container.addChild(display);
		}
		
		public function resetPosition() {
			Loom2D.juggler.removeTweens(display);
			display.x = getDisplayX(tx);
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
		
		public function get transitionalTileX():Number {
			return display.x/tw-0.5;
		}
		
		public function get transitionalTileY():Number {
			return display.y/th-0.5;
		}
		
		private function getDisplayX(tx:Number):Number {
			return (tx+0.5)*tw;
		}
		private function getDisplayY(ty:Number):Number {
			return (ty+0.5)*th;
		}
		
		//public function getColor():Color {
			//// TODO fix instances
			//return Color.fromInt(getTypeColor(type));
		//}
		
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
			
			state = IDLE;
			
			display.rotation = 0;
			display.visible = true;
			if (texture) {
				display.texture = texture;
				display.center();
				display.color = getTypeColor(type);
				lastColor = Color.fromInt(display.color);
			}
		}
		
		public function clear(delayed:Boolean = false, index:int = 0) {
			if (state != IDLE) return;
			reset(-1);
			state = CLEARING;
			if (delayed) {
				//display.rotation = Math.PI/4;
				//var duration = Math.randomRange(0, 0.5);
				var duration = index*0.1;
				shaker.start(juggler);
				juggler.delayCall(cleared, duration);
			} else {
				cleared(false);
			}
			//display.visible = false;
			//display.rotation = Math.PI/4;
		}
		
		private function cleared(delayed:Boolean = true) {
			state = CLEARED;
			display.visible = false;
			if (delayed) {
				shaker.stop();
				onClear(this);
			}
		}
		
		public function swapFrom(x:Number, y:Number) {
			state = SWAPPING;
			display.x = getDisplayX(x);
			display.y = getDisplayY(y);
			juggler.tween(display, SWAP_TIME, {
				x: getDisplayX(tx),
				y: getDisplayY(ty),
				transition: Transitions.EASE_IN_OUT
			});
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
		
	}
	
}