package loom.modestmaps.extras
{
    import loom.modestmaps.geo.Location;
    
    public class Distance
    {
        public static const R_MILES:Number = 3963.1;
        public static const R_NAUTICAL_MILES:Number = 3443.9;
        public static const R_KM:Number = 6378;
        public static const R_METERS:Number = 6378000;
        
        public static const EPSILON = 1e-8;
        
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
        
        /**
         * Returns the haversine (great-circle i.e. closest) distance between two points on Earth as
         * a sphere. The default radius is the Earth radius in meters, but you can provide a different one
         * for different units, planets or spheres in general.
         * @param start The first of the points on the sphere.
         * @param end   The second of the points on the sphere.
         * @param r     The radius of the sphere in your preferred unit.
         * @return      The distance between the two locations in the same unit as r.
         */
        public static function haversineDistance(start:Location, end:Location, r:Number=R_METERS):Number
        {
            var lat1:Number = Math.degToRad(start.lat);
            var lon1:Number = Math.degToRad(start.lon);
            var lat2:Number = Math.degToRad(end.lat);
            var lon2:Number = Math.degToRad(end.lon);
            
            var dLat = lat2-lat1;
            var dLon = lon2-lon1;
            
            if (Math.abs(dLat) < EPSILON && Math.abs(dLon) < EPSILON) return 0;
            
            var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                    Math.cos(lat1) * Math.cos(lat2) * 
                    Math.sin(dLon/2) * Math.sin(dLon/2)
            ; 
            var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
            var d = r * c;
            return d;
        }
    }
}