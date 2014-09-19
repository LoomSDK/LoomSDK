// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.display
{    
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    
    import loom2d.utils.VertexData;
    import loom2d.textures.Texture;
    
    /** TODO
     */

    [Native(managed)]
    public native class Shape extends DisplayObject
    {
        /** Creates a quad with a certain size and color. The 'premultipliedAlpha' parameter 
         *  controls if the alpha value should be premultiplied into the color values on 
         *  rendering, which can influence blending output. You can use the default value in 
         *  most cases.  The last parameter is whether or not to initialize the vertices of
         *  the Quad with the data provided, or to leave empty for custom manipulation.  */
        public function Shape()
        {            
            
        }
        
        public native function clear():void;
        public native function lineStyle(thickness:Number = NaN, color:uint = 0x00000000, alpha:Number = 1, pixelHinting:Boolean = false, scaleMode:String = "", caps:String = "round", joints:String = "round", miterLimit:Number = 0):void;
        public native function beginFill(color:uint = 0x00000000, alpha:Number = 1):void;
        public native function endFill():void;
        public native function moveTo(x:Number, y:Number):void;
        public native function lineTo(x:Number, y:Number):void;
        public native function curveTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number):void;
        public native function cubicCurveTo(controlX1:Number, controlY1:Number, controlX2:Number, controlY2:Number, anchorX:Number, anchorY:Number):void;
        public native function drawCircle(x:Number, y:Number, radius:Number):void;
        public native function drawEllipse(x:Number, y:Number, width:Number, height:Number):void;
        public native function drawRect(x:Number, y:Number, width:Number, height:Number):void;
        public native function drawRoundRect(x:Number, y:Number, width:Number, height:Number, ellipseWidth:Number, ellipseHeight:Number):void;
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            // TODO fix
            resultRect.setTo(0, 0, 100, 100);
            
            return resultRect;
        }

    }
}