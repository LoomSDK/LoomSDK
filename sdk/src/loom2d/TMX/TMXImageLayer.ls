package loom2d.tmx
{
    import system.xml.*;

    /**
     * A class used to parse and store TMX image layer data and properties
     */

    public class TMXImageLayer
    {
        public var name:String;
        public var opacity:Number = 1;
        public var visible:Boolean = true;

        public var properties:Dictionary.<String, String> = {};
        public var image:TMXImage = null;

        public function TMXImageLayer(parentFile:String, element:XMLElement)
        {
            name = element.getAttribute("name");
            var opacityAttr = element.findAttribute("opacity");
            opacity = opacityAttr ? opacityAttr.numberValue : 1.0;
            var visibleAttr = element.findAttribute("visible");
            visible = visibleAttr ? visibleAttr.numberValue as Boolean : true;

            var nextChild:XMLElement = element.firstChildElement();
            while (nextChild)
            {
                if (nextChild.getValue() == "image")
                {
                    image = new TMXImage(parentFile, nextChild);
                }
                else if (nextChild.getValue() == "properties")
                {
                    TMXDocument.loadProperties(nextChild, properties);
                }

                nextChild = nextChild.nextSiblingElement();
            }
        }
    }
}