package loom2d.math 
{
    /**
     * 2D Affine Transform.
     * 
     * Matrix represents 2D affine transforms.
     */
    final public native class Matrix 
    {

        private static var sHelperPoint:Point;

        public native function set a(value:float);
        public native function get a():float;

        public native function set b(value:float);
        public native function get b():float;

        public native function set c(value:float);
        public native function get c():float;

        public native function set d(value:float);
        public native function get d():float;

        public native function set tx(value:float);
        public native function get tx():float;

        public native function set ty(value:float);
        public native function get ty():float;

        /**
         * Static Identity matrix for general use
        */
        public static const IDENTITY:Matrix = new Matrix(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
        
        
        public native function Matrix(_a:Number = 1.0, _b:Number = 0.0, 
                                _c:Number = 0.0, _d:Number = 1.0, 
                                _tx:Number = 0.0, _ty:Number = 0.0);
        
        /**
         * Append a skew transform to this matrix.
         */
        public native function skew(xSkew:Number, ySkew:Number):void;
        
        /**
         * Transform a coordinate by this matrix, returning the result in a Point.
         * @param   x X coordinate to transform.
         * @param   y Y coordinate to transform.
         * @param   outPoint If provided, this point is reused rather than allocating a new one.
         * @return  A Point containing the transformed point (x, y).
         */
        public native function transformCoord(x:Number, y:Number):Point;

        /**
         * Calculate the determinant of this matrix.
         */
        public native function determinant():Number;

        /**
         * Invert this matrix.
         */
        public native function invert():void;
        
        /**
         * Reset this matrix to be an identity transformation.
         */
        public native function identity():void;
        
        /**
         * Utility to set the values of the matrix.
         */
        public native function setTo(_a:Number, _b:Number, _c:Number, _d:Number, _tx:Number, _ty:Number):void;
        
        /**
         * Make this matrix match another matrix.
         * @param   other Matrix to match.
         */
        public native function copyFrom(other:Matrix):void;
        
        /**
         * Append a scale transformation to this matrix.
         */
        public native function scale(sx:Number, sy:Number):void;
        
        /**
         * Concatenate this matrix with another one.
         */
        public native function concat(m:Matrix):void;
        
        /**
         * Apply a rotation transform to this matrix.
         */
        public native function rotate(angle:Number):void;
        
        /**
         * Apply a translation transform to this matrix.
         */
        public native function translate(dx:Number, dy:Number):void;
        
        public native function toString():String;
    }
    
}