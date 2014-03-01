package loom2d.tmx
{
    import system.xml.*;

    /**
     * A class used to parse and store data from a TMX object layer
     */

    public class TMXObjectGroup
    {
        public var name:String;
        public var color:String;
        public var opacity:Number = 1;
        public var visible:Boolean = true;

        public var properties:Dictionary.<String, String> = {};

        public var objects:Vector.<TMXObject> = [];

        public function TMXObjectGroup(element:XMLElement)
        {
            name = element.getAttribute("name");
            color = element.getAttribute("color");
            var opacityAttr = element.findAttribute("opacity");
            opacity = opacityAttr ? opacityAttr.numberValue : 1.0;
            var visibleAttr = element.findAttribute("visible");
            visible = visibleAttr ? visibleAttr.numberValue as Boolean : true;

            var nextChild:XMLElement = element.firstChildElement();
            while (nextChild)
            {
                if (nextChild.getValue() == "object")
                {
                    var object:TMXObject = parseObject(nextChild);
                    objects.pushSingle(object);
                }
                else if (nextChild.getValue() == "properties")
                {
                    TMXDocument.loadProperties(nextChild, properties);
                }

                nextChild = nextChild.nextSiblingElement();
            }
        }

        private function parseObject(element:XMLElement):TMXObject
        {
            var x = element.getNumberAttribute("x");
            var y = element.getNumberAttribute("y");
            var name = element.getAttribute("name");
            var type = element.getAttribute("type");

            var child = element.firstChildElement();

            if (!child)
            {
                var width = element.getNumberAttribute("width");
                var height = element.getNumberAttribute("height");
                var gidAttr = element.findAttribute("gid");
                if (gidAttr)
                {
                    return new TMXTileObject(name, type, x, y, gidAttr.numberValue);
                }
                else
                {
                    return new TMXRectangle(name, type, x, y, width, height);
                }
            }
            else if (child.getValue() == "ellipse")
            {
                width = element.getNumberAttribute("width");
                height = element.getNumberAttribute("height");
                return new TMXEllipse(name, type, x, y, width, height);
            }
            else if (child.getValue() == "polygon")
            {
                return new TMXPolygon(name, type, x, y, parsePoints(child.getAttribute("points")));
            }
            else if (child.getValue() == "polyline")
            {
                return new TMXPolyLine(name, type, x, y, parsePoints(child.getAttribute("points")));
            }

            return null;
        }

        private function parsePoints(pointsString:String):Vector.<int>
        {
            var vec = new Vector.<int>();

            var points = pointsString.split(" ");
            var point:String = null;
            for each (point in points)
            {
                var coords = point.split(",");
                vec.push(coords[0].toNumber(), coords[1].toNumber());
            }

            return vec;
        }
    }

    /**
     * An Enum used to reference TMXObject shape types
     */

    public enum TMXObjectShape
    {
        RECTANGLE,
        ELLIPSE,
        TILE,
        POLYGON,
        POLYLINE
    }

    /**
     * A base class for storing data about TMX objects.
     */

    public class TMXObject
    {
        public var x:int;
        public var y:int;
        public var shape:TMXObjectShape;
        public var name:String;
        public var type:String;

        public function TMXObject(name:String, type:String, x:int, y:int)
        {
            this.name = name;
            this.type = type;
            this.x = x;
            this.y = y;
        }
    }

    /**
     * Stores data about TMX Rectangle objects
     */

    public class TMXRectangle extends TMXObject
    {
        public var width:int;
        public var height:int;

        public function TMXRectangle(name:String, type:String, x:int, y:int, width:int, height:int)
        {
            super(name, type, x, y);
            this.shape = TMXObjectShape.RECTANGLE;
            this.width = width;
            this.height = height;
        }
    }

    /**
     * Stores data about TMX Ellipse objects
     */

    public class TMXEllipse extends TMXObject
    {
        public var width:int;
        public var height:int;

        public function TMXEllipse(name:String, type:String, x:int, y:int, width:int, height:int)
        {
            super(name, type, x, y);
            this.shape = TMXObjectShape.ELLIPSE;
            this.width = width;
            this.height = height;
        }
    }

    /**
     * Stores data about TMX Tile objects
     */
     
    public class TMXTileObject extends TMXObject
    {
        public var gid:int;

        public function TMXTileObject(name:String, type:String, x:int, y:int, gid:int)
        {
            super(name, type, x, y);
            this.shape = TMXObjectShape.TILE;
            this.gid = gid;
        }
    }

    /**
     * Stores data about TMX Polygon objects
     */

    public class TMXPolygon extends TMXObject
    {
        public var points:Vector.<int> = [];

        public function TMXPolygon(name:String, type:String, x:int, y:int, points:Vector.<int>)
        {
            super(name, type, x, y);
            this.shape = TMXObjectShape.POLYGON;
            this.points = points;
        }
    }

    /**
     * Stores data about TMX PolyLine objects
     */

    public class TMXPolyLine extends TMXObject
    {
        public var points:Vector.<int> = [];

        public function TMXPolyLine(name:String, type:String, x:int, y:int, points:Vector.<int>)
        {
            super(name, type, x, y);
            this.shape = TMXObjectShape.POLYLINE;
            this.points = points;
        }
    }
}