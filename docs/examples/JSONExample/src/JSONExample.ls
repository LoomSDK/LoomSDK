package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;
    
    import loom.LoomTextAsset;

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
            // Load and parse a JSON file.
            var jsonAsset = LoomTextAsset.create("assets/test.json");
            jsonAsset.updateDelegate += handleJSON;
            jsonAsset.load();

        }
    }
}