/*
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 */

package loom.modestmaps.core
{
    import loom.modestmaps.core.painter.TilePainter;
    import loom.modestmaps.core.TileGrid;
    import loom.modestmaps.ModestMaps;
    import system.platform.Platform;

    import loom2d.display.DisplayObject;
    import loom2d.display.Sprite;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    
    public class QuadNode {
        
        public static var pool:QuadNode;
        public static var poolCount:int = 0;
        public var poolNext:QuadNode = null;
        
        /** Only counted on the root node for now */
        public var descendants:int = 0;
        public var root:QuadNode = null;
        public var parent:QuadNode = null;
        public var child:int = -1;
        public var col:int = 0;
        public var row:int = 0;
        public var zoom:int = 0;
        public var a:QuadNode;
        public var b:QuadNode;
        public var c:QuadNode;
        public var d:QuadNode;
        
        public var tile:Tile;
        
        //public var _tile:Tile;
        //public function set tile(v:Tile) { trace(v); _tile = v; }
        //public function get tile():Tile { return _tile; }
        
        public function QuadNode() {}
        
        public function reset(root:QuadNode, parent:QuadNode, child:int, col:int, row:int, zoom:int)
        {
            if (this.root) destroy();
            if (root) root.descendants++;
            this.root = root;
            this.parent = parent;
            this.child = child;
            this.col = col;
            this.row = row;
            this.zoom = zoom;
        }
        
        public static function create(root:QuadNode, parent:QuadNode, child:int, col:int, row:int, zoom:int):QuadNode
        {
            var node:QuadNode = null;
            if (pool) {
                node = pool;
                pool = pool.poolNext;
                poolCount--;
            }
            if (!node) node = new QuadNode();
            node.reset(root, parent, child, col, row, zoom);
            return node;
        }
        
        public function isPrunable():Boolean
        {
            return root && !a && !b && !c && !d && !tile;
        }
        
        public function destroy()
        {
            Debug.assert(root, "Invalid node, missing root, already destroyed?");
            Debug.assert(!a && !b && !c && !d, "Destroying a node with children currently unsupported");
            Debug.assert(!tile, "Destroying a node with an existing tile currently unsupported");
            root.descendants--;
            switch (child) {
                case 0: parent.a = null; break;
                case 1: parent.b = null; break;
                case 2: parent.c = null; break;
                case 3: parent.d = null; break;
            }
            root = null;
            parent = null;
            child = -1;
            col = -1;
            row = -1;
            zoom = -1;
            
            poolNext = pool;
            pool = this;
            poolCount++;
        }
        
        /*
        static public function classify(col:int, row:int, zoomDiff:int):int
        {
            var scaleFactor:int = 1 << zoomDiff;
            var invScaleFactor = 1.0 / scaleFactor;
            var scaledCol = col * invScaleFactor;
            var scaledRow = row * invScaleFactor;
            var targetCol = Math.floor(scaledCol); 
            var targetRow = Math.floor(scaledRow);
            trace("  ", col, row, scaledCol, scaledRow, targetCol, targetRow, Math.ceil(scaledCol - targetCol), Math.ceil(scaledRow - targetRow));
            var targetChild = Math.ceil(scaledCol - targetCol) + Math.ceil(scaledRow - targetRow)*2;
            return targetChild;
        }
        */
        /*
        static public function getNode(root:QuadNode, col:int, row:int, inzoom:int):QuadNode
        {
            var node = root;
            //trace("getnode");
            //trace(col, row, inzoom);
            //trace(col, row, inzoom);
            for (var z:int = 0; z < inzoom; z++) {
                node.ensureChildren();
                var child = classify(col, row, inzoom-z);
                trace(z, child);
                //trace("  ", col, row, inzoom-z, child);
                switch (child) {
                    case 0: node = node.a; break;
                    case 1: node = node.b; break;
                    case 2: node = node.c; break;
                    case 3: node = node.d; break;
                }
            }
            trace("getnode", col, row, inzoom, node.zoom, node.tile);
            //Debug.assert(false);
            return node;
        }
        */
        
        public function classify(childCol:int, childRow:int, childZoom:int):int
        {
            var zoomDelta = childZoom-zoom;
            var localCol = (col + 0.5) * (1 << zoomDelta);
            var localRow = (row + 0.5) * (1 << zoomDelta);
            //trace("local ", localCol, localRow, zoomDelta);
            var child = 0;
            if (childCol >= localCol) child++;
            if (childRow >= localRow) child += 2;
            return child;
        }
        
        static public function getNode(root:QuadNode, col:int, row:int, inzoom:int):QuadNode
        {
            var node = root;
            //trace("getnode");
            //trace(col, row, inzoom);
            //trace(col, row, inzoom);
            for (var z:int = 0; z < inzoom; z++) {
                node.ensureChildren(root);
                var child = node.classify(col, row, inzoom);
                //trace(z, child);
                //trace("  ", col, row, inzoom-z, child);
                switch (child) {
                    case 0: node = node.a; break;
                    case 1: node = node.b; break;
                    case 2: node = node.c; break;
                    case 3: node = node.d; break;
                }
            }
            node.ensureChildren(root);
            //trace("getnode", col, row, inzoom, node.zoom, node.tile);
            //Debug.assert(false);
            return node;
        }
        
        public function get aTile():Tile { return a ? a.tile : null; }
        public function get bTile():Tile { return b ? b.tile : null; }
        public function get cTile():Tile { return c ? c.tile : null; }
        public function get dTile():Tile { return d ? d.tile : null; }
        
        private function ensureChildren(root:QuadNode) {
            if (!a) a = QuadNode.create(root, this, 0, col*2+0, row*2+0, zoom+1);
            if (!b) b = QuadNode.create(root, this, 1, col*2+1, row*2+0, zoom+1);
            if (!c) c = QuadNode.create(root, this, 2, col*2+0, row*2+1, zoom+1);
            if (!d) d = QuadNode.create(root, this, 3, col*2+1, row*2+1, zoom+1);
        }
    }
    
    public class Tile extends Sprite
    {
        // not a coordinate, because it's very important these are ints
        public var zoom:int;
        public var row:int;
        public var column:int;
        public var inWell:Boolean;
        public var isVisible:Boolean;
        public var isPainting:Boolean;
        public var isPainted:Boolean;
        public var lastRepop:int;
        public var visToken:int;
        
        public var nextActive:Tile;
        public var prevActive:Tile;
        public var nextInactive:Tile;
        public var prevInactive:Tile;
        
        public var nextQueue:Tile;
        public var prevQueue:Tile;
        
        public var urls:Vector.<String>;
        public var openRequests:int;
        public var lastLoad:int = -1;
        
        public var quadNode:QuadNode;
        
        public var loadStatus:String;
        public var loadPriority:Number;
    
        public var assignedTextures:Vector.<Texture> = [];

        protected static var textureRefs:Dictionary.<Texture, int> = {};
        protected static var imagePool = new Vector.<Image>();
        

        public function Tile(column:int, row:int, zoom:int)
        {
            init(column, row, zoom);
        }
        
        public function updateRepop() {
            lastRepop = Platform.getTime();
        }
        
        /** override this in a subclass and call grid.setTileCreator if you want to draw on your tiles */
        public function init(column:int, row:int, zoom:int):void
        {
            Debug.assert(!nextActive);
            Debug.assert(!nextInactive);
            Debug.assert(!prevActive);
            Debug.assert(!prevInactive);
            Debug.assert(!nextQueue);
            Debug.assert(!prevQueue);
            this.zoom = zoom;
            this.depth = zoom;
            this.row = row;
            this.column = column;  
            inWell = false;
            isVisible = false;
            isPainting = false;
            isPainted = false;
            quadNode = null;
            loadStatus = "";
            openRequests = 0;
            hide();
        }        

        /** once TileGrid is done with a tile, it will call destroy and possibly reuse it later */
        public function destroy():void
        {
            //clean up all textures
            for(var i=0;i<assignedTextures.length;i++)
            {
                //texture ref counter
                var tex:Texture = assignedTextures[i];
                var refs = textureRefs[tex];
                refs--;
                textureRefs[tex] = refs;
                if(refs == 0)
                {
                    TilePainter.returnTexture(tex);
                    textureRefs.deleteKey(tex);
                } else if (refs < 0) {
                    trace("Texture reference should be 0 or greater");
                }
            }
            assignedTextures.clear();

            //dispose all child Images
            while (numChildren > 0) {
                var child:DisplayObject = removeChildAt(0, false, false);
                
                //dispose the image data
                if(child is Image)
                {
                    imagePool.pushSingle(child as Image);
                }
            }
        }

        public function assignTexture(texture:Texture):Image
        {
            var img:Image;
            
            img = imagePool.length > 0 ? imagePool.pop() : new Image();
            
            //create an image for the newly loaded texture and add it to the tile
            img.texture = texture;
            addChild(img, false);
            
            //texture ref counter
            var refs = textureRefs[texture];
            if (!refs) refs = 0;
            textureRefs[texture] = refs+1;

            //store texture in a vector so we can track all of them
            assignedTextures.pushSingle(texture);
            return img;
        }
        
        public function get isShowing():Boolean
        {
            return this.visible;
        }
        
        public function showNow():void
        {
            this.visible = true;
        }
        
        public function show():void 
        {
            this.visible = true;
            // if you want to do something when the tile is ready then override this method
        }
        
        public function hide():void
        {
            this.visible = false;
        }
        
        public function paintError(w:Number=256, h:Number=256):void
        {
            //TODO_TEC: Show an error visually for this tile... display an X texture or something?
            //trace("ERROR setting a texture for this tile!");
        }

        public function toString():String
        {
            return "(" + column + ", " + row + ", " + zoom + ")";
        }
    }
}
