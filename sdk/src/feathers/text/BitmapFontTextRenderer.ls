package feathers.text
{

    import feathers.core.ITextRenderer;
    import feathers.core.FeathersControl;
    import feathers.system.DeviceCapabilities;
    import loom2d.text.TextField;
    import loom2d.text.BitmapFont;
    import loom2d.math.Point;
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.QuadBatch;
    import loom2d.utils.VAlign;


    public class BitmapFontTextRenderer extends FeathersControl implements ITextRenderer
    {
        private static const HELPER_POINT:Point;

        // Dummy to avoid property spam.
        public var embedFonts:Boolean = false;

        public function BitmapFontTextRenderer()
        {
            Debug.assert( TextField.defaultBitmapFont != null,
                "Tried creating a BitmapFontTextRenderer and no BitmapFonts are registered. " + 
                "Have you called registerBitmapFont() on loom2d.text.TextField?"
            );
            
            _textFormat = new BitmapFontTextFormat(TextField.defaultBitmapFont, 12, 0xffffff);

            super();

            addChild(_quadBatch);
        }
        
        protected var _explicitAlign:String = null;
        protected var _vAlign:String = VAlign.CENTER;
        protected var _quadBatch:QuadBatch = new QuadBatch();

        /**
         * Set to a value from TextFormatAlign to override the horizontal centering in
         * the BitmapFontTextFormat.
         */
        public function set align(value:String):void
        {
            _explicitAlign = value;
            invalidate();
        }

        public function get align():String
        {
            if(_explicitAlign != null)
                return _explicitAlign;
            return _textFormat.align;
        }

        /**
         * Set to a value from VAlign to use for the vertical centering of the text
         */
        public function set vAlign(value:String):void
        {
            _vAlign = value;
            invalidate();
        }

        public function get vAlign():String
        {
            return _vAlign;
        }
        public var autoSize:Boolean = false;

        protected function processDisplayText(input:String):String
        {
            // Pass through; subclasses may want to rewrite the display string.
            return input;
        }

        protected var _textFormat:BitmapFontTextFormat;

        public function set textFormat(value:BitmapFontTextFormat):void
        {
            _textFormat = value;
            invalidate();
        }

        public function get textFormat():BitmapFontTextFormat
        {
            return _textFormat;
        }

        protected var _text:String = "";

        public function get text():String
        {
            return _text;
        }

        public function set text(value:String):void
        {
            // Store the text.
            _text = value;
            invalidate();
            
            //trace("Scale factor is " + (DeviceCapabilities.dpi/72))
            //trace("Display for '" + tmp + "' took " + (getChildAt(0) as DisplayObjectContainer).numChildren + " nodes " + width + "x" + height);
        }

        public function validate():void
        {
            super.validate();

            var tmp:String = processDisplayText(_text);

            // Add text.
            _quadBatch.reset();
            _textFormat.font.fillQuadBatch(_quadBatch, width, height, tmp, _textFormat.size, _textFormat.color, align, vAlign, autoSize);
        }

        public function get baseline():Number
        {
            const font:BitmapFont = this._textFormat.font;
            const formatSize:Number = this._textFormat.size;
            const fontSizeScale:Number = isNaN(formatSize) ? 1 : (formatSize / font.size);
            if(isNaN(font.baseline))
            {
                return font.lineHeight * fontSizeScale;
            }
            return font.baseline * fontSizeScale;            
        }

        public function measureText():Point
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                //trace("explicit resize " + _textFormat.align);
                HELPER_POINT.x = this.explicitWidth;
                HELPER_POINT.y = this.explicitHeight;
                return HELPER_POINT;
            }

            var tmp:String = processDisplayText(_text);
            return _textFormat.font.getStringDimensions(tmp, maxWidth, maxHeight,  
                _textFormat.size);
        }

        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);

            if(dataInvalid || stylesInvalid || sizeInvalid)
            {
                if(!this.textFormat || !this._text)
                {
                    this.setSizeInternal(0, 0, false);
                    return;
                }
                HELPER_POINT = this.measureText();
                this.setSizeInternal(HELPER_POINT.x, HELPER_POINT.y, false);
            }
        }

    }
}