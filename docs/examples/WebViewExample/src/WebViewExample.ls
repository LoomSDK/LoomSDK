package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;

    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;        
    import loom2d.events.ResizeEvent;

    import loom.WebView;

    /**
     *  Loom Example showcasing some of the features of Loom.WebView.
     *
     *  Note: WebView does not currently function on Windows, so this demo
     *  will not work as expected on a Windows target.
     */
    public class WebViewExample extends Application
    {
        override public function run():void
        {

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Loading...";
            label.x = 120;
            label.y = stage.stageHeight - 36;
            label.scale = 0.2;
            stage.addChild(label);

            var arrowBack =  new Image(Texture.fromAsset("assets/arrow_left.png"));
            arrowBack.x = 20;
            arrowBack.y = stage.stageHeight - 36;
            stage.addChild(arrowBack);

            var arrowForward = new Image(Texture.fromAsset("assets/arrow_right.png"));
            arrowForward.x = 60;
            arrowForward.y = stage.stageHeight - 36;
            stage.addChild(arrowForward);

            var webView = new WebView();
            webView.onRequestSent += function(url:String) {
                label.text = url;
            };

            arrowBack.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(arrowBack, TouchPhase.BEGAN);
                if (touch)
                    webView.goBack();                    
            } );            

            arrowForward.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(arrowForward, TouchPhase.BEGAN);
                if (touch)
                    webView.goForward();                    
            } );            


            stage.addEventListener( Event.RESIZE, function(e:ResizeEvent) { 
                webView.setDimensions(0, 40, e.width, e.height-40);
                arrowBack.y = e.height - 36;
                arrowForward.y = e.height - 36;
                label.y = e.height - 36;

            } );                        
            
            webView.request("http://google.com");
            webView.show();
            webView.height = stage.stageHeight-40;
            webView.y = 40;
        }
    }
}