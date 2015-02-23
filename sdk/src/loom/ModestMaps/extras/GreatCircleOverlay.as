package com.modestmaps.extras
{
    import com.modestmaps.Map;
    import com.modestmaps.core.MapExtent;
    import com.modestmaps.geo.Location;
    
    import flash.display.Sprite;
    //import flash.filters.DropShadowFilter;
    import flash.geom.Point;
    import flash.utils.Dictionary;
    
    /** 
    * a subclass of overlay that will render dashed great-circle arcs
    */
    public class GreatCircleOverlay extends Overlay
    {        
        public var lines:Array = [];
        private var styles:Dictionary = new Dictionary();
    
        public function GreatCircleOverlay(map:Map)
        {
            super(map);
            //this.filters = [ new DropShadowFilter(2,90,0x000000,0.35,8,8,2,1,false,false,false) ];
        }
        
        override public function redraw(sprite:Sprite):void
        {
            sprite.graphics.clear();
            for each (var line:Array in lines) {
                var lineStyle:LineStyle = styles[line] as LineStyle;
                var p:Point = map.locationPoint(line[0] as Location, sprite);
                sprite.graphics.moveTo(p.x, p.y);
                var i:int = 0;
                var prev:Location;
                for each (var location:Location in line.slice(1)) {
                    var thickness:Number = Math.min(1,1-Math.abs(i-(line.length/2))/(line.length/3));
/*                     if (i % 4 == 0 && i != line.length-1) {
                        sprite.graphics.lineStyle();
                    }
                    else {
                        lineStyle.apply(sprite.graphics, 1+thickness);
                    }            */
                    lineStyle.apply(sprite.graphics, 1+thickness);
                    p = map.locationPoint(location, sprite);
                    if (prev && (Math.abs(prev.lat-location.lat) > 10 || Math.abs(prev.lon-location.lon) > 10)) {
                        sprite.graphics.moveTo(p.x,p.y);
                    }
                    else {
                        sprite.graphics.lineTo(p.x,p.y);
                    }
                    i++;
                    prev = location;
                }
            }
        }
    
        public function addGreatCircle(start:Location, end:Location, lineStyle:LineStyle = null):MapExtent
        {
    
            var extent:MapExtent = new MapExtent();
            var latlngs:Array = [];

            with (Math) {
                
    			var lat1:Number = start.lat * PI / 180.0;
    			var lon1:Number = start.lon * PI / 180.0;
    			var lat2:Number = end.lat * PI / 180.0;
    			var lon2:Number = end.lon * PI / 180.0;
    			
    			var d:Number = 2*asin(sqrt( pow((sin((lat1-lat2)/2)),2) + cos(lat1)*cos(lat2)*pow((sin((lon1-lon2)/2)),2)));
    			var bearing:Number = atan2(sin(lon1-lon2)*cos(lat2), cos(lat1)*sin(lat2)-sin(lat1)*cos(lat2)*cos(lon1-lon2))  / -(PI/180);
    			bearing = bearing < 0 ? 360 + bearing : bearing;
    
                var numSegments:int = int(40 + (400 * Distance.approxDistance(start,end) / (Math.PI * 2 * 6378000)));
    			for (var n:int = 0 ; n < numSegments; n++ ) {
    				var f:Number = (1/(numSegments-1)) * n;
    				var A:Number = sin((1-f)*d)/sin(d);
    				var B:Number = sin(f*d)/sin(d);
    				var x:Number = A*cos(lat1)*cos(lon1) +  B*cos(lat2)*cos(lon2);
    				var y:Number = A*cos(lat1)*sin(lon1) +  B*cos(lat2)*sin(lon2);
    				var z:Number = A*sin(lat1)           +  B*sin(lat2);
    
    				var latN:Number = atan2(z,sqrt(pow(x,2)+pow(y,2)));
    				var lonN:Number = atan2(y,x);
    				var l:Location = new Location(latN/(PI/180), lonN/(PI/180));
    				latlngs.push(l);
    				extent.enclose(l);
                }
            }
            
            lines.push(latlngs);
            
            styles[latlngs] = lineStyle || new LineStyle();
    
            refresh();
            
            return extent;
        }
        
    }
}
