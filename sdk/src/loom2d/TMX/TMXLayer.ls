package loom2d.tmx
{
    import system.xml.*;

    /**
     * A class used to parse and store TMX layer data, tiles, and properties
     */

    public class TMXLayer
    {
        public var name:String;
        public var x:int = 0;
        public var y:int = 0;
        public var width:int;
        public var height:int;
        public var tileWidth:int;
        public var tileHeight:int;
        public var opacity:Number = 1;
        public var visible:Boolean = true;
        public var tiles:Vector.<uint> = [];

        public var properties:Dictionary.<String, String> = {};

        public function TMXLayer(element:XMLElement, tileWidth:int, tileHeight:int)
        {
            name = element.getAttribute("name");
            var xAttr = element.findAttribute("x");
            x = xAttr ? xAttr.numberValue : 0;
            var yAttr = element.findAttribute("y");
            y = yAttr ? xAttr.numberValue : 0;
            var widthAttr = element.findAttribute("width");
            width = widthAttr ? widthAttr.numberValue : 0;
            var heightAttr = element.findAttribute("height");
            height = heightAttr ? heightAttr.numberValue : 0;
            var opacityAttr = element.findAttribute("opacity");
            opacity = opacityAttr ? opacityAttr.numberValue : 1.0;
            var visibleAttr = element.findAttribute("visible");
            visible = visibleAttr ? visibleAttr.numberValue as Boolean : true;

            this.tileWidth = tileWidth;
            this.tileHeight = tileHeight;

            var nextChild:XMLElement = element.firstChildElement();
            while (nextChild)
            {
                if (nextChild.getValue() == "data")
                {
                    var data:TMXData = new TMXData(nextChild, width, height);
                    tiles = data.data;
                }
                else if (nextChild.getValue() == "properties")
                {
                    TMXDocument.loadProperties(nextChild, properties);
                }

                nextChild = nextChild.nextSiblingElement();
            }
        }

        public function getTileGidAt(x:int, y:int):int
        {
            if (x < 0 || y<0) return 0;
            var tileIndex:int = x + y * width;
            return tileIndex < tiles.length ? tiles[tileIndex] : 0;
        }
    }
}