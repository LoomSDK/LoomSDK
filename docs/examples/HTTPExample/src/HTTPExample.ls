package
{

    import loom.Application;    
    import loom.HTTPRequest;
    import system.Void;

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
        
        override public function onTick() {
            
            trace("BEGIN Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam ultrices erat eu dui congue interdum. Ut sagittis neque sit amet posuere sagittis. Proin sit amet massa metus. In sapien neque, egestas nec ultricies at, sollicitudin at ante. Mauris gravida orci aliquam arcu tempor, vel placerat dui pellentesque. Duis vel dolor sed lorem laoreet placerat. Integer dictum augue rutrum nunc viverra, ac interdum elit feugiat. Sed varius porta velit, sit amet volutpat massa vulputate id. Interdum et malesuada fames ac ante ipsum primis in faucibus.    Suspendisse nec nulla nisl. Suspendisse sed cursus justo, in auctor dui. Nam in est id metus aliquam pretium id non velit. Integer blandit at felis sit amet maximus. Praesent varius, mauris ut accumsan imperdiet, dui nisi elementum odio, scelerisque maximus mi nulla a est. Duis malesuada, risus sed tristique varius, augue mauris ornare leo, vitae mattis neque nisl quis velit. Maecenas ut posuere sem, et egestas massa. Aliquam eu tortor quam. Morbi libero risus, dapibus et eros varius, dapibus fermentum tortor. Phasellus rutrum metus in euismod pretium. Ut ac condimentum odio. Aenean non est feugiat, mollis lectus ac, bibendum turpis.    Curabitur massa nisi, mattis auctor sollicitudin fermentum, pharetra nec magna. Praesent tincidunt interdum sapien vel pharetra. Phasellus mattis mi sed nulla lacinia, nec scelerisque magna convallis. Ut pharetra vitae diam vitae laoreet. Fusce ultrices, ante in suscipit semper, ipsum quam malesuada risus, a convallis ipsum metus quis elit. Phasellus sed lorem ullamcorper, bibendum justo a, posuere felis. Suspendisse metus dui, condimentum eget rhoncus vel, luctus id arcu. Vestibulum ullamcorper tincidunt felis, a feugiat sem vulputate sed. Donec et enim accumsan, condimentum lacus a, tristique orci. Integer a accumsan enim. Vestibulum nec luctus ante, ac euismod libero. Cras tincidunt, purus sit amet commodo suscipit, lorem mauris accumsan ex, at accumsan quam nisl ac risus. Nulla eu mi eu tellus suscipit pharetra id id dolor. Vivamus efficitur ligula ac felis condimentum, sed dapibus nisl malesuada. Suspendisse placerat vel mauris eu tempor. Integer a interdum felis, et commodo odio.    Nulla facilisi. Integer eget tincidunt odio. Curabitur consectetur commodo turpis, tempor molestie diam mattis at. Maecenas id felis quis tortor vulputate vulputate. Sed vitae diam id tellus maximus sodales rutrum ut velit. Quisque eleifend ornare eros, eget cursus dolor varius eget. Nulla in finibus quam, ac consectetur sem. Suspendisse potenti. Fusce egestas ac erat non semper.    Donec eu arcu nec lorem mollis semper nec at diam. Nunc eu mi porttitor, malesuada quam quis, accumsan enim. Proin at aliquam ipsum, sit amet interdum velit. Curabitur elementum, ipsum quis pulvinar volutpat, nulla enim vehicula quam, ac porta orci velit et ipsum. Nunc vulputate sed arcu a lacinia. Pellentesque ut elementum nunc, id sodales orci. Duis congue et ante sed auctor. Nulla interdum lacus tincidunt tellus fringilla, quis feugiat ipsum dapibus. END");
            
            return super.onTick();
        }
        
    }
}