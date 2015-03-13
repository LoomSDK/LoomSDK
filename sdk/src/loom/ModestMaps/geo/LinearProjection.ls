/*
 * $Id$
 */

package loom.modestmaps.geo
{
    import loom2d.math.Point;
    import loom.modestmaps.geo.Transformation;
    import loom.modestmaps.geo.AbstractProjection; 
     
    public class LinearProjection extends AbstractProjection
    {
        function LinearProjection(zoom:Number, T:Transformation)
        {
            super(zoom, T);
        }
        
       /*
        * String signature of the current projection.
        */
        override public function toString():String
        {
            return 'Linear('+zoom+', '+T.toString()+')';
        }
        
       /*
        * Return raw projected point.
        */
        override protected function rawProject(point:Point):Point
        {
            return new Point(point.x, point.y);
        }
        
       /*
        * Return raw unprojected point.
        */
        override protected function rawUnproject(point:Point):Point
        {
            return new Point(point.x, point.y);
        }
    }
}