/**
 * MapProvider for Open Street Map data.
 * 
 * @author migurski
 * $Id$
 */
package loom.modestmaps.mapproviders
{ 
    import loom.modestmaps.core.Coordinate;
    import system.platform.Platform;
    
    public class MapboxProvider
        extends AbstractMapProvider
        implements IMapProvider
    {
        private static const HIGH_DPI_PREFIX = "@2x";
        
        private var mapID:String;
        private var accessToken:String;
        private var format:String;
        private var highDPI:Boolean;
        
        public function MapboxProvider(mapID:String, accessToken:String, format:String = "", autoDPI:Boolean = true, minZoom:int=MIN_ZOOM, maxZoom:int=MAX_ZOOM)
        {
            if (mapID == null || mapID.length == 0 || mapID.indexOf(" ") != -1) {
                Debug.print("Mapbox map ID invalid, please check for spaces and length: "+mapID);
                mapID = null;
            }
            if (accessToken == null || accessToken.length == 0 || accessToken.indexOf(" ") != -1) {
                Debug.print("Mapbox access token invalid, please check for spaces and length: "+accessToken);
                accessToken = null;
            }
            this.accessToken = accessToken;
            this.mapID = mapID;
            if (!format || format.length == 0) {
                format = ".png";
            }
            if (autoDPI && Platform.getDPI() > 250) format = HIGH_DPI_PREFIX + format;
            if (format.indexOf(HIGH_DPI_PREFIX) == 0) highDPI = true;
            this.format = format;
            super(minZoom, maxZoom);
        }
        
        override public function get supportsHighDPI():Boolean { return true; }
        
        override public function get tileWidth():Number
        {
            return highDPI ? 512 : 256;
        }

        override public function get tileHeight():Number
        {
            return highDPI ? 512 : 256;
        }

        public function toString() : String
        {
            return "MAPBOX";
        }
    
        public function getTileUrls(coord:Coordinate):Vector.<String>
        {
            var sourceCoord:Coordinate = sourceCoordinate(coord);
            if (mapID != null && accessToken != null && (sourceCoord.row < 0 || sourceCoord.row >= Math.pow(2, coord.zoom))) {
                return [];
            }
            return [
                'http://api.tiles.mapbox.com/v4/' +
                mapID + '/' +
                (sourceCoord.zoom) + '/' +
                (sourceCoord.column) + '/' +
                (sourceCoord.row) +
                (format) +
                "?access_token=" + accessToken
            ];
        }
        
    }
}