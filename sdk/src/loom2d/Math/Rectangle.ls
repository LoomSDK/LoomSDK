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
        
        public native function contains(_x:Number, _y:Number):Boolean;

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
            var left:Number   = Math.max2(rect1.x, rect2.x);
            var right:Number  = Math.min2(rect1.x + rect1.width, rect2.x + rect2.width);
            var top:Number    = Math.max2(rect1.y, rect2.y);
            var bottom:Number = Math.min2(rect1.y + rect1.height, rect2.y + rect2.height);

            if (left > right || top > bottom)
                return false;

            return true;
        }        
    }
    
}
