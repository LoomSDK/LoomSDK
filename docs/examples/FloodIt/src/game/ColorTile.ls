package game {
    import loom2d.animation.Transitions;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    import loom2d.ui.TextureAtlasManager;
    
    public class ColorTile extends Sprite
    {
        public var tileX:int, tileY:int;
        
        /**
         * Used for marking when flooding the tiles.
         */
        public var visited:int = 0;
        
        /**
         * Reference to the TileType defining the type of this tile.
         */
        protected var type:TileType;
        
        /**
         * Used for animation purposes, so the previous and current tiles
         * can appear on the board at the same time.
         */
        protected var previous:Image;
        
        /**
         * Image displaying the current tile based on the type.
         */
        protected var current:Image;
        
        /**
         * Marks first-time tile painting.
         */
        private var painted:Boolean;
        
        private var shrinkTween:Dictionary.<Object> = { delay: 0, scale: 0.2, transition: Transitions.EASE_OUT, onComplete: hidePrevious };
        private var showTween:Dictionary.<Object> = { delay: 0, scale: 1, transition: Transitions.EASE_OUT_BACK };
        
        public function ColorTile(tileX:int, tileY:int)
        {
            // Load with a texture initially due to unintended behavior if no texture is set on Image
            previous = new Image(TextureAtlasManager.getTexture("tiles", "tile0.png"));
            addChild(previous);
            current = new Image(TextureAtlasManager.getTexture("tiles", "tile0.png"));
            addChild(current);
            
            this.tileX = tileX;
            this.tileY = tileY;
            
            reset(true);
        }
        
        public function get image():Image
        {
            return current;
        }
        
        /**
         * Reset the state and stop animation.
         */
        public function reset(initial:Boolean = false):void
        {
            visited = 0;
            Loom2D.juggler.removeTweens(this);
            if (initial) {
                // Hide the previous tile
                previous.visible = false;
                painted = false;
                previous.scale = 1;
                current.scale = 1;
            }
        }
        
        public function get colorIndex():int
        {
            return type.index;
        }
        
        /**
         * Position the provided image
         */
        protected function resize(image:Image)
        {
            image.scale = 1;
            image.center();
            image.x = image.width/2;
            image.y = image.height/2;
        }
        
        private function hidePrevious() 
        {
            previous.visible = false;
        }
        
        private function preshowCurrent() 
        {
            current.visible = true;
            current.scale = 0;
        }
        
        public function paint(newType:TileType, delay:Number = 0):void
        {
            var prevColor = type ? type.color : 0;
            
            type = newType;
            
            // Only handle the previous type when it exists
            if (painted) {
                // Setup the previous type for animation
                previous.visible = true;
                previous.texture = current.texture;
                resize(previous);
                previous.color = prevColor;
            } else {
                painted = true;
            }
            
            // Setup the current type for animation
            current.visible = false;
            current.texture = type.texture;
            resize(current);
            
            // Shrink the previous type
            shrinkTween["delay"] = delay;
            Loom2D.juggler.tween(previous, 0.5, shrinkTween);
            // Show and bring in the current type
            Loom2D.juggler.delayCall(preshowCurrent, delay + 0.1);
            showTween["delay"] = delay+0.11;
            Loom2D.juggler.tween(current, 0.5, showTween);
            
            current.color = type.color;
        }
        
        override public function toString():String
        {
            return colorIndex.toString();
        }
    } 
}