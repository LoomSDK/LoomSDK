// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.text
{
    import system.platform.Path;

    import loom2d.math.Rectangle;
    import loom2d.math.Point;
    
    import loom2d.display.Image;
    import loom2d.display.QuadBatch;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;
    //import loom2d.textures.TextureSmoothing;
    import loom2d.utils.HAlign;
    import loom2d.utils.VAlign;

    /** The BitmapFont class parses bitmap font files and arranges the glyphs 
     *  in the form of a text.
     *
     *  The class parses the XML format as it is used in the 
     *  [AngelCode Bitmap Font Generator](http://www.angelcode.com/products/bmfont/) or
     *  the [Glyph Designer](http://glyphdesigner.71squared.com/). 
     *  This is what the file format looks like:
     *
     *  ~~~xml
     *  &lt;font&gt;
     *    &lt;info face="BranchingMouse" size="40" /&gt;
     *    &lt;common lineHeight="40" /&gt;
     *    &lt;pages&gt;  &lt;!-- currently, only one page is supported --&gt;
     *      &lt;page id="0" file="texture.png" /&gt;
     *    &lt;/pages&gt;
     *    &lt;chars&gt;
     *      &lt;char id="32" x="60" y="29" width="1" height="1" xoffset="0" yoffset="27" xadvance="8" /&gt;
     *      &lt;char id="33" x="155" y="144" width="9" height="21" xoffset="0" yoffset="6" xadvance="9" /&gt;
     *    &lt;/chars&gt;
     *    &lt;kernings&gt; &lt;!-- Kerning is optional --&gt;
     *      &lt;kerning first="83" second="83" amount="-4"/&gt;
     *    &lt;/kernings&gt;
     *  &lt;/font&gt;
     *  ~~~
     *  
     *  Pass an instance of this class to the method `registerBitmapFont` of the
     *  TextField class. Then, set the `fontName` property of the text field to the 
     *  `name` value of the bitmap font. This will make the text field use the bitmap
     *  font.  
     */ 
    public class BitmapFont
    {
        /** Use this constant for the `fontSize` property of the TextField class to 
         *  render the bitmap font in exactly the size it was created. */ 
        public static const NATIVE_SIZE:int = -1;
        
        /** The font name of the embedded minimal bitmap font. Use this e.g. for debug output. */
        public static const MINI:String = "mini";
        
        private static const CHAR_SPACE:int           = 32;
        private static const CHAR_TAB:int             =  9;
        private static const CHAR_NEWLINE:int         = 10;
        private static const CHAR_CARRIAGE_RETURN:int = 13;
        
        private var mTexture:Texture;
        private var mChars:Dictionary.<int, BitmapChar>;
        private var mName:String;
        private var mSize:Number;
        private var mLineHeight:Number;
        private var mBaseline:Number;
        private var mHelperImage:Image;
        private var mCharLocationPool:Vector.<CharLocation>;

        private static var sFontCache:Dictionary.<String, BitmapFont> = {};

        /** Helper objects. */
        private static var sHelperPoint:Point;
   
        public function BitmapFont()
        {

        }

        public static function load(fontSource:String):BitmapFont
        {
            Debug.assert(fontSource.indexOf(".fnt") != -1, "Please specify a fnt file to load");

            if (sFontCache[fontSource])
            {
                return sFontCache[fontSource];
            }

            var bmf = new BitmapFont();

            var bfi:BitmapFontInfo = BitmapFontParser.parseFont(fontSource);

            Debug.assert(bfi, "unable to parse bitmap info");
            Debug.assert(bfi.textureName, "null texture name from bitmap font info");

            // calculate font texture path relative to the fnt file
            var delim = Path.getFolderDelimiter();
            var fontPath = Path.normalizePath(fontSource);
            var _dir = fontPath.split(delim);

            // default to assets folder
            var dir = "assets";

            if (_dir.length)
            {    
                // strip off .fnt file
                _dir.length = _dir.length - 1;

                dir = _dir.join(delim);
                
            }            

            var texture = Texture.fromAsset(dir + delim + bfi.textureName);

            Debug.assert(texture, "Unable to load texture");

            bmf.mName = "unknown";
            bmf.mLineHeight = bmf.mSize = bmf.mBaseline = 14;
            bmf.mTexture = texture;
            bmf.mChars = new Dictionary();
            bmf.mHelperImage = new Image(texture);
            bmf.mCharLocationPool = new Vector.<CharLocation>();
            bmf.parseFontAsset(bfi);

            sFontCache[fontSource] = bmf;

            return bmf;

        }
        
        /** Disposes the texture of the bitmap font! */
        public function dispose():void
        {
            if (mTexture)
                mTexture.dispose();
        }

        private function parseFontAsset(bfi:BitmapFontInfo):void
        {
            Debug.assert(mTexture, "null texture");

            var scale:Number = mTexture.scale;
            var frame:Rectangle = mTexture.frame;

            mName = bfi.name;
            mSize = bfi.size;
            mLineHeight = bfi.lineHeight;
            mBaseline = bfi.baseLine;

            for each (var c:BitmapCharInfo in bfi.characters)
            {
                    var texture:Texture = Texture.fromTexture(mTexture, c.region);
                    var bitmapChar:BitmapChar = new BitmapChar(c.id, texture, c.xOffset, c.yOffset, c.xAdvance); 
                    addChar(c.id, bitmapChar);          
            }


            if (mSize <= 0)
            {
                trace("[Loom2D] Warning: invalid font size " + mSize + " in '" + mName + "' font.");
                mSize = (mSize == 0.0 ? 16.0 : mSize * -1.0);
            }            

        }
        
        // TODO: Fix up XML loading
        /*
        private function parseFontXml(fontXml:XML):void
        {
            var scale:Number = mTexture.scale;
            var frame:Rectangle = mTexture.frame;
            
            mName = fontXml.info.attribute("face");
            mSize = parseFloat(fontXml.info.attribute("size")) / scale;
            mLineHeight = parseFloat(fontXml.common.attribute("lineHeight")) / scale;
            mBaseline = parseFloat(fontXml.common.attribute("base")) / scale;
            
            if (fontXml.info.attribute("smooth").toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (mSize <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + mName + "' font.");
                mSize = (mSize == 0.0 ? 16.0 : mSize * -1.0);
            }
            
            for each (var charElement:XML in fontXml.chars.char)
            {
                var id:int = parseInt(charElement.attribute("id"));
                var xOffset:Number = parseFloat(charElement.attribute("xoffset")) / scale;
                var yOffset:Number = parseFloat(charElement.attribute("yoffset")) / scale;
                var xAdvance:Number = parseFloat(charElement.attribute("xadvance")) / scale;
                
                var region:Rectangle = new Rectangle();
                region.x = parseFloat(charElement.attribute("x")) / scale + frame.x;
                region.y = parseFloat(charElement.attribute("y")) / scale + frame.y;
                region.width  = parseFloat(charElement.attribute("width")) / scale;
                region.height = parseFloat(charElement.attribute("height")) / scale;
                
                var texture:Texture = Texture.fromTexture(mTexture, region);
                var bitmapChar:BitmapChar = new BitmapChar(id, texture, xOffset, yOffset, xAdvance); 
                addChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int = parseInt(kerningElement.attribute("first"));
                var second:int = parseInt(kerningElement.attribute("second"));
                var amount:Number = parseFloat(kerningElement.attribute("amount")) / scale;
                if (second in mChars) getChar(second).addKerning(first, amount);
            }
        }
        */
        
        /** Returns a single bitmap char with a certain character ID. */
        public function getChar(charID:int):BitmapChar
        {
            return mChars[charID];
        }
        
        /** Adds a bitmap char with a certain character ID. */
        public function addChar(charID:int, bitmapChar:BitmapChar):void
        {
            mChars[charID] = bitmapChar;
        }
        
        /** Creates a sprite that contains a certain text, made up by one image per char. */
        public function createSprite(width:Number, height:Number, text:String,
                                     fontSize:Number=-1, color:uint=0xff00ff, 
                                     hAlign:String="center", vAlign:String="center",      
                                     autoScale:Boolean=true, 
                                     kerning:Boolean=true, sprite:Sprite=null):Sprite
        {
            var charLocations:Vector.<CharLocation> = arrangeChars(width, height, text, fontSize, 
                                                                   hAlign, vAlign, autoScale, kerning);
            var numChars:int = charLocations.length;

            if (!sprite)
                sprite = new Sprite();
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                // TODO: visit type aliasing
                //https://theengineco.atlassian.net/browse/LOOM-1395
                var _char:Image = charLocation._char.createImage();
                _char.x = charLocation.x;
                _char.y = charLocation.y;
                _char.scaleX = _char.scaleY = charLocation.scale;
                _char.color = color;
                //trace(" " + _char.scaleX + " " + _char.color);
                sprite.addChild(_char);
            }
            
            return sprite;
        }
        
        /** Draws text into a QuadBatch. */
        public function fillQuadBatch(quadBatch:QuadBatch, width:Number, height:Number, text:String,
                                      fontSize:Number=-1, color:uint=0xffffff, 
                                      hAlign:String="center", vAlign:String="center",      
                                      autoScale:Boolean=true, 
                                      kerning:Boolean=true):void
        {
            var charLocations:Vector.<CharLocation> = arrangeChars(width, height, text, fontSize, 
                                                                   hAlign, vAlign, autoScale, kerning);
            var numChars:int = charLocations.length;
            mHelperImage.color = color;
            
            if (numChars > 8192)
                Debug.assert(0, "Bitmap Font text is limited to 8192 characters.");

            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                mHelperImage.texture = charLocation._char.texture;
                mHelperImage.readjustSize();
                mHelperImage.x = charLocation.x;
                mHelperImage.y = charLocation.y;
                mHelperImage.scaleX = mHelperImage.scaleY = charLocation.scale;
                quadBatch.addImage(mHelperImage);
            }
        } 
        
        /** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
         *  Returns a Vector of CharLocations. */
        private function arrangeChars(width:Number, height:Number, text:String, fontSize:Number=-1,
                                      hAlign:String="center", vAlign:String="center",
                                      autoScale:Boolean=false, kerning:Boolean=true):Vector.<CharLocation>
        {
            if (text == null || text.length == 0)
            {
                //trace("early out - no text!");
                return new Vector.<CharLocation>();
            }

            // Enforce sanity of font size.
            if (fontSize < 0) 
                fontSize *= -mSize;
            
            var lines:Vector.<Vector.<CharLocation>>;
            var finished:Boolean = false;
            var charLocation:CharLocation;
            var numChars:int;
            var containerWidth:Number;
            var containerHeight:Number;
            var scale:Number;

            var currentX:Number = 0;
            var currentY:Number = 0;

            var sanity:int = 60;
            
            lines = new Vector.<Vector.<CharLocation>>();

            while (!finished)
            {
                scale = fontSize / mSize;
                containerWidth  = width / scale;
                containerHeight = height / scale;
                
                lines.length = 0;
                
                //trace("Trying to fit into " + containerHeight + " line " + (mLineHeight * scale) + " fits? " + (mLineHeight * scale <= containerHeight));
                if (mLineHeight * scale <= containerHeight || !autoScale)
                {
                    var lastWhiteSpace:int = -1;
                    var lastCharID:int = -1;
                    currentX = 0;
                    currentY = 0;
                    var currentLine:Vector.<CharLocation> = new Vector.<CharLocation>();
                    
                    numChars = text.length;
                    for (var i:int=0; i<numChars; i++)
                    {
                        //trace("Considering char " + i);
                        var lineFull:Boolean = false;
                        var charID:int = text.charCodeAt(i);

                        //check for a UTF8 character
                        //NOTE: This only supports Latin UTF8 characters for now. Others alphabets such as Cyrillic or Mandarin will have unexpected results
                        if((i < (numChars - 1)) && ((charID == 0xC2) || (charID == 0xC3)))
                        {
                            var newChar:int = text.charCodeAt(++i);
                            //UTF8 C2 means we can use the next char as-is, but C3 needs an additional bit set
                            charID = (charID == 0xC3) ? newChar | 0x40 : newChar;
                        }

                        var _char:BitmapChar = getChar(charID);                    
                        if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN)
                        {
                            lineFull = true;
                        }
                        else if (_char == null)
                        {
                            trace("[Starling] Missing character: " + charID);
                        }
                        else
                        {
                            if (charID == CHAR_SPACE || charID == CHAR_TAB)
                                lastWhiteSpace = i;
                            
                            if (kerning)
                                currentX += _char.getKerning(lastCharID);
                            
                            charLocation = mCharLocationPool.length ?
                                mCharLocationPool.pop() : new CharLocation(_char);
                            
                            charLocation._char = _char;
                            charLocation.x = currentX + _char.xOffset;
                            charLocation.y = currentY + _char.yOffset;
                            currentLine.push(charLocation);
                            
                            currentX += _char.xAdvance;
                            lastCharID = charID;
                            
                            if (charLocation.x + _char.width > containerWidth)
                            {
                                //trace("New line");
                                // remove characters and add them again to next line
                                var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;
                                var removeIndex:int = currentLine.length - numCharsToRemove;
                                
                                currentLine.splice(removeIndex, numCharsToRemove);
                                
                                if (currentLine.length == 0)
                                    break;
                                
                                i -= numCharsToRemove;
                                lineFull = true;
                            }
                        }
                        
                        if (i == numChars - 1)
                        {
                            //trace("Done");
                            lines.push(currentLine);
                            finished = true;
                        }
                        else if (lineFull)
                        {
                            // Autosize text always goes on one line for now.
                            if(autoScale)
                                break;

                            //trace("Line was full.");
                            lines.push(currentLine);
                            
                            if (lastWhiteSpace == i)
                                currentLine.pop();
                            
                            //if (currentY + 2*mLineHeight <= containerHeight)
                            if(true)
                            {
                                currentLine = new Vector.<CharLocation>();
                                currentX = 0;
                                currentY += mLineHeight;
                                lastWhiteSpace = -1;
                                lastCharID = -1;
                            }
                            else
                            {
                                break;
                            }
                        }
                    } // for each char
                } // if (mLineHeight <= containerHeight)

                if(sanity-- < 0)
                {
                    trace("Failed to lay out text " + text + " after many tries.");
                    break;
                }
                
                if (autoScale && !finished)
                {
                    //trace("Reducing");
                    fontSize -= 1;
                    lines.length = 0;
                }
                else
                {
                    finished = true; 
                }
            } // while (!finished)
            
            var finalLocations:Vector.<CharLocation> = new Vector.<CharLocation>();
            var numLines:int = lines.length;
            var bottom:Number = currentY + mLineHeight;
            var yOffset:int = 0;
            
            if (vAlign == VAlign.BOTTOM)      yOffset =  containerHeight - bottom;
            else if (vAlign == VAlign.CENTER) yOffset = (containerHeight - bottom) / 2;
            
            for (var lineID:int=0; lineID<numLines; ++lineID)
            {
                var line:Vector.<CharLocation> = lines[lineID];
                numChars = line.length;
                
                if (numChars == 0) continue;
                
                var xOffset:int = 0;
                var lastLocation:CharLocation = line[line.length-1];
                var right:Number = lastLocation.x - lastLocation._char.xOffset 
                                                  + lastLocation._char.xAdvance;
                
                if (hAlign == HAlign.RIGHT)       xOffset =  containerWidth - right;
                else if (hAlign == HAlign.CENTER) xOffset = (containerWidth - right) / 2;
                
                for (var c:int=0; c<numChars; ++c)
                {
                    charLocation = line[c];
                    charLocation.x = scale * (charLocation.x + xOffset);
                    charLocation.y = scale * (charLocation.y + yOffset);
                    charLocation.scale = scale;
                    
                    if (charLocation._char.width > 0 && charLocation._char.height > 0)
                        finalLocations.push(charLocation);
                    
                    // return to pool for next call to "arrangeChars"
                    mCharLocationPool.push(charLocation);
                }
            }

            return finalLocations;
        }
        
        // Return how wide this string will be on an infinite canvas.
        public function getStringDimensions(s:String, maxWidth:Number, maxHeight:Number, size:Number = -1):Point
        {
            var chars = arrangeChars(maxWidth, maxHeight, s, size, "left", "top", false, true);

            sHelperPoint.x = sHelperPoint.y = 0;

            if(chars.length == 0)
            {
                return sHelperPoint;
            }

            // Get the last character for an estimate.
            var maxX = 0, maxY = 0;
            for(var i=0; i<chars.length; i++)
            {
                var curChar = chars[i];
                var right = curChar.x + curChar._char.width * curChar.scale;
                var bottom = curChar.y + curChar._char.height * curChar.scale;

                if(right > maxX)
                    maxX = right;

                if(bottom > maxY)
                    maxY = bottom;
            }

            sHelperPoint.x = maxX + 1;
            sHelperPoint.y = maxY + 1;

            return sHelperPoint;
        }

        /** The name of the font as it was parsed from the font file. */
        public function get name():String { return mName; }
        
        /** The native size of the font. */
        public function get size():Number { return mSize; }
        
        /** The height of one line in pixels. */
        public function get lineHeight():Number { return mLineHeight; }
        public function set lineHeight(value:Number):void { mLineHeight = value; }
        
        /** The smoothing filter that is used for the texture. */ 
        //public function get smoothing():String { return mHelperImage.smoothing; }
        //public function set smoothing(value:String):void { mHelperImage.smoothing = value; } 
        
        /** The baseline of the font. */
        public function get baseline():Number { return mBaseline; }
    }

    class CharLocation
    {
        public var _char:BitmapChar;
        public var scale:Number;
        public var x:Number;
        public var y:Number;
        
        public function CharLocation(_char:BitmapChar)
        {
            this._char = _char;
        }
    }

}