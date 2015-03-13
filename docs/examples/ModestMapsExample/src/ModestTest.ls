package
{
    import loom.Application;
    import loom2d.display.Stage;
    import loom2d.display.StageScaleMode;

    import loom.modestmaps.Map;
    import loom.modestmaps.mapproviders.AbstractMapProvider;
    import loom.modestmaps.mapproviders.OpenStreetMapProvider; 
    import loom.modestmaps.mapproviders.microsoft.MicrosoftRoadMapProvider; 
    
    import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;
    import loom2d.math.Point;



    /** Simple applicaiton that demonstrates how to use Modest Maps to show a digital map provider */
    public class ModestMapExample extends Application
    {       
        var map:Map;
        
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
                        
            map = new Map(stage.stageWidth, 
                                stage.stageHeight, 
                                true, 
                                new MicrosoftRoadMapProvider(true, AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM),
                                //new OpenStreetMapProvider(AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM),
                                stage,
                                null);

            stage.addChild(map);
            
            //simle keyboard controls
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }
        

        //keyboard handler
        private function keyDownHandler(event:KeyboardEvent):void
        {   
            var keycode = event.keyCode;

            //always zoom at the center of the screen
            var zoomPoint:Point = new Point(stage.stageWidth / 2, stage.stageHeight / 2);

            //process zooming
            if (keycode == LoomKey.Q)
                map.zoomByAbout(0.05, zoomPoint);
            if (keycode == LoomKey.E)
                map.zoomByAbout( -0.05, zoomPoint);
        }
    }
}