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
	import loom.modestmaps.mapproviders.BlueMarbleMapProvider;
    
    import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;
    import loom2d.math.Point;

    /** Simple application that demonstrates how to use Modest Maps to show a digital map provider */
    public class ModestMapExample extends Application
    {       
        var _map:Map;
        var _mapProviders:Vector.<IMapProvider> = [];
        var _provider:int = 0;
		

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
                        
            //create some providers
            _mapProviders.pushSingle(new MicrosoftRoadMapProvider(true, AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM));
            _mapProviders.pushSingle(new OpenStreetMapProvider(AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM));
			_mapProviders.pushSingle(new BlueMarbleMapProvider(AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM));

            //creat the map with our default provider
            _map = new Map(stage.stageWidth, 
                                stage.stageHeight, 
                                true, 
                                _mapProviders[_provider],
                                stage,
                                null);

            stage.addChild(_map);
            
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
                _map.zoomByAbout(0.05, zoomPoint);
            if (keycode == LoomKey.HYPHEN)
                _map.zoomByAbout( -0.05, zoomPoint);

            //switch map provider!
            if(keycode == LoomKey.OPEN_BRACKET)
            {
                _provider--;
                if(_provider < 0)
                {
                    _provider = _mapProviders.length - 1;
                }
            }
            else if(keycode == LoomKey.CLOSE_BRACKET)
            {
                _provider++;
                if(_provider >= _mapProviders.length)
                {
                    _provider = 0;
                }
            }
            var newProvider:IMapProvider = _mapProviders[_provider];
            if(newProvider != _map.getMapProvider())
            {
                _map.setMapProvider(newProvider);
            }
        }
    }
}