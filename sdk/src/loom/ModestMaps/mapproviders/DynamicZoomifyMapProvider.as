package com.modestmaps.mapproviders
{
	import com.modestmaps.geo.LinearProjection;
	import com.modestmaps.geo.Location;
	import com.modestmaps.geo.MercatorProjection;
	import com.modestmaps.geo.Transformation;
	
	import flash.geom.Point;
	
	public class DynamicZoomifyMapProvider extends AbstractZoomifyMapProvider implements IMapProvider
	{
	    public function DynamicZoomifyMapProvider(baseURL:String, imageWidth:Number, imageHeight:Number, mercator:Boolean,
	    										  l1:Location, p1:Point, l2:Location, p2:Point, l3:Location, p3:Point)
	    {
	        defineImageProperties(baseURL, imageWidth, imageHeight);
	        var projectionZoom:int = Math.ceil(Math.log(Math.max(imageWidth, imageHeight)) / Math.LN2);
	        var t:Transformation = deriveTransformation(mercator, l1, p1, l2, p2, l3, p3);
	        __projection = mercator ? new MercatorProjection(projectionZoom, t) : new LinearProjection(projectionZoom, t);
	    }
	    
	    protected function rawProject(lat:Number):Number
	    {
	        return Math.log(Math.tan(0.25 * Math.PI + 0.5 * lat));        
	    }
	    
	    /** Generates a transform based on three pairs of points, l1 -> p1, l2 -> p2, l3 -> p3. */
	    protected function deriveTransformation(mercator:Boolean, l1:Location, p1:Point, l2:Location, p2:Point, l3:Location, p3:Point):Transformation
	    {
	        var deg2rad:Number = Math.PI/180.0;
	        
	        var a1x:Number = l1.lon*deg2rad;
	        var a1y:Number = mercator ? rawProject(l1.lat*deg2rad) : l1.lat*deg2rad;
	        var a2x:Number = p1.x;
	        var a2y:Number = p1.y;
	        var b1x:Number = l2.lon*deg2rad;
	        var b1y:Number = mercator ? rawProject(l2.lat*deg2rad) : l2.lat*deg2rad;
	        var b2x:Number = p2.x;
	        var b2y:Number = p2.y;
	        var c1x:Number = l3.lon*deg2rad;
	        var c1y:Number = mercator ? rawProject(l3.lat*deg2rad) : l3.lat*deg2rad;
	        var c2x:Number = p3.x;
	        var c2y:Number = p3.y;
	
	        var x:Array = linearSolution(a1x, a1y, a2x, b1x, b1y, b2x, c1x, c1y, c2x);
	        var y:Array = linearSolution(a1x, a1y, a2y, b1x, b1y, b2y, c1x, c1y, c2y);
	        
	        return new Transformation(x[0], x[1], x[2], y[0], y[1], y[2]);
	    }
	
	    /** Solves a system of linear equations.
	
	      t1 = (a * r1) + (b + s1) + c
	      t2 = (a * r2) + (b + s2) + c
	      t3 = (a * r3) + (b + s3) + c
	
	    r1 - t3 are the known values.
	    a, b, c are the unknowns to be solved.
	    returns the a, b, c coefficients.
	    */
	    protected function linearSolution(r1:Number, s1:Number, t1:Number, r2:Number, s2:Number, t2:Number, r3:Number, s3:Number, t3:Number):Array
	    {
	        var a:Number = (((t2 - t3) * (s1 - s2)) - ((t1 - t2) * (s2 - s3))) / (((r2 - r3) * (s1 - s2)) - ((r1 - r2) * (s2 - s3)));
	        var b:Number = (((t2 - t3) * (r1 - r2)) - ((t1 - t2) * (r2 - r3))) / (((s2 - s3) * (r1 - r2)) - ((s1 - s2) * (r2 - r3)));
	        var c:Number = t1 - (r1 * a) - (s1 * b);
	        return [ a, b, c ];
	    }
	    
	    override public function toString():String
	    {
	        return "DYNAMIC_ZOOMIFY";
	    }
	}
}

