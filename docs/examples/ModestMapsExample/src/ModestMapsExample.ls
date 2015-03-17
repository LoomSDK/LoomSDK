package
{
	import loom.Application;
	import loom.modestmaps.geo.Location;
	import loom.modestmaps.Map;
	import loom.modestmaps.mapproviders.AbstractMapProvider;
	import loom.modestmaps.mapproviders.IMapProvider;
	import loom.modestmaps.mapproviders.microsoft.MicrosoftRoadMapProvider;
	import loom.modestmaps.mapproviders.OpenStreetMapProvider;
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
        var map:Map;
        var msProvider:MicrosoftRoadMapProvider;
        var osmProvider:OpenStreetMapProvider;
		var count:int = 0;
		var timer:Timer;
		var location:Location;
        
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
			
			map.addEventListener(TouchEvent.TOUCH, touchHandler);
			
			timer = new Timer(200);
            timer.onComplete = function()
             {
             	map.putMarker(location, NewPin()); 
             };
        }
        
		private function touchHandler(event:TouchEvent):void
		{
			var touch = event.getTouch(map, TouchPhase.BEGAN);
			if (touch)
			{
				var touchPos = new Point(touch.globalX, touch.globalY);		
				location = map.pointLocation(touchPos);
				timer.start();
			}	
			touch = event.getTouch(stage, TouchPhase.ENDED); //user hold was not long enough
			if (touch)
			{
				timer.stop();
			}
			touch = event.getTouch(stage, TouchPhase.MOVED); //user hold and move (for panning etc)
			if (touch)
			{
				timer.stop();
			}
		}
		
		private function NewPin():ImageMarker
		{
			var pin = new ImageMarker(map, "pin" + count, Texture.fromAsset("assets/pin.png"));
			pin.scale =  0.1;
			count ++;
			return pin;
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
			
			if (keycode == LoomKey.B)
			{
				map.removeMarker("pin1");
			}
			
			if (keycode == LoomKey.V)
			{
				var pin:Image = map.getMarker("pin1") as Image;
				trace (pin);
			}
        }
    }
}