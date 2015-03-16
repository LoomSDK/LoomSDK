package feathers.text {
    import feathers.core.FeathersControl;
    import feathers.core.ITextRenderer;
    import loom2d.display.Graphics;
    import loom2d.display.Shape;
    import loom2d.display.TextAlign;
    import loom2d.display.TextAlign;
    import loom2d.display.TextFormat;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import system.Void;
    
    public class VectorTextRenderer extends FeathersControl implements ITextRenderer
    {
        private static const HELPER_POINT:Point;
        private static const DEFAULT_TEXT_FORMAT:TextFormat = new TextFormat();
        
        protected var g:Graphics;
        protected var _textFormat:TextFormat = DEFAULT_TEXT_FORMAT;
        
        protected var _text:String = "";
        protected var _shape:Shape;
        
        public function VectorTextRenderer()
        {
            super();
            
            _shape = new Shape();
            g = _shape.graphics;
            addChild(_shape);
        }
        
        function get baseline():Number
        {
            return _textFormat.lineHeight;
        }

        function get text():String
        {
            return _text;
        }
        
        function set text(value:String)
        {
            _text = value;
            invalidate();
            //trace("hello", value);
        }

        public function set textFormat(value:TextFormat):void
        {
            _textFormat = value;
            invalidate();
        }

        public function get textFormat():TextFormat
        {
            return _textFormat;
        }
        
        protected function processDisplayText(input:String):String
        {
            // Pass through; subclasses may want to rewrite the display string.
            return input;
        }
        
        public function validate():void
        {
            super.validate();
            
            //trace("validate", width, height, _text);
            
            //var p = measureText();
            
            var tmp:String = processDisplayText(_text);
            g.clear();
            _textFormat.align = TextAlign.MIDDLE;
            g.textFormat(_textFormat);
            //g.drawTextBox(0, 0, width+1, tmp);
            g.drawTextLine(0, height/2, tmp);
            //g.lineStyle(1, 0xFF0000);
            //g.moveTo(0, 0);
            //g.lineTo(width, height);
            //g.drawRect(0, 0, width, height); 
        }
        
        protected function measureText():Point
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                HELPER_POINT.x = this.explicitWidth;
                HELPER_POINT.y = this.explicitHeight;
                //trace("helper", HELPER_POINT);
                return HELPER_POINT;
            }
            
            var tmp:String = processDisplayText(_text);
            
            if (tmp == null) return new Point(0, 0);
            
            //var bounds:Rectangle = g.textBoxBounds(_textFormat, 0, 0, needsWidth ? Number.MAX_VALUE : this.explicitWidth, tmp);
            var bounds:Rectangle = g.textLineBounds(_textFormat, 0, 0, tmp);
            //var bounds:Rectangle = g.textBoxBounds(new TextFormat(), 0, 0, needsWidth ? 2147483647 : this.explicitWidth, tmp);
            
            //trace("bounds", needsWidth, needsHeight, new Point(bounds.width, bounds.height), tmp);
            return new Point(bounds.width, bounds.height);
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