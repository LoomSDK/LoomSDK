package  {
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.textures.Texture;
	
	public class Tile {
		
		private var display:Image;
		
		public var type:int;
		public var tx:int;
		public var ty:int;
		public var tw:int;
		public var th:int;
		
		public function Tile(container:DisplayObjectContainer, tx:int, ty:int, tw:int, th:int) {
			this.tx = tx;
			this.ty = ty;
			this.tw = tw;
			this.th = th;
			display = new Image();
			display.x = (tx+0.5)*tw;
			display.y = (ty+0.5)*th;
			container.addChild(display);
		}
		
		public function reset(type:int, texture:Texture = null) {
			this.type = type;
			
			if (type == -1) {
				display.visible = false;
				return;
			}
			
			display.visible = true;
			display.texture = texture;
			display.center();
			
			var typeColors:Vector.<Number> = new <Number>[
				0xBF0C43,
				0xF9BA15,
				0x8EAC00,
				0x127A97,
				0x452B72,
				0xE5DDCB,
				0x689B8D,
			];
			display.color = typeColors[type];
		}
		
		private function setColor(color:Number) {
			display.color = color;
		}
		
	}
	
}