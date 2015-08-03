/**
 * MapProvider for a WMS server, in either EPSG:4326 or EPSG:900913
 */
package loom.modestmaps.mapproviders
{ 
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.geo.LinearProjection;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.geo.Transformation;
    
    
    public class WMSMapProvider extends AbstractMapProvider implements IMapProvider
    {
        
        public static const EPSG_4326:String = "EPSG:4326";
        public static const EPSG_900913:String = "EPSG:900913";

        public static const DEFAULT_PARAMS:Dictionary.<String, String> = {
            'LAYERS': '0,1',
            'FORMAT': 'image/png',
            'VERSION': '1.1.1',
            'SERVICE': 'WMS',
            'REQUEST': 'GetMap',
            'SRS': 'EPSG:4326',
            'WIDTH': '256',
            'HEIGHT': '256'
        };

        private var serverUrl:String;
        private var wmsParams:Dictionary.<String, String>;
        private var wms:String;                     
        


        public function WMSMapProvider(serverURL:String, wmsParams:Dictionary.<String, String>)
        {
            super(MIN_ZOOM, MAX_ZOOM);
            
            if (!wmsParams) wmsParams = DEFAULT_PARAMS;
            
            this.serverUrl = serverURL;
            this.wmsParams = wmsParams;
            this.wms = "?" + createURLencodedString(wmsParams);
           
            if (wmsParams['SRS'] == EPSG_4326) {
                var t:Transformation = new Transformation(166886.05360752725, 0, 524288, 0, -166886.05360752725, 524288);
                __projection = new LinearProjection(20, t);                 
            }
            else if (wmsParams['SRS'] && wmsParams['SRS'] != EPSG_900913) {
                Debug.assert("[WMSMapProvider] Only Linear and (Google-style) Mercator projections are currently supported");
            }
        }

        public function getTileUrls(coord:Coordinate):Vector.<String>
        {
        	var worldSize:int = Math.pow(2, coord.zoom);
        	// FIXME: check this for lat-lon projection, it's probably wrong
            if (coord.row < 0 || coord.row >= worldSize) {
            	return [];
            }

            var sourceCoord:Coordinate = sourceCoordinate(coord);
            var bottomLeftCoord:Coordinate = sourceCoord.down();
            var topRightCoord:Coordinate = sourceCoord.right();
             
            var boundingBox:String;

            if (wmsParams['SRS'] == EPSG_4326) {
            	// lat-lon is easy?
	            var bottomLeftLocation:Location = coordinateLocation(bottomLeftCoord);
    	        var topRightLocation:Location = coordinateLocation(topRightCoord);
        	    boundingBox = '&BBOX=' + [ bottomLeftLocation.lon.toFixed(5), 
        	    						   bottomLeftLocation.lat.toFixed(5), 
        	    						   topRightLocation.lon.toFixed(5), 
        	    						   topRightLocation.lat.toFixed(5) ].join(',');
	            return [serverUrl + wms + boundingBox];
        	}
        	
        	// the following only works for EPSG_900913...
        	
			// these are magic numbers derived from the approx. radius of the earth in meters
			// they get us into the raw mercator-ish units that WMS servers expect
			// ...don't ask me, I just read http://wiki.osgeo.org/wiki/WMS_Tiling_Client_Recommendation#Tile_Grid_Definition
			var quadrantWidth:Number = 20037508.34;
			var magicZoom:Number = Math.log(2*quadrantWidth) / Math.LN2;        	

			// apply that number os a zoom, it's basically getting us tile coordinates for zoom level 25.something...
        	bottomLeftCoord.zoomToInPlace(magicZoom);
        	topRightCoord.zoomToInPlace(magicZoom);
        	
        	// flip and offset so we have correct minx,miny,maxx,maxy
        	var minx:Number = bottomLeftCoord.column - quadrantWidth;
        	var miny:Number = quadrantWidth - bottomLeftCoord.row;
        	var maxx:Number = topRightCoord.column - quadrantWidth;
        	var maxy:Number = quadrantWidth - topRightCoord.row;
        	        	
        	boundingBox = '&BBOX=' + [ minx.toFixed(5), miny.toFixed(5), maxx.toFixed(5), maxy.toFixed(5) ].join(',');

            return [  serverUrl + wms + boundingBox  ];
        }
                
        public function toString() : String
        {
            return "WMS";
        }

        private function replace(str:String, oldStr:String, newStr:String):String
        {
            var res:String = "";
            var splitStr:Vector.<String> = str.split(oldStr);
            for (var i=0;i<splitStr.length-1;i++)
            {
                res += (splitStr[i] + newStr);
            }
            res += splitStr[i];
            return res;
        }

        private function encodeUriComponent(str:String):String
        {
            var res:String = replace(str, "&", "%26");
            res = replace(res, " ","%20");
            return res;
        }

        private function createURLencodedString(hash:Dictionary.<String, String>):String
        {
            var first:Boolean = true;
            var uri:String = "";
            for (var key:String in hash) 
            {
                if(!first)
                {
                    uri += "&";
                    first = false;                  
                }
                uri += encodeUriComponent(key) + "=" + encodeUriComponent(hash[key]);
            }
            return uri;
        }        
    }
}
