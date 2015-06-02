/*
 * $Id$
 */

package loom.modestmaps.geo
{
    import loom2d.math.Point;
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.geo.Transformation;
    import loom.modestmaps.geo.IProjection;
     
    public class AbstractProjection implements IProjection
    {
        protected const HELPER_POINT:Point;
        
        // linear transformation, if any.
        protected var T:Transformation;
        
        // required native zoom for which transformation above is valid.
        protected var zoom:Number;
    
        public function AbstractProjection(zoom:Number, T:Transformation)
        {
            // a transformation is not strictly necessary
            if(T)
                this.T = T;
                
            this.zoom = zoom;
        }
        
       /**
        * String signature of the current projection.
        */
        public function toString():String
        {
            Debug.assert("Abstract method not implemented by subclass.");
            return null;
        }
        
       /**
        * @return raw projected point.
        */
        protected function rawProject(point:Point)
        {
            Debug.assert("Abstract method not implemented by subclass.");
        }
        
       /**
        * @return raw unprojected point.
        */
        protected function rawUnproject(point:Point)
        {
            Debug.assert("Abstract method not implemented by subclass.");
        }
        
       /**
        * @return projected and transformed point.
        */
        public function project(point:Point)
        {
            rawProject(point);
        
            if(T)
                T.transform(point);
        }
        
       /**
        * @return untransformed and unprojected point.
        */
        public function unproject(point:Point)
        {
            if(T)
                T.untransform(point);
    
            rawUnproject(point);
        }
        
       /**
        * @return projected and transformed coordinate for a location.
        */
        public function locationCoordinate(location:Location):Coordinate
        {
            HELPER_POINT.x = Math.PI*location.lon/180;
            HELPER_POINT.y = Math.PI*location.lat/180;
            project(HELPER_POINT);
            return new Coordinate(HELPER_POINT.y, HELPER_POINT.x, zoom);
        }
        
//TODO_24: native?       
       /**
        * @return untransformed and unprojected location for a coordinate.
        */
        public function coordinateLocation(coordinate:Coordinate):Location
        {
            coordinate = coordinate.zoomTo(zoom);
            HELPER_POINT.x = coordinate.column;
            HELPER_POINT.y = coordinate.row;
            unproject(HELPER_POINT);
            return new Location(180*HELPER_POINT.y/Math.PI, 180*HELPER_POINT.x/Math.PI);
        }
    }
}