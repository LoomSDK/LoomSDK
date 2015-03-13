/**
 * vim:et sts=4 sw=4 cindent:
 * @ignore
 *
 * @author darren
 * @author migurski
 * $Id$
 *
 * AbstractMapProvider is the base class for all MapProviders.
 * 
 * @description AbstractMapProvider is the base class for all 
 *              MapProviders. MapProviders are primarily responsible
 *              for "painting" map Tiles with the correct 
 *              graphic imagery.
 */

package loom.modestmaps.mapproviders
{
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.geo.IProjection;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.geo.MercatorProjection;
    import loom.modestmaps.geo.Transformation;
    
    public class AbstractMapProvider
    {       
        public static const MIN_ZOOM:int = 1;
        public static const MAX_ZOOM:int = 20;
        
        protected var __projection:IProjection;
        
        // boundaries for the current provider
        protected var __topLeftOutLimit:Coordinate;
        protected var __bottomRightInLimit:Coordinate;
    
        /*
         * Abstract constructor, should not be instantiated directly.
         */
        public function AbstractMapProvider(minZoom:int, maxZoom:int)
        {
            // see: http://modestmaps.mapstraction.com/trac/wiki/TileCoordinateComparisons#TileGeolocations
            var t:Transformation = new Transformation(1.068070779e7, 0, 3.355443185e7,
                                                      0, -1.068070890e7, 3.355443057e7);
                                                                  
            __projection = new MercatorProjection(26, t);

            __topLeftOutLimit = new Coordinate(0, Number.NEGATIVE_INFINITY, minZoom);
            __bottomRightInLimit = (new Coordinate(1, Number.POSITIVE_INFINITY, 0)).zoomTo(maxZoom);
        }
    
       /*
        * String signature of the current map provider's geometric behavior.
        */
        public function geometry():String
        {
            return __projection.toString();
        }
    
        /**
         * Wraps the column around the earth, doesn't touch the row.
         * 
         * Row coordinates shouldn't be outside of outerLimits, 
         * so we shouldn't need to worry about them here.
         * 
         * @param coord The Coordinate to wrap.
         */
        public function sourceCoordinate(coord:Coordinate):Coordinate
        {
            var wrappedColumn:Number = coord.column % Math.pow(2, coord.zoom);
    
            while (wrappedColumn < 0)
            {
                wrappedColumn += Math.pow(2, coord.zoom);
            }
            
            // we don't wrap rows here because the map/grid should be enforcing outerLimits :)
                
            return new Coordinate(coord.row, wrappedColumn, coord.zoom);
        }
    
       /**
        * Get top left outer-zoom limit and bottom right inner-zoom limits,
        * as Coordinates in a two element array.
        */
        public function outerLimits():Vector.<Coordinate>
        {
            return [ __topLeftOutLimit.copy(), __bottomRightInLimit.copy() ];
        }
    
       /*
        * Return projected and transformed coordinate for a location.
        */
        public function locationCoordinate(location:Location):Coordinate
        {
            return __projection.locationCoordinate(location);
        }
        
       /*
        * Return untransformed and unprojected location for a coordinate.
        */
        public function coordinateLocation(coordinate:Coordinate):Location
        {
            return __projection.coordinateLocation(coordinate);
        }

        public function get tileWidth():Number
        {
            return 256;
        }

        public function get tileHeight():Number
        {
            return 256;
        }

    }
}