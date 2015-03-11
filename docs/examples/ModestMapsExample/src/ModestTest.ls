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
		var map:CustomMap;
		var doubleTouchInput:TwoInputTouch;
		
        override public function run():void
        {
			//Graphics.setDebug(Graphics.DEBUG_STATS);
            stage.scaleMode = StageScaleMode.LETTERBOX;
						
			map = new CustomMap(stage.stageWidth, 
								stage.stageHeight, 
								true, 
								new BlankProvider(AbstractMapProvider.MIN_ZOOM, AbstractMapProvider.MAX_ZOOM), 
								stage);

			stage.addChild(map);
		
			doubleTouchInput = new TwoInputTouch(stage);
			doubleTouchInput.OnDoubleTouchEvent += onDoubleTouch;
			doubleTouchInput.OnDoubleTouchEndEvent += onDoubleTouchEnd;
			
			//var microsoftMap:MicrosoftProvider = new MicrosoftProvider("AERIAL", true, 1, 50);
			
			//for (var i:Number = 0; i < 10; i++)
			//{
			//	var urls = microsoftMap.getTileUrls(new Coordinate(i, 1, 20));
			//	trace(urls);
			//}
			
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
	
	class CustomTile extends Tile
	{
		private var initialised:Boolean = false;
		public function CustomTile(column:int, row:int, zoom:int)
		{
			super(column, row, zoom);
		}

		override public function init(column:int, row:int, zoom:int):void
		{
			//trace("INIT WAS CALLED");
			super.init(column, row, zoom);
			
//TEST CODE!!!
			if (!initialised)
			{
				var bitmap:Image = new Image();            
				bitmap.center();
				bitmap.scaleX = 0.3;
				bitmap.scaleY = 0.3;
				//bitmap.x = Random.randRangeInt(0, Map.MapStage.stageWidth);
				//bitmap.y = Random.randRangeInt(0, Map.MapStage.stageHeight);
				//bitmap.x = 0;
				//bitmap.y = 0;
				addChild(bitmap);   
				
				var label = new SimpleLabel("assets/Curse-hd.fnt");
				label.text = Random.randRangeInt(0, 10) as String;
				label.scale = 0.25;
				label.center();
				addChild(label);
				
				//initialised = true;
			}
        }   
	}

    class CustomMap extends Map
    {
        public function CustomMap(width:Number, height:Number, draggable:Boolean, provider:IMapProvider, mapStage:Stage=null, ... rest)
        {
            super(width, height, draggable, provider, mapStage, rest);
            grid.setTileCreator(CreateCustomTile);
        }

        /* Custom Tile creator factor function for this map type */
        protected function CreateCustomTile():CustomTile
        {
            return new CustomTile(0, 0, 0);
        }
    }    

	class BlankProvider extends AbstractMapProvider implements IMapProvider
	{
        public function BlankProvider(minZoom:int, maxZoom:int)
        {
            super(minZoom, maxZoom);
        }

		public function getTileUrls(coord:Coordinate):Vector.<String>
		{
			return [];
		}
		
		public function toString():String
		{
			return "BLANK_PROVIDER";
		}
		
		override public function get tileWidth():Number
		{
			return 32;
		}

		override public function get tileHeight():Number
		{
			return 32;
		}
	}
}