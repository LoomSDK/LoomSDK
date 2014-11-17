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
    import loom2d.math.Rectangle;
    
    /** TODO
     */
    
    public enum TextAlign {
        // Horizontal align
        
        /** Default, align text horizontally to left. */
        LEFT = 1,
        
        /** Align text horizontally to center. */
        CENTER = 2,
        
        /** Align text horizontally to right. */
        RIGHT = 4,
        
        
        // Vertical align
        
        /** Align text vertically to top. */
        TOP = 8,
        
        /** Align text vertically to middle. */
        MIDDLE = 16,
        
        /** Align text vertically to bottom. */
        BOTTOM = 32,
        
        /** Default, align text vertically to baseline. */
        BASELINE = 64,
    };
    
    public native class TextFormat
    {
        public native function set color(value:int);
        public native function get color():int;
        public native function set size(value:float);
        public native function get size():float;
        public native function set align(value:int);
        public native function get align():float;
        public native function set letterSpacing(value:float);
        public native function get letterSpacing():float;
        public native function set lineHeight(value:float);
        public native function get lineHeight():float;
    }
    
    [Native(managed)]
    public native class SVG
    {
        public native function loadFile(path:String, units:String = "px", dpi:Number = 96);
        public native function loadString(svg:String, units:String = "px", dpi:Number = 96);
    }
    
    [Native(managed)]
    public native class Graphics
    {
        public function Graphics()
        {            
            
        }
        
        public native function clear():void;
        public native function lineStyle(thickness:Number = NaN, color:uint = 0x00000000, alpha:Number = 1, pixelHinting:Boolean = false, scaleMode:String = "", caps:String = "round", joints:String = "round", miterLimit:Number = 0):void;
        public native function textFormat(format:TextFormat):void;
        public native function beginFill(color:uint = 0x00000000, alpha:Number = 1):void;
        public native function endFill():void;
        public native function moveTo(x:Number, y:Number):void;
        public native function lineTo(x:Number, y:Number):void;
        public native function curveTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number):void;
        public native function cubicCurveTo(controlX1:Number, controlY1:Number, controlX2:Number, controlY2:Number, anchorX:Number, anchorY:Number):void;
        public native function arcTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number, radius:Number):void;
        public native function drawCircle(x:Number, y:Number, radius:Number):void;
        public native function drawEllipse(x:Number, y:Number, width:Number, height:Number):void;
        public native function drawRect(x:Number, y:Number, width:Number, height:Number):void;
        public native function drawRoundRect(x:Number, y:Number, width:Number, height:Number, ellipseWidth:Number, ellipseHeight:Number):void;
        public native function drawArc(x:Number, y:Number, radius:Number, angleFrom:Number, angleTo:Number, direction:int):void;
        public native function drawTextLabel(x:Number, y:Number, text:String):void;
        public native function drawTextBox(x:Number, y:Number, width:Number, text:String):void;
        public native function drawSVG(x:Number, y:Number, scale:Number, svg:SVG):void;
        public native function getBounds():Rectangle;

    }
}