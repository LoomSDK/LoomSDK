/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.text
{
    import feathers.text.TextFormatAlign;

    import loom2d.text.BitmapFont;
    import loom2d.text.TextField;

    /**
     * Customizes a bitmap font for use by a `BitmapFontTextRenderer`.
     * 
     * @see feathers.controls.text.BitmapFontTextRenderer
     */
    public class BitmapFontTextFormat
    {
        /**
         * Constructor.
         */
        public function BitmapFontTextFormat(_font:Object, _size:Number = NaN, 
            _color:uint = 0xff00ff, _bold:Boolean = false, 
            _align:String = "left" /* Go back to TextFormatAlign.LEFT when LOOM-1441 is fixed.*/)
        {
            if(_font is String)
            {
                _font = TextField.getBitmapFont(_font as String);
            }
            if(!(_font is BitmapFont))
            {
                Debug.assert("BitmapFontTextFormat font must be a BitmapFont instance or a String representing the name of a registered bitmap font. Got: " + font);
            }
            this.font = BitmapFont(_font);
            this.size = _size;
            this.color = _color;
            this.align = _align;
        }

        public function get fontName():String
        {
            return this.font ? this.font.name : null;
        }
        
        /**
         * The BitmapFont instance to use.
         */
        public var font:BitmapFont;
        
        /**
         * The multiply color.
         */
        public var color:uint;
        
        /**
         * The size at which to display the bitmap font. Set to `NaN`
         * to use the default size in the BitmapFont instance.
         */
        public var size:Number;
        
        /**
         * The number of extra pixels between characters. May be positive or
         * negative.
         */
        public var letterSpacing:Number = 0;

        [Inspectable(type="String",enumeration="left,center,right")]

        /**
         * Determines the alignment of the text, either left, center, or right.
         */
        public var align:String = TextFormatAlign.LEFT;
        
        /**
         * Determines if the kerning values defined in the BitmapFont instance
         * will be used for layout.
         */
        public var isKerningEnabled:Boolean = true;
    }
}