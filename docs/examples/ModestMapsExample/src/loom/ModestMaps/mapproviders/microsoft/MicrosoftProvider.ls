
package loom.modestmaps.mapproviders.microsoft
{
    import loom.modestmaps.ModestMaps;
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.mapproviders.AbstractMapProvider;
    import loom.modestmaps.mapproviders.IMapProvider;
    
    /**
     * @author tom
     * @author darren
     * @author migurski
     * $Id:$
     */
    
    public class MicrosoftProvider extends AbstractMapProvider implements IMapProvider
    {
        public static const AERIAL:String = "AERIAL";
        public static const ROAD:String = "ROAD";
        public static const HYBRID:String = "HYBRID";

        public static var serverSalt:int = int(Math.random() * 4);

        protected const urlStart:Dictionary.<String, String> = {
            AERIAL: "http://a",
            ROAD:   "http://r",
            HYBRID: "http://h"
        };
        protected const urlMiddle:Dictionary.<String, String> = {
            AERIAL: ".ortho.tiles.virtualearth.net/tiles/a",
            ROAD:   ".ortho.tiles.virtualearth.net/tiles/r",
            HYBRID: ".ortho.tiles.virtualearth.net/tiles/h"
        };
        protected const urlEnd:Dictionary.<String, String> = {
            AERIAL: ".jpeg?g=90",
            ROAD:   ".png?g=90",
            HYBRID: ".jpeg?g=90"
        };
        
        protected var type:String;
        protected var hillShading:Boolean;
        
        public function MicrosoftProvider(type:String, hillShading:Boolean, minZoom:int, maxZoom:int)
        {
            //NOTE_TEC: clamp at 19 as any higher will request PNGs that use a format that Loom does not support
            super(minZoom, Math.min2(19, maxZoom));
            
            this.type = type;
            this.hillShading = hillShading;
    
            if (hillShading) {
                urlEnd[ROAD] += "&shading=hill"; 
            }
    
            // Microsoft don't have a zoom level 0 right now:
            __topLeftOutLimit.zoomTo(1);
        }
   
        public function toString():String
        {
            return "MICROSOFT_"+type;
        }
        
        public function getTileUrls(coord:Coordinate):Vector.<String>
        {
            if (coord.row < 0 || coord.row >= (1 << coord.zoom)) {
                return null;
            }
            // this is so that requests will be consistent in this session, rather than totally random
            var server:int = Math.abs(serverSalt + coord.row + coord.column + coord.zoom) % 4;
            var zoomString:String = ModestMaps.getMSProviderZoomString(coord.column, coord.row, coord.zoom);
            return [ urlStart[type] + server + urlMiddle[type] + zoomString + urlEnd[type] ];
        }
    }
}