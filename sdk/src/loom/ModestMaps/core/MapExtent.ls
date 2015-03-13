/*
 * $Id$
 */

package loom.modestmaps.core
{
    import loom.modestmaps.geo.Location;
    
    import loom2d.math.Rectangle;
    
    public class MapExtent extends Object
    {
        // TODO: OK for rectangular projections, but we need a better way for other projections
        public var north:Number;
        public var south:Number;
        public var east:Number;
        public var west:Number;
        
        /** @param n the most northerly latitude
         *  @param s the southern latitude
         *  @param e the eastern-most longitude
         *  @param w the westest longitude */
        public function MapExtent(n:Number, s:Number, e:Number, w:Number)
        {
            north = Math.max(n, s);
            south = Math.min(n, s);
            east = Math.max(e, w);
            west = Math.min(e, w);
        }
        
        public function clone():MapExtent
        {
            return new MapExtent(north, south, east, west);
        }
        
        /** enlarges this extent so that the given extent is inside it */
        public function encloseExtent(extent:MapExtent):void
        {
            north = Math.max(extent.north, north);
            south = Math.min(extent.south, south);
            east = Math.max(extent.east, east);
            west = Math.min(extent.west, west);         
        }
        
        /** enlarges this extent so that the given location is inside it */
        public function enclose(location:Location):void
        {
            north = Math.max(location.lat, north);
            south = Math.min(location.lat, south);
            east = Math.max(location.lon, east);
            west = Math.min(location.lon, west);
        }
        
        public function get northWest():Location
        {
            return new Location(north, west);
        }
        
        public function get southWest():Location
        {
            return new Location(south, west);
        }
        
        public function get northEast():Location
        {
            return new Location(north, east);
        }
        
        public function get southEast():Location
        {
            return new Location(south, east);
        }
        
        public function set northWest(nw:Location):void
        {
            north = nw.lat;
            west = nw.lon;
        }
        
        public function set southWest(sw:Location):void
        {
            south = sw.lat;
            west = sw.lon;
        }
        
        public function set northEast(ne:Location):void
        {
            north = ne.lat;
            east = ne.lon;
        }
        
        public function set southEast(se:Location):void
        {
            south = se.lat;
            east = se.lon;
        }

        public function get center():Location
        {   
            return new Location(south + (north - south) / 2, east + (west - east) / 2);
        }

        public function set center(location:Location):void
        {   
            var w:Number = east - west;
            var h:Number = north - south;
            north = location.lat - h / 2;
            south = location.lat + h / 2;
            east = location.lon + w / 2;
            west = location.lon - w / 2;
        }

        public function inflate(lat:Number, lon:Number):void
        {
            north += lat;
            south -= lat;
            west -= lon;
            east += lon;
        }

        public function getRect():Rectangle
        {
            var left:Number = Math.min(east, west);
            var top:Number = Math.min(north, south);
            var width:Number = Math.max(east, west) - left;
            var height:Number = Math.max(north, south) - top;
            return new Rectangle(left, top, width, height); 
        }
        
        public function contains(location:Location):Boolean
        {
            return getRect().contains(location.lon, location.lat);
        }
                
        public function containsExtent(extent:MapExtent):Boolean
        {
            return getRect().containsRect(extent.getRect());
        }

        /** @return "north, south, east, west" */
        public function toString():String
        {
            return [north, south, east, west].join(', ');
        }

        /** Creates a new MapExtent from the given String.
         * @param str "north, south, east, west"
         * @return a new MapExtent from the given string */
        public static function fromString(str:String):MapExtent
        {
            var parts:Vector.<String> = str.split(",");
            return new MapExtent(parts[0].toNumber(),
                                 parts[1].toNumber(),
                                 parts[2].toNumber(),
                                 parts[3].toNumber());
        }

        /** calculate the north/south/east/west extremes of the given array of locations */
        public static function fromLocations(locations:Vector.<Location>):MapExtent
        {
            if (!locations || locations.length == 0) return new MapExtent(0, 0, 0, 0);

            var extent:MapExtent;
            
            for each (var location:Location in locations)
            {
                if (!extent) {
                    if (location && !isNaN(location.lat) && !isNaN(location.lon)) {
                        extent = new MapExtent(location.lat, location.lat, location.lon, location.lon);
                    }                   
                }
                else {
                    if (location && !isNaN(location.lat) && !isNaN(location.lon)) {
                        extent.enclose(location);
                    }
                }
            }
            
            if (!extent) {
                extent = new MapExtent(0, 0, 0, 0);
            }
            
            return extent;
        }

        public static function fromLocation(location:Location):MapExtent
        {
            return new MapExtent(location.lat, location.lat, location.lon, location.lon);
        }
        
        public static function fromLocationProperties(objects:Vector.<Dictionary.<String, Location>>, locationProp:String='location'):MapExtent
        {
            return fromLocations(objects.map(
                function(obj:Dictionary.<String, Location>, index:Number, vector:Vector):Location 
                { 
                    return obj[locationProp] as Location; 
                } 
            ));
        }
        
    }
}