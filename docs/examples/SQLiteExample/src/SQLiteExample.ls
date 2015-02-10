package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
	import loom.sqlite.Connection;
	import loom.sqlite.Statement;
	
	/**
     *  Simple example to demonstrate SQLite
     */
	
    public class SQLiteExample extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            stage.addChild(sprite);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "SQLite Example";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

			//lukesCode();
			statementTest();
        }
	
		private function statementTest()
		{
		    var c:Connection = Connection.open("MyTestDB.db", Connection.FLAG_READWRITE | Connection.FLAG_CREATE);
			
		    var s:Statement = c.prepare("SELECT * FROM hotel_rates WHERE cityId=? AND rateDate >= ? AND rateDate <= ?");
			
		    trace("getParameterCount(): " + s.getParameterCount());
			
		    trace("getParameterName(): " + s.getParameterName(0));

		    trace("getParameterIndex(): " + s.getParameterIndex("hello"));
			
		}
		
		private function lukesCode()
		{
			trace("SQLite Version: " + Connection.version);

		    var c:Connection = Connection.open("MyTestDB.db", Connection.FLAG_READWRITE | Connection.FLAG_CREATE);
		    if(c.errorCode != Connection.ERROR_NONE)
		    {
			   trace("open ERROR: " + c.errorMessage);
		    }
		    else
		    {
			   trace("open SUCCESS!");
		    }
		    var s:Statement = c.prepare("SELECT * FROM hotel_rates WHERE cityId=? AND rateDate >= ? AND rateDate <= ?");
		    if(c.errorCode != Connection.ERROR_NONE)
		    {
				trace("prepare ERROR: " + c.errorMessage);
		    }
		    else
		    {
			    trace("prepare SUCCESS!");
		    }

		    var theDevil:int = s.getParameterCount();
		    trace("THE DEVIL IS: " + theDevil);
 
		    c.close();
		}
	}
}