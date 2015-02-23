package com.modestmaps.extras
{
    import com.modestmaps.geo.Location;
    
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
            
			var a1:Number = radians(start.lat);
			var b1:Number = radians(start.lon);
			var a2:Number = radians(end.lat);
			var b2:Number = radians(end.lon);

            var d:Number;
            with(Math) {
                d = acos(cos(a1)*cos(b1)*cos(a2)*cos(b2) + cos(a1)*sin(b1)*cos(a2)*sin(b2) + sin(a1)*sin(a2)) * r;
            }
            return d;
        }        

        private static function radians(degrees:Number):Number
        {
            return degrees * Math.PI / 180.0;
        }
    }
}