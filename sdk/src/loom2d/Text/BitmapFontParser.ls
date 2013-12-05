
package loom2d.text
{
    import system.platform.File;
    import loom2d.math.Rectangle;

    public class BitmapCharInfo
    {
        public var id:int;
        public var xOffset:Number;
        public var yOffset:Number;
        public var xAdvance:Number;
        
        public var region:Rectangle = new Rectangle();

        public function parseChar(tokens:Vector.<string>)
        {
            for each (var token in tokens)
            {
                if (token.indexOf("=") != -1)
                {
                    var kv = token.split("=");
                    
                    switch(kv[0].toLowerCase())
                    {
                        case "id":
                            id = Number.fromString(kv[1]);
                            break;

                        case "xoffset":
                            xOffset = Number.fromString(kv[1]);
                            break;

                        case "yoffset":
                            yOffset = Number.fromString(kv[1]);
                            break;

                        case "xadvance":
                            xAdvance = Number.fromString(kv[1]);
                            break;

                        case "x":
                            region.x = Number.fromString(kv[1]);
                            break;

                        case "y":
                            region.y = Number.fromString(kv[1]);
                            break;

                        case "width":
                            region.width = Number.fromString(kv[1]);
                            break;

                        case "height":
                            region.height = Number.fromString(kv[1]);
                            break;

                    }
                }
            }
        }
    }

    public class BitmapFontInfo
    {
        public var name:string = "Anonymous Font";
        public var size:float;
        public var lineHeight:float;
        public var baseLine:float;
        public var textureName:string;

        public var characters:Vector.<BitmapCharInfo> = new Vector.<BitmapCharInfo>();

        public function parsePage(tokens:Vector.<string>)
        {
            for each (var token in tokens)
            {
                if (token.indexOf("=") != -1)
                {
                    var kv = token.split("=");

                    switch (kv[0].toLowerCase())
                    {
                        case "file":

                            textureName = kv[1];
                            if (kv[1].charAt(0) == "\"")
                                textureName = textureName.substr(1, textureName.lastIndexOf("\"") - 1);

                            break;

                    }
                }                            
            }            
        }

        public function parseInfo(tokens:Vector.<string>)
        {
            for each (var token in tokens)
            {

                if (token.indexOf("=") != -1)
                {
                    var kv = token.split("=");

                    switch (kv[0].toLowerCase())
                    {
                        case "size":
                            size = Number.fromString(kv[1]);
                            break;
                        case "lineheight":
                            lineHeight = Number.fromString(kv[1]);
                            break;
                        case "base":
                            baseLine = Number.fromString(kv[1]);
                            break;

                    }
                }                            
            }            
        }

        public function parseCommon(tokens:Vector.<string>)
        {
            for each (var token in tokens)
            {

                if (token.indexOf("=") != -1)
                {
                    var kv = token.split("=");

                    switch (kv[0].toLowerCase())
                    {
                        case "lineheight":
                            lineHeight = Number.fromString(kv[1]);
                            break;
                        case "base":
                            baseLine = Number.fromString(kv[1]);
                            break;

                    }
                }                            
            }            
        }


        public function parseChar(tokens:Vector.<string>)
        {
            var bci = new BitmapCharInfo;
            bci.parseChar(tokens);
            characters.pushSingle(bci);
        }
    }

    public class BitmapFontParser
    {
        public static function parseFont(fontAssetFile:String = null, fontAssetSource:String = null):BitmapFontInfo
        {

            var fontAsset = fontAssetSource;

            if (fontAssetFile)
                fontAsset = File.loadTextFile(fontAssetFile);

            if (!fontAsset)
            {
                trace("BitmapFontParser.parseFont - failed to load data from '" + fontAssetFile + "'");
                return null;
            }

            var bfi = new BitmapFontInfo;

            for each (var line in fontAsset.split("\n"))
            {
                var tokens = line.split(" ");

                if (!tokens.length)
                    continue;

                // handle info line
                if (tokens[0] == "info")
                {
                    var face = line.split("face=")[1].substr(1);
                    face = face.substr(0, face.indexOf("\""));
                    bfi.name = face;
                    
                    bfi.parseInfo(tokens);
                }
                else if (tokens[0] == "common")
                {
                    bfi.parseCommon(tokens);
                }                                
                else if (tokens[0] == "page")
                {
                    bfi.parsePage(tokens);
                }                
                else if (tokens[0] == "char")
                {
                    bfi.parseChar(tokens);
                }
        
            }

            return bfi;
        }
    }
}