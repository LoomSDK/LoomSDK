package loom2d.tmx
{
    import loom.LoomTextAsset;

    import system.xml.*;

    public delegate TMXUpdatedCallback(file:String, document:TMXDocument);
    public delegate TMXLoadCompleteCallback(file:String, document:TMXDocument);
    public delegate TMXTilesetParsedCallback(file:String, tileset:TMXTileset);
    public delegate TMXLayerParsedCallback(file:String, layer:TMXLayer);
    public delegate TMXObjectGroupParsedCallback(file:String, objectGroup:TMXObjectGroup);
    public delegate TMXImageLayerParsedCallback(file:String, imageLayer:TMXImageLayer);
    public delegate TMXPropertiesParsedCallback(file:String, properties:Dictionary.<String, String>);

    /**
     * A class used to parse and store data from a TMX file, including tile/object layers and
     * their properties.
     */

    public class TMXDocument
    {
        public var version:Number;
        public var orientation:String;
        public var width:int;
        public var height:int;
        public var tileWidth:int;
        public var tileHeight:int;
        public var backgroundcolor:String;

        public var properties:Dictionary.<String, String> = {};

        public var tilesets:Vector.<TMXTileset> = [];
        public var layers:Vector.<TMXLayer> = [];
        public var objectGroups:Vector.<TMXObjectGroup> = [];
        public var imageLayers:Vector.<TMXImageLayer> = [];

        public var onTMXUpdated:TMXUpdatedCallback = new TMXUpdatedCallback();
        public var onTMXLoadComplete:TMXLoadCompleteCallback = new TMXLoadCompleteCallback();
        public var onTilesetParsed:TMXTilesetParsedCallback = new TMXTilesetParsedCallback();
        public var onLayerParsed:TMXLayerParsedCallback = new TMXLayerParsedCallback();
        public var onObjectGroupParsed:TMXObjectGroupParsedCallback = new TMXObjectGroupParsedCallback();
        public var onImageLayerParsed:TMXImageLayerParsedCallback = new TMXImageLayerParsedCallback();
        public var onPropertiesParsed:TMXPropertiesParsedCallback = new TMXPropertiesParsedCallback();

        private var _filename:String = null;
        private var _textAsset:LoomTextAsset = null;
        private var _tsxTestAssets:Dictionary.<String, LoomTextAsset> = {};

        public function TMXDocument(filename:String)
        {
            _filename = filename;
            _textAsset = LoomTextAsset.create(_filename);
            _textAsset.updateDelegate += onTextAssetUpdated;
        }

        public function load():void
        {
            _textAsset.load();
        }

        public function getLayerByName(name:String):TMXLayer
        {
            for each(var layer:TMXLayer in layers)
                if (layer.name == name) return layer;

            return null;
        }

        public static function loadProperties(element:XMLElement, propertiesMap:Dictionary.<String, String>)
        {
            var nextChild:XMLElement = element.firstChildElement("property");
            while (nextChild)
            {
                propertiesMap[nextChild.getAttribute("name")] = nextChild.getAttribute("value");

                nextChild = nextChild.nextSiblingElement("property");
            }
        }

        private function onTextAssetUpdated(name:String, contents:String):void
        {
            var xmlDoc = new XMLDocument();
            var result = xmlDoc.parse(contents);
            if (result != XMLError.XML_NO_ERROR)
            {
                trace("Encountered error parsing " + name + ": " + result);
                return;
            }

            var root:XMLElement = xmlDoc.rootElement();
            parseMap(root);
        }

        private function parseMap(root:XMLElement):void
        {
            Debug.assert(root.getValue() == "map", "Error: expected 'map' as root node of TMX file!");

            version = root.getNumberAttribute("version");
            orientation = root.getAttribute("orientation");
            width = root.getNumberAttribute("width");
            height = root.getNumberAttribute("height");
            tileWidth = root.getNumberAttribute("tilewidth");
            tileHeight = root.getNumberAttribute("tileheight");
            backgroundcolor = root.getAttribute("backgroundcolor");

            onTMXUpdated(_filename, this);

            var nextChild:XMLElement = root.firstChildElement();
            while (nextChild)
            {
                if (nextChild.getValue() == "tileset")
                {
                    var tileset:TMXTileset = new TMXTileset(_filename, nextChild);
                    tilesets.pushSingle(tileset);
                    onTilesetParsed(_filename, tileset);

                    if (tileset.sourcePath != null)
                    {
                        var tsxAsset = _tsxTestAssets[tileset.sourcePath];
                        if (tsxAsset == null)
                        {
                            tsxAsset = LoomTextAsset.create(tileset.sourcePath);
                            // TODO: This spits out a warning, but that looks bad.
                            // Want to ignore the initial load or else we get into a reload loop here.
                            tsxAsset.load();
                            tsxAsset.updateDelegate += onTilesetUpdated;
                            _tsxTestAssets[tileset.sourcePath] = tsxAsset;
                        }
                    }
                }
                else if (nextChild.getValue() == "layer")
                {
                    var layer:TMXLayer = new TMXLayer(nextChild, tileWidth, tileHeight);
                    layers.pushSingle(layer);
                    onLayerParsed(_filename, layer);
                }
                else if (nextChild.getValue() == "objectgroup")
                {
                    var objectGroup:TMXObjectGroup = new TMXObjectGroup(nextChild);
                    objectGroups.pushSingle(objectGroup);
                    onObjectGroupParsed(_filename, objectGroup);
                }
                else if (nextChild.getValue() == "imagelayer")
                {
                    var imageLayer:TMXImageLayer = new TMXImageLayer(_filename, nextChild);
                    imageLayers.pushSingle(imageLayer);
                    onImageLayerParsed(_filename, imageLayer);
                }
                else if (nextChild.getValue() == "properties")
                {
                    TMXDocument.loadProperties(nextChild, properties);
                    onPropertiesParsed(_filename, properties);
                }

                nextChild = nextChild.nextSiblingElement();
            }

            onTMXLoadComplete(_filename, this);
        }

        private function onTilesetUpdated(name:String, contents:String):void
        {
            load();
        }
    }
}