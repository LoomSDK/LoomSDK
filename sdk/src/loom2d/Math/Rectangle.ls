package loom2d.math 
{
    
    /**
     * A basic Rectangle class.
     */
    final public native class Rectangle 
    {

        public native function Rectangle(_x:Number=0, _y:Number=0, _width:Number=0, _height:Number=0);        
        
        public native function set x(value:float);
        public native function get x():float;

        public native function set y(value:float);
        public native function get y():float;

        public native function set width(value:float);
        public native function get width():float;

        public native function set height(value:float);
        public native function get height():float;
        
        public native function get minX():Number;
        
        public native function get maxX():Number;
        
        public native function get minY():Number;
        
        public native function get maxY():Number;
        
        public native function get top():Number;

        public native function get bottom ():Number;
        
        public native function get left():Number;
        
        public native function get right():Number;
       
        /**
         * If p is outside of the rectangle's current bounds, expand it to include p.
         */
        public native function expandByPoint(p:Point):void;
        
        /**
         * Returns true if p is inside the bounds of this rectangle.
         */
        public native function containsPoint(p:Point):Boolean;
        
        /**
         * Returns true if x and y is inside the bounds of this rectangle.
         */
        public native function contains(_x:Number, _y:Number):Boolean;
        
        /**
         * Returns true if rect is entirely inside of this rectangle is inside the bounds of this rectangle.
         */
        public native function containsRect(rect:Rectangle):Boolean;

        /**
         * Assign the x,y,width,height of this rectangle.
         */
        public native function setTo(_x:Number, _y:Number, _width:Number, _height:Number):void;

        public native function toString():String;
        
        /**
         * Make a copy of this Rectangle.
         */
        public native function clone():Rectangle;

        /**
         * Returns true if any part of the two rectangles overlaps.
         */
        public static function intersects(rect1:Rectangle, rect2:Rectangle):Boolean
        {
            if (rect1.right < rect2.left) return false; // 1 is left of 2
            if (rect1.left > rect2.right) return false; // 1 is right of 2
            if (rect1.bottom < rect2.top) return false; // 1 is above 2
            if (rect1.top > rect2.bottom) return false; // 1 is below 2
            return true;
        }
    }
    
}
