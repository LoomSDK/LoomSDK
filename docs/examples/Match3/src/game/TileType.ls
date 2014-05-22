package game {
	import loom2d.textures.Texture;
	
	public class TileType {
		public var index:int;
		public var color:uint;
		public var character:String;
		public var texture:Texture;
		public function TileType(color:uint, character:String, texture:Texture) {
			this.color = color;
			this.character = character;
			this.texture = texture;
		}
		
	}
	
}