package loom2d.tmx
{
    import system.platform.Path;
    import system.xml.*;

    /**
     * A class used to parse and store data from TMX tile sets
     */

    public class TMXTileset
    {
        public var name:String;
        public var sourcePath:String;
        public var firstgid:uint;
        public var tilewidth:int;
        public var tileheight:int;
        public var spacing:int;
        public var margin:int;

        public var properties:Dictionary.<String, String> = {};

        public var image:TMXImage = null;
        public var tileoffset:TMXTileOffset = null;
        public var tiles:Vector.<TMXTile> = [];
        public var terrainTypes:Vector.<TMXTerrain> = [];

        private var _parentFile:String = null;

        public function TMXTileset(parentFile:String, element:XMLElement)
        {
            _parentFile = parentFile;
            parseTileSet(element);
        }

        public function parseTileSet(element:XMLElement)
        {
            var nameAttr = element.findAttribute("name");
            if (nameAttr) name = nameAttr.value;

            var sourceAttr = element.findAttribute("source");
            if (sourceAttr)
            {
                var source = sourceAttr.value;
                var slashIndex = _parentFile.lastIndexOf(Path.getFolderDelimiter());
                sourcePath = _parentFile.substr(0, slashIndex+1) + source;

                var sourceDoc = new XMLDocument();
                sourceDoc.loadFile(sourcePath);
                parseTileSet(sourceDoc.rootElement());
            }

            var firstgidAttr = element.findAttribute("firstgid");
            if (firstgidAttr) firstgid = firstgidAttr.numberValue;

            var tilewidthAttr = element.findAttribute("tilewidth");
            if (tilewidthAttr) tilewidth = tilewidthAttr.numberValue;

            var tileheightAttr = element.findAttribute("tileheight");
            if (tileheightAttr) tileheight = tileheightAttr.numberValue;

            var spacingAttr = element.findAttribute("spacing");
            if (spacingAttr) spacing = spacingAttr.numberValue;

            var marginAttr = element.findAttribute("margin");
            if (marginAttr) margin = marginAttr.numberValue;

            var nextChild:XMLElement = element.firstChildElement();
            while (nextChild)
            {
                if (nextChild.getValue() == "image")
                {
                    image = new TMXImage(_parentFile, nextChild);
                }
                else if (nextChild.getValue() == "tileoffset")
                {
                    tileoffset = new TMXTileOffset(nextChild);
                }
                else if (nextChild.getValue() == "terraintypes")
                {
                    parseTerrainTypes(nextChild);
                }
                else if (nextChild.getValue() == "tile")
                {
                    tiles.pushSingle(new TMXTile(nextChild));
                }
                else if (nextChild.getValue() == "properties")
                {
                    TMXDocument.loadProperties(nextChild, properties);
                }

                nextChild = nextChild.nextSiblingElement();
            }
        }

        private function parseTerrainTypes(element:XMLElement)
        {
            var nextChild:XMLElement = element.firstChildElement();
            while (nextChild)
            {
                if (nextChild.getValue() == "terrain")
                {
                    terrainTypes.pushSingle(new TMXTerrain(nextChild));
                }

                nextChild = nextChild.nextSiblingElement();
            }
        }
    }

    /**
     * Parses and stores data from TMX images
     */

    public class TMXImage
    {
        public var format:String;
        public var source:String;
        public var trans:String;
        public var width:int;
        public var height:int;

        public function TMXImage(parentFile:String, element:XMLElement)
        {
            format = element.getAttribute("format");
            trans = element.getAttribute("trans");
            width = element.getNumberAttribute("width");
            height = element.getNumberAttribute("height");

            source = element.getAttribute("source");
            var slashIndex = parentFile.lastIndexOf(Path.getFolderDelimiter());
            source = parentFile.substr(0, slashIndex+1) + source;

            // TODO: Handle images which include data
        }
    }

    /**
     * A simple class that parses and stores x and y tile offsets
     */

    public class TMXTileOffset
    {
        public var x:int;
        public var y:int;

        public function TMXTileOffset(element:XMLElement)
        {
            x = element.getNumberAttribute("x");
            y = element.getNumberAttribute("y");
        }
    }

    /**
     * A class used to parse and store data from a TMX tile
     */

    public class TMXTile
    {
        public var id:uint;
        public var terrain:Vector.<int> = [];
        public var probability:Number = 1;

        public function TMXTile(element:XMLElement)
        {
            id = element.getNumberAttribute("id") as uint;
            var probabilityAttr = element.findAttribute("probability");
            probability = probabilityAttr ? probabilityAttr.numberValue : 1.0;
            var terrainAttr = element.findAttribute("terrain");
            if (terrainAttr)
            {
                var terrainStrings = terrainAttr.value.split(",");
                for each (var terrainString in terrainStrings)
                {
                    terrain.pushSingle(terrainString.toNumber());
                }
            }
        }
    }

    /**
     * A class used to parse and store TMX terrain data
     */

    public class TMXTerrain
    {
        public var name:String;
        public var tile:uint;

        public function TMXTerrain(element:XMLElement)
        {
            name = element.getAttribute("name");
            tile = element.getNumberAttribute("tile");
        }
    }
}