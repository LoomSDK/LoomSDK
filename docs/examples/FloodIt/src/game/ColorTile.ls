package game {
    import loom2d.animation.Transitions;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    
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
        private var painted = false;
        
        public function ColorTile(tileX:int, tileY:int)
        {
            // Load with a texture initially due to unintended behavior if no texture is set on Image
            previous = new Image(Texture.fromAsset("assets/tiles/tile0.png"));
            addChild(previous);
            current = new Image(Texture.fromAsset("assets/tiles/tile0.png"));
            addChild(current);
            
            // Hide the non-existent previous tile first
            previous.visible = false;
            
            this.tileX = tileX;
            this.tileY = tileY;
        }
        
        public function get image():Image
        {
            return current;
        }
        
        /**
         * Reset the state and stop animation.
         */
        public function reset():void
        {
            visited = 0;
            Loom2D.juggler.removeTweens(this);
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
            current.alpha = 1;
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
            current.alpha = 0;
            current.texture = type.texture;
            resize(current);
            
            // The scale to shrink to mid-animation
            var midScale = 0.2;
            
            // Shrink the previous type
            Loom2D.juggler.tween(previous, 0.5, { delay: delay, scale: midScale, transition: Transitions.EASE_OUT, onComplete: hidePrevious } );
            // Show and bring in the current type
            Loom2D.juggler.delayCall(preshowCurrent, delay+0.1);
            Loom2D.juggler.tween(current, 0.5, { delay: delay+0.11, scale: 1, transition: Transitions.EASE_OUT_BACK } );
            
            current.color = type.color;
        }
        
        override public function toString():String
        {
            return colorIndex.toString();
        }
    } 
}