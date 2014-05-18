package
{
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.textures.Texture;
	import loom2d.textures.TextureSmoothing;
	
	struct Match {
		public var index:int;
		public var type:int;
		public var begin:int;
		public var end:int;
		public static operator function =(a:Match, b:Match):Match
        {
            a.index = b.index;
            a.type = b.type;
            a.begin = b.begin;
            a.end = b.end;
            return a;
        }
		public function toString():String {
			return index + ":[" + begin + ", " + end + "]";
		}
	}
	
	public class Board extends DisplayObjectContainer
	{
		
		var types = 5;
		var typeTextures:Vector.<Texture>;
		
		var tileCols = 8;
		var tileRows = 8;
		var tileWidth = 12;
		var tileHeight = 12;
		var tiles:Vector.<Tile>;
		var tileDisplay = new Sprite();
		
		var rowMatches = new Vector.<Match>();
		var colMatches = new Vector.<Match>();
		
		var minSequence:int = 3;
		
		public function Board()
		{
			loadTypeTextures();
			generateTiles();
			randomizeTiles();
			findMatches();
			
			addChild(tileDisplay);
		}
		
		public function resize(w:Number, h:Number) {
			tileDisplay.x = (w-tileRows*tileWidth)/2;
			tileDisplay.y = (h-tileCols*tileHeight)/2;
		}
		
		private function loadTypeTextures() {
			typeTextures = new Vector.<Texture>(types);
			for (var i in typeTextures) {
				//var tex = Texture.fromAsset("assets/tiles/tile" + i + ".png");
				var tex = Texture.fromAsset("assets/tiles/tileGrayscale.png");
				tex.smoothing = TextureSmoothing.NONE;
				typeTextures[i] = tex;
			}
		}
		
		private function generateTiles():void {
			tiles = new Vector.<Tile>(tileRows*tileCols);
			for (var iy = 0; iy < tileRows; iy++) {
				for (var ix = 0; ix < tileCols; ix++) {
					var tile = new Tile(tileDisplay, ix, iy, tileWidth, tileHeight);
					tiles[ix+iy*tileRows] = tile;
				}
			}
		}
		
		private function randomizeTiles() {
			for each (var tile in tiles) {
				resetTile(tile, Math.randomRangeInt(0, types-1));
			}
		}
		
		private function resetTile(tile:Tile, type:int) {
			tile.reset(type, typeTextures[type]);
		}
		
		private function findMatches() {
			rowMatches.clear();
			findSequentialMatches(rowMatches, 0);
			colMatches.clear();
			findSequentialMatches(colMatches, 1);
			trace("row " + rowMatches);
			trace("col " + colMatches);
		}
		
		private function findSequentialMatches(matches:Vector.<Match>, dim:int) {
			var lo = dim == 0 ? tileRows : tileCols;
			var li = dim == 0 ? tileCols : tileRows;
			for (var io = 0; io < lo; io++) {
				var prevType = -1;
				var sum = -1;
				for (var ii = 0; ii < li+1; ii++) {
					var type:int;
					if (ii >= li) {
						type = -1;
					} else {
						var index = dim == 0 ? ii+io*tileRows : io+ii*tileRows;
						var tile = tiles[index];
						type = tile.type;
					}
					if (type == prevType) {
						sum++;
					} else {
						if (sum >= minSequence) {
							var m = new Match();
							m.index = io;
							m.type = prevType;
							m.begin = ii-sum;
							m.end = ii-1;
							matches.push(m);
						}
						sum = 1;
						prevType = tile.type;
					}
				}
			}
		}
		
		private function resetVector(vec:Vector.<int>, begin:int = 0, end:int = -1) {
			var l = vec.length;
			if (end == -1) end = l;
			for (var i = begin; i < end; i++) vec[i] = 0;
		}
		
		public function tick() {
			
		}
		
		public function render() {
			
		}
		
	}
}