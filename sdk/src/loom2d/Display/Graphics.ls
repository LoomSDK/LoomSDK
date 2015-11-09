package loom2d.display
{
    import loom2d.math.Matrix;
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;
    
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
     * SVG vector image that can be loaded from a file or string. Draw with `Graphics.drawSVG()`.
     */
    public native class SVG
    {
        /**
         * Get the width of the displayed SVG in pixels before any transformations.
         */
        public native function get width():Number;
        
        /**
         * Get the height of the displayed SVG in pixels before any transformations.
         */
        public native function get height():Number;
        
        
        /**
         * Load a file containing the SVG layout and replace the current SVG contents with it.
         * 
         * @see `fromFile`
         * @param path  The path of the SVG asset.
         * @param units The unit to interpret the values in.
         *              The supported values are `px`, `pt`, `pc`, `mm`, `cm`, `in`, `%`, `em`, `ex`.
         *              Use `px` for direct interpretation.
         *              Use one of the other units along with `dpi` to scale the image accordingly.
         * @param dpi   Dots per inch of the SVG image. Used for proper scaling units other than `px`.
         */
        public native function loadFile(path:String, units:String = "px", dpi:Number = 96);
        
        /**
         * Load an SVG image asset from the file system and return it as an SVG object.
         * This is the static factory for convenient loading through the use of `loadFile`.
         * 
         * @see `loadFile`
         * @param path  The path of the SVG asset.
         * @param units The unit to interpret the values in.
         *              The supported values are `px`, `pt`, `pc`, `mm`, `cm`, `in`, `%`, `em`, `ex`.
         *              Use `px` for direct interpretation.
         *              Use one of the other units along with `dpi` to scale the image accordingly.
         * @param dpi   Dots per inch of the SVG image. Used for proper scaling units other than `px`.
         */
        public static function fromFile(path:String, units:String = "px", dpi:Number = 96):SVG {
            var svg = new SVG(); svg.loadFile(path, units, dpi); return svg;
        }
        
        /**
         * Load an SVG layout from a string and replace the current SVG contents with it.
         * Use `loadFile` when loading a file asset to enable support for live reloading.
         * 
         * @see `fromString`
         * @see `loadFile`
         * @param path  The path of the SVG asset.
         * @param units The unit to interpret the values in.
         *              The supported values are `px`, `pt`, `pc`, `mm`, `cm`, `in`, `%`, `em`, `ex`.
         *              Use `px` for direct interpretation.
         *              Use one of the other units along with `dpi` to scale the image accordingly.
         * @param dpi   Dots per inch of the SVG image. Used for proper scaling units other than `px`.
         */
        public native function loadString(svg:String, units:String = "px", dpi:Number = 96);
        
        
        /**
         * Load an SVG layout from a string and return it as an SVG object.
         * This is the static factory for convenient loading through the use of `loadString`.
         * Use `fromFile` when loading a file asset to enable support for live reloading.
         * 
         * @see `loadString`
         * @see `fromFile`
         * @param path  The path of the SVG asset.
         * @param units The unit to interpret the values in.
         *              The supported values are `px`, `pt`, `pc`, `mm`, `cm`, `in`, `%`, `em`, `ex`.
         *              Use `px` for direct interpretation.
         *              Use one of the other units along with `dpi` to scale the image accordingly.
         * @param dpi   Dots per inch of the SVG image. Used for proper scaling units other than `px`.
         */
        public static function fromString(path:String, units:String = "px", dpi:Number = 96):SVG {
            var svg = new SVG(); svg.loadString(path, units, dpi); return svg;
        }
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
            Debug.assert(false, "You cannot instantiate a Graphics object. Create a Shape using `var shape = new Shape()` and use its `shape.graphics` object instead.");
        }
        
        /**
         * Clear all draw commands and return to a clean state.
         */
        public native function clear():void;

        /**
         * Resets the bounds to their default state.
         */
        public native function clearBounds():void;
        
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
         * Begin a textured fill with an existing Texture. Use the `matrix` parameter to control
         * the texture transformation matrix within the fill and `repeat` and `smooth` to control
         * how the texture gets rendered on a per-fill basis.
         * 
         * @param texture   The Texture to fill the shape with.
         * @param matrix    Transformation matrix of the texture within the fill.
         * @param repeat    Repeat the texture in all directions within the fill.
         * @param smooth    Switch between the smooth (bilinear) and non-smooth (nearest) texture smoothing.
         */
        public function beginTextureFill(texture:Texture, matrix:Matrix = null, repeat:Boolean = true, smooth:Boolean = true):void {
            beginTextureFillID(texture.nativeID, matrix, repeat, smooth);
        }
        protected native function beginTextureFillID(id:int, matrix:Matrix, repeat:Boolean, smooth:Boolean):void;
        
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
        
        /**
         * Creates new rounded rectangle shaped sub-path with individually controllable corner radiuses.
         */
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
         * Draw an SVG at the provided position with the provided scale and line thickness multiplier.
         * The SVG is drawn with the top left corner placed at the provided position and then scaled according to the provided scale.
         * 
         * @param svg           The SVG to draw.
         * @param x             The x position coordinate.
         * @param x             The y position coordinate.
         * @param scale         The scale multiplier of the SVG image.
         * @param lineThickness A multiplier for the stroke thickness of the drawn lines.
         *                      For example, setting this to 2 will double the width of all the drawn lines.
         */
        public native function drawSVG(svg:SVG, x:Number = 0, y:Number = 0, scale:Number = 1, lineThickness:Number = 1):void;
        
        /**
         * Get the current bounds of the graphics drawn by this instance.
         */
        public native function getBounds():Rectangle;
    }
}
