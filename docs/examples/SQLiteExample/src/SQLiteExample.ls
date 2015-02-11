package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
	import loom.sqlite.Connection;
	import loom.sqlite.Statement;
	import loom.sqlite.ResultCode;
	import loom.sqlite.DataType;
	
	/**
     *  Simple example to demonstrate SQLite
     */
	
    public class SQLiteExample extends Application
    {
    	var connection:Connection;
		var statement:Statement;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "SQLite Example";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

			openConnection();

		//	prepareStatement("CREATE TABLE test_table(id int, name varchar(255))");
		//	statement.step();

		//	prepareStatement("INSERT INTO test_table(id , name) VALUES (1, 'kevin')");
		//	statement.step();

			prepareStatement("SELECT * FROM test_table");
			statement.step();

			testTrace();

			statement.finalize();
			connection.close();
        }

		private function openConnection()
		{
		    connection = Connection.open("MyTestDB.db",  Connection.FLAG_CREATE | Connection.FLAG_READWRITE );
		}

		private function prepareStatement(sqlString:String)
		{
			statement = connection.prepare(sqlString);
		    if(connection.errorCode != ResultCode.SQLITE_OK)
		    {
				trace("prepare ERROR: " + connection.errorMessage);
		    }
		    else
		    {
			    trace("prepare SUCCESS!");
		    }
		}

		private function testTrace()
		{
			trace (statement.columnType(0) + " " + statement.columnType(1));
			//trace (statement.columnInt(0) + statement.columnString(1));
		}

		/*
		private function displayData()
		{
			var rowCount = 0;
			while (statement.step() == ResultCode.SQLITE_ROW)
			{
				for (var i = 0; i < 5; i++) 
				{
					var currentColType = statement.colType(i);

					switch (currentColType)
					{
						case DataType.SQLITE_INTEGER 	: label[rowCount][i].tesxt = statemment.colunmInt;
							break;
						case DataType.SQLITE_FLOAT 		: label[rowCount][i].tesxt = statement.columndouble;
							break;
						case DataType.SQLITE_TEXT 		: label[rowCount][i].tesxt = statement.columnstring;
							break;
					}
				};	
				rowCount++;
			}
		}
		*/
	}
}