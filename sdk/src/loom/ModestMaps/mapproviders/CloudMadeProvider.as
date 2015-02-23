package com.modestmaps.mapproviders
{
	import com.modestmaps.core.Coordinate;
	
	public class CloudMadeProvider extends OpenStreetMapProvider
	{
		public static const THE_ORIGINAL:String = '1';
		public static const FINE_LINE:String = '2';
		public static const TOURIST:String = '7';
		
		public static const FRESH:String = '997';
		public static const PALE_DAWN:String = '998';
		public static const MIDNIGHT_COMMANDER:String = '999';

		/** see http://developers.cloudmade.com/projects to get hold of an API key */
		public var key:String;
		
		/** use the constants above or see maps.cloudmade.com for more styles */
		public var style:String;
		
		public function CloudMadeProvider(key:String, style:String='1')
		{
			super();
			this.key = key;
			this.style = style;
		}
		
		override public function getTileUrls(coord:Coordinate):Array
		{
			var worldSize:int = Math.pow(2, coord.zoom);
			if (coord.row < 0 || coord.row >= worldSize) {
				return [];
			}
			coord = sourceCoordinate(coord);
			var server:String = [ 'a.', 'b.', 'c.', '' ][int(worldSize * coord.row + coord.column) % 4];
			var url:String = 'http://' + server + 'tile.cloudmade.com/' + [ key, style, tileWidth, coord.zoom, coord.column, coord.row ].join('/') + '.png'; 
			return [ url ];
		}
		
		override public function toString():String
		{
			return 'CLOUDMADE';
		}	
	}
}
