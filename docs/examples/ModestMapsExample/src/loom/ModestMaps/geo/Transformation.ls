/*
 * $Id$
 */

package loom.modestmaps.geo
{
    //import flash.geom.Point;
    import loom2d.math.Point;

    public class Transformation
    {
        protected var ax:Number;
        protected var bx:Number;
        protected var cx:Number;
        protected var ay:Number;
        protected var by:Number;
        protected var cy:Number;

        /** 
         * equivalent to "new flash.geom.Matrix(ax,bx,ay,by,cy,cx)"
         */
        public function Transformation(ax:Number, bx:Number, cx:Number, ay:Number, by:Number, cy:Number)
        {
            this.ax = ax;
            this.bx = bx;
            this.cx = cx;
            this.ay = ay;
            this.by = by;
            this.cy = cy; 
        }
        
       /**
        * String signature of the current transformation.
        */
        public function toString():String
        {
            return 'T(['+ax+','+bx+','+cx+']['+ay+','+by+','+cy+'])';
        } 
        
       /**
        * Transform a point.
        */
        public function transform(point:Point)
        {
            var px = point.x;
            var py = point.y;
            point.x = ax*px + bx*py + cx;
            point.y = ay*px + by*py + cy; 
        }
        
       /**
        * Inverse of transform; p = untransform(transform(p))
        */
        public function untransform(point:Point)
        {
            var px = point.x;
            var py = point.y;
            point.x = (px*by - py*bx - cx*by + cy*bx) / (ax*by - ay*bx);
            point.y = (px*ay - py*ax - cx*ay + cy*ax) / (bx*ay - by*ax); 
        }
    }
}