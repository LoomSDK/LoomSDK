package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;
    
    import loom.LoomTextAsset;

    
    class Test {
        public var greeting:String = "hello";
        public var quoted:String = "What is this thing \\ you call \"life\"?\r\nLust for money?\n\tPower?\nOr were you just born with a heart full of neutrality?";
        public var age:int = 25;
        public var alive:Boolean = true;
        public var array = [123, "abc", 456, "def", false];
        public var fruit:Fruit = new Fruit("apple");
        public var nullref:Fruit;
        public var dict:Dictionary.<String, Object> = {
            "a": 1,
            "b": 2,
            "c": [3, 4, 5, {
                "d": 6,
                "e": [7, 8, 9]
            }],
            "f": "string",
            "g": true,
            "h": false,
            "i": 0.5,
            "j": null,
            "k": new Fruit("banana"),
            "l": [new Fruit("pineapple")],
            "m": [null]
        };
        public function Test() {}
    }
    
    class Fruit {
        public var type:String = "apple";
        public function Fruit(type:String) { this.type = type; }
    }
    
    /**
     * Simple example of a live reloadable JSON file.
     *
     * Do loom run, then open and edit assets/test.json to see results!
     */
    public class JSONExample extends Application
    {
        public function handleJSON(path:String, contents:String):void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Load test JSON (gotten from http://json.org/example.html)
            var json = new JSON();
            json.loadString(contents);

            var jsonRoot = json.getObject("menu");

            trace("Parsing JSON from " + path + "!");
            trace("");

            // Iterate through the keys of an object
            trace("Object keys: ");
            var key = jsonRoot.getObjectFirstKey();
            while (key != "")
            {
                trace("   * " + key);
                key = jsonRoot.getObjectNextKey(key);
            }

            // Parse and show the menu data.
            label.text = jsonRoot.getString("header");
            trace("Root type: " + jsonRoot.getJSONType());
            trace("Header: " + label.text);

            trace("Items:");
            var itemArray = jsonRoot.getArray("items");
            for(var i=0; i<itemArray.getArrayCount(); i++)
            {
                var itemObject = itemArray.getArrayObject(i);

                // Null is a break.
                if(!itemObject)
                {
                    trace("   --------");
                    continue;
                }

                // Otherwise it's an item.
                trace("   #" + i + ". " + itemObject.getString("id"));
            }

            // Also, let's make a modification and show it off.
            jsonRoot.setString("testValue", "Hi there!");
            trace(jsonRoot.serialize());
        }

        var label:SimpleLabel;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth; 
            bg.height = stage.stageHeight; 
            stage.addChild(bg);
            
            label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Modify test.json!";
            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = 240;
            sprite.y = 120;
            stage.addChild(sprite);
            
            
            var json = new JSON();
            
            json.initObject();
            
            
            // Circular reference tests
            // Commented due to it failing an assertion,
            // uncomment to try it. Both Vector and Object
            // indirect circular references should be detected.
            /*
            var oa = { };
            var ob = { "circular": oa };
            oa["circular"] = ob;
            var va:Vector.<Object> = [];
            var vb:Vector.<Object> = [va];
            va.push(vb);
            
            json.setValue("infiniteObject", oa);
            json.setValue("infiniteVector", va);
            
            trace(json.serialize());
            return;
            //*/
            
            json.setValue("index", 5);
            json.setValue("duration", 5);
            json.setValue("loc", [1, 2]);
            json.setValue("scale", [3, 4]);
            json.setValue("array", [1, 2, "arraystring", ["array array", 1, 2, true], { "obj": [true] }, false, 0.5]);
            json.setValue("object", { "key": "value", "otherkey": true });
            json.setValue("alpha", 0.5);
            json.setValue("visible", true);
            json.setValue("label", "alabel");
            
            trace("\n\n\nManual reflected setup and serialization\n\n");
            trace(json.serialize());
            
            trace("\n\n\nStringified reflected objects\n\n");
            var t = new Test();
            trace(JSON.stringify(t));
            
            
            // Load and parse a JSON file.
            var jsonAsset = LoomTextAsset.create("assets/test.json");
            jsonAsset.updateDelegate += handleJSON;
            jsonAsset.load();
        }
    }
}