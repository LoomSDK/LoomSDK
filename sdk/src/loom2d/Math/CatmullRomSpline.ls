package loom2d.math 
{
    /**
     * A class for doing CatmullRom Spline evaluations
     */
    final public native class CatmullRomSpline 
    {
        private static var sHelperPoint:Point;
        
        /**
         * CatmullRom Spline constructor that takes in the size of the elements 
         * (2 = X,Y Tuple, 3 = X,Y,Z Triple, 4 = X,Y,Z,W Quadruple) to expect.  
         *
         * NOTE: For now, only 2 (Tuple) is supported.
         */
        public native function CatmullRomSpline(_elementSize:int);        
     

        public native function get elementSize():int;
        public native function get splineLength():float;
       
        /**
         * Clears the Spline data to starting values
         */
        public native function clear():void;
        
        /**
         * Adds a new object to the Spline, based on the element size specified for the spline.
         * -Element Size of 2 = Point
         * If 'replaceLast' is true, then the object will overwrite the last object in the spline 
         * instead of merely being added to the list of elements in the spline.
         */
        public native function addElement(p:Object, replaceLast:Boolean):void;

        /**
         * Finalizes the spline data and makes it ready for operations such as splineLength and evaulate, etc.
         */
        public native function finalize():void;

        /**
         * Returns a Element of the Spline at time 't'.  The return Object must be 
         * cast into the expected type (ie. as Point)
         */
        public native function evaluate(t:float):Object;

        /**
         * Returns the First Derivative of the Spline at time 't'.  The return Object must be 
         * cast into the expected type (ie. as Point)
         */
        public native function firstDerivative(t:float):Object;

        /**
         * Returns the Second Derivative of the Spline at time 't'.  The return Object must be 
         * cast into the expected type (ie. as Point)
         */
        public native function secondDerivative(t:float):Object;

        /**
         * Returns the Length of the spline arc between t0 and t1
         */
        public native function arcLength(t0:float, t1:float):float;
    }
    
}