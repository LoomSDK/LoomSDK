package
{
	import loom2d.display.DisplayObjectContainer;
	import loom2d.display.Image;
	import loom2d.display.Sprite;
	import loom2d.events.Touch;
	import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	import loom2d.Loom2D;
	import loom2d.math.Color;
	import loom2d.math.Point;
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
	
	public delegate TileCleared(x:Number, y:Number, color:Color):Void;
	
	public class Board extends DisplayObjectContainer
	{
		private var DIM_ROWS = 0;
		private var DIM_COLS = 1;
		
		public var onTileClear:TileCleared;
		
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
		
		var selectedTile:Tile = null;
		
		public function Board()
		{
			
			addChild(tileDisplay);
			
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function init() {
			loadTypeTextures();
			generateTiles();
			reset();
		}
		
		public function resize(w:Number, h:Number) {
			tileDisplay.x = (w-tileRows*tileWidth)/2;
			tileDisplay.y = (h-tileCols*tileHeight)/2;
		}
		
		public function reset() {
			randomizeTiles();
			updateBoard();
		}
		
		private function loadTypeTextures() {
			typeTextures = new Vector.<Texture>(types);
			for (var i in typeTextures) {
				//var tex = Texture.fromAsset("assets/tiles/tile" + i + ".png");
				var tex = Texture.fromAsset("assets/tiles/tileGrayscale.png");
				//tex.smoothing = TextureSmoothing.NONE;
				typeTextures[i] = tex;
			}
		}
		
		private function generateTiles():void {
			tiles = new Vector.<Tile>(tileRows*tileCols);
			for (var iy = 0; iy < tileRows; iy++) {
				for (var ix = 0; ix < tileCols; ix++) {
					var tile = new Tile(tileDisplay, ix, iy, tileWidth, tileHeight);
					tile.onDrop += tileDropped;
					tiles[ix+iy*tileRows] = tile;
				}
			}
		}
		
		private function randomizeTiles() {
			rseed = 1;
			for each (var tile in tiles) {
				resetTile(tile, getRandomType());
				tile.resetPosition();
			}
		}
		
		private var rseed = 0;
		private function rand():int {
			return rseed = (rseed * 1103515245 + 12345) & 0xFFFFFFFF;
		}
		private function getRandomType():int {
			return Math.randomRangeInt(0, types-1);
			//return rand()%types;
		}
		
		private function resetTile(tile:Tile, type:int) {
			tile.reset(type, typeTextures[type]);
		}
		
		
		private function onTouch(e:TouchEvent):void {
			for each (var touch in e.touches) {
				processTouch(touch);
			}
		}
		
		private function processTouch(touch:Touch) {
			switch (touch.phase) {
				case TouchPhase.BEGAN:
					tileSelect(getTouchedTile(touch));
					//reset();
					break;
			}
		}
		
		private function getTouchedTile(touch:Touch):Tile {
			var p:Point = touch.getLocation(tileDisplay);
			p.x = Math.clamp(Math.floor(p.x/tileWidth), 0, tileCols-1);
			p.y = Math.clamp(Math.floor(p.y/tileHeight), 0, tileRows-1);
			return tiles[p.x+p.y*tileCols];
		}
		
		private function tileSelect(tile:Tile) {
			if (selectedTile) {
				selectedTile.deselect();
				swapTiles(tile, selectedTile);
				selectedTile = null;
			} else {
				selectedTile = tile;
				selectedTile.select();
			}
		}
		
		private function swapTiles(a:Tile, b:Tile) {
			var t = a.type;
			resetTile(a, b.type);
			resetTile(b, t);
			updateBoard();
		}
		
		private function updateBoard() {
			rowMatches.clear();
			findSequentialMatches(rowMatches, DIM_ROWS);
			colMatches.clear();
			findSequentialMatches(colMatches, DIM_COLS);
			if (rowMatches.length+colMatches.length > 0) {
				//trace(rowMatches.length+colMatches.length + " matches");
				//trace(rowMatches);
				//trace(colMatches);
				//debugMatches(rowMatches, DIM_ROWS);
				//debugMatches(colMatches, DIM_COLS);
				clearMatches(rowMatches, DIM_ROWS);
				clearMatches(colMatches, DIM_COLS);
				//Loom2D.juggler.delayCall(collapseColumns, 0.1);
			}
			Loom2D.juggler.delayCall(collapseColumns, 0.5);
			//collapseColumns();
		}
		
		private function tileDropped(tile:Tile) {
			//trace("tile dropped", tile.tx, tile.ty);
			updateBoard();
		}
		
		private function findSequentialMatches(matches:Vector.<Match>, dim:int) {
			var lo = dim == DIM_ROWS ? tileRows : tileCols;
			var li = dim == DIM_ROWS ? tileCols : tileRows;
			for (var io = 0; io < lo; io++) {
				var prevType = -1;
				var sum = -1;
				for (var ii = 0; ii < li+1; ii++) {
					var type:int;
					if (ii >= li) {
						type = -1;
					} else {
						var index = dim == DIM_ROWS ? ii+io*tileRows : io+ii*tileRows;
						var tile = tiles[index];
						switch (tile.state) {
							case Tile.IDLE:
								type = tile.type; break;
							default:
								type = -1;
						}
					}
					if (type == prevType) {
						sum++;
					} else {
						if (prevType != -1 && sum >= minSequence) {
							var m = new Match();
							m.index = io;
							m.type = prevType;
							m.begin = ii-sum;
							m.end = ii-1;
							matches.push(m);
						}
						sum = 1;
						prevType = type;
					}
				}
			}
		}
		
		private function debugMatches(matches:Vector.<Match>, dim:int) {
			for (var mi = 0; mi < matches.length; mi++) {
				var match = matches[mi];
				for (var i = match.begin; i <= match.end; i++) {
					var index = dim == DIM_ROWS ? i+match.index*tileRows : match.index+i*tileRows;
					var tile = tiles[index];
					tile.debugDisable();
				}
			}
		}
		
		private function clearMatches(matches:Vector.<Match>, dim:int) {
			for (var mi = 0; mi < matches.length; mi++) {
				var match = matches[mi];
				for (var i = match.begin; i <= match.end; i++) {
					var index = dim == DIM_ROWS ? i+match.index*tileRows : match.index+i*tileRows;
					var tile = tiles[index];
					Debug.assert(tile.state != Tile.DROPPING);
					clearTile(tile);
				}
			}
		}
		
		private function clearTile(tile:Tile) {
			if (tile.state == Tile.CLEARED) return;
			var color = tile.getColor();
			tile.clear();
			onTileClear((tile.tx+0.5)*tileWidth+tileDisplay.x, (tile.ty+0.5)*tileHeight+tileDisplay.y, color);
		}
		
		private function isColumnDropping(ix:int):Boolean {
			for (var iy = tileRows-1; iy >= 0; iy--) {
				if (tiles[ix+iy*tileRows].state == Tile.DROPPING) return true;
			}
			return false;
		}
		
		private function collapseColumns() {
			for (var ix = 0; ix < tileCols; ix++) {
				var iy:int;
				if (isColumnDropping(ix)) continue;
				var drop = 0;
				for (iy = tileRows-1; iy >= 0; iy--) {
					var tile = tiles[ix+iy*tileRows];
					if (tile.state != Tile.CLEARED) continue;
					
					var type:int = -1;
					var ay = iy;
					var dropY:Number = 0;
					while (ay >= 0) {
						var above = tiles[ix+ay*tileRows];
						if (above.state != Tile.CLEARED) {
							type = above.type;
							dropY = above.transitionalTileY();
							above.clear();
							break;
						}
						ay--;
					}
					if (type == -1) {
						type = getRandomType();
						drop++;
						dropY = -drop;
					}
					resetTile(tile, type);
					tile.dropFrom(dropY);
					//drop++;
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