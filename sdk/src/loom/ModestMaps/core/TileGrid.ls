package loom.modestmaps.core 
{
    import loom.modestmaps.events.MapChange;
    import loom.modestmaps.events.MapExtentChange;
    import loom.modestmaps.events.MapPan;
    import loom.modestmaps.events.MapState;
    import loom.modestmaps.events.MapTileLoad;
    import loom.modestmaps.events.MapZoom;
    import loom.modestmaps.ModestMaps;
    import loom.modestmaps.Map;
    import loom.modestmaps.core.painter.ITilePainter;
    import loom.modestmaps.core.painter.ITilePainterOverride;
    import loom.modestmaps.core.painter.TilePainter;
    import loom.modestmaps.events.MapEvent;
    import loom.modestmaps.mapproviders.IMapProvider;
    import loom.modestmaps.core.TwoInputTouch;
    import loom2d.animation.IAnimatable;
    import loom2d.display.Image;
    import loom2d.display.Quad;
    import loom2d.Loom2D;
    
    import loom2d.display.DisplayObject;
    import loom2d.display.Sprite;
    import loom2d.events.Event;
    
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.text.TextField;
    
    public class TileGrid extends Sprite implements IAnimatable
    {       
        /** if we don't have a tile at currentZoom, onRender will look for tiles up to 5 levels out.
         *  set this to 0 if you only want the current zoom level's tiles
         *  WARNING: tiles will get scaled up A LOT for this, but maybe it beats blank tiles? */ 
        public static var MaxParentSearch:int = 5;
        /** if we don't have a tile at currentZoom, onRender will look for tiles up to one levels further in.
         *  set this to 0 if you only want the current zoom level's tiles
         *  WARNING: bad, bad nasty recursion possibilities really soon if you go much above 1
         *  - it works, but you probably don't want to change this number :) */
        public static var MaxChildSearch:int = 1;

        /** if MaxParentSearch is enabled, setting MaxParentLoad to between 1 and MaxParentSearch
         *   will make requests for lower zoom levels first */
        public static var MaxParentLoad:int = 0;

        /** this is the maximum size of tileCache (visible tiles will also be kept in the cache).  
         *  the larger this is, the more texture memory will be needed to store the loaded images. */     
        public static var MaxTilesToKeep:int = 128;// 256*256*4bytes = 0.25MB ... so 128 tiles is 32MB of memory, minimum!
        
        /** 0 or 1, really: 2 will load *lots* of extra tiles */
        public static var TileBuffer:int = 1;
        
        /** set this to true to enable enforcing of map bounds from the map provider's limits */
        public static var EnforceBoundsEnabled:Boolean = false;
                
        /** set this to false, along with RoundScalesEnabled, if you need a map to stay 'fixed' in place as it changes size */
        public static var RoundPositionsEnabled:Boolean = true;
                
        /** set this to false, along with RoundPositionsEnabled, if you need a map to stay 'fixed' in place as it changes size */
        public static var RoundScalesEnabled:Boolean = true;

        
        // TILE_WIDTH and TILE_HEIGHT are now tileWidth and tileHeight
        // this was needed for the NASA DailyPlanetProvider which has 512x512px tiles
        // public static const TILE_WIDTH:Number = 256;
        // public static const TILE_HEIGHT:Number = 256;        
        
        // read-only, kept up to date by calculateBounds()
        protected var _minZoom:Number;
        protected var _maxZoom:Number;

        protected var minTx:Number, maxTx:Number, minTy:Number, maxTy:Number;

        // read-only, convenience for tileWidth/Height
        protected var _tileWidth:Number;
        protected var _tileHeight:Number;

        // pan and zoom etc are stored in here
        // NB: this matrix is never applied to a DisplayObject's transform
        //     because it would require scaling tile positions to compensate.
        //     Instead, we adapt its values such that the current zoom level
        //     is approximately scale 1, and positions make sense in screen pixels
        protected var worldMatrix:Matrix;
        
        // this turns screen points into coordinates
        protected var _invertedMatrixDirty:Boolean = true;
        protected var _invertedMatrix:Matrix = Matrix.IDENTITY;
        
        // the corners and center of the screen, in map coordinates
        protected var _coordinatesDirty:Boolean = true;
        protected var _topLeftCoordinate:Coordinate = new Coordinate(0, 0, 0);
        protected var _bottomRightCoordinate:Coordinate = new Coordinate(0, 0, 0);
        protected var _topRightCoordinate:Coordinate = new Coordinate(0, 0, 0);
        protected var _bottomLeftCoordinate:Coordinate = new Coordinate(0, 0, 0);
        protected var _centerCoordinate:Coordinate = new Coordinate(0, 0, 0);

        // where the tiles live:
        protected var well:Sprite;
        static public var wellTiles:Dictionary.<String, Tile> = {};

        //protected var provider:IMapProvider;
        protected var tilePainter:ITilePainter;

        // coordinate bounds derived from IMapProviders
        protected var limits:Vector.<Coordinate>;
        
        // keys we've recently seen
        protected var recentlySeen:Vector.<Tile> = [];
        protected var recentlySeenIndex:int = 0;
        
        // currently visible tiles
        protected var visibleTiles:Vector.<Tile> = [];
                
        //NOTE_TEC: not porting DebugField for now at least...
        // // a textfield with lots of stats
        // public var debugField:DebugField;
        
        // what zoom level of tiles is 'correct'?
        protected var currentTileZoom:int; 
        // so we know if we're going in or out
        protected var previousTileZoom:int;     
        
        // for sorting the queue:
        protected var centerRow:Number;
        protected var centerColumn:Number;

        // for pan events
        protected var startPan:Coordinate;
        public var panning:Boolean;
        
        // for zoom events
        protected var startZoom:Number = -1;
        public var zooming:Boolean;
        
        protected var mapWidth:Number;
        protected var mapHeight:Number;
        
        protected var draggable:Boolean;

        // setting this.dirty = true will request an Event.RENDER
        protected var _dirty:Boolean;
        
        private var positionDirty:Boolean;

        // setting to true will dispatch a CHANGE event which Map will convert to an EXTENT_CHANGED for us
        protected var matrixChanged:Boolean = false;
        
        // Making the doubleTouchInput public so that the sensitivity can be set and additional callbacks can be made
        public var doubleTouchInput:TwoInputTouch;
        
        protected var bgTouchArea:Image;
        
        protected var repopCount:int = -1;
        protected var repopCounter:int;
        protected var repopCol:int = -1;
        protected var repopRow:int = -1;
        protected var repopMinCol:int = -1;
        protected var repopMaxCol:int = -1;
        protected var repopMinRow:int = -1;
        protected var repopMaxRow:int = -1;

        public var onPan:MapPan;
        public var onZoom:MapZoom;
        public var onChange:MapChange;
        public var onMapRender:MapChange;
        public var onTileLoad:MapTileLoad;
        
        public function TileGrid(w:Number, h:Number, draggable:Boolean, provider:IMapProvider)
        {
            this.draggable = draggable;
            
            if (provider is ITilePainterOverride) {
                this.tilePainter = ITilePainterOverride(provider).getTilePainter();
            }
            else {
                this.tilePainter = new TilePainter(this, provider, MaxParentLoad == 0 ? centerDistanceCompare : zoomThenCenterCompare);
            }
            tilePainter.getOnTileLoad() += onTileLoading;
            
            this.limits = provider.outerLimits();
            
            // but do grab tile dimensions:
            _tileWidth = provider.tileWidth;
            _tileHeight = provider.tileHeight;

            // and calculate bounds from provider
            calculateBounds();
            
            this.mapWidth = w;
            this.mapHeight = h;         
            clipRect = new Rectangle(0, 0, mapWidth, mapHeight);
            
            //NOTE_TEC: not porting DebugField for now at least...
            // debugField = new DebugField();
            // debugField.x = mapWidth - debugField.width - 15; 
            // debugField.y = mapHeight - debugField.height - 15;

            //empty tiles (while they are still loading)
            // NOTE_TEC: This is so that you can have user input on tiles that are yet to load
            bgTouchArea = new Image();
            bgTouchArea.setSize(mapWidth, mapHeight);
            bgTouchArea.color = 0x00000000;
            bgTouchArea.alpha = 0;
            bgTouchArea.ignoreHitTestAlpha = true;
            addChild(bgTouchArea);
            
            well = new Sprite();
            well.name = 'well';
            well.depthSort = true;
            addChild(well);

            worldMatrix = new Matrix();

            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage); 
        }
        
        
        /**
         * Get the Tile instance that corresponds to a given coordinate.
         */
        public function getCoordTile(coord:Coordinate):Tile
        {
            // these get floored when they're cast as ints in tileKey()
            return wellTiles[ModestMaps.tileKey(coord.column, coord.row, coord.zoom)];
        }
        
        private function onAddedToStage(event:Event):void
        {
            if (draggable) {
                addEventListener(TouchEvent.TOUCH, touchEventProcess);

                doubleTouchInput = new TwoInputTouch(stage);
                doubleTouchInput.OnDoubleTouchEvent += onDoubleTouch;
                doubleTouchInput.OnDoubleTouchEndEvent += onDoubleTouchEnd;
            }
            
            onRender += _onRender;
            Loom2D.juggler.add(this);

            //NOTE_TEC: not porting DebugField for now at least...
            // addEventListener(Event.ENTER_FRAME, onEnterFrame);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            dirty = true;
            // force an on-render in case we were added in a render handler
            _onRender();
        }
        
        private function onRemovedFromStage(event:Event):void
        {
            if (hasEventListener(TouchEvent.TOUCH)) {
                removeEventListener(TouchEvent.TOUCH, touchEventProcess);
            }
            if(doubleTouchInput)
            {
                doubleTouchInput.OnDoubleTouchEvent -= onDoubleTouch;
                doubleTouchInput.OnDoubleTouchEndEvent -= onDoubleTouchEnd;
                doubleTouchInput = null;
            }
            onRender -= _onRender;
            Loom2D.juggler.remove(this);

            //NOTE: not porting DebugField for now at least...
            // removeEventListener(Event.ENTER_FRAME, onEnterFrame);

            // FIXME: should we still do this, in TilePainter?
            //queueTimer.stop();
            removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        /** The classes themselves serve as factories!
         * 
         * @param tileCreator Function that will instantiate and return a Tile object e.g. Tile, TweenTile, etc.
         * 
         * @see http://norvig.com/design-patterns/img013.gif  
         */ 
        
        public function setTileCreator(tileCreator:Function):void
        {
            // first get rid of everything, which passes tiles back to the pool
            clearEverything();
            // then assign the new class, which creates a new pool array
            tilePainter.setTileCreator(tileCreator);
        }
        
        //NOTE_TEC: not porting DebugField for now at least...
        // /** processes the tileQueue and optionally outputs stats into debugField */
        // protected function onEnterFrame(event:Event=null):void
        // {
        //  if (debugField.parent) {
        //      debugField.update(this, blankCount, recentlySeen.length, tilePainter);
        //      debugField.x = mapWidth - debugField.width - 15; 
        //      debugField.y = mapHeight - debugField.height - 15;
        //  }
        // }

        protected function onRendered():void
        {
            // listen out for this if you want to be sure map is in its final state before reprojecting markers etc.
            onMapRender();
        }
        
        protected function onPanned():void
        {
            calcCoordinatePoint(startPan);
            onPan(MapState.CHANGED, ModestMaps.LastCoordinateX - mapWidth/2, ModestMaps.LastCoordinateY - mapHeight/2);
        }
        
        protected function onZoomed():void
        {
            onZoom(MapState.CHANGED, zoomLevel, zoomLevel-startZoom);
        }
        
        protected function onChanged():void
        {
            // doesn't bubble, unlike MapEvent
            // Map will pick this up and dispatch MapEvent.EXTENT_CHANGED for us
            onChange();
        }
        
        
        protected function onBeginTileLoading(event:MapEvent):void
        {
            dispatchEvent(event);           
        }

        protected function onAllTilesLoaded(event:MapEvent):void
        {
            dispatchEvent(event);
            // request redraw to take parent and child tiles off the stage if we haven't already
            dirty = true;           
        }
        private function onTileLoading(state:MapState):void {
            onTileLoad(state);
            if (state == MapState.STOPPED) dirty = true;
        }   

        
        /** 
         * figures out from worldMatrix which tiles we should be showing, adds them to the stage, adds them to the tileQueue if needed, etc.
         * 
         * from my recent testing, TileGrid.onRender takes < 5ms most of the time, and rarely >10ms
         * (Flash Player 9, Firefox, Macbook Pro)
         *  
         */        
        protected function _onRender():void
        {
            //var t:Number = getTimer();
            
            //trace(well.numChildren);
            
            if (!dirty || !stage) {
                //trace(getTimer() - t, "ms in", provider);     
                onRendered();
                return;
            }

            processChange();
            
            // what zoom level of tiles should we be loading, taking into account min/max zoom?
            // (0 when scale == 1, 1 when scale == 2, 2 when scale == 4, etc.)
            var newZoom:int = Math.min2(maxZoom, Math.max2(minZoom, Math.round(zoomLevel)));
            
            // see if the newZoom is different to currentZoom
            // so we know which way we're zooming, if any:
            if (currentTileZoom != newZoom) {
                previousTileZoom = currentTileZoom;
            }
            
            // this is the level of tiles we'll be loading:
            currentTileZoom = newZoom;
            
            //trace("left", tilePainter.getCacheSize(), recentlySeen.length, wellTiles.length, visibleTiles.length, wellTiles.length);
            
            //figure out the visible tiles
            determineVisibleTiles();

            // loop over all tiles and find parent or child tiles from cache to compensate for unloaded tiles:
            repopulateVisibleTiles(MinColRow.x, MaxColRow.x, MinColRow.y, MaxColRow.y);
            
            // position tiles such that currentZoom is approximately scale 1
            // and x and y make sense in pixels relative to tlC.column and tlC.row (topleft)
            positionDirty = true;
            
            // update centerRow and centerCol for sorting the tileQueue in processQueue()
            centerCoordinate.zoomToInPlace(currentTileZoom);
            centerColumn = centerCoordinate.zoomToCol;
            centerRow = centerCoordinate.zoomToRow;

            onRendered();

            dirty = false;
                        
            //trace(getTimer() - t, "ms in", provider);         
        }

        private function processChange():void
        {
            var boundsEnforced:Boolean = enforceBounds();            
            if (zooming || panning) {
                if (panning) {
                    onPanned();
                }   
                if (zooming) {
                    onZoomed();
                }
            }
            else if (boundsEnforced) {
                onChanged();
            }
            else if (matrixChanged) {
                matrixChanged = false;
                onChanged();
            }            
        }
                

        private var MinColRow:Point;
        private var MaxColRow:Point;
        private var TopLeftColRow:Point;
        private function determineVisibleTiles():void
        {
            //make sure our coordinates are all up to date
            recalculateCoordinates();

            // find start and end columns for the visible tiles, at current tile zoom
            // we project all four corners to take account of potential rotation in worldMatrix
            _topLeftCoordinate.zoomToInPlace(currentTileZoom);
            _bottomRightCoordinate.zoomToInPlace(currentTileZoom);
            _topRightCoordinate.zoomToInPlace(currentTileZoom);
            _bottomLeftCoordinate.zoomToInPlace(currentTileZoom);
            
            // optionally pad it out a little bit more with a tile buffer
            // TODO: investigate giving a directional bias to TILE_BUFFER when panning quickly
            // NB:- I'm pretty sure these calculations are accurate enough that using 
            //      Math.ceil for the maxCols will load one column too many -- Tom         
            MinColRow.x = Math.floor(minCoord(_topLeftCoordinate.zoomToCol, 
                                                _bottomRightCoordinate.zoomToCol,
                                                _topRightCoordinate.zoomToCol,
                                                _bottomLeftCoordinate.zoomToCol)) - TileBuffer;
            MaxColRow.x = Math.floor(maxCoord(_topLeftCoordinate.zoomToCol,
                                                _bottomRightCoordinate.zoomToCol,
                                                _topRightCoordinate.zoomToCol,
                                                _bottomLeftCoordinate.zoomToCol)) + TileBuffer;
            MinColRow.y = Math.floor(minCoord(_topLeftCoordinate.zoomToRow,
                                                _bottomRightCoordinate.zoomToRow,
                                                _topRightCoordinate.zoomToRow,
                                                _bottomLeftCoordinate.zoomToRow)) - TileBuffer;
            MaxColRow.y = Math.floor(maxCoord(_topLeftCoordinate.zoomToRow,
                                                _bottomRightCoordinate.zoomToRow,
                                                _topRightCoordinate.zoomToRow,
                                                _bottomLeftCoordinate.zoomToRow)) + TileBuffer;
            TopLeftColRow.x = _topLeftCoordinate.zoomToCol;
            TopLeftColRow.y = _topLeftCoordinate.zoomToRow;
        }

        private function minCoord(a:Number, b:Number, c:Number, d:Number):Number
        {
            if(a < b)
            {
                if(a < c) { return (a < d) ? a : d; }
                else { return (c < d) ? c : d; }
            }
            else
            {
                if(b < c) { return (b < d) ? b : d; }
                else { return (c < d) ? c : d; }
            }
        }

        private function maxCoord(a:Number, b:Number, c:Number, d:Number):Number
        {
            if(a > b)
            {
                if(a > c) { return (a > d) ? a : d; }
                else { return (c > d) ? c : d; }
            }
            else
            {
                if(b > c) { return (b > d) ? b : d; }
                else { return (c > d) ? c : d; }
            }
        }
        private function rvtStart():void
        {
            //reset the visible tile flags
            var len = recentlySeen.length;
            for (var i = 0; i < len; i++) {
                var tile = recentlySeen[i];
                tile.isVisible = false;
            }
            
            visibleTiles.clear(); 
        }
        
        private function rvtEnd():void
        {
            positionDirty = true;
        }

        var WorkCoord:Coordinate = new Coordinate(0,0,0);

        private function rvtProcessTile(col:int, row:int, zoom:int, add:Boolean = true):Tile
        {
            // create a string key for this tile
            var key:String = ModestMaps.tileKey(col, row, zoom);
            
            // see if we already have this tile
            var tile:Tile = wellTiles[key];
            
            // create it if not, and add it to the load queue
            if (!tile && add) {
                tile = tilePainter.getTileFromCache(key);
                if (!tile) {
                    WorkCoord.setVals(row, col, currentTileZoom);
                    tile = tilePainter.createAndPopulateTile(WorkCoord, key); 
                }
                else {
                    tile.show();
                }
                wellAdd(tile, key);
            }
            
            if (tile) {
                if (add) {
                    visibleTiles.pushSingle(tile);
                }
                tile.isVisible = true;
                tile.updateRepop();
            }
            
            return tile;        
        }


        var searchedParentKeys:Dictionary.<String, Boolean> = {};
        private function rvtMakeTileReady(col:int, row:int):void
        {
            var foundParent:Boolean = false;
            var foundChildren:int = 0;
            searchedParentKeys.clear();

            if (currentTileZoom > previousTileZoom) 
            {
                // if it still doesn't have enough images yet, or it's fading in, try a double size parent instead
                if (MaxParentSearch > 0 && currentTileZoom > minZoom) 
                {
                    var firstParentKey:String = ModestMaps.prepParentLoad(col, row, currentTileZoom, currentTileZoom-1);
                    if (!searchedParentKeys[firstParentKey])
                     {
                        searchedParentKeys[firstParentKey] = true;
                        if (ensureVisible(firstParentKey)) {
                            foundParent = true;
                        }
                        if (!foundParent && (currentTileZoom - 1 < MaxParentLoad)) {
                            //trace("requesting parent tile at zoom", pzoom);
                            requestParentLoad(firstParentKey);
                        }                                   
                    }
                }
            }
            else 
            {
                // currentZoom <= previousZoom, so we're zooming out
                // and therefore we might want to reuse 'smaller' tiles
                
                // if it doesn't have an image yet, see if we can make it from smaller images
                if (!foundParent && MaxChildSearch > 0 && currentTileZoom < maxZoom) 
                {
                    for (var czoom:int = currentTileZoom+1; czoom <= Math.min2(maxZoom, currentTileZoom+MaxChildSearch); czoom++) 
                    {
                        childKeys(col, row, currentTileZoom, czoom);
                        for each (var ckey:String in ChildKeysVec) 
                        {
                            if (ensureVisible(ckey))
                            {
                                foundChildren++;
                            }
                        }

                        if (foundChildren == ChildKeysVec.length) {
                            break;
                        } 
                    }
                }
            }

            var stillNeedsAnImage:Boolean = !foundParent && foundChildren < 4;                  

            // if it still doesn't have an image yet, try more parent zooms
            if (stillNeedsAnImage && MaxParentSearch > 1 && currentTileZoom > minZoom) {
                var startZoomSearch:int = currentTileZoom - 1;                
                if (currentTileZoom > previousTileZoom) {
                    // we already looked for parent level 1, and didn't find it, so:
                    startZoomSearch -= 1;
                }
                
                var endZoomSearch:int = Math.max2(minZoom, currentTileZoom-MaxParentSearch);
                for (var pzoom:int = startZoomSearch; pzoom >= endZoomSearch; pzoom--) {
                    var pkey:String = ModestMaps.prepParentLoad(col, row, currentTileZoom, pzoom);
                    if (!searchedParentKeys[pkey]) {
                        searchedParentKeys[pkey] = true;
                        if (ensureVisible(pkey)) {                              
                            stillNeedsAnImage = false;
                            break;
                        }
                        if (currentTileZoom - pzoom < MaxParentLoad) {
                            //trace("requesting parent tile at zoom", pzoom);
                            requestParentLoad(pkey);
                        }
                    }
                    else {
                        break;
                    }
                }
            }
        }

        /**
         * loops over given cols and rows and adds tiles to visibleTiles array and the well
         * using child or parent tiles to compensate for tiles not yet available in the tileCache
         */
        private function repopulateVisibleTiles(minCol:int, maxCol:int, minRow:int, maxRow:int):void
        {
            //prep/clear data
            rvtStart();
         
            //// loop over currently visible tiles
            //for (var col:int = minCol; col <= maxCol; col++) {
                //for (var row:int = minRow; row <= maxRow; row++) {
                    //var tile:Tile = rvtProcessTile(col, row);
                    //
                    //// if the tile isn't ready yet, we're going to reuse a parent tile
                    //// if there isn't a parent tile, and we're zooming out, we'll reuse child tiles
                    //// if we don't get all 4 child tiles, we'll look at more parent levels
                    ////
                    //// yes, this is quite involved, but it should be fast enough because most of the loops
                    //// don't get hit most of the time
                    ////
                    //
                    //var tileReady:Boolean = tile.isShowing() && !tilePainter.isPainting(tile);
                    //if (!tileReady) {
                        //rvtMakeTileReady(col, row);
                    //}
                //}
            //}
            //
            //pruneTiles();
            //
            //return;
            
            /*
            for (var i:int = well.numChildren-1; i >= 0; i--) {
                var wellTile:Tile = well.getChildAtUnsafe(i) as Tile;
                wellTile.isPending = false;
            }
            */
            
            repopulateVisibleTilesPending(minCol, maxCol, minRow, maxRow);
            
            if (repopCol < minCol) repopCol = minCol;
            if (repopCol > maxCol) repopCol = maxCol;
            if (repopRow < minRow) repopRow = minRow;
            if (repopRow > maxRow) repopRow = maxRow;
            repopMinCol = minCol;
            repopMaxCol = maxCol;
            repopMinRow = minRow;
            repopMaxRow = maxRow;
            
            //repopCol = minCol;
            //repopRow = minRow;
            
            //if (repopCount == -1) Loom2D.juggler.add(this);
            
            repopCounter = 0;
            repopCount = (maxCol-minCol+1)*(maxRow-minRow+1);
            
            //trace("repop", minCol, repopCol, maxCol, minRow, repopRow, maxRow, repopCount);
            
            repopulateVisibleTilesFrame();
            
            // loop over currently visible tiles
            //for (var col:int = minCol; col <= maxCol; col++) 
            //{
                //for (var row:int = minRow; row <= maxRow; row++) 
                //{
                //}
            //}            
        }
        
        private function repopulateVisibleTilesPending(minCol:int, maxCol:int, minRow:int, maxRow:int) {
            for (var col:int = minCol; col <= maxCol; col++) {
                for (var row:int = minRow; row <= maxRow; row++) {
                    var tile:Tile = rvtProcessTile(col, row, currentTileZoom, false);
                    
                    // if the tile isn't ready yet, we're going to reuse a parent tile
                    // if there isn't a parent tile, and we're zooming out, we'll reuse child tiles
                    // if we don't get all 4 child tiles, we'll look at more parent levels
                    //
                    // yes, this is quite involved, but it should be fast enough because most of the loops
                    // don't get hit most of the time
                    //
                    
                    //var tileReady:Boolean = tile.isShowing() && !tilePainter.isPainting(tile);
                    //if (!tileReady) {
                        //rvtMakeTileReady(col, row);
                    //}
                }
            }
            //visibleTiles.clear();
        }
        
        public function advanceTime(time:Number) {
            if (repopCount != -1) repopulateVisibleTilesFrame();
            pruneLeastRecent();
            if (positionDirty) positionTiles(TopLeftColRow.x, TopLeftColRow.y);
        }
        
        private function repopulateVisibleTilesFrame()
        {
            var time = Platform.getTime();
            
            var timeLimit = 3;
            var countLimit = 1000;
            var c:int;
            for (c = 0; (Platform.getTime() - time) < timeLimit && c < countLimit; c++) {
                var tile:Tile = rvtProcessTile(repopCol, repopRow, currentTileZoom);
                
                // if the tile isn't ready yet, we're going to reuse a parent tile
                // if there isn't a parent tile, and we're zooming out, we'll reuse child tiles
                // if we don't get all 4 child tiles, we'll look at more parent levels
                //
                // yes, this is quite involved, but it should be fast enough because most of the loops
                // don't get hit most of the time
                //
                
                var tileReady:Boolean = tile.isShowing() && !tilePainter.isPainting(tile);
                if (!tileReady) {
                    rvtMakeTileReady(repopCol, repopRow);
                }
                
                repopCol++;
                if (repopCol > repopMaxCol) {
                    repopCol = repopMinCol;
                    repopRow++;
                    if (repopRow > repopMaxRow) {
                        repopRow = repopMinRow;
                    }
                }
                repopCounter++;
                if (repopCounter > repopCount) {
                    repopCount = -1;
                    rvtEnd();
                    break;
                }
            }
            
            time = Platform.getTime()-time;
            
            positionDirty = true;
        }
        
        private function pruneLeastRecent() {
            //return;
            
            //for (var m = 0; m < recentlySeen.length; m++) {
            
            if (tilePainter.getCacheSize() < MaxTilesToKeep) return;
            
            //if (recentlySeenIndex < 0) recentlySeenIndex = 0;
            //if (recentlySeenIndex >= recentlySeen.length) recentlySeenIndex = recentlySeen.length-1;
            //trace(tilePainter.getCacheSize(), recentlySeenIndex, recentlySeen.length);
            //if (recentlySeenIndex < 0) return;
            
            var len = recentlySeen.length;
            
            var now = Platform.getTime();
            var leastRecentIndex = -1;
            var leastRecent:Tile = null;
            var leastRecentDiff = -1;
            var tile:Tile;
            var iw = 0;
            var iv = 0;
            var ip = 0;
            var ipd = 0;
            for (var i:int = 0; i < len; i++) {
                tile = recentlySeen[i];
                if (tile.inWell) { iw++; }
                if (tile.isVisible) { iv++; }
                if (tilePainter.isPainting(tile)) { ip++; }
                if (tilePainter.isPainted(tile)) { ipd++; }
                if (tile.isVisible) continue;
                var tileRepop = now-tile.lastRepop;
                if (tileRepop > leastRecentDiff) {
                    leastRecentDiff = tileRepop;
                    leastRecent = tile;
                    leastRecentIndex = i;
                }
            }
            
            if (!leastRecent) {
                //trace("Least recent not found", iw, iv, ip, ipd);
                return;
            }
            
            tile = leastRecent;
            
            //trace(tilePainter.getCacheSize(), leastRecentIndex, leastRecentDiff, leastRecent);
            
            if (!tile.inWell) {
                if (tile.inWell) wellRemove(tile);
                tilePainter.returnKey(tile.name);
            }
            recentlySeen.splice(leastRecentIndex, 1);
            
            recentlySeenIndex++;
            if (recentlySeenIndex >= recentlySeen.length) {
                recentlySeenIndex = 0;
            }
        }


        // TODO: do this with events instead?
        public function tilePainted(tile:Tile):void
        {           
            if (currentTileZoom-tile.zoom <= MaxParentLoad) {
                tile.show();
            }
            else {
                tile.showNow();
            }
        }
        
        /** 
         * returns an array of all the tiles that are on the screen
         * (including parent and child tiles currently visible until
         * the current zoom level finishes loading)
         * */
        public function getVisibleTiles():Vector.<Tile>
        {
            return visibleTiles;
        }
        
        private function positionTiles(realMinCol:Number, realMinRow:Number):void
        {
            
            

            
//TODO_24: native prep for lower down                
            // scales to compensate for zoom differences between current grid zoom level
            var zl:Number = zoomLevel;
            var invTileWidth:Number = 1.0 / tileWidth;
            for (var z:int = 0; z <= maxZoom; z++) {
                var tileScale = Math.pow(2, zl-z);
                // round up to the nearest pixel to avoid seams between zoom levels
                if (RoundScalesEnabled) {
                    _tileScales[z] = Math.ceil(tileScale * tileWidth) * invTileWidth; 
                }
                else {
                    _tileScales[z] = tileScale;
                }
            }
            
//TODO_24: native           
            // hugs http://www.senocular.com/flash/tutorials/transformmatrix/
            var px:Point = worldMatrix.deltaTransformCoord(0, 1);
            var tileAngleDegrees:Number = (Math.atan2(px.y, px.x) - Math.degToRad(90));
            
            var i = 0;
            var len = well.numChildren;
            var count = 0;
            const TILE_DEPTH_SHIFT = 16;
            // apply the sorted depths, position all the tiles and also keep recentlySeen updated:
            for (i = 0; i < len; i++) {
                var tile:Tile = well.getChildAtUnsafe(i) as Tile;
                
                tile.depth = (-Math.abs(tile.zoom-currentTileZoom) << TILE_DEPTH_SHIFT) | tile.zoom;
                
               	
//_TODO_24: native all below here... need to return scale, x, y, rot... doable?
                tile.scaleX = tile.scaleY = _tileScales[tile.zoom];

                // rounding can also helps the rare seams not fixed by rounding the tile scale, 
                // but makes slow zooming uglier: 
                ModestMaps.setLastCoordinate(tile.column, 
                                                tile.row, 
                                                tile.zoom, 
                                                zoomLevel,
                                                tileWidth/scale,
                                                worldMatrix,
                                                null, 
                                                null);
                tile.x = ModestMaps.LastCoordinateX;
                tile.y = ModestMaps.LastCoordinateY;                
                tile.rotation = tileAngleDegrees;               
            }
        }
        
        private function zoomThenCenterCompare(t1:Tile, t2:Tile):int
        {
            if (t1.zoom == t2.zoom) {
                return centerDistanceCompare(t1, t2);
            }
            return t1.zoom < t2.zoom ? -1 : t1.zoom > t2.zoom ? 1 : 0; 
        }

        // for sorting arrays of tiles by distance from center Coordinate       
        private function centerDistanceCompare(t1:Tile, t2:Tile):int
        {
            if (t1.zoom == t2.zoom && t1.zoom == currentTileZoom && t2.zoom == currentTileZoom) {
                var d1:int = Math.pow(t1.row+0.5-centerRow,2) + Math.pow(t1.column+0.5-centerColumn,2); 
                var d2:int = Math.pow(t2.row+0.5-centerRow,2) + Math.pow(t2.column+0.5-centerColumn,2); 
                return d1 < d2 ? -1 : d1 > d2 ? 1 : 0; 
            }
            return Math.abs(t1.zoom-currentTileZoom) < Math.abs(t2.zoom-currentTileZoom) ? -1 : 1;
        }
        
        // for sorting arrays of tiles by distance from currentZoom in a DESCENDING fashion
        private function distanceFromCurrentZoomCompare(t1:Tile, t2:Tile):int
        {
            var d1:int = Math.abs(t1.zoom-currentTileZoom);
            var d2:int = Math.abs(t2.zoom-currentTileZoom);
            return d1 < d2 ? 1 : d1 > d2 ? -1 : zoomCompare(t2, t1); // t2, t1 so that big tiles are on top of small 
        }

        // for when tiles have same difference in zoom in distanceFromCurrentZoomCompare        
        private static function zoomCompare(t1:Tile, t2:Tile):int
        {
            return t1.zoom == t2.zoom ? 0 : t1.zoom > t2.zoom ? -1 : 1; 
        }

        // makes sure that if a tile with the given key exists in the cache
        // that it is added to the well and added to visibleTiles
        // returns null if tile does not exist in cache
        private function ensureVisible(key:String):Tile
        {
            var tile:Tile = tilePainter.getTileFromCache(key);
            if (tile) {
                if (!tile.inWell) {
                    wellAdd(tile, key);
                    tilePainted(tile);
                }

                if (!tile.isVisible) {
                    visibleTiles.pushSingle(tile); // don't get rid of it yet!
                    tile.isVisible = true;
                }
                return tile;
            }
            return null;
        }
        
        private function wellAdd(tile:Tile, key:String)
        {
            well.addChild(tile, false);
            wellTiles[key] = tile;
            tile.inWell = true;
            recentlySeen.push(tile);
        }
        
        private function wellRemove(tile:Tile)
        {
            well.removeChild(tile, false, false);
            wellTiles.deleteKey(tile.name);
            tile.inWell = false;
            tile.hide();
            tilePainter.cancelPainting(tile);
        }
        
        // for use in requestParentLoad
        private var tempCoord:Coordinate = new Coordinate(0,0,0);
        
        /** create a tile and add it to the queue - WARNING: this is buggy for the current zoom level, it's only used for parent zooms when MaxParentLoad is > 0 */ 
        private function requestParentLoad(key:String):Tile
        {
            var tile:Tile;
            tile = ensureVisible(key);
            if (!tile) {
                tile = rvtProcessTile(ModestMaps.ParentLoadCol, ModestMaps.ParentLoadRow, ModestMaps.ParentLoadZoom);
            }
            return tile;
        }

        

        
        // TODO: check that this does the right thing with negative row/col?
        //NOTE_TEC: Removed Vector<> creation for return to save garbage generation
        private var ChildKeysVec:Vector.<String> = new Vector.<String>();
        private function childKeys(col:int, row:int, zoom:int, childZoom:int):void
        {
            ChildKeysVec.clear();
            var invScaleFactor:Number = 1.0 / Math.pow(2, zoom-childZoom); // one zoom in = 0.5
            var rowColSpan:int = Math.pow(2, childZoom - zoom); // one zoom in = 2, two = 4
            var colScale:int = col*invScaleFactor;
            var rowScale:int = row*invScaleFactor;
            for (var ccol:int = colScale; ccol < colScale+rowColSpan; ccol++) {
                for (var crow:int = rowScale; crow < rowScale+rowColSpan; crow++) {
                    ChildKeysVec.pushSingle(ModestMaps.tileKey(ccol, crow, childZoom));
                }
            }
        }
                
        var doubleTouchActive = false;  // If we're doing a double touch we don't want the map to pan twice
        var canProcessDoubleTap = true; // We don't want a double tap event to fire over two consective frames, so we introduce a lock on when it can happen
        var doubleTapZoomAmount = 1; // The amount to zoom in on a double tap
        public function touchEventProcess(event:TouchEvent):void
        {
            prepareForPanning(true);
            
            var touches = event.getTouches(stage);          
            
            if (touches[0].phase == TouchPhase.MOVED && !doubleTouchActive)
                mouseDragged(touches[0].getMovement(stage));
            
            if (touches[0].phase == TouchPhase.ENDED)
                mouseReleased(event);
    
            // Reset our ability to process taps when the tap counter resets
            if (touches[0].tapCount == 1)
                canProcessDoubleTap = true;
                
            if (touches[0].tapCount == 2 && canProcessDoubleTap)
            {
                zoomByAbout(doubleTapZoomAmount, touches[0].getLocation(stage));
            }
        }

        public function mouseReleased(event:TouchEvent):void
        {
            donePanning();
            dirty = true;
        }

        public function mouseDragged(deltaPos:Point):void
        {           
            tx += deltaPos.x;
            ty += deltaPos.y;
            dirty = true;
        }
        
        // Two touch controls
        var canRotate:Boolean = true;
        var isRotating:Boolean = false;
        
        function onDoubleTouchEnd()
        {
            canRotate = true;
            isRotating = false;
            doubleTouchActive = false;
            accumulatedZoomValue = 0;
        }

        
        public function rotateByAbout(angle:Number, targetPoint:Point):void
        {
            prepareForZooming();
            prepareForPanning();
            
            var m:Matrix = worldMatrix;
            
            m.translate(-targetPoint.x, -targetPoint.y);
            m.rotate(angle);
            m.translate(targetPoint.x, targetPoint.y);          
            
            setMatrix(m);

            doneZooming();
            donePanning();
        } 

        
        private var accumulatedZoomValue:Number = 0;
        function onDoubleTouch(touch1:Point, touch2:Point)
        {
            doubleTouchActive = true;
            
            accumulatedZoomValue += doubleTouchInput.getZoomDelta();
            if (Math.abs(accumulatedZoomValue) > 2.4)
            {               
                zoomByAbout(doubleTouchInput.getZoomDelta() * doubleTouchInput.zoomSensitivity, doubleTouchInput.getTouchMidPoint());
                
                // If we start zooming we don't want to rotate, unless we were already rotating
                if (!isRotating)
                {
                    canRotate = false;
                }
            }
            
            if (canRotate && Math.abs(doubleTouchInput.getAngleDelta()) > 0.1)
            {               
                rotateByAbout(doubleTouchInput.getAngleDelta() * doubleTouchInput.rotationSensitivity, doubleTouchInput.getTouchMidPoint());
                isRotating = true;
            }
            
            // We always want to pan the map around the center of our fingers
            mouseDragged(doubleTouchInput.getTouchMidPointDelta());
        }
        
        /** zoom in or out by zoomDelta, keeping the requested point in the same place */
        public function zoomByAbout(zoomDelta:Number, targetPoint:Point, duration:Number=-1):void
        {
            var zl:Number = zoomLevel;
            if (zl + zoomDelta < minZoom) {
                zoomDelta = minZoom - zl;                
            }
            else if (zl + zoomDelta > maxZoom) {
                zoomDelta = maxZoom - zl; 
            } 
            
            var sc:Number = Math.pow(2, zoomDelta);
            
            prepareForZooming();
            prepareForPanning();
            
            var m:Matrix = getMatrix();
            
            m.translate(-targetPoint.x, -targetPoint.y);
            m.scale(sc, sc);
            m.translate(targetPoint.x, targetPoint.y);          
            
            setMatrix(m);

            doneZooming();
            donePanning();
        }        


        /** derived from map provider by calculateBounds(), read-only here for convenience */
        public function get minZoom():Number
        {
            return _minZoom;
        }
        /** derived from map provider by calculateBounds(), read-only here for convenience */
        public function get maxZoom():Number
        {
            return _maxZoom;
        }

        /** convenience method for tileWidth */
        public function get tileWidth():Number
        {
            return _tileWidth;
        }
        /** convenience method for tileHeight */
        public function get tileHeight():Number
        {
            return _tileHeight;
        }

        private function recalculateInvertedMatrix():void
        {
            if(!_invertedMatrixDirty)
            {
                return;
            }
            _invertedMatrixDirty = false;
            ModestMaps.getGridInverseMatrix(worldMatrix, tileWidth, tileHeight, scale, _invertedMatrix);
        }

        private function recalculateCoordinates():void
        {
            recalculateInvertedMatrix();

            if(!_coordinatesDirty)
            {
                return;
            }
            _coordinatesDirty = false;

            ModestMaps.setGridCoordinates(_invertedMatrix, mapWidth, mapHeight, scale);

            //pull out the values calcualted natively and set them here
            _topLeftCoordinate.setVals(ModestMaps.GridTLx, ModestMaps.GridTLy, ModestMaps.GridZoom);  
            _bottomRightCoordinate.setVals(ModestMaps.GridBRx, ModestMaps.GridBRy, ModestMaps.GridZoom);  
            _topRightCoordinate.setVals(ModestMaps.GridTRx, ModestMaps.GridTRy, ModestMaps.GridZoom);  
            _bottomLeftCoordinate.setVals(ModestMaps.GridBLx, ModestMaps.GridBLy, ModestMaps.GridZoom);  
            _centerCoordinate.setVals(ModestMaps.GridCx, ModestMaps.GridCy, ModestMaps.GridZoom);  
        }

        public function get invertedMatrix():Matrix
        {
            recalculateInvertedMatrix();
            return _invertedMatrix;
        }
        public function get topLeftCoordinate():Coordinate
        {
            recalculateCoordinates();
            return _topLeftCoordinate;
        }
        public function get bottomRightCoordinate():Coordinate
        {
            recalculateCoordinates();
            return _bottomRightCoordinate;
        }
        public function get topRightCoordinate():Coordinate
        {
            recalculateCoordinates();
            return _topRightCoordinate;
        }
        public function get bottomLeftCoordinate():Coordinate
        {
            recalculateCoordinates();
            return _bottomLeftCoordinate;
        }
        public function get centerCoordinate():Coordinate
        {
            recalculateCoordinates();
            return _centerCoordinate;
        }        

        //NOTE_TEC: Removed Point usage here as it was generating too much garbage as Points are structs in Loom
        public function calcCoordinatePoint(coord:Coordinate, context:DisplayObject=null):void
        {
            ModestMaps.setLastCoordinate(coord.column, 
                                            coord.row, 
                                            coord.zoom, 
                                            zoomLevel,
                                            tileWidth/scale,
                                            worldMatrix,
                                            context, 
                                            this);
        }
        
//TODO_24: Native this        
        private var PointCoord = new Coordinate(0, 0, 0);
        public function pointCoordinate(point:Point, context:DisplayObject=null):Coordinate
        {           
            if (context && context != this)
            {
                point = context.localToGlobal(point);
                point = this.globalToLocal(point);
            }
            
            var p:Point = invertedMatrix.transformCoord(point.x, point.y);
            PointCoord.setVals(p.y, p.x, zoomLevel);
            return PointCoord;
        }
        
        public function prepareForPanning(dragging:Boolean=false):void
        {
            if (panning) {
                donePanning();
            }
            startPan = centerCoordinate.copy();
            panning = true;
            onStartPanning();
        }
        
        protected function onStartPanning():void
        {
            onPan(MapState.STARTED, 0, 0);
        }
        
        public function donePanning():void
        {
            startPan = null;
            panning = false;
            onStopPanning();
        }
        
        protected function onStopPanning():void
        {
            onPan(MapState.STOPPED, 0, 0);
        }
        
        public function prepareForZooming():void
        {
            if (startZoom >= 0) {
                doneZooming();
            }
            
            startZoom = zoomLevel;
            zooming = true;
            onStartZooming();
        }
        
        protected function onStartZooming():void
        {
            onZoom(MapState.STARTED, startZoom, NaN);
        }
        
        
        public function doneZooming():void
        {
            onStopZooming();
            startZoom = -1;
            zooming = false;
        }

        protected function onStopZooming():void
        {
            onZoom(MapState.STOPPED, zoomLevel, zoomLevel - startZoom);
        }

        public function resetTiles(coord:Coordinate):void
        {
            var sc:Number = Math.pow(2, coord.zoom);

            worldMatrix.identity();
            worldMatrix.scale(sc, sc);
            worldMatrix.translate(mapWidth/2, mapHeight/2 );
            worldMatrix.translate(-tileWidth*coord.column, -tileHeight*coord.row);

            // reset the inverted matrix, request a redraw, etc.
            dirty = true;
        }


        private var InvLN2:Number = 1.0 / Math.LN2;
        public function get zoomLevel():Number
        {
            return Math.log(scale) * InvLN2;
        }

        public function set zoomLevel(n:Number):void
        {
            if (zoomLevel != n)
            {
                scale = Math.pow(2, n);                     
            }
        }

        public function get scale():Number
        {
            return Math.sqrt(worldMatrix.a * worldMatrix.a + worldMatrix.b * worldMatrix.b);
        }

        public function set scale(n:Number):void
        {
            if (scale != n)
            {
                var needsStop:Boolean = false;
                if (!zooming) {
                    prepareForZooming();
                    needsStop = true;
                }
                
                var sc:Number = n / scale;
                worldMatrix.translate(-mapWidth/2, -mapHeight/2);
                worldMatrix.scale(sc, sc);
                worldMatrix.translate(mapWidth/2, mapHeight/2);
                
                dirty = true;   
                
                if (needsStop) {
                    doneZooming();
                }
            }
        }
                
        public function resizeTo(p:Point):void
        {
            if (mapWidth != p.x || mapHeight != p.y)
            {
                var dx:Number = p.x - mapWidth;
                var dy:Number = p.y - mapHeight;
                
                // maintain the center point:
                tx += dx/2;
                ty += dy/2;
                
                mapWidth = p.x;
                mapHeight = p.y;
                clipRect = new Rectangle(0, 0, mapWidth, mapHeight);
                bgTouchArea.setSize(mapWidth, mapHeight);

                //NOTE_TEC: not porting DebugField for now at least...
                // debugField.x = mapWidth - debugField.width - 15; 
                // debugField.y = mapHeight - debugField.height - 15;
                
                dirty = true;

                // force this but only for onResize
                _onRender();
            }
        }
        
        public function setMapProvider(provider:IMapProvider):void
        {
            if (provider is ITilePainterOverride) {
                this.tilePainter = ITilePainterOverride(provider).getTilePainter();
            }
            else {
                this.tilePainter = new TilePainter(this, provider, MaxParentLoad == 0 ? centerDistanceCompare : zoomThenCenterCompare);
            }
            tilePainter.getOnTileLoad() += onTileLoading;
            
            // TODO: set limits independently of provider
            this.limits = provider.outerLimits();

            _tileWidth = provider.tileWidth;
            _tileHeight = provider.tileHeight;
            
            calculateBounds();
            
            clearEverything();
        }
        
        protected function clearEverything(event:Event=null):void
        {
            while (well.numChildren > 0) {
                wellRemove(well.getChildAtUnsafe(well.numChildren-1) as Tile);
            }
            wellTiles.clear();

            tilePainter.reset();
                        
            recentlySeen = [];
                        
            dirty = true;
        }

        private var _tileScales:Vector.<Number> = [];
        protected function calculateBounds():void
        {
            var tl:Coordinate = limits[0] as Coordinate;
            var br:Coordinate = limits[1] as Coordinate;

            _maxZoom = Math.max2(tl.zoom, br.zoom);  
            _minZoom = Math.min2(tl.zoom, br.zoom);
            
            //pre-create this work vector whenever _maxZoom changes
            _tileScales = new Vector.<Number>(_maxZoom + 1);          

            tl = tl.zoomTo(0);
            br = br.zoomTo(0);
            
            minTx = tl.column * tileWidth;
            maxTx = br.column * tileWidth;

            minTy = tl.row * tileHeight;
            maxTy = br.row * tileHeight;
        }
        
        /** this may seem like a heavy function, but it only gets called once per render 
         *  and it doesn't have any loops, so it flies by, really */
        public function enforceBoundsOnMatrix(matrix:Matrix):Boolean
        {
            var touched:Boolean = false;

            // first check that we're not zoomed in too close...
            
            var matrixScale:Number = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
            var matrixZoomLevel:Number = Math.log(matrixScale) * InvLN2;

            if (matrixZoomLevel < minZoom || matrixZoomLevel > maxZoom) {
                var oldScale:Number = matrixScale; 
                matrixZoomLevel = Math.max2(minZoom, Math.min2(matrixZoomLevel, maxZoom));
                matrixScale = Math.pow(2, matrixZoomLevel);
                var scaleFactor:Number = matrixScale / oldScale;
                matrix.scale(scaleFactor, scaleFactor);
                touched = true;
            }

            // then make sure we haven't gone too far...
            var inverse:Matrix = new Matrix();
            inverse.copyFrom(worldMatrix);          
            inverse.invert();
            inverse.scale(matrixScale/tileWidth, matrixScale/tileHeight);
            
            // zoom topLeft and bottomRight coords to 0
            // so that they can be compared against minTx etc.
            
            var topLeftPoint:Point = inverse.transformCoord(0,0);
            var topLeft:Coordinate = new Coordinate(topLeftPoint.y, topLeftPoint.x, matrixZoomLevel).zoomTo(0);

            var bottomRightPoint:Point = inverse.transformCoord(mapWidth, mapHeight);
            var bottomRight:Coordinate = new Coordinate(bottomRightPoint.y, bottomRightPoint.x, matrixZoomLevel).zoomTo(0);
            
            // apply horizontal constraints
            
            var leftX:Number = topLeft.column * tileWidth;
            var rightX:Number = bottomRight.column * tileWidth;
            
            if (rightX-leftX > maxTx-minTx) {
                // if we're wider than the map, center align 
                matrix.tx = (mapWidth-(minTx+maxTx)*matrixScale)/2;
                touched = true;
            }
            else if (leftX < minTx) {
                matrix.tx += (leftX-minTx)*matrixScale;
                touched = true;
            }
            else if (rightX > maxTx) {
                matrix.tx += (rightX-maxTx)*matrixScale;
                touched = true;
            }

            // apply vertical constraints

            var upY:Number = topLeft.row * tileHeight;
            var downY:Number = bottomRight.row * tileHeight;

            if (downY-upY > maxTy-minTy) {
                // if we're taller than the map, center align                   
                matrix.ty = (mapHeight-(minTy+maxTy)*matrixScale)/2;
                touched = true;
            }
            else if (upY < minTy) {
                matrix.ty += (upY-minTy)*matrixScale;
                touched = true;
            }
            else if (downY > maxTy) {
                matrix.ty += (downY-maxTy)*matrixScale;
                touched = true;
            }

            return touched;         
        }
        
        /** called inside of onRender before events are fired
         *  enforceBoundsOnMatrix modifies worldMatrix directly
         *  doesn't use scale/zoomLevel setters to correct values otherwise we'd get stuck in a loop! */
        protected function enforceBounds():Boolean
        {
            if (!EnforceBoundsEnabled) {
                return false;
            }
            
            var touched:Boolean = enforceBoundsOnMatrix(worldMatrix);

            /*          
            this is potentially the way to wrap the x position
            but all the tiles flash and the values aren't quite right
            so wrapping the matrix needs more work :(
            
            var wrapTx:Number = 256 * scale;
            
            if (worldMatrix.tx > 0) {
                worldMatrix.tx = worldMatrix.tx - wrapTx; 
            }
            else if (worldMatrix.tx < -wrapTx) {
                worldMatrix.tx += wrapTx; 
            } */

            // to make sure we haven't gone too far
            // zoom topLeft and bottomRight coords to 0
            // so that they can be compared against minTx etc.
            
            if (touched) {
                _coordinatesDirty = true;
                _invertedMatrixDirty = true;
            }

            return touched;         
        }
        
        protected function set dirty(d:Boolean):void
        {
            _dirty = d;
            if (d) {
                _coordinatesDirty = true;
                _invertedMatrixDirty = true;
            }
        }
        
        protected function get dirty():Boolean
        {
            return _dirty;
        }


        public function getMatrix():Matrix
        {
            var m:Matrix = new Matrix();
            m.copyFrom(worldMatrix);
            return m;
        }

        public function setMatrix(m:Matrix):void
        {
            worldMatrix = m;
            matrixChanged = true;
            dirty = true;
        }
        
        public function get a():Number
        {
            return worldMatrix.a;
        }
        public function get b():Number
        {
            return worldMatrix.b;
        }
        public function get c():Number
        {
            return worldMatrix.c;
        }
        public function get d():Number
        {
            return worldMatrix.d;
        }
        public function get tx():Number
        {
            return worldMatrix.tx;
        }
        public function get ty():Number
        {
            return worldMatrix.ty;
        }

        public function set a(n:Number):void
        {
            worldMatrix.a = n;
            dirty = true;
        }
        public function set b(n:Number):void
        {
            worldMatrix.b = n;
            dirty = true;
        }
        public function set c(n:Number):void
        {
            worldMatrix.c = n;
            dirty = true;
        }
        public function set d(n:Number):void
        {
            worldMatrix.d = n;
            dirty = true;
        }
        public function set tx(n:Number):void
        {
            worldMatrix.tx = n;
            dirty = true;
        }
        public function set ty(n:Number):void
        {
            worldMatrix.ty = n;
            dirty = true;
        }
                                
    }
    


    //NOTE_TEC: not porting DebugField for now at least...
    // import loom.modestmaps.core.Tile;
    // import flash.text.TextFormat;
    // import flash.system.System;

    // class DebugField extends TextField
    // {
    //  // for stats:
    //  protected var lastFrameTime:Number;
    //  protected var fps:Number = 30;  

    //  public function DebugField():void
    //  {
    //      defaultTextFormat = new TextFormat(null, 12, 0x000000, false);
    //      backgroundColor = 0xffffff;
    //      background = true;
    //      text = "messages";
    //      name = 'debugField';
    //      mouseEnabled = false;
    //      selectable = false;
    //      multiline = true;
    //      wordWrap = false;
            
    //      lastFrameTime = getTimer();
    //  }
        
    //  public function update(grid:TileGrid, blankCount:int, recentCount:int, tilePainter:ITilePainter):void
    //  {
    //      // for stats...
    //      var frameDuration:Number = getTimer() - lastFrameTime;
            
    //      lastFrameTime = getTimer();
            
    //      fps = (0.9 * fps) + (0.1 * (1000.0/frameDuration));

    //      var well:Sprite = grid.getChildByName('well') as Sprite;

    //      // report stats:
    //      var tileChildren:int = 0;
    //      for (var i:int = 0; i < well.numChildren; i++) {
    //          tileChildren += Tile(well.getChildAt(i)).numChildren;
    //      }
            
    //      this.text = "tx: " + grid.tx.toFixed(3)
    //              + "\nty: " + grid.ty.toFixed(3)
    //              + "\nsc: " + grid.scale.toFixed(4)
    //              + "\nfps: " + fps.toFixed(0)
    //              + "\ncurrent child count: " + well.numChildren
    //              + "\ncurrent child of tile count: " + tileChildren
    //              + "\nvisible tile count: " + grid.getVisibleTiles().length
    //              + "\nblank count: " + blankCount
    //              + "\nrecently used tiles: " + recentCount
    //              + "\ntiles created: " + Tile.count
    //              + "\nqueue length: " + tilePainter.getQueueCount()
    //              + "\nrequests: " + tilePainter.getRequestCount()
    //              + "\nfinished (cached) tiles: " + tilePainter.getCacheSize()
    //          //  + "\nmemory: " + (System.totalMemory/1048576).toFixed(1) + "MB"; 
    //      width = textWidth+8;
    //      height = textHeight+4;
    //  }   
    // }
}