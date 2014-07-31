package game {
    import FloodIt;
    import loom2d.animation.Transitions;
    import loom2d.display.Sprite;
    import loom2d.math.Point;
    
    import loom2d.Loom2D;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.math.Color;
        
    
    public class ColorTile extends Sprite
    {
        public var tileX:int, tileY:int;
        public var visited:int = 0;
        public var counter:int = 0;
        
        protected var type:TileType;
        protected var previous:Image;
        protected var current:Image;
        protected var currentColor:uint;

        public function ColorTile(tileX:int, tileY:int)
        {
            super();
            previous = new Image();
            addChild(previous);
            current = new Image();
            addChild(current);
            
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
            return type.index;
        }
        
        protected function resize(image:Image)
        {
            image.scale = 2;
            //image.width = 128;
            //image.height = 128;
            image.center();
            image.x = image.width/2;
            image.y = image.height/2;
        }
        
        public function paint(type:TileType, delay:Number = 0):void
        {
            this.type = type;
            
            if (current.texture) {
                previous.texture = current.texture;
                //previous.width = 128;
                //previous.height = 128;
                //previous.center();
                resize(previous);
                previous.color = currentColor;
                current.alpha = 0;
                //current.scale = 0.6;
            }
            
            current.texture = type.texture;
            resize(current);
            //current.width = 128;
            //current.height = 128;
            //current.center();
            //setTexCoords(0, new Point(0, 0));
            //setTexCoords(1, new Point(0, 1));
            //setTexCoords(2, new Point(1, 1));
            //setTexCoords(3, new Point(1, 0));
            
            currentColor = type.color;
            
            var goalColor = Color.fromInt(currentColor);
            
            Loom2D.juggler.tween(previous, 1, { "delay": delay*5, "scale": 0.6, "transition": Transitions.EASE_OUT } );
            Loom2D.juggler.tween(current, 0.0, { "delay": delay*5+1.5, "alpha": 1, "scale": 0.6 } );
            Loom2D.juggler.tween(current, 1.0, { "delay": delay*5+2, "scale": 2, "transition": Transitions.EASE_OUT_BACK } );
            
            //current.scale = 0;
            //Loom2D.juggler.tween(current, 1, { "delay": delay*0.2, "scale": 1, "transition": Transitions.EASE_IN_OUT_BACK } );
            
            //Loom2D.juggler.tween(current, 0.2, { "delay": delay, "alpha": 1, "r": goalColor.red, "g": goalColor.green, "b": goalColor.blue } );
            current.color = currentColor;
            //Loom2D.juggler.tween(current, 2, { "delay": delay*5, "alpha": 1, "transition": Transitions.EASE_IN_OUT } );
        }
        
        override public function toString():String
        {
            return colorIndex.toString();
        }
    } 
}