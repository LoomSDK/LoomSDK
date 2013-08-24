package
{

    import loom.Application;    
    import loom.HTTPRequest;

    import loom2d.math.Point;
    import loom2d.display.StageScaleMode;
    import loom2d.ui.SimpleLabel;

    /**
     *  An example which makes a simple HTTP request
     */
    public class HTTPExample extends Application
    {

        var request:HTTPRequest;

        override public function run():void
        {
            // setup the GUI
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/fonts/Curse-hd.fnt");
            label.text = "HTTP Example";

            label.x = stage.stageWidth/2 - label.width/2;
            label.y = 16;
            stage.addChild(label);

            label = new SimpleLabel("assets/fonts/Curse-hd.fnt", 320, 128);
            label.text = "Sending HTTP request...";

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            // create a request object querying our location

            request = new HTTPRequest("http://ip-api.com/json");
            request.method = "GET";

            // set the success delegate
            request.onSuccess += function(v:String) {                 
                
                trace("Success", v);

                // parse the returned JSON
                var json = new JSON();
                json.loadString(v);

                // set the label to our city 
                label.text = "Hello " + json.getString("city") + "!"; 

            };

            // set the failure delegate
            request.onFailure += function(v:String) {
                // darn, there was an error 
                label.text = "Error receiving data";
                trace("Error:", v); 
            };
            

            // send request
            trace("Sending request...");
            request.send();            

        }
    }
}