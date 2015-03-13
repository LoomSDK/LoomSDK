package com.modestmaps.mapproviders
{
	import com.modestmaps.core.Coordinate;
	
	/**
	 * @author migurski
	 * $Id$
	 */
	
	public class AbstractZoomifyMapProvider extends AbstractMapProvider implements IMapProvider
	{
	    private var __baseDirectory:String;
	    private var __groups:Vector.<Coordinate>;
	
	    public function AbstractZoomifyMapProvider()
        {
            super(MIN_ZOOM, MAX_ZOOM);
	        
	       /*
	        * Example sub-class constructor:
	        *
	        *   public function MyZoomifyMapProvider()
	        *   {
	        *       super();
	        *
	        *       // defineImageProperties() *must* be called!
	        *       defineImageProperties('http://example.com/', 256, 256);
	        *
	        *       // Calculate the transformation and projectionbased on chosen markers.  
	        *       // See http://modestmaps.com/calculator.html
	        *       var t:Transformation = new Transformation(1, 0, 0, 0, 1, 0);
	        *       __projection = new LinearProjection(0, t);
	        *   }
	        *
	        */
	    }
	
	    public function toString():String
	    {
	        return "ABSTRACT_ZOOMIFY";
	    }
	
	   /**
	    * Zoomifyer EZ (download: http://www.zoomify.com/express.htm) cuts a base
	    * image into tiles, and creates a metadata file named ImageProperties.xml
	    * in the same directory. Instead of parsing that file, pass the relevant
	    * bits to this method. Base directory *must* have a trailing slash.
	    *
	    * Example:
	    *
	    *   ImageProperties.xml content:
	    *       <IMAGE_PROPERTIES WIDTH="11258" HEIGHT="7085" NUMTILES="1650" NUMIMAGES="1" VERSION="1.8" TILESIZE="256" />
	    *
	    *   URL of ImageProperties.xml:
	    *       http://example.com/ImageProperties.xml
	    *
	    *   Corresponding call to defineImageProperties():
	    *       defineImageProperties('http://example.com/', 11258, 7085);
	    *
	    * Tiles created by Zoomifyer EZ are placed in folders named "TileGroup{0..n}",
	    * in groups of 256, so we need to quickly iterate through the entire set of
	    * tile coordinates to determine where the group boundaries are. These are
	    * stored in the __groups array.
	    */
		protected function defineImageProperties(baseDirectory:String, width:Number, height:Number):void
		{
	        __baseDirectory = baseDirectory;
	
	        var zoom:Number = Math.ceil(Math.log(Math.max(width, height)) / Math.LN2);
	
	        __topLeftOutLimit = new Coordinate(0, 0, 0);
	        __bottomRightInLimit = (new Coordinate(height, width, zoom)).zoomTo(zoom - 8);
	
	        __groups = [];
	        var i:Number = 0;
	        
	       /*
	        * Iterate over all possible tiles in order: left to right, top to
	        * bottom, zoomed-out to zoomed-in. Note the first tile coordinate
	        * in each group of 256.
	        */
	        for(var c:Coordinate = __topLeftOutLimit.copy(); c.zoom <= __bottomRightInLimit.zoom; c.zoom += 1) {
	            
	            // edges of the image at current zoom level
	            var tlo:Coordinate = __topLeftOutLimit.zoomTo(c.zoom);
	            var bri:Coordinate = __bottomRightInLimit.zoomTo(c.zoom);
	        
	            // left-to-right, top-to-bottom, like reading a book
	            for(c.row = tlo.row; c.row <= bri.row; c.row += 1) {
	                for(c.column = tlo.column; c.column <= bri.column; c.column += 1) {
	                
	                    // zoomify groups tiles into folders of 256 each
	                    if(i % 256 == 0)
	                        __groups.pushSingle(c.copy());
	                    
	                    i += 1;
	                }
	            }   
	        }
	    }
	    
	    private function coordinateGroup(c:Coordinate):Number
	    {
	        for(var i:Number = 0; i < __groups.length; i += 1) {
	            if(i+1 == __groups.length)
	                return i;
	        
	            var g:Coordinate = __groups[i+1].copy();
	
	            if(c.zoom < g.zoom || (c.zoom == g.zoom && (c.row < g.row || (c.row == g.row && c.column < g.column))))
	                return i;
	        }
	        return -1;
	    }
	
	    public function getTileUrls(coord:Coordinate):Vector.<String>
	    {
	        return [ __baseDirectory+'TileGroup'+coordinateGroup(coord)+'/'+(coord.zoom)+'-'+(coord.column)+'-'+(coord.row)+'.jpg' ];
	    }
	}
	
}