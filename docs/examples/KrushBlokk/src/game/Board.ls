package game
{
    import game.TileType;
    import loom.sound.Sound;
    import loom2d.animation.Juggler;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
    import loom2d.math.Color;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;
    
    /**
     * Value object for storing found possible swaps
     */
    struct Swap
    {
        public var a:Tile;
        public var b:Tile;
        public function Swap(a:Tile = null, b:Tile = null)
        {
            this.a = a;
            this.b = b;
        }
        public static operator function =(a:Swap, b:Swap):Swap
        {
            a.a = b.a;
            a.b = b.b;
            return a;
        }
    }
    
    /**
     * Value object for storing found matches with the specified type
     */
    public struct Match
    {
        /** Index of the row/column in which the match was found */
        public var index:int;
        public var type:TileType;
        /** Inclusive begin index of the column/row match sequence */
        public var begin:int;
        /** Inclusive end index of the column/row match sequence */
        public var end:int;
        public static operator function =(a:Match, b:Match):Match
        {
            a.index = b.index;
            a.type = b.type;
            a.begin = b.begin;
            a.end = b.end;
            return a;
        }
        public function toString():String
        {
            return index + ":[" + begin + ", " + end + "]";
        }
    }
    
    public delegate TileCleared(x:Number, y:Number, color:Color):Void;
    public delegate TilesMatched(m:Match):Void;
    public delegate GameEnded():Void;
    
    /**
     * Match 3 board logic handling all the tiles and the interaction between them,
     * contains the algorithms responsible for checking possible swaps, matching tiles and
     * collapsing columns.
     */
    public class Board extends DisplayObjectContainer
    {
        /** Dimension of rows */
        static const DIM_ROW = 0;
        /** Dimension of columns */
        static const DIM_COL = 1;
        
        public var onTileCleared:TileCleared;
        public var onTilesMatched:TilesMatched;
        public var onEnded:GameEnded;
        
        public var freeformMode:Boolean = false;
        
        /** True while in ending animation */
        private var ending:Boolean = false;
        private var endedTiles:int;
        
        private var juggler:Juggler;
        
        /** Number of tile types used */
        private var types:int = 6;
        private var tileTypes:Vector.<TileType>;
        
        private var tileCols = 8;
        private var tileRows = 8;
        private var tileWidth = 12;
        private var tileHeight = 12;
        private var tiles:Vector.<Tile>;
        private var tileDisplay = new Sprite();
        
        private var rowMatches = new Vector.<Match>();
        private var colMatches = new Vector.<Match>();
        private var matchIndex:int;
        
        private var rowSwaps = new Vector.<Swap>();
        private var colSwaps = new Vector.<Swap>();
        private var typeSums:Vector.<int>;
        
        private /** The minimum amount of same-type tiles needed to get a match */
        private var minSequence:int = 3;
        
        private var selectedTile:Tile = null;
        
        private var tileMove:Sound;
        
        // Super special matching sequence
        private var matchSequence:String = "LOOMSDK";
        
        public function Board(juggler:Juggler)
        {
            this.juggler = juggler;
            
            // Crop tile display to the desired viewport, so that tiles dropping from above get cut off.
            tileDisplay.clipRect = new Rectangle(0, 0, tileCols*tileWidth, tileRows*tileHeight);
            addChild(tileDisplay);
            
            tileMove = Sound.load("assets/sounds/tileMove.ogg");
            
            addEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        public function init()
        {
            typeSums = new Vector.<int>(types);
            initTypes();
            generateTiles();
        }
        
        public function get contentWidth():Number { return tileRows*tileWidth; }
        public function get contentHeight():Number { return tileCols*tileHeight; }
        
        public function reset()
        {
            ending = false;
            randomizeTiles();
            neutralizeTiles();
            updateBoard();
        }
        
        /**
         * Show ending animation of exploding tiles
         */
        public function end()
        {
            ending = true;
            endedTiles = 0;
            for (var i = 0; i < tiles.length; i++) {
                var tile:Tile = tiles[i];
                var row = Math.floor(i/tileCols);
                var col = i%tileCols;
                var oddRow = row&1;
                tile.clear(true, (i*(1-oddRow)+(tileCols-col+row*tileCols)*oddRow)*0.04, true);
            }
        }
        
        /** Define tile types */
        private function initTypes()
        {
            tileTypes = new <TileType>[
                new TileType(0xBF0C43, "L", Texture.fromAsset("assets/tiles/tileL.png")),
                new TileType(0xF9BA15, "O", Texture.fromAsset("assets/tiles/tileO.png")),
                new TileType(0x8EAC00, "M", Texture.fromAsset("assets/tiles/tileM.png")),
                new TileType(0x127A97, "S", Texture.fromAsset("assets/tiles/tileS.png")),
                new TileType(0x452B72, "D", Texture.fromAsset("assets/tiles/tileD.png")),
                new TileType(0xE5DDCB, "K", Texture.fromAsset("assets/tiles/tileK.png")),
            ];
            for (var i:int = 0; i < tileTypes.length; i++) {
                tileTypes[i].index = i;
            }
        }
        
        /** Construct tiles in a grid */
        private function generateTiles()
        {
            tiles = new Vector.<Tile>(tileRows*tileCols);
            for (var iy = 0; iy < tileRows; iy++) {
                for (var ix = 0; ix < tileCols; ix++) {
                    var tile = new Tile(juggler, tileDisplay, ix, iy, tileWidth, tileHeight);
                    tile.onDrop += tileDropped;
                    tile.onClear += tileCleared;
                    tiles[ix+iy*tileCols] = tile;
                }
            }
        }
        
        private function randomizeTiles()
        {
            rseed = 1;
            for each (var tile in tiles) {
                tile.reset(getRandomType());
                tile.resetPosition();
            }
        }
        
        // Seeded random function useful for consistent debugging
        private var rseed = -1;
        private function rand():int
        {
            return rseed = (rseed * 1103515245 + 12345) & 0xFFFFFFFF;
        }
        private function getRandomType():TileType
        {
            // Switching between these two lines allows for switching between randomized seed random
            // and constant-seed random. The former better for replayability, the latter better for
            // consistently random boards while debugging.
            return tileTypes[Math.randomRangeInt(0, types-1)];
            //return tileTypes[rand()%types];
        }
        
        /**
         * Randomize matching tiles until none match anymore.
         */
        private function neutralizeTiles()
        {
            updateMatches();
            while (rowMatches.length+colMatches.length > 0) {
                neutralizeMatches(rowMatches, DIM_ROW);
                neutralizeMatches(colMatches, DIM_COL);
                updateMatches();
            }
        }
        
        private function neutralizeMatches(matches:Vector.<Match>, dim:int)
        {
            for (var mi = 0; mi < matches.length; mi++) {
                var match = matches[mi];
                for (var i = match.begin; i <= match.end; i++) {
                    var index = dim == DIM_ROW ? i+match.index*tileCols : match.index+i*tileCols;
                    var tile:Tile = tiles[index];
                    tile.reset(getRandomType());
                }
                onTilesMatched(match);
            }
        }
        
        // Tile picking and swapping logic
        
        private function onTouch(e:TouchEvent)
        {
            for each (var touch in e.touches) {
                processTouch(touch);
            }
        }
        private function processTouch(touch:Touch)
        {
            switch (touch.phase) {
                case TouchPhase.BEGAN:
                    tileSelect(getTouchedTile(touch));
                    break;
                case TouchPhase.MOVED:
                    tileSelect(getTouchedTile(touch), true);
                    break;
            }
        }
        private function getTouchedTile(touch:Touch):Tile
        {
            var p:Point = touch.getLocation(tileDisplay);
            p.x = Math.clamp(Math.floor(p.x/tileWidth), 0, tileCols-1);
            p.y = Math.clamp(Math.floor(p.y/tileHeight), 0, tileRows-1);
            return tiles[p.x+p.y*tileCols];
        }
        
        private function tileSelect(tile:Tile, sticky:Boolean = false)
        {
            if (selectedTile == tile) return;
            if (tile.state == Tile.SWAPPING) return;
            if (selectedTile) {
                if (tile.state == Tile.IDLE && selectedTile.state == Tile.IDLE && neighborTiles(selectedTile, tile)) {
                    swapTiles(tile, selectedTile);
                    sticky = false;
                    tile = null;
                }
            }
            if (sticky) return;
            if (selectedTile) selectedTile.deselect();
            selectedTile = tile;
            if (selectedTile) selectedTile.select();
        }
        
        private function neighborTiles(a:Tile, b:Tile):Boolean
        {
            return Math.abs(a.tx-b.tx)+Math.abs(a.ty-b.ty) == 1;
        }
        
        private function containedInCurrentMatches(tile:Tile):Boolean
        {
            return containedInMatches(tile, rowMatches, DIM_ROW) || containedInMatches(tile, colMatches, DIM_COL);
        }
        
        /**
         * Swap two tiles (and swap back if they don't make a match in non-freeform mode)
         * @param   returning   true if it's a returning non-matching swap
         */
        private function swapTiles(a:Tile, b:Tile, returning:Boolean = false)
        {
            // Change tile types
            var t = a.type;
            a.reset(b.type);
            b.reset(t);
            // Swapping animations
            var tx = a.transitionalTileX;
            var ty = a.transitionalTileY;
            a.swapFrom(b.transitionalTileX, b.transitionalTileY);
            b.swapFrom(tx, ty);
            // Wait for swap 
            juggler.delayCall(tilesSwapped, Tile.swapTime, a, b, returning);
            // Sound effect
            tileMove.setPitch(1+Math.randomRange(-0.1, 0.1));
            tileMove.play();
        }
        
        /**
         * After swap animation concludes.
         * @param   returning   true if it's after a returning non-matching swap
         */
        private function tilesSwapped(a:Tile, b:Tile, returning:Boolean)
        {
            a.state = Tile.IDLE;
            b.state = Tile.IDLE;
            // Ensure that the tiles are in their proper positions
            a.resetPosition();
            b.resetPosition();
            if (returning) {
                updateBoard();
                return;
            }
            updateMatches();
            if (freeformMode || containedInCurrentMatches(a) || containedInCurrentMatches(b)) {
                updateBoard();
            } else {
                swapTiles(b, a, true);
            }
        }
        
        /**
         * Check for matches and possible swaps in the current board configuration
         */
        private function updateBoard()
        {
            updateMatches();
            if (rowMatches.length+colMatches.length > 0) {
                clearMatches(rowMatches, DIM_ROW);
                clearMatches(colMatches, DIM_COL);
            }
            
            rowSwaps.clear();
            findPossibleSwaps(rowSwaps, typeSums, DIM_ROW);
            colSwaps.clear();
            findPossibleSwaps(colSwaps, typeSums, DIM_COL);
            
            if (rowSwaps.length+colSwaps.length > 0) {
                // Uncommenting the following lines allows for automatic swapping of matching tiles - good for debugging.
                //var index = Math.randomRangeInt(0, rowSwaps.length+colSwaps.length-1);
                //var swap = index < rowSwaps.length ? rowSwaps[index] : colSwaps[index-rowSwaps.length];
                //if (columnReady(swap.a.tx) && columnReady(swap.b.tx)) swapTiles(swap.a, swap.b);
            } else {
                var i:int;
                for (i = 0; i < tiles.length; i++) {
                    if (tiles[i].state != Tile.IDLE) break;
                }
                // No more moves left
                if (i >= tiles.length) {
                    reset();
                    return;
                }
            }
            
            Loom2D.juggler.delayCall(collapseColumns, 0.3);
        }
        
        /**
         * Randomly pick a possible swap and swap the tiles
         * @return Swap containing the tiles swapped or null if no swaps were able to be made
         */
        public function randomSwap():Swap
        {
            rowSwaps.clear();
            findPossibleSwaps(rowSwaps, typeSums, DIM_ROW);
            colSwaps.clear();
            findPossibleSwaps(colSwaps, typeSums, DIM_COL);
            
            var len = rowSwaps.length + colSwaps.length;
            shuffleSwaps(rowSwaps);
            shuffleSwaps(colSwaps);
            var rowIndex = 0;
            var colIndex = 0;
            for (var i = 0; i < len; i++) {
                var index = i;
                var swap:Swap;
                // Pick randomly from the row or column array
                if (colIndex >= colSwaps.length || (Math.random() < 0.5 && rowIndex < rowSwaps.length)) {
                    swap = rowSwaps[rowIndex++];
                } else {
                    swap = colSwaps[colIndex++];
                }
                if (columnReady(swap.a.tx) && columnReady(swap.b.tx)) {
                    swapTiles(swap.a, swap.b);
                    return swap;
                }
            }
            // Exhausted all the possible swaps due to changed state, return with null swap
            return new Swap(null, null);
        }
        
        /**
         * Shuffle the Swap Vector in-place using the Fisher–Yates algorithm
         */
        private function shuffleSwaps(v:Vector.<Swap>) {
            var current = v.length;
            var random:int;
            var temp:Swap;
            while (current != 0) {
                random = Math.floor(Math.random()*current);
                current -= 1;
                temp = v[current];
                v[current] = v[random];
                v[random] = temp;
            }
        }
        
        /**
         * Update the match Vectors according to the current state
         */
        private function updateMatches()
        {
            rowMatches.clear();
            findSequentialMatches(rowMatches, DIM_ROW);
            colMatches.clear();
            findSequentialMatches(colMatches, DIM_COL);
            matchIndex = 0;
        }
        
        private function containedInMatches(tile:Tile, matches:Vector.<Match>, dim:int):Boolean
        {
            for (var mi = 0; mi < matches.length; mi++) {
                var match = matches[mi];
                if (containedInMatch(tile, match, dim)) return true;
            }
            return false;
        }
        
        /**
         * @return  true if `tile` is contained within the match
         */
        private function containedInMatch(tile:Tile, match:Match, dim:int):Boolean
        {
            var tileOuter:int;
            var tileInner:int;
            if (dim == DIM_ROW) {
                tileOuter = tile.ty;
                tileInner = tile.tx;
            } else {
                tileOuter = tile.tx;
                tileInner = tile.ty;
            }
            return match.index == tileOuter && match.begin <= tileInner && match.end >= tileInner;
        }
        
        /**
         * Called when the drop animation of `tile` concludes
         */
        private function tileDropped(tile:Tile)
        {
            updateBoard();
        }
        
        /**
         * Called when `tile` clearing animation concludes
         */
        private function tileCleared(tile:Tile)
        {
            var color = tile.lastColor;
            onTileCleared((tile.tx+0.5)*tileWidth+tileDisplay.x, (tile.ty+0.5)*tileHeight+tileDisplay.y, color);
            if (ending) {
                endedTiles++;
                if (endedTiles >= tiles.length) {
                    onEnded();
                }
            } else {
                collapseColumns();
            }
        }
        
        /**
         * Find matches of the same type and a special sequence match
         */
        private function findSequentialMatches(matches:Vector.<Match>, dim:int)
        {
            var lo = dim == DIM_ROW ? tileRows : tileCols;
            var li = dim == DIM_ROW ? tileCols : tileRows;
            for (var io = 0; io < lo; io++) {
                // Don't find matches in non-ready columns
                if (dim == DIM_COL && !columnReady(io)) continue;
                var prevType:TileType = null;
                var sum = 0;
                var seqIndex = 0;
                // Iterate over the entire row/column plus one to avoid duplicated logic
                // for matches ending at the end of the board
                for (var ii = 0; ii < li+1; ii++) {
                    var type:TileType = null;
                    if (ii < li) {
                        var index = dim == DIM_ROW ? ii+io*tileCols : io+ii*tileCols;
                        var tile = tiles[index];
                        switch (tile.state) {
                            case Tile.IDLE:
                                type = tile.type; break;
                            default:
                                type = null;
                        }
                    }
                    
                    // Special sequence matching
                    var sequenceMatched = false;
                    if (type && type.character == matchSequence.charAt(seqIndex)) {
                        seqIndex++;
                        if (seqIndex >= matchSequence.length) {
                            sum = seqIndex;
                            prevType = null;
                            sequenceMatched = true;
                            seqIndex = 0;
                        }
                    } else {
                        if (seqIndex > 0) {
                            seqIndex = 0;
                            ii--;
                            continue;
                        }
                    }
                    
                    if (type == prevType) {
                        sum++;
                    } else {
                        // Sequence type combo breaker!
                        // Entered at the beginning, end and when the tile type changes
                        var m:Match;
                        if ((prevType != null && sum >= minSequence) || sequenceMatched) {
                            m = new Match();
                            m.index = io;
                            m.type = prevType;
                            if (sequenceMatched) {
                                m.begin = ii-sum+1;
                                m.end = ii;
                            } else {
                                m.begin = ii-sum;
                                m.end = ii-1;
                            }
                            matches.push(m);
                        }
                        prevType = type;
                        sum = 1;
                    }
                    
                }
            }
        }
        
        /** 
         * Find all the possible swaps that would result in a match
         */
        private function findPossibleSwaps(swaps:Vector.<Swap>, typeSums:Vector.<int>, dim:int)
        {
            var lo = dim == DIM_ROW ? tileRows : tileCols;
            var li = dim == DIM_ROW ? tileCols : tileRows;
            for (var io:int = 0; io < lo; io++) {
                resetVector(typeSums);
                for (var ii:int = 0; ii < li; ii++) {
                    var index = dim == DIM_ROW ? ii+io*tileCols : io+ii*tileCols;
                    var stride = dim == DIM_ROW ? 1 : tileCols;
                    var tile:Tile = tiles[index];
                    var type:TileType = tile.type;
                    if (type) typeSums[type.index]++;
                    if (ii >= minSequence) {
                        type = tiles[index-minSequence*stride].type;
                        if (type) typeSums[type.index]--;
                    }
                    var i:int;
                    if (ii >= minSequence-1) {
                        var oneShort = -1;
                        var justOne = -1;
                        for (i = 0; i < typeSums.length; i++) {
                            if (typeSums[i] == 1) justOne = i;
                            if (typeSums[i] == minSequence-1) oneShort = i;
                        }
                        if (oneShort != -1 && justOne != -1) {
                            var justOneIndex:int = -1;
                            for (i = 0; i < minSequence; i++) {
                                justOneIndex = index+(-(minSequence-1)+i)*stride;
                                if (tiles[justOneIndex].type.index == justOne) break;
                            }
                            Debug.assert(justOneIndex != -1);
                            var standout = tiles[justOneIndex];
                            if (standout.state != Tile.IDLE) continue;
                            
                            var jx = justOneIndex%tileCols;
                            var jy = Math.floor(justOneIndex/tileCols);
                            var swapLeft  = jx > 0;
                            var swapRight = jx < tileCols-1;
                            var swapUp    = jy > 0;
                            var swapDown  = jy < tileRows-1;
                            if (dim == DIM_ROW) {
                                swapLeft  = swapLeft  && i == 0;
                                swapRight = swapRight && i == minSequence-1;
                            } else {
                                swapUp    = swapUp    && i == 0;
                                swapDown  = swapDown  && i == minSequence-1;
                            }
                            
                            var swapIndex:int;
                            var swapee:Tile;
                            
                            if (swapLeft) {
                                swapee = tiles[justOneIndex-1];
                                if (swapee.type && swapee.type.index == oneShort && swapee.state == Tile.IDLE) swaps.push(new Swap(standout, swapee));
                            }
                            if (swapRight) {
                                swapee = tiles[justOneIndex+1];
                                if (swapee.type && swapee.type.index == oneShort && swapee.state == Tile.IDLE) swaps.push(new Swap(standout, swapee));
                            }
                            if (swapUp) {
                                swapee = tiles[justOneIndex-tileCols];
                                if (swapee.type && swapee.type.index == oneShort && swapee.state == Tile.IDLE) swaps.push(new Swap(standout, swapee));
                            }
                            if (swapDown) {
                                swapee = tiles[justOneIndex+tileCols];
                                if (swapee.type && swapee.type.index == oneShort && swapee.state == Tile.IDLE) swaps.push(new Swap(standout, swapee));
                            }
                        }
                    }
                }
            }
        }
        
        /**
         * Clear all the tiles that are a part of the provided matches
         */
        private function clearMatches(matches:Vector.<Match>, dim:int)
        {
            for (var mi = 0; mi < matches.length; mi++) {
                var match = matches[mi];
                for (var i = match.begin; i <= match.end; i++) {
                    var index = dim == DIM_ROW ? i+match.index*tileCols : match.index+i*tileCols;
                    var tile = tiles[index];
                    Debug.assert(tile.state != Tile.DROPPING);
                    if (tile.state != Tile.IDLE) continue;
                    tile.clear(true, (matchIndex++)*0.1);
                }
                onTilesMatched(match);
            }
        }
        
        /**
         * @return  true if the column is ready for more matches
         */
        private function columnReady(ix:int):Boolean
        {
            for (var iy = tileRows-1; iy >= 0; iy--) {
                var tile:Tile = tiles[ix+iy*tileCols];
                if (tile.state != Tile.IDLE && tile.state != Tile.CLEARED) return false;
            }
            return true;
        }
        
        /**
         * Collapse the columns containing empty tiles
         */
        private function collapseColumns()
        {
            for (var ix = 0; ix < tileCols; ix++) {
                var iy:int;
                if (!columnReady(ix)) continue;
                var drop = 0;
                for (iy = tileRows-1; iy >= 0; iy--) {
                    var tile = tiles[ix+iy*tileCols];
                    if (tile.state != Tile.CLEARED) continue;
                    
                    var type:TileType = null;
                    var ay = iy;
                    var dropY:Number = 0;
                    while (ay >= 0) {
                        var above = tiles[ix+ay*tileCols];
                        if (above.state != Tile.CLEARED) {
                            type = above.type;
                            dropY = above.transitionalTileY;
                            above.clear();
                            break;
                        }
                        ay--;
                    }
                    if (!type) {
                        type = getRandomType();
                        drop++;
                        dropY = -drop;
                    }
                    tile.reset(type);
                    tile.dropFrom(dropY);
                }
            }
        }
        
        private function resetVector(vec:Vector.<int>, begin:int = 0, end:int = -1)
        {
            var l = vec.length;
            if (end == -1) end = l;
            for (var i = begin; i < end; i++) vec[i] = 0;
        }
        
    }
}