/*
 * $Id$
 */

package com.modestmaps.geo
{
	public class Location
	{
	    public static const MAX_LAT:Number = 84;
	    public static const MIN_LAT:Number = -MAX_LAT;
	    public static const MAX_LON:Number = 180;
	    public static const MIN_LON:Number = -MAX_LON;
	    
	    // Latitude, longitude, _IN DEGREES_.
	    public var lat:Number;
	    public var lon:Number;
	
		public static function fromString(str:String, lonlat:Boolean=false):Location
		{
			var parts = str.split("/\s*,\s*/");
			if (lonlat) parts = parts.reverse();
			return new Location(parts[0] as Number, parts[1] as Number);
		}

	    public function Location(lat:Number, lon:Number)
	    {
	        this.lat = lat;
	        this.lon = lon;
	    }
	    
	    public function equals(loc:Location):Boolean
	    {
	        return loc && loc.lat == lat && loc.lon == lon;
	    }
	    
	    public function clone():Location
	    {
	        return new Location(lat, lon);
	    }

        /**
         * This function normalizes latitude and longitude values to a sensible range
         * (±84°N, ±180°E), and returns a new Location instance.
         */
        public function normalize():Location
        {
            var loc:Location = clone();
            loc.lat = Math.max(MIN_LAT, Math.min(MAX_LAT, loc.lat));
            while (loc.lon > 180) loc.lon -= 360;
            while (loc.lon < -180) loc.lon += 360;
            return loc;
        }

// TODO_AHMED: Removed argument from toString presicion:Number which was used by
	    override public function toString():String
	    {
	        return [lat.toFixed(5), lon.toFixed(5)].join(',');
	    }
	}
}