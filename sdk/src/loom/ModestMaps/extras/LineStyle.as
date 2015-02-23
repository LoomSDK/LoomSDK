package com.modestmaps.extras
{
    import flash.display.Graphics;

    public class LineStyle
    {
        public var thickness:Number;
        public var color:uint;
        public var alpha:Number;
        public var pixelHinting:Boolean;
        public var scaleMode:String;
        public var caps:String;
        public var joints:String;
        public var miterLimit:Number;
        
        public function LineStyle(thickness:Number=0, color:uint=0, alpha:Number=1, pixelHinting:Boolean=false, scaleMode:String="normal", caps:String=null, joints:String=null, miterLimit:Number=3.0)
        {
            this.thickness = thickness;
            this.color = color;
            this.alpha = alpha;
            this.pixelHinting = pixelHinting;
            this.scaleMode = scaleMode;
            this.caps = caps;
            this.joints = joints;
            this.miterLimit = miterLimit;
        }
        
        public function apply(graphics:Graphics, thicknessMod:Number=1, alphaMod:Number=1):void
        {
            graphics.lineStyle(thickness * thicknessMod, color, alpha * alphaMod, pixelHinting, scaleMode, caps, joints, miterLimit);
        }
    }    
}