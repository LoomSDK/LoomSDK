package
{
	import com.modestmaps.Map;
    import com.modestmaps.core.Tile;
    import com.modestmaps.core.Coordinate;
    import com.modestmaps.mapproviders.IMapProvider;
    import com.modestmaps.mapproviders.AbstractMapProvider; 
    import com.modestmaps.mapproviders.microsoft.MicrosoftProvider; 
	import feathers.controls.NumericStepper;
	import loom2d.math.Point;

    import loom.Application;

    import loom2d.display.Stage;
    import loom2d.display.Sprite;
	import loom2d.display.Quad; 

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
	
	import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;
	
	import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
	import loom2d.events.TouchPhase;
	
	import loom.graphics.Graphics;



    public class ModestTest extends Application
    {		
		var map:Map;
		var doubleTouchInput:TwoInputTouch;
		
        override public function run():void
        {
			Graphics.setDebug(Graphics.DEBUG_STATS);
            stage.scaleMode = StageScaleMode.LETTERBOX;
						
			map = new Map(stage.stageWidth, 
								stage.stageHeight, 
								true, 
								new MicrosoftProvider(MicrosoftProvider.ROAD, true, MicrosoftProvider.MIN_ZOOM, MicrosoftProvider.MAX_ZOOM),
								stage,
                                null);

			stage.addChild(map);
		
			doubleTouchInput = new TwoInputTouch(stage);
			doubleTouchInput.OnDoubleTouchEvent += onDoubleTouch;
			doubleTouchInput.OnDoubleTouchEndEvent += onDoubleTouchEnd;
			
			stage.addEventListener(TouchEvent.TOUCH, onSingleTouch);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }
		
		var canRotate:Boolean = true;
		var isRotating:Boolean = false;
		
		function onDoubleTouchEnd()
		{
			canRotate = true;
			isRotating = false;
		}
		
		function onDoubleTouch(touch1:Point, touch2:Point)
		{
			if (Math.abs(doubleTouchInput.getZoomDelta()) > 3.2)
			{
				map.zoomByAbout(doubleTouchInput.getZoomDelta() * doubleTouchInput.rotationSensitivity, doubleTouchInput.getTouchMidPoint());
				// If we start zooming we don't want to rotate, unless we were already rotating
				if (!isRotating)
				{
					canRotate = false;
				}
			}
			
			if (canRotate && Math.abs(doubleTouchInput.getAngleDelta()) > 0.1)
			{
				map.rotateByAbout(doubleTouchInput.getAngleDelta() * doubleTouchInput.zoomSensitivity, doubleTouchInput.getTouchMidPoint());
				isRotating = true;
			}
			
			// We always want to pan the map
			map.panBy(doubleTouchInput.getTouchMidPointDelta().x, doubleTouchInput.getTouchMidPointDelta().y);
		}
		
		function onSingleTouch(event:TouchEvent)
		{		
			var touches = event.getTouches(stage);
			
			if (touches.length < 2) // Single fincger pan
			{
				var touch:Touch = event.getTouch(stage);
				map.panBy(touch.getMovement(stage).x, touch.getMovement(stage).y);
			}
		}
		
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