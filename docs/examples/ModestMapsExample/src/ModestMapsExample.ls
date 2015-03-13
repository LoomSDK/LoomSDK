package
{
    import loom.Application;
    import loom2d.display.Stage;
    import loom2d.display.StageScaleMode;

    import loom.modestmaps.Map;
    import loom.modestmaps.mapproviders.IMapProvider;
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
        var msProvider:MicrosoftRoadMapProvider;
        var osmProvider:OpenStreetMapProvider;
        
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
                        
            //create some providers
            msProvider = new MicrosoftRoadMapProvider(true, AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM);
            osmProvider = new OpenStreetMapProvider(AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM);

            map = new Map(stage.stageWidth, 
                                stage.stageHeight, 
                                true, 
                                msProvider,
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
            if (keycode == LoomKey.PADEQUAL_SIGN)
                map.zoomByAbout(0.05, zoomPoint);
            if (keycode == LoomKey.HYPHEN)
                map.zoomByAbout( -0.05, zoomPoint);

            //switch map provider!
            if(keycode == LoomKey.M)
            {
                var newProvider:IMapProvider = (map.getMapProvider() == msProvider) ? osmProvider : msProvider;
                map.setMapProvider(newProvider);
            }
        }
    }
}