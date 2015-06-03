/*
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 */

package loom.modestmaps.core
{
    import loom.modestmaps.core.TileGrid;
    import loom.modestmaps.ModestMaps;
    import system.platform.Platform;

    import loom2d.display.DisplayObject;
    import loom2d.display.Sprite;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    
    
    public class Tile extends Sprite
    {
        // not a coordinate, because it's very important these are ints
        public var zoom:int;
        public var row:int;
        public var column:int;
        public var inWell:Boolean;
        public var isVisible:Boolean;
        public var lastRepop:int;
        public var count:int;
        public var token:int;
        
        public var nextActive:Tile;

        protected var assignedTextures:Vector.<Texture> = [];

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
            this.zoom = zoom;
            this.row = row;
            this.column = column;  
            inWell = false;
            isVisible = false;
            count = 1;
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
                    tex.dispose();
                    textureRefs.deleteKey(tex);
                } else if (refs < 0) {
                    trace("Texture reference should be 0 or greater");
                }
            }
            assignedTextures.clear();

            //dispose all child Images
            while (numChildren > 0) {
                var child:DisplayObject = removeChildAt(0);
                
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
        
        public function isShowing():Boolean
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
            trace("ERROR setting a texture for this tile!");
        }

        public function toString():String
        {
            return "(" + column + ", " + row + ", " + zoom + ")";
        }
    }
}
