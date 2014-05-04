package loom2d.math 
{
    /**
     * 2D Point structure which has useful utility methods and is assign by value.
     */
    public struct Point 
    {        

        // note that we need to new here as the default args
        // won't be setup as we're in the static initializer
        public static var ZERO:Point = new Point(0, 0);

        /**
         * Direct access to the x and y components of the Point.
         */
        public var x:Number, y:Number;        

        /**
         * Constructor for Point with optional components.
         */
        public function Point(_x:Number = 0, _y:Number = 0)
        {
            x = _x;
            y = _y;
        }

        /**
         * Clones this Point to a new one.
         */
        public function clone():Point
        {
            return new Point(x, y);
        }

        /**
         * Returns a string representation of the Point.
         */
        public function toString():String
        {
            return "[Point " + x + ", " + y + "]";
        }

        /**
         * Gets the length defined by the Point.
         */
        public function get length():Number
        {
            return Math.sqrt(x*x + y*y);
        }

        /**
         * Gets the length^2 defined by the Point.
         */
        public function get lengthSquared():Number
        {
            return x*x + y*y;
        }

        /**
         * Checks whether the Point is numerically equal to another Point.
         */        
        public function equals(p:Point):Boolean
        {
            if (x != p.x)
                return false;
            if (y != p.y)
                return false;
            return true;
        }

        /**
         * Normalizes the Point to a specified length.
         */        
        public function normalize(thickness:Number = 1):void
        {
            var oldLength = this.length;
            if (oldLength == 0) return;
            
            var thickNessOverLength = thickness / oldLength;
            x *= thickNessOverLength;
            y *= thickNessOverLength;
        }

        /**
         * Offsets the point by the given delta values.
         */
        public function offset(dx:Number, dy:Number):void
        {
            x += dx;
            y += dy;
        }

        /**
         * Scales the point by the given Scalar.
         */
        public function scale(s:Number):void
        {
            x *= s;
            y *= s;
        }

        /**
         * Subtracts the supplied Point from this Point.
         */
        public function subtract(other:Point):Point
        {
            return this - other;
        }

        /**
         * Adds the supplied Point to this Point.
         */
        public function add(other:Point):Point
        {
            return this + other;
        }

        /**
         * Assigns p2 to p1 and returns p1 (required by struct types).
         */
        public static operator function =(p1:Point, p2:Point):Point
        {
            p1.x = p2.x;
            p1.y = p2.y;
            return p1;
        }

        /**
         * Adds Point p2 to Point p1 and returns p1.
         */
        public static operator function +(p1:Point, p2:Point):Point
        {
            tempPoint.x = p1.x + p2.x;
            tempPoint.y = p1.y + p2.y;
            return tempPoint;
        }    

        /**
         * Adds Point p to this Point.
         */
        public operator function +=(p:Point):void
        {
            x += p.x;
            y += p.y;
        }

        /**
         * Subtracts Point p2 from Point p1 and returns the result.
         */
        public static operator function -(p1:Point, p2:Point):Point
        {
            tempPoint.x = p1.x - p2.x;
            tempPoint.y = p1.y - p2.y;
            return tempPoint;
        }    

        /**
         * Subtracts Point p from this Point.
         */
        public operator function -=(p:Point):void
        {
            x -= p.x;
            y -= p.y;
        }
     

        /**
         * Multiplies This point by the scalar s.
         */
        public operator function *=(s:Number):void
        {
            x *= s;
            y *= s;
        }
        

        /**
         * Divides This point by the scalar s.
         */
        public operator function /=(s:Number):void
        {
            var invS = 1.0 / s;
            x *= invS;
            y *= invS;
        }
    
        /**
         * Gets the distance between two Points.
         */
        public static function distance(p1:Point, p2:Point):Number
        {
            return Math.sqrt(Point.distanceSquared(p1, p2));
        }

        /**
         * Gets the distance squared between two Points.
         */
        public static function distanceSquared(p1:Point, p2:Point):Number
        {
            var dx = p2.x - p1.x;
            var dy = p2.y - p1.y;
            return dx*dx + dy*dy;
        }

        /**
         * Interpolates 2 points returning a new point at the specified time.
         */
        public static function interpolate(p1:Point, p2:Point, t:Number):Point
        {
            tempPoint.x = p2.x + ((1-t) * (p1.x - p2.x));
            tempPoint.y = p2.y + ((1-t) * (p1.y - p2.y));
            return tempPoint;
        }

        /**
         * Returns the dot product between p1 and p2, as though they were Vectors
         */
        public static function dot(p1:Point, p2:Point):Number
        {
            return (p1.x * p2.x) + (p1.y * p2.y);
        }

        /**
         * Gets a polar Point given an angle and length.
         */         
        public static function polar(len:Number, angle:Number):Point
        {
            tempPoint.x = len * Math.cos(angle);
            tempPoint.y = len * Math.sin(angle);
            return tempPoint;
        }

        /**
         * Private return point for operations.
         */
        private static var tempPoint:Point;

    }
}
