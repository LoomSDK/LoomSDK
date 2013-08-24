package loom2d.tmx
{
    import system.xml.XMLDocument;
    import system.xml.XMLElement;
    import system.xml.XMLPrinter;

    import loom2d.display.Sprite;
    import loom2d.events.Event;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAtlas;
  
    /**
     *
     */
    public class TMXTileSheet extends Sprite
    {
        // the name and file paths
        private var _name:String;
        private var _sheetFilename:String;
        // texture, atlas and loader
        private var _sheet:Texture;
        private var _textureAtlas:TextureAtlas;
        private var _startID:uint;
        private var _tileHeight:uint;
        private var _tileWidth:uint;
 
        public function TMXTileSheet(xml:XMLElement):void
        {
            loadTileSheet(xml);
        }
 
        private function loadTileSheet(xml:XMLElement):void
        {
            //name:String, sheetFile:String, tileWidth:uint, tileHeight:uint, startID:uint            
            _name = xml.getAttribute("name");

            // we need to handle relative tmx files
            _sheetFilename = "assets/" + xml.firstChildElement("image").getAttribute("source");

            _startID = xml.getNumberAttribute("firstgid") - 1;
 
            _tileHeight = xml.getNumberAttribute("tileheight");
            _tileWidth = xml.getNumberAttribute("tilewidth");
 
            trace("creating TMX tilesheet");

            trace(_name);
            trace(_sheetFilename);
            trace(_startID);
            trace(_tileHeight);
            trace(_tileWidth);

            loadAtlas();
 
        }
 
        /*
        Load the image file needed for this tilesheet
         */
        private function loadSheet():void
        {
            // var sprite:DisplayObject = _imageLoader.content;
            //_sheet = Bitmap(sprite);
 
            loadAtlas();
        }
 
        /*
        dynamically create a texture atlas to look up tiles
         */
        private function loadAtlas():void
        {
            trace("loading atlas");

            var _sheet = Texture.fromAsset(_sheetFilename);
            
            var numRows:uint = _sheet.height / _tileHeight;
            var numCols:uint = _sheet.width / _tileWidth;
 
            var id:int = _startID;

            var xml:XMLDocument = new XMLDocument;

            var atlas = xml.newElement("TextureAtlas");
            xml.insertEndChild(atlas);

            atlas.setAttribute("imagePath", _sheetFilename);
 
            for (var i:int = 0; i < numRows; i++)
            {
                for (var j:int = 0; j < numCols; j++)
                {
                    id++;
                    var subTexture = xml.newElement("SubTexture");

                    subTexture.setAttribute("name", String(id));

                    // For proper display on linear filtering mode, we inset a half
                    // texel on all 4 sides. Turn this off when using point sampling.
                    // For point sampling, you can disable the offset.
                    subTexture.setAttribute("x", String(j * _tileWidth + 0.5));
                    subTexture.setAttribute("y", String(i * _tileHeight + 0.5));
                    subTexture.setAttribute("width", String(_tileWidth - 1));
                    subTexture.setAttribute("height", String(_tileHeight - 1));

                    atlas.insertEndChild(subTexture);

                }
            }

            _textureAtlas = new TextureAtlas(_sheet, atlas);
            trace("done with atlas, dispatching");
            //dispatchEvent(new loom2d.events.Event(loom2d.events.Event.COMPLETE));
        }
 
        /*
        public function get sheet():Bitmap
        {
            return _sheet;
        }
        */
 
        public function get textureAtlas():TextureAtlas
        {
            return _textureAtlas;
        }
    }
}