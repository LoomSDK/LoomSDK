/*
 * $Id$
 */

package com.modestmaps.geo
{ 
	import loom2d.math.Point;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.geo.Location;

	public interface IProjection
	{
	   /*
	    * Return projected and transformed point.
	    */
	    function project(point:Point):Point;
	    
	   /*
	    * Return untransformed and unprojected point.
	    */
	    function unproject(point:Point):Point;
	    
	   /*
	    * Return projected and transformed coordinate for a location.
	    */
	    function locationCoordinate(location:Location):Coordinate;
	    
	   /*
	    * Return untransformed and unprojected location for a coordinate.
	    */
	    function coordinateLocation(coordinate:Coordinate):Location;
	    
	    function toString():String;
	}
}