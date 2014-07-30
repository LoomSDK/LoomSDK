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
        
        public function reset():void
        {
            visited = 0;
            Loom2D.juggler.removeTweens(this);
        }
        
        public function get colorIndex():int
        {
            return _colorIndex;
        }
        
        public function paint(color:int, delay:Number = 0):void
        {
            _colorIndex = color;
            
            var goalColor = Color.fromInt(FloodIt.colors[colorIndex]);
            
            Loom2D.juggler.tween(this, 0.2, { "delay": delay, "r": goalColor.red, "g": goalColor.green, "b": goalColor.blue } );
        }
        
        override public function toString():String
        {
            return colorIndex.toString();
        }
    } 
}