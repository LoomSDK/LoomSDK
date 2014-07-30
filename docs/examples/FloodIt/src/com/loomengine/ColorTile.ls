package com.loomengine.flooder
{
    import FloodIt;
    
    import loom2d.Loom2D;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.math.Color;
        
    
    public class ColorTile extends Image
    {
        public var tileX:int, tileY:int;
        public var visited:int = 0;
        
        protected var _colorIndex:int = -1;

        public function ColorTile(tileX:int, tileY:int)
        {
            super(Texture.fromAsset("assets/tile.png"));
            
            this.tileX = tileX;
            this.tileY = tileY;
        }
        
        public function reset(color:int):void
        {
            visited = 0;
            colorIndex = color;
        }
        
        public function get colorIndex():int
        {
            return _colorIndex;
        }
        
        public function set colorIndex(value:int):void
        {
            var init = _colorIndex == -1;
            _colorIndex = value;
            
            var goalColor = Color.fromInt(FloodIt.colors[colorIndex]);
            
            if (init) {
                color = goalColor.toInt();
            } else {
                Loom2D.juggler.tween(this, 0.2, { "r": goalColor.red, "g": goalColor.green, "b": goalColor.blue } );
            }
        }
        
        override public function toString():String
        {
            return colorIndex.toString();
        }
    } 
}