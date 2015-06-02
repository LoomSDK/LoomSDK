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

        protected var assignedTextures:Vector.<Texture> = [];

        protected static var textureRefs:Dictionary.<Texture, int> = {};
        protected static var imagePool:Vector.<Image> = null;


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
            this.zoom = zoom;
            this.row = row;
            this.column = column;  
            inWell = false;
            isVisible = false;
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
                textureRefs[tex]--;
                if(textureRefs[tex] == 0)
                {
                    tex.dispose();
                    textureRefs.deleteKey(tex);
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
            //create the pool if we need to
            if((imagePool == null) || (imagePool.length == 0))
            {
                imagePool = new Vector.<Image>(TileGrid.MaxTilesToKeep * 2);
                for(var i=0;i<imagePool.length;i++)
                {
                    imagePool[i] = new Image(null);
                }
            }
            
            //create an image for the newly loaded texture and add it to the tile
            var img:Image = imagePool.pop();
            img.texture = texture;
            addChild(img, false);

            //texture ref counter
            if(textureRefs[texture] == null)
            {
                textureRefs[texture] = 0;
            }
            textureRefs[texture]++;

            //store texture in a vector so we can track all of them
            assignedTextures.pushSingle(texture);
            return img;
        }
        
        public function isShowing():Boolean
        {
            return this.alpha == 1.0;
        }
        
        public function showNow():void
        {
            this.alpha = 1.0;
        }
        
        public function show():void 
        {
            this.alpha = 1.0;
            // if you want to do something when the tile is ready then override this method
        }
        
        public function hide():void
        {
            this.alpha = 0.0;
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
