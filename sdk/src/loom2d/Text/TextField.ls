package loom2d.text
{
    public class TextField
    {
        /** The default BitmapFont to use when none is specified. It is set to the first registered font. */
        public static var defaultBitmapFont:BitmapFont;

        protected static var bitmapFonts:Dictionary.<String, BitmapFont> = new Dictionary.<String, BitmapFont>();

        /** Makes a bitmap font available at any TextField in the current stage3D context.
         *  The font is identified by its `name`.
         *  Per default, the `name` property of the bitmap font will be used, but you 
         *  can pass a custom name, as well. @returns the name of the font. */
        public static function registerBitmapFont(bitmapFont:BitmapFont, name:String=null):String
        {
            if (name == null) name = bitmapFont.name;
            bitmapFonts[name] = bitmapFont;
            if (!defaultBitmapFont) defaultBitmapFont = bitmapFont;
            return name;
        }
        
        /** Unregisters the bitmap font and, optionally, disposes it. */
        public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
        {
            if (dispose && bitmapFonts[name] != null)
                bitmapFonts[name].dispose();
            
            //delete bitmapFonts[name];
            bitmapFonts[name] = null;
        }
        
        /** Returns a registered bitmap font (or null, if the font has not been registered). */
        public static function getBitmapFont(name:String):BitmapFont
        {
            return bitmapFonts[name];
        }
    }
}