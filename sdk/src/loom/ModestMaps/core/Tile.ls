/*
 * vim:et sts=4 sw=4 cindent:
 * $Id$
 */

package com.modestmaps.core
{
	import loom2d.display.DisplayObject;
    import loom2d.display.Sprite;
    import loom2d.display.Image;
	import loom2d.textures.Texture;
	
	
	public class Tile extends Sprite
	{		
		public static var count:int = 0;
		
		// not a coordinate, because it's very important these are ints
		public var zoom:int;
		public var row:int;
		public var column:int;

        protected var requestedTextures:Vector.<Texture> = [];
        protected var assignedTextures:Vector.<Texture> = [];
				

		public function Tile(column:int, row:int, zoom:int)
		{
			init(column, row, zoom);
						
			count++;
		} 
		
		/** override this in a subclass and call grid.setTileCreator if you want to draw on your tiles */
	    public function init(column:int, row:int, zoom:int):void
	    {
			this.zoom = zoom;
			this.row = row;
			this.column = column;			
			hide();
	    }        

		/** once TileGrid is done with a tile, it will call destroy and possibly reuse it later */
	    public function destroy():void
	    {
return;            
//TODO_24: not working!!! If this happens, our updates of new tile image requests seem to stop... :/            
	    	while (numChildren > 0) {
	    		var child:DisplayObject = removeChildAt(0);
				
                //dispose the image data
                if(child is Image)
                {
                    child.dispose();
                }
            }

            //clean up all textures
            var i:int;
            for(i=0;i<requestedTextures.length;i++)
            {
                requestedTextures[i].cancelHTTPRequest();
            }
            for(i=0;i<assignedTextures.length;i++)
            {
//TODO_24: Need a ref counter to be safe... static for all tiles as it seems sometimes tiles share textures?... :/                
                assignedTextures[i].dispose();
            }
            assignedTextures.clear();
            requestedTextures.clear();
	    }

        public function requestTexture(texture:Texture):void
        {
            //store texture in a vector so we can track all of them
            requestedTextures.pushSingle(texture);
        }

        public function assignTexture(texture:Texture):void
        {
            //create an image for the newly loaded texture and add it to the tile
            var img:Image = new Image(texture);                    
            addChild(img);

            //make sure it's not in our requested list still
            requestedTextures.remove(texture);

            //store texture in a vector so we can track all of them
            assignedTextures.pushSingle(texture);
        }

        public function isUsingTexture(texture:Texture):Boolean
        {
            return (assignedTextures.contains(texture) || requestedTextures.contains(texture)) ? true : false;
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
		    // length of 'X' side, padding from edge, weight of 'X' symbol
		    var size:uint = 32;
		    var padding:uint = 4;
		    var weight:uint = 4;
//LUKE_SAYS: Might not be needed.... this just paints some design on the tile, so rather just add a custom image instead
		    /*with (graphics)
			{
				clear();		        
			
				beginFill(0x808080);
				drawRect(0, 0, w, h);

		        moveTo(0, 0);
		        beginFill(0x444444, 1);
		        lineTo(size, 0);
		        lineTo(size, size);
		        lineTo(0, size);
		        lineTo(0, 0);
		        endFill();
		        
		        moveTo(weight+padding, padding);
		        beginFill(0x888888, 1);
		        lineTo(padding, weight+padding);
		        lineTo(size-weight-padding, size-padding);
		        lineTo(size-padding, size-weight-padding);
		        lineTo(weight+padding, padding);
		        endFill();
		        
		        moveTo(size-weight-padding, padding);
		        beginFill(0x888888, 1);
		        lineTo(size-padding, weight+padding);
		        lineTo(weight+padding, size-padding);
		        lineTo(padding, size-weight-padding);
		        lineTo(size-weight-padding, padding);
		        endFill();
		    };*/	
		}
	}
}
