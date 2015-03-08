package
{
	import com.modestmaps.Map;
    import com.modestmaps.core.Tile;
    import com.modestmaps.core.Coordinate;
    import com.modestmaps.mapproviders.IMapProvider;
    import com.modestmaps.mapproviders.AbstractMapProvider; 
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
		
		public var panSensitivity = 1;
		
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
		
			this.stage.addEventListener(TouchEvent.TOUCH, onTouch);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }
		
		var touchMidpoint:Point; 
		
		function onTouch(event:TouchEvent)
		{			
			var touches = event.getTouches(stage);
			
			if (touches.length < 2) // Panning
			{
				var touch:Touch = event.getTouch(stage);
				map.panBy(touch.getMovement(stage).x, touch.getMovement(stage).y);
			}
			else // Zoom or rotation
			{
				var touch1:Touch = touches[0];
				var touch2:Touch = touches[1];
				
				// If we've just started a multitouch, store the midpoint of the touches
				if (touches[1].phase == TouchPhase.BEGAN)
				{
					touchMidpoint = new Point((touch1.getLocation(stage).x + touch2.getLocation(stage).x)/2 , (touch1.getLocation(stage).y + touch2.getLocation(stage).y)/2);
				}
				
				var prevAngle:Number = Math.atan2(touch2.getPreviousLocation(stage).y, touch2.getPreviousLocation(stage).x) - Math.atan2(touch1.getPreviousLocation(stage).y, touch1.getPreviousLocation(stage).x);
				var curAngle:Number = Math.atan2(touch2.getLocation(stage).y, touch2.getLocation(stage).x) - Math.atan2(touch1.getLocation(stage).y, touch1.getLocation(stage).x);
				
				var angleDifference:Number = Math.radToDeg( Math.abs(prevAngle - curAngle) );
				
				// If the angle between our fingers is less than a threshold value, it makes sense that the user must want to zoom instead of rotate
				if (angleDifference < 1)
				{
					var prevDist = Math.sqrt(Math.pow((touch2.previousGlobalX - touch1.previousGlobalX), 2) + Math.pow((touch2.previousGlobalY - touch1.previousGlobalY), 2));
					var curDist = Math.sqrt(Math.pow((touch2.globalX - touch1.globalX), 2) + Math.pow((touch2.globalY - touch1.globalY), 2));
					
					map.zoomByAbout((curDist - prevDist) / 150, touchMidpoint);
				}
				else
				{
					map.rotateByAbout((curAngle - prevAngle) * 5, touchMidpoint);
				}
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
				var bitmap:Image = new Image(Texture.fromAsset("assets/logo.png"));            
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