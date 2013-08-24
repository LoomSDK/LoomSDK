package loom2d.tmx
{

    import system.utils.Base64;
    import system.xml.XMLDocument;
    import system.xml.XMLElement;
    import system.xml.XMLError;

    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAtlas;
    
    /**
     * Handy TMX Tilemap loader and renderer.
     *
     * Notice this class is optimized to render tilemaps with LINEAR filtering.
     * This means that we are currenly biasing everything so that it all matches up
     * properly with linear sampling. See TMXTileSheet.loadAtlas for specifics on
     * texel resampling and see TMXTileMap.drawLayers for the code which forces tiles
     * to be the right size. If you want to render with point sampling see loadAtlas.
     *
     * @author shaun.mitchell
     */
    public class TMXTileMap extends Sprite
    {
        // The TMX file to load
        private var _fileName:String;
        private var _mapLoaded:Boolean;
        // XML of TMX file
        private var _TMX:XMLDocument;
        // Layers and tilesheet holders
        private var _layers:Vector.<TMXLayer>;
        private var _tilesheets:Vector.<TMXTileSheet>;
        // variables pertaining to map description
        private var _numLayers:uint;
        private var _numTilesets:uint;
        private var _tilelistCount:uint;
        private var _mapWidth:uint;
        private var _tileHeight:uint;
        private var _tileWidth:uint;
        // used to get the correct tile from various tilesheets
        private var _gidLookup:Vector.<uint>;        
 
        public function TMXTileMap():void
        {
            _mapLoaded = false;
            _fileName = "";
            _numLayers = 0;
            _numTilesets = 0;
            _tilelistCount = 0;
            _mapWidth = 0;
            _tileHeight = 0;
            _tileWidth = 0;
 
            _layers = new Vector.<TMXLayer>();
            _tilesheets = new Vector.<TMXTileSheet>();
            _gidLookup = new Vector.<uint>();
        }
 
        public function load(file:String):void
        {
            _fileName = file;

            trace("loading tilesets from file");
            _mapLoaded = true;

            _TMX = new XMLDocument;

            var result = _TMX.loadFile(file);

            Debug.assert(result == XMLError.XML_NO_ERROR, "Error loading TMX: " + file);

            var element = _TMX.rootElement();
            _mapWidth = element.getNumberAttribute("width");
            _tileHeight = element.getNumberAttribute("tilewidth");
            _tileWidth = element.getNumberAttribute("tileheight");
  
            trace("map width " + _mapWidth);
            trace("tileWidth " + _tileWidth);
            trace("tileHeight " + _tileHeight);

            _numLayers = getNumLayers();
            _numTilesets = getNumTilesets();

            trace("num layers " + _numLayers);
            trace("num tilesets " + _numTilesets);

            for (var i = 0; i < _numTilesets; i++)
            {
                var tileset = getTileset(i);
                loadTileSheet(tileset);
            }

            loadMapData();
            
        }

        private function loadTileSheet(tileset:XMLElement)
        {
            _gidLookup.push(tileset.getNumberAttribute("firstgid"));

            var sheet = new TMXTileSheet(tileset);
            _tilesheets.push(sheet);

        }

        // Getters ------------------------------------------
        public function layers():Vector.<TMXLayer>
        {
            return _layers;
        }
 
        public function tilesheets():Vector.<TMXTileSheet>
        {
            return _tilesheets;
        }
 
        public function numLayers():uint
        {
            return _numLayers;
        }
 
        public function numTilesets():uint
        {
            return _numTilesets;
        }
 
        public function mapWidth():uint
        {
            return _mapWidth;
        }
 
        public function tileHeight():uint
        {
            return _tileHeight;
        }
 
        public function tileWidth():uint
        {
            return _tileWidth;
        }
 
        // End getters --------------------------------------

        // get the number of tilsets from the TMX XML
        private function getTileset(index:uint):XMLElement
        {
            if (_mapLoaded)
            {
                var count:uint = 0;
                var element = _TMX.rootElement();
                var node = element.firstChildElement("tileset");
                while (node)
                {
                    if (count == index)
                        return node;

                    count++;

                    node = node.nextSiblingElement("tileset");
                }
             }

            return null;
        }



        // get the number of tilsets from the TMX XML
        private function getNumTilesets():uint
        {
            if (_mapLoaded)
            {
                var count:uint = 0;
                var element = _TMX.rootElement();
                var node = element.firstChildElement("tileset");
                while (node)
                {
                    count++;

                    node = node.nextSiblingElement("tileset");
                }
 
                return count;
            }
 
            return 0;
        }

        // get the number of layers from the TMX XML
        private function getLayer(index:uint):XMLElement
        {
            if (_mapLoaded)
            {
                var count:uint = 0;
                var element = _TMX.rootElement();
                var node = element.firstChildElement("layer");
                while (node)
                {
                    if (count == index)
                        return node;

                    count++;

                    node = node.nextSiblingElement("layer");
                }
 
            }
 
            return null;
        }

 
        // get the number of layers from the TMX XML
        private function getNumLayers():uint
        {
            if (_mapLoaded)
            {
                var count:uint = 0;
                var element = _TMX.rootElement();
                var node = element.firstChildElement("layer");
                while (node)
                {
                    count++;

                    node = node.nextSiblingElement("layer");
                }
 
                return count;
            }
 
            return 0;
        }
  
        private function loadMapData():void
        {   
            
            if (_mapLoaded)
            {
                for (var i:int = 0; i < _numLayers; i++)
                {
                    trace("loading map data");

                    var xmllayer = getLayer(i);

                    var width = xmllayer.getNumberAttribute("width");
                    var height = xmllayer.getNumberAttribute("height");

                    var ba:ByteArray = new ByteArray;

                    Base64.decode(xmllayer.firstChildElement("data").getText(), ba);

                    ba.uncompress(width * height * 4);
 
                    var data:Vector.<int> = new Vector.<int>();
 
                    for (var j:int = 0; j < ba.length; j += 4)
                    {
                        // Get the grid ID
 
                        var a:int = ba.readUnsignedByte();
                        var b:int = ba.readUnsignedByte();
                        var c:int = ba.readUnsignedByte();
                        var d:int = ba.readUnsignedByte();
 
                        var gid:int = a | b << 8 | c << 16 | d << 24;

                        data.pushSingle(gid);
                    }
 
                    var tmxLayer:TMXLayer = new TMXLayer(data);
 
                    _layers.push(tmxLayer);
                }
 
                drawLayers();
            }
            
        }
 
        // draw the layers into a holder contained in a TMXLayer object
        private function drawLayers():void
        {

            trace("drawLayers ", _mapWidth, " ", _tileWidth, " ", _tileHeight);

            trace("drawing layers " + _numLayers);
            for (var i:int = 0; i < _numLayers; i++)
            {
                var row:int = 0;
                var col:int = 0;
                for (var j:int = 0; j < _layers[i].getData().length; j++)
                {
                    if (col > (_mapWidth - 1) * _tileWidth)
                    {
                        col = 0;
                        row += _tileHeight;
                    }

                    //trace(i, " ", j, " ", _layers[i].getData().length);
    
                    if (_layers[i].getData()[j] != 0)
                    {
                        var sheet = _tilesheets[findTileSheet(_layers[i].getData()[j])];
                        var atlas = sheet.textureAtlas;
                        var texture = atlas.getTexture(String(_layers[i].getData()[j]));
                        var img:Image = new Image(texture);

                        //trace(col, " ", row);
                        
                        img.x = col;
                        img.y = row;
                        img.width = _tileWidth;
                        img.height = _tileHeight;
                        _layers[i].getHolder().addChild(img);
                    }
 
                    col += _tileWidth;
                }
            }
         }
 
        private function findTileSheet(id:uint):int
        {
            var value:int = 0;
            var theOne:int;
            for (var i:int = 0; i < _tilesheets.length; i++)
            {
                
                if (!_tilesheets[i].textureAtlas)
                {
                    trace("Missing texture atlas");
                    continue;
                }

                if (_tilesheets[i].textureAtlas.getTexture(String(id)) != null)
                {
                    theOne = i;
                }
                else
                {
                    value = i;
                }
            }
            return theOne;
        }
    }
}