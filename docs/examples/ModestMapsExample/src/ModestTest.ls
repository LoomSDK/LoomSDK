package
{
	import com.modestmaps.Map;
	import com.modestmaps.TweenMap;
	import loom2d.display.Stage;
	
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
	
	import system.reflection.Type;

    public class ModestTest extends Application
    {
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
			            
			// make a draggable TweenMap so that we have smooth zooming and panning animation
			// use our blank provider, defined below:
			var map = new TweenMap(stage.stageWidth, stage.stageHeight, true, new BlankProvider());
			//map.addEventListener(MouseEvent.DOUBLE_CLICK, map.onDoubleClick);
			stage.addChild(map);			
        }
    }
	
	import loom2d.display.Sprite;
	import com.modestmaps.core.Tile;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.mapproviders.IMapProvider;
	import com.modestmaps.mapproviders.AbstractMapProvider;	

	class CustomTile extends Tile
	{
		public function CustomTile(column:int, row:int, zoom:int)
		{
			super(column, row, zoom);
		}

		override public function init(column:int, row:int, zoom:int):void
		{
			super.init(column, row, zoom);
			
			var sprite = new Image(Texture.fromAsset("assets/bg.png"));
			
			sprite.width = 32;
			sprite.height = 32;
			
			stage.addChild(sprite);
			
			// Insert image here
			/*graphics.clear();
			graphics.beginFill(0xffffff);
			graphics.drawRect(0,0,32,32);
			graphics.endFill();
			
			var r:int = Math.random() * 255;
			var g:int = Math.random() * 255;
			var b:int = Math.random() * 255;

			var c:int = 0xff000000 | r << 16 | g << 8 | b;
			
			graphics.beginFill(c);
			graphics.drawCircle(16,16,8);
			graphics.endFill();*/
		}
	}

	class BlankProvider extends AbstractMapProvider implements IMapProvider
	{
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