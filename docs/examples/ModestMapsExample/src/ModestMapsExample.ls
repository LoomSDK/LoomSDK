package
{
    import loom.Application;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.Map;
    import loom.modestmaps.mapproviders.AbstractMapProvider;
    import loom.modestmaps.mapproviders.IMapProvider;
    import loom.modestmaps.mapproviders.MapboxProvider;
    import loom.modestmaps.mapproviders.microsoft.MicrosoftRoadMapProvider;
    import loom.modestmaps.mapproviders.OpenStreetMapProvider;
    import loom.modestmaps.mapproviders.BlueMarbleMapProvider;
    import loom.modestmaps.overlays.ImageMarker;
    import loom2d.Loom2D;
    import system.platform.File;

    import loom.platform.LoomKey;
    import loom.platform.Timer;
    import loom2d.display.Image;
    import loom2d.display.StageScaleMode;
    import loom2d.events.*;
    import loom2d.math.Point;
    import loom2d.textures.Texture;
    
    /** Simple application that demonstrates how to use Modest Maps to show a digital map provider */
    public class ModestMapExample extends Application
    {       
        private var _map:Map;
        private var _mapProviders:Vector.<IMapProvider> = [];
        private var _provider:int = 0;

        private var _pinCount:int = 0;
        private var _markerHoldTimer:Timer;
        private var _markerLoc:Location;
        private var _markerTouchStart:Point;
        private var _markerTouchCur:Point;
        
        private const PinHoldTime:int = 700;
        private const PinTouchBias:int = 4;
        
        private var landmarkViewer:LandmarkViewer;
        
        override public function run():void
        {   
            
            stage.scaleMode = StageScaleMode.NONE;
            
            // Uncomment to log framerate every second
            //stage.reportFps = true;
            
            //create some providers
            _mapProviders.pushSingle(new MapboxProvider(File.loadTextFile("assets/mapbox/id.txt"), File.loadTextFile("assets/mapbox/token.txt")));
            _mapProviders.pushSingle(new MicrosoftRoadMapProvider(true));
            _mapProviders.pushSingle(new OpenStreetMapProvider());
            _mapProviders.pushSingle(new BlueMarbleMapProvider());
            
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
            
            landmarkViewer = new LandmarkViewer(_map);
            landmarkViewer.loadVolcanoes("assets/volcanoes.tsv");
            
            
            //marker placement logic
            _map.addEventListener(TouchEvent.TOUCH, touchHandler);          
            _markerHoldTimer = new Timer(PinHoldTime);
            _markerHoldTimer.onComplete = function() 
            { 
                if(Point.distance(_markerTouchStart, _markerTouchCur) < PinTouchBias)
                {
                    _map.putMarker(_markerLoc, newPin()); 
                }
            };
        }

        //make a new pin!
        private function newPin():ImageMarker
        {
            var pin = new ImageMarker(_map, "pin" + _pinCount++, Texture.fromAsset("assets/pin.png"));
            return pin;
        }
        
        
        override public function onTick() {
            landmarkViewer.onTick();
        }

        //keyboard handler
        private function keyDownHandler(event:KeyboardEvent):void
        {   
            var keycode = event.keyCode;

            //always zoom at the center of the screen
            var zoomPoint:Point = new Point(_map.getWidth() / 2, _map.getHeight() / 2);
            
            if (keycode == LoomKey.C) trace(_map.getCenter());
            
            if (keycode == LoomKey.S) landmarkViewer.runVolcanoShowcase();
            
            //process zooming
            if (keycode == LoomKey.EQUALS)
                _map.zoomByAbout(0.05, zoomPoint);
            if (keycode == LoomKey.HYPHEN)
                _map.zoomByAbout( -0.05, zoomPoint);
            
            var switched = false;
            
            //switch map provider!
            if(keycode == LoomKey.LEFTBRACKET)
            {
                _provider--;
                if(_provider < 0)
                {
                    _provider = _mapProviders.length - 1;
                }
                switched = true;
            }
            else if(keycode == LoomKey.RIGHTBRACKET)
            {
                _provider++;
                if(_provider >= _mapProviders.length)
                {
                    _provider = 0;
                }
                switched = true;
            }
            if (switched) {
                var newProvider:IMapProvider = _mapProviders[_provider];
                if(newProvider != _map.getMapProvider())
                {
                    _map.setMapProvider(newProvider);
                }
            }
        }

        //touch handler
        private function touchHandler(event:TouchEvent):void
        {
            //if more than 1 touch point, or a touch end was found, we need to stop the timer
            var touches = event.getTouches(_map);
            if ((touches.length > 1) || event.getTouch(_map, TouchPhase.ENDED))
            {
                _markerHoldTimer.stop();
                return;
            }


            //touch began?
            var touch = event.getTouch(_map, TouchPhase.BEGAN);
            if (touch)
            {
                var touchPos = touch.getLocation(_map);     
                _markerLoc = _map.pointLocation(touchPos);
                _markerHoldTimer.start();
                _markerTouchStart = touchPos;
                _markerTouchCur = touchPos;
            }
            else
            {
                //track moving
                touch = event.getTouch(_map, TouchPhase.MOVED);
                if(touch)
                {
                    _markerTouchCur = touch.getLocation(_map);
                }
            }
        }        
    }
}