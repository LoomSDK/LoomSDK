package loom2d.display
{
    import loom2d.math.Rectangle;
    
    /**
     * Text alignment flags used by the Graphics class.
     *
     * You may combine flags with the bitwise OR operator to specify
     * vertical and horizontal alignment, ie, LEFT | TOP.
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
    
    [Native(managed)] 
    /**
     * Describe the format of some text for the Graphics class. Pass
     * to Graphics.textFormat() to specify the active format.
     */
    public native class TextFormat
    {
        /**
         * Describe a font format by specifying font name, indicating size, color, and if it's bolded.
         *
         * If you don't specify a property, it remains unspecified and doesn't alter render state when the
         * format is passed via textFormat().
         */
        function TextFormat(font:String = null, size:Number = NaN, color:Number = NaN, bold:Object = null) {
            if (font != null) this.font = font;
            if (!isNaN(size)) this.size = size;
            if (!isNaN(color)) this.color = color;
        }
        
        /**
         * What font should we use with this text format? The name is one previously
         * passed to TextFormat.load().
         */
        public native function set font(value:String);
        public native function get font():String;
        
        /**
         * RGB color of the text.
         */
        public native function set color(value:int);
        public native function get color():int;
        
        /**
         * Size of text in pixels.
         */
        public native function set size(value:float);
        public native function get size():float;
        
        /**
         * Align as specified in TextAlign.
         */
        public native function set align(value:int);
        public native function get align():float;
        
        /**
         * Add additional spacing between letters.
         */
        public native function set letterSpacing(value:float);
        public native function get letterSpacing():float;
        
        /**
         * Add additional space between lines (in pixels).
         */
        public native function set lineHeight(value:float);
        public native function get lineHeight():float;
        
        /**
         * Load a TTF font from a given path and register it under the specified name.
         */
        public native static function load(fontName:String, filePath:String);
    }
    
    [Native(managed)]
    /**
     * Utility class to load SVG vectors from a file or string. Draw with Graphics.drawSVG().
     */
    public native class SVG
    {
        public native function loadFile(path:String, units:String = "px", dpi:Number = 96);
        public native function loadString(svg:String, units:String = "px", dpi:Number = 96);
    }
    
    [Native(managed)]
    /**
     * Draw GPU accelerated vector graphics. Used in conjunction with the Shape class.
     *
     * Draw calls are buffered and drawn every frame until you call clear().
     */
    public native class Graphics
    {
        public function Graphics()
        {
        }
        
        /**
         * Clear all draw commands and return to a clean state.
         */
        public native function clear():void;
        
        /*
         * Specify the style used for lines.
         */
        public native function lineStyle(thickness:Number = NaN, color:uint = 0x00000000, alpha:Number = 1, pixelHinting:Boolean = false, scaleMode:String = "", caps:String = "round", joints:String = "round", miterLimit:Number = 0):void;
        
        /**
         * Indicate the format used to display text.
         */
        public native function textFormat(format:TextFormat):void;
        
        /**
         * Get the bounds of a given string as it would be drawn with specified format.
         */
        public native function textLineBounds(format:TextFormat, x:Number, y:Number, text:String):Rectangle;
        
        /**
         * Determine the logical width of the passed strings. This can vary from bounds and is
         * usually used for positioning text.
         */
        public native function textLineAdvance(format:TextFormat, x:Number, y:Number, text:String):float;
        
        /**
         * Determine the bounds of a text box drawn with the provided position, line width and format.
         */
        public native function textBoxBounds(format:TextFormat, x:Number, y:Number, width:Number, text:String):Rectangle;
        
        /**
         * Indicate we are beginning a filled shape.
         */
        public native function beginFill(color:uint = 0x00000000, alpha:Number = 1):void;
        
        /**
         * End drawing of a filled shape.
         */
        public native function endFill():void;
        
        /**
         * Starts new sub-path with specified point as first point.
         */
        public native function moveTo(x:Number, y:Number):void;
        
        /**
         * Adds line segment from the last point in the path to the specified point.
         */
        public native function lineTo(x:Number, y:Number):void;

        /**
         * Adds quadratic bezier segment from last point in the path via a control point to the specified point.
         */
        public native function curveTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number):void;
        
        /**
         * Adds cubic bezier segment from last point in the path via two control points to the specified point.
         */
        public native function cubicCurveTo(controlX1:Number, controlY1:Number, controlX2:Number, controlY2:Number, anchorX:Number, anchorY:Number):void;
        
        /**
         * Adds an arc segment at the corner defined by the last path point, and two specified points.
         */
        public native function arcTo(controlX:Number, controlY:Number, anchorX:Number, anchorY:Number, radius:Number):void;
        
        /**
         * Creates new circle shaped sub-path. 
         */
        public native function drawCircle(x:Number, y:Number, radius:Number):void;
        
        /**
         * Creates new ellipse shaped sub-path.
         */
        public native function drawEllipse(x:Number, y:Number, width:Number, height:Number):void;
        
        /**
         * Creates new rectangle shaped sub-path.
         */
        public native function drawRect(x:Number, y:Number, width:Number, height:Number):void;
        
        /**
         * Creates new rounded rectangle shaped sub-path.
         */
        public native function drawRoundRect(x:Number, y:Number, width:Number, height:Number, ellipseWidth:Number, ellipseHeight:Number):void;
        
        public native function drawRoundRectComplex(x:Number, y:Number, width:Number, height:Number, topLeftRadius:Number, topRightRadius:Number, bottomLeftRadius:Number, bottomRightRadius:Number):void;
        
        /**
         * Creates new circle arc shaped sub-path. The arc center is at x,y, the arc radius is radius, and the arc is drawn from angle angleFrom to angleTo, and swept in direction dir (NVG_CCW, or NVG_CW). Angles are specified in radians.
         */
        public native function drawArc(x:Number, y:Number, radius:Number, angleFrom:Number, angleTo:Number, direction:int):void;
        
        /**
         * Draw a line of text using the current format.
         */
        public native function drawTextLine(x:Number, y:Number, text:String):void;
        
        /**
         * Draw text in a box using the current format.
         */
        public native function drawTextBox(x:Number, y:Number, width:Number, text:String):void;
        
        /**
         * Draw an SVG at the given center point.
         */
        public native function drawSVG(x:Number, y:Number, scale:Number, svg:SVG):void;
        
        /**
         * Get the current bounds of the graphics drawn by this instance.
         */
        public native function getBounds():Rectangle;
    }
}
