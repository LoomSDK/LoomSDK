package
{
	import com.modestmaps.Map;
    import com.modestmaps.core.Tile;
    import com.modestmaps.core.Coordinate;
    import com.modestmaps.mapproviders.IMapProvider;
    import com.modestmaps.mapproviders.AbstractMapProvider; 


    import loom.Application;

    import loom2d.display.Stage;
    import loom2d.display.Sprite;
	import loom2d.display.Quad; 

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
	

    public class ModestTest extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
						
			var map = new CustomMap(stage.stageWidth, stage.stageHeight, true, new BlankProvider(), stage);

			stage.addChild(map);
        }
    }
	
	class CustomTile extends Tile
	{
		public function CustomTile(column:int, row:int, zoom:int)
		{
			super(column, row, zoom);
//TEST CODE!!!
            var quad = new Quad(4, 4, 0xFF00FF00);
            quad.center();
            quad.x = Random.randRangeInt(0, Map.MapStage.stageWidth);
            quad.y = Random.randRangeInt(0, Map.MapStage.stageHeight);
            
            Map.MapStage.addChild(quad);            
		}

		override public function init(column:int, row:int, zoom:int):void
		{
			super.init(column, row, zoom);
			
			// var sprite = new Image(Texture.fromAsset("assets/bg.png"));
			
			// sprite.width = 32;
			// sprite.height = 32;
			
			//stage.addChild(sprite);
			
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