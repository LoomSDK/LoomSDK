
package loom2d.text
{
    
    import loom2d.display.Image;
    import loom2d.textures.Texture;

    /** A BitmapChar contains the information about one char of a bitmap font.  
     *  _You don't have to use this class directly in most cases. 
     *  The TextField class contains methods that handle bitmap fonts for you._    
     */ 
    public class BitmapChar
    {
        private var mTexture:Texture;
        private var mCharID:int;
        private var mXOffset:Number;
        private var mYOffset:Number;
        private var mXAdvance:Number;

        // char id -> kerning amount
        private var mKernings:Dictionary.<int, Number>;
        
        /** Creates a char with a texture and its properties. */
        public function BitmapChar(id:int, texture:Texture, 
                                   xOffset:Number, yOffset:Number, xAdvance:Number)
        {
            mCharID = id;
            mTexture = texture;
            mXOffset = xOffset;
            mYOffset = yOffset;
            mXAdvance = xAdvance;
            mKernings = null;
        }
        
        /** Adds kerning information relative to a specific other character ID. */
        public function addKerning(charID:int, amount:Number):void
        {
            if (mKernings == null)
                mKernings = new Dictionary.<int, Number>();
            
            mKernings[charID] = amount;
        }
        
        /** Retrieve kerning information relative to the given character ID. */
        public function getKerning(charID:int):Number
        {
            if (mKernings == null || mKernings[charID] == null) return 0.0;
            else return mKernings[charID];
        }
        
        /** Creates an image of the char. */
        public function createImage():Image
        {
            return new Image(mTexture);
        }
        
        /** The unicode ID of the char. */
        public function get charID():int { return mCharID; }
        
        /** The number of points to move the char in x direction on character arrangement. */
        public function get xOffset():Number { return mXOffset; }
        
        /** The number of points to move the char in y direction on character arrangement. */
        public function get yOffset():Number { return mYOffset; }
        
        /** The number of points the cursor has to be moved to the right for the next char. */
        public function get xAdvance():Number { return mXAdvance; }
        
        /** The texture of the character. */
        public function get texture():Texture { return mTexture; }
        
        /** The width of the character in points. */
        public function get width():Number { return mTexture.width; }
        
        /** The height of the character in points. */
        public function get height():Number { return mTexture.height; }
    }
}