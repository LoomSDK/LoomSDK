
package com.modestmaps.mapproviders.microsoft
{
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.mapproviders.AbstractMapProvider;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.util.BinaryUtil;
	
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

		protected const urlStart:Object = {
			AERIAL: "http://a",
			ROAD:   "http://r",
			HYBRID: "http://h"
		};
		protected const urlMiddle:Object = {
			AERIAL: ".ortho.tiles.virtualearth.net/tiles/a",
			ROAD:   ".ortho.tiles.virtualearth.net/tiles/r",
			HYBRID: ".ortho.tiles.virtualearth.net/tiles/h"
		}
		protected const urlEnd:Object = {
			AERIAL: ".jpeg?g=90",
			ROAD:   ".png?g=90",
			HYBRID: ".jpeg?g=90"
		};
		
		protected var type:String;
		protected var hillShading:Boolean;
		
		public function MicrosoftProvider(type:String=ROAD, hillShading:Boolean=true, minZoom:int=MIN_ZOOM, maxZoom:int=MAX_ZOOM)
		{
		    super(minZoom, maxZoom);
		    
			this.type = type;
			this.hillShading = hillShading;
	
			if (hillShading) {
				urlEnd[ROAD] += "&shading=hill"; 
			}
	
			// Microsoft don't have a zoom level 0 right now:
	        __topLeftOutLimit.zoomTo(1);
		}
		
		protected function getZoomString(coord:Coordinate):String
		{
	        var sourceCoord:Coordinate = sourceCoordinate(coord);
		    
			// convert row + col to zoom string
			// padded with zeroes so we end up with zoom digits after slicing:
			var rowBinaryString:String = BinaryUtil.convertToBinary(sourceCoord.row);
			rowBinaryString = rowBinaryString.slice(-sourceCoord.zoom);
			
			var colBinaryString : String = BinaryUtil.convertToBinary(sourceCoord.column);
			colBinaryString = colBinaryString.slice(-sourceCoord.zoom);
	
			// generate zoom string by combining strings
			var zoomString : String = "";
	
			for(var i:Number = 0; i < sourceCoord.zoom; i += 1) {
				zoomString += BinaryUtil.convertToDecimal(rowBinaryString.charAt( i ) + colBinaryString.charAt( i ));
			}
			
			return zoomString; 
		}
	
		public function toString():String
		{
			return "MICROSOFT_"+type;
		}
		
		public function getTileUrls(coord:Coordinate):Array
		{
			if (coord.row < 0 || coord.row >= Math.pow(2, coord.zoom)) {
				return null;
			}
			// this is so that requests will be consistent in this session, rather than totally random
			var server:int = Math.abs(serverSalt + coord.row + coord.column + coord.zoom) % 4;
			return [ urlStart[type] + server + urlMiddle[type] + getZoomString(coord) + urlEnd[type] ];
		}
	
	}
}