/**
 * MapProvider for Open Street Map data.
 * 
 * @author migurski
 * $Id$
 */
package loom.modestmaps.mapproviders
{ 
    import loom.modestmaps.core.Coordinate;
    
    public class OpenStreetMapProvider
        extends AbstractMapProvider
        implements IMapProvider
    {
        public function OpenStreetMapProvider(minZoom:int=MIN_ZOOM, maxZoom:int=MAX_ZOOM)
        {
            super(minZoom, maxZoom);
        }

        public function toString() : String
        {
            return "OPEN_STREET_MAP";
        }
    
        public function getTileUrls(coord:Coordinate):Vector.<String>
        {
            var sourceCoord:Coordinate = sourceCoordinate(coord);
            if (sourceCoord.row < 0 || sourceCoord.row >= Math.pow(2, coord.zoom)) {
                return [];
            }
            return [ 'http://tile.openstreetmap.org/'+(sourceCoord.zoom)+'/'+(sourceCoord.column)+'/'+(sourceCoord.row)+'.png' ];
        }
        
    }
}