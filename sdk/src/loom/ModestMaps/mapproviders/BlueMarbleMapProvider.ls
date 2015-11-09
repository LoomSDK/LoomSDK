/**
 * @author migurski
 * $Id$
 */
package loom.modestmaps.mapproviders
{
	import loom.modestmaps.core.Coordinate;
	
	public class BlueMarbleMapProvider 
		extends AbstractMapProvider
		implements IMapProvider
	{
	    public var baseURL:String;
	    
	    public function BlueMarbleMapProvider(minZoom:int = MIN_ZOOM, maxZoom:int = MAX_ZOOM)
        {
            super(minZoom, Math.min2(9, maxZoom));
            if (!baseURL) baseURL = 'http://s3.amazonaws.com/com.modestmaps.bluemarble/';
	    }
	
	    public function toString():String
	    {
	        return "BLUE_MARBLE";
	    }
	
	    public function getTileUrls(coord:Coordinate):Vector.<String>
	    {
	        var sourceCoord:Coordinate = sourceCoordinate(coord);
	        if (sourceCoord.row < 0 || sourceCoord.row >= Math.pow(2, coord.zoom)) {
	        	return [];
	    	}
	        return [ baseURL + (sourceCoord.zoom) + '-r' + (sourceCoord.row) + '-c' + (sourceCoord.column) + '.jpg' ];
	    }
	    
	}
}
