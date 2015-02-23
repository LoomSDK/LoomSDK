package com.modestmaps.mapproviders
{

	import com.modestmaps.geo.MercatorProjection;
	import com.modestmaps.geo.Transformation;
	
	public class ACTransitMapProvider extends AbstractZoomifyMapProvider implements IMapProvider
	{
	    public function ACTransitMapProvider()
        {
	        defineImageProperties('http://actransit.modestmaps.com/', 11258, 7085);
	        
	       /*
	        * Euclid Ave. & Ridge Rd., Berkeley
	        * 37.876022, -122.260365
	        *   = coord(2296, 172, 14)
	        * 
	        * Monarch St. & W. Tower Ave., Alameda
	        * 37.783503, -122.308559
	        *   = coord(7061, 3350, 14)
	        * 
	        * 140th Ave. & E 14th. St., Oakland
	        * 37.713159, -122.139795
	        *   = coord(2929, 10960, 14)
	        */
	        var t:Transformation = new Transformation(1449749.02835779, -2150945.931013119, 4632165.032378035,
	                                                  -2162454.5923735118, -1441023.4254683803, -3581364.9874006994);
	        
	        __projection = new MercatorProjection(14, t);
	    }
	
	    override public function toString():String
	    {
	        return "AC_TRANSIT";
	    }
	}

}