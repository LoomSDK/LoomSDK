/*
 * $Id$
 */

package com.modestmaps.geo
{
	import loom2d.math.Point;
	import com.modestmaps.geo.Transformation;
	import com.modestmaps.geo.AbstractProjection; 
	 
	public class MercatorProjection extends AbstractProjection
	{
	    public function MercatorProjection(zoom:Number, T:Transformation)
	    {
	        super(zoom, T);
	    }
	    
	   /*
	    * String signature of the current projection.
	    */
	    override public function toString():String
	    {
	        return 'Mercator('+zoom+', '+T.toString()+')';
	    }
	    
	   /*
	    * Return raw projected point.
	    * See: http://mathworld.wolfram.com/MercatorProjection.html (2)
	    */
	    override protected function rawProject(point:Point):Point
	    {
	        return new Point(point.x, 
	                         Math.log(Math.tan(0.25 * Math.PI + 0.5 * point.y)));
	    }
	    
	   /*
	    * Return raw unprojected point.
	    * See: http://mathworld.wolfram.com/MercatorProjection.html (7)
	    */
	    override protected function rawUnproject(point:Point):Point
	    {
	        return new Point(point.x,
	                         2 * Math.atan(Math.pow(Math.E, point.y)) - 0.5 * Math.PI);
	    }
	}
}