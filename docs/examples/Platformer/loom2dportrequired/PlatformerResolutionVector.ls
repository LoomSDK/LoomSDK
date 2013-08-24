package 
{
    import loom2d.math.Point;

    /**
     * Helper for keeping track of collision resolution state.
     */
    public class PlatformerResolutionVector
    {
        public var enabled:Boolean = false;
        protected var _distance:Number = 0;
        public var axis:Point2;
        public var slope:Number = 0;
        
        public function PlatformerResolutionVector(axis:Point2)
        {
            this.axis = axis;
        }

        // Copy constructor
        public function dupe():PlatformerResolutionVector
        {
            var retVal = new PlatformerResolutionVector(axis);
            retVal.enabled = enabled;
            retVal.slope = slope;
            retVal._distance = _distance;

            return retVal;
        }
        
        public function set distance( value:Number ):void
        {
            _distance = value;
            // Automatically disable this vector if the distance is set.
            enabled = false;
            // Automatically reset the slope if the distance is set.
            slope = 0;
        }
        
        public function get distance( ):Number
        {
            return _distance;
        }
    }
}