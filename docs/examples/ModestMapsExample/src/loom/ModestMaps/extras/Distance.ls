package loom.modestmaps.extras
{
    import loom.modestmaps.geo.Location;
    
    public class Distance
    {
        public static const R_MILES:Number = 3963.1;
        public static const R_NAUTICAL_MILES:Number = 3443.9;
        public static const R_KM:Number = 6378;
        public static const R_METERS:Number = 6378000;
        
        /** 
         * <p>you can specify different units by optionally providing the 
         * earth's radius in the units you desire</p>
         * 
         * <p>Default is 6,378,000 metres, suggested values are:</p>
         * <ul>
         *   <li>3963.1 statute miles</li>
         *   <li>3443.9 nautical miles</li>
         *   <li>6378 km</li>
         * </ul>
         * 
         * @return distance between given start and end locations in metres
         * 
         * @see http://jan.ucc.nau.edu/~cvm/latlon_formula.html 
         * */
        public static function approxDistance(start:Location, end:Location, r:Number=R_METERS):Number 
        {
            var a1:Number = Math.degToRad(start.lat);
            var b1:Number = Math.degToRad(start.lon);
            var a2:Number = Math.degToRad(end.lat);
            var b2:Number = Math.degToRad(end.lon);

            var d:Number = Math.acos(Math.cos(a1)*Math.cos(b1)*Math.cos(a2)*Math.cos(b2) + 
                           Math.cos(a1)*Math.sin(b1)*Math.cos(a2)*Math.sin(b2) + 
                           Math.sin(a1)*Math.sin(a2)) * r;;
            return d;
        }        
    }
}