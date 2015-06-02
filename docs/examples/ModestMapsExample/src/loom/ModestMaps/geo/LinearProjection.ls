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
        * Raw projected point remains the same.
        */
        override protected function rawProject(point:Point)
        {
        }
        
       /*
        * Raw unprojected point remains the same.
        */
        override protected function rawUnproject(point:Point)
        {
        }
    }
}