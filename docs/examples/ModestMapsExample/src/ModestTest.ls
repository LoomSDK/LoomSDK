package
{
    import loom.Application;
    import loom2d.display.Stage;
    import loom2d.display.StageScaleMode;

    import com.modestmaps.Map;
    import com.modestmaps.mapproviders.AbstractMapProvider;
    import com.modestmaps.mapproviders.OpenStreetMapProvider; 
    import com.modestmaps.mapproviders.microsoft.MicrosoftRoadMapProvider; 
	
	import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;
    import loom2d.math.Point;
	import loom.graphics.Graphics;



    public class ModestTest extends Application
    {		
		var map:Map;
		
        override public function run():void
        {
			// Graphics.setDebug(Graphics.DEBUG_STATS);
            stage.scaleMode = StageScaleMode.LETTERBOX;
						
			map = new Map(stage.stageWidth, 
								stage.stageHeight, 
								true, 
                                new MicrosoftRoadMapProvider(true, AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM),
								//new OpenStreetMapProvider(AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM),
								stage,
                                null);

			stage.addChild(map);
			

//TEST CODE!!!
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }
		



//TEST CODE
        function keyDownHandler(event:KeyboardEvent):void
        {   
            var keycode = event.keyCode;
            if(keycode == LoomKey.W)
                map.panBy(0, -5);
            if(keycode == LoomKey.S)
                map.panBy(0, 5);
            if(keycode == LoomKey.A)
                map.panBy(-5, 0);
            if(keycode == LoomKey.D)
                map.panBy(5, 0);
			if (keycode == LoomKey.Q)
				map.zoomByAbout(0.05, new Point(0, 0));
			if (keycode == LoomKey.E)
				map.zoomByAbout( -0.05, new Point(stage.width/2, stage.height/2));
			if (keycode == LoomKey.R)
				map.rotateByAbout(0.05, new Point(stage.width/2, stage.height/2));
			if (keycode == LoomKey.T)
				map.rotateByAbout(-0.05, new Point(stage.width/2, stage.height/2));
        }
    }
}