package com.modestmaps.extras
{
	import com.modestmaps.Map;
	import com.modestmaps.core.MapExtent;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.geo.Location;
	
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	/** 
	 * VERY EXPERIMENTAL, requires javascript, uses this technique: 
	 * http://www.actionscript.org/resources/articles/745/1/JavaScript-and-VBScript-Injection-in-ActionScript-3/Page1.html
	 * 
	 * TODO: update spans for Microsoft, add Yahoo :)
	 * 
	 * In general, lots of this needs reworking... at least, IMapProviders should be able to provide copyright strings 
	 * without requiring javascript, and without needing to edit this file.
	 */
	[Event(name="copyrightChanged", type="com.modestmaps.events.MapEvent")] 
	public class MapCopyright extends Sprite
	{
		private static const script_js:XML = <script>
			<![CDATA[
				function() {
					modestMaps = {
					    
					    swfId: 'replaceMe',
					    
					    setSwfId:
					    	function(id)
					    	{
					    		this.swfId = id;
					    	},
					    
					    copyright:
					        function(provider, cenLat, cenLon, minLat, minLon, maxLat, maxLon, zoom)
					        {
					            switch(provider) {
					                case 'BLUE_MARBLE':
					                case 'DAILY_PLANET':
					                    document.getElementById(this.swfId).copyrightCallback('Image courtesy of NASA');
					                    break;
					                    
					                case 'NATURAL_EARTH_III':
					                    document.getElementById(this.swfId).copyrightCallback('Public domain map from <a href=\'http://www.shadedrelief.com/natural3/pages/use.html\'>Tom Patterson, www.shadedrelief.com</a>');
					                    break;
					        
					                case 'OPEN_STREET_MAP':
					                    document.getElementById(this.swfId).copyrightCallback('Map data <a href=\'http://www.openstreetmap.org\'>CC-BY-SA OpenStreetMap.org</a>');
					                    break;
					        
					                case 'CLOUDMADE':
					                    document.getElementById(this.swfId).copyrightCallback('Map tiles &copy; <a href="http://www.cloudmade.com">CloudMade</a>. Map data <a href=\'http://www.openstreetmap.org\'>CC-BY-SA OpenStreetMap.org</a>');
					                    break;
					        
					                case 'MICROSOFT_ROAD':
					                    this.microsoft.copyright('road', minLat, minLon, maxLat, maxLon, zoom);
					                    break;
					        
					                case 'MICROSOFT_AERIAL':
					                    this.microsoft.copyright('aerial', minLat, minLon, maxLat, maxLon, zoom);
					                    break;
					        
					                case 'MICROSOFT_HYBRID':
					                    this.microsoft.copyright(undefined, minLat, minLon, maxLat, maxLon, zoom);
					                    break;
					    
					                case 'YAHOO_ROAD':
					                case 'YAHOO_AERIAL':
					                case 'YAHOO_HYBRID':
					                case 'YAHOO_OVERLAY':
					                    document.getElementById(this.swfId).copyrightCallback('&copy; Yahoo');
					                    break;

					                default:
					                    document.getElementById(this.swfId).copyrightCallback('Copyright owner not found.');
					                    break;
					            } 
					        },
					    
					    microsoft: {
					        holders:
					            {'microsoft':   '&copy; 2006 Microsoft Corporation',
					             'navteq':      '&copy; 2006 NAVTEQ',
					             'and':         '&copy; AND',
					             'mds':         '&copy; 2006 MapData Sciences Pty Ltd',
					             'zenrin':      '&copy; 2006 Zenrin',
					             'nasa':        'Image courtesy of NASA',
					             'harris':      '&copy; Harris Corp, Earthstar Geographics LLC',
					             'usgs':        'Image courtesy of USGS',
					             'earthdata':   '&copy; EarthData',
					             'getmap':      '&copy; Getmapping plc',
					             'geoeye':      '&copy; 2006 GeoEye',
					             'pasco':       '&copy; 2005 Pasco'},
					    
					        // tract: [kind, holder, min zoom, max zoom, min lat, min lon, max lat, max lon]
					        tracts:
					            [['road', 'microsoft', 1, 20, -90, -180, 90, 180],
					             ['road', 'navteq', 1, 9, -90, -180, 90, 180],
					             ['road', 'navteq', 10, 19, 16, -180, 90, -50],
					             ['road', 'navteq', 10, 19, 27, -32, 40, -13],
					             ['road', 'navteq', 10, 19, 35, -11, 72, 20],
					             ['road', 'navteq', 10, 19, 21, 20, 72, 32],
					             ['road', 'navteq', 10, 17, 21.92, 113.14, 22.79, 114.52],
					             ['road', 'navteq', 10, 17, 21.73, 119.7, 25.65, 122.39],
					             ['road', 'navteq', 10, 17, 0, 98.7, 8, 120.17],
					             ['road', 'navteq', 10, 17, 0.86, 103.2, 1.92, 104.45],
					             ['road', 'and', 10, 19, -90, -180, 90, 180],
					             ['road', 'mds', 5, 17, -45, 111, -9, 156],
					             ['road', 'mds', 5, 17, -49.7, 164.42, -30.82, 180],
					             ['road', 'zenrin', 4, 18, 23.5, 122.5, 46.65, 151.66],
					             ['road', 'microsoft', 1, 20, -90, -180, 90, 180],
					             ['aerial', 'nasa', 1, 8, -90, -180, 90, 180],
					             ['aerial', 'harris', 9, 13, -90, -180, 90, 180],
					             ['aerial', 'usgs', 14, 19, 17.99, -150.11, 61.39, -65.57],
					             ['aerial', 'earthdata', 14, 19, 21.25, -158.3, 21.72, -157.64],
					             ['aerial', 'earthdata', 14, 19, 39.99, -80.53, 40.87, -79.43],
					             ['aerial', 'earthdata', 14, 19, 34.86, -90.27, 35.39, -89.6],
					             ['aerial', 'earthdata', 14, 19, 40.6, -74.18, 41.37, -73.51],
					             ['aerial', 'getmap', 14, 19, 49.94, -6.35, 58.71, 1.78],
					             ['aerial', 'geoeye', 14, 17, 44.43, -63.75, 45.06, -63.45],
					             ['aerial', 'geoeye', 14, 17, 45.39, -73.78, 45.66, -73.4],
					             ['aerial', 'geoeye', 14, 17, 45.2, -75.92, 45.59, -75.55],
					             ['aerial', 'geoeye', 14, 17, 42.95, -79.81, 44.06, -79.42],
					             ['aerial', 'geoeye', 14, 17, 50.35, -114.26, 51.25, -113.82],
					             ['aerial', 'geoeye', 14, 17, 48.96, -123.33, 49.54, -122.97],
					             ['aerial', 'geoeye', 14, 17, -35.42, 138.32, -34.47, 139.07],
					             ['aerial', 'geoeye', 14, 17, -32.64, 115.58, -32.38, 115.85],
					             ['aerial', 'geoeye', 14, 17, -34.44, 150.17, -33.27, 151.49],
					             ['aerial', 'geoeye', 14, 17, -28.3, 152.62, -26.94, 153.64],
					             ['aerial', 'pasco', 14, 17, 23.5, 122.5, 46.65, 151.66]],
					    
					        copyright:
					            function(kind, minLat, minLon, maxLat, maxLon, zoom)
					            {
					                var tracts = this.tracts;
					                var holders = [];
					                var matches = {};
					    
					                for(var i = 0; i < tracts.length; i += 1) {
					                    var tract = tracts[i];
					                    if((tract[0] == kind || !kind) && tract[2] <= zoom && zoom <= tract[3] && tract[4] <= maxLat && minLat <= tract[6] && tract[5] <= maxLon && minLon <= tract[7]) {
					                        matches[tract[1]] = true;
					                    }
					                }
					                
					                for(var p in matches) {
					                    holders.push(this.holders[p]);
					                }
					                
					                document.getElementById(modestMaps.swfId).copyrightCallback(holders.join(', '));
					            }
					    }
					    
					};
				}
			]]>
		</script>;
		
		private static var scriptAdded:Boolean = false;
		
		protected var map:Map;
		
		/** htmlText to be added to a label - listen for MapEvent.COPYRIGHT_CHANGED */
		public var copyright:String = "";

		public var copyrightField:TextField;
		
		protected var offsetX:Number=10;
		protected var offsetY:Number=10;

		public function MapCopyright(map:Map, offsetX:Number=10, offsetY:Number=10)
		{
			this.map = map;
			
			this.offsetX = offsetX;
			this.offsetY = offsetY;

			if (!scriptAdded) {
				try {
					ExternalInterface.call(script_js);
			        ExternalInterface.call('modestMaps.setSwfId', ExternalInterface.objectID);
			        ExternalInterface.addCallback("copyrightCallback", setCopyright);
			 	}
			 	catch (error:Error) {
			 		trace("problem adding setCopyright as callback in Map.as");
			 		trace(error.getStackTrace());
			 	}
			}
			
	        map.addEventListener(MapEvent.STOP_ZOOMING, onMapChange);
	        map.addEventListener(MapEvent.ZOOMED_BY, onMapChange);
	        map.addEventListener(MapEvent.STOP_PANNING, onMapChange);
	        map.addEventListener(MapEvent.PANNED, onMapChange);
	        map.addEventListener(MapEvent.EXTENT_CHANGED, onMapChange);
	        map.addEventListener(MapEvent.MAP_PROVIDER_CHANGED, onMapChange);
	        map.addEventListener(MapEvent.RESIZED, onMapResized);

			copyrightField = new TextField();
			copyrightField.defaultTextFormat = new TextFormat('Arial', 10, 0x000000, false, null, null, null, '_blank');
			copyrightField.selectable = false;
			copyrightField.mouseEnabled = true;
			copyrightField.multiline = true;
			addChild(copyrightField);			
			onMapChange(null);	
		}
		
	    protected var copyrightTimeout:uint;
	    
		protected function onMapChange(event:MapEvent):void
	    {
	    	if (copyrightTimeout) {
	    		clearTimeout(copyrightTimeout);
	    	}
	    	copyrightTimeout = setTimeout(callCopyright, 250);
	    }
	    
	    protected function onMapResized(event:MapEvent):void
	    {
			copyrightField.x = map.getWidth() - copyrightField.width - offsetX;
			copyrightField.y = map.getHeight() - copyrightField.height - offsetY;	    		
	    }
	    
	   /**
 	    * Call javascript:modestMaps.copyright() with details about current view.
 	    * See js/copyright.js.
 	    */
 	    protected function callCopyright():void
 	    {
	    	if (copyrightTimeout) {
	    		clearTimeout(copyrightTimeout);
	    	}
	    	
	    	var extent:MapExtent = map.getExtent();
	    	
	        var cenL:Location = extent.center;
 	        var minL:Location = extent.southEast;
 	        var maxL:Location = extent.northWest;
 	   
 	        var minLat:Number = Math.min(minL.lat, maxL.lat);
 	        var minLon:Number = Math.min(minL.lon, maxL.lon);
 	        var maxLat:Number = Math.max(minL.lat, maxL.lat);
 	        var maxLon:Number = Math.max(minL.lon, maxL.lon);
 	       
 	       	try {
 	    	    ExternalInterface.call("modestMaps.copyright", map.getMapProvider().toString(), cenL.lat, cenL.lon, minLat, minLon, maxLat, maxLon, map.getZoom());
 	    	}
 	    	catch (error:Error) {
 	    		//trace("problem setting copyright in Map.as");
 	    		//trace(error.getStackTrace());	
 	    	}
 	    }
	    
	   /**  this function gets exposed to javascript as a callback
        * 
        *   to display the copyright string in your flash piece, you then need to listen for 
        *   the COPYRIGHT_CHANGED MapEvent, or add MapCopyright as a child of map for a basic implementation.
	    */
	    public function setCopyright(copyright:String):void {
	    	this.copyright = copyright;
	    	this.copyright = this.copyright.replace(/&copy;/g,"©");

			copyrightField.htmlText = this.copyright;
			copyrightField.width = copyrightField.textWidth + 4;
			copyrightField.height = copyrightField.textHeight + 4;

			onMapResized(null);
				    		
	    	dispatchEvent(new MapEvent(MapEvent.COPYRIGHT_CHANGED, this.copyright));
	    }
	    
	}
}
