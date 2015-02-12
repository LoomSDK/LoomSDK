package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.events.Event;

	import loom.sqlite.Connection;
	import loom.sqlite.Statement;
	import loom.sqlite.ResultCode;
	import loom.sqlite.DataType;

    import feathers.controls.*;
    import feathers.events.FeathersEventType;
    import feathers.themes.MetalWorksMobileTheme;

    import loom2d.text.TextField;    
    import loom2d.text.BitmapFont;
	
	/**
     *  Simple example to demonstrate SQLite
     */
	
    public class SQLiteExample extends Application
    {
    	var connection:Connection;
		var statement:Statement;
		var queryInput:TextInput;

		var row1:Vector.<Label> = [];

        //Import the Feathers theme we'll use for our controls
        public var theme:MetalWorksMobileTheme;


        override public function run():void
        {
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansPro");
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansProSemibold");
            theme = new MetalWorksMobileTheme();  

            stage.scaleMode = StageScaleMode.LETTERBOX;

            queryInput = new TextInput();
            queryInput.width = stage.stageWidth - 25;
            queryInput.height = 100;
            queryInput.x = 12.5;
            queryInput.y = 150;            
            queryInput.prompt = "SQL query";                        
            queryInput.maxChars = 100; 
            queryInput.isEditable = true;                                
            stage.addChild(queryInput);

            var runQueryButton = new Button();
            runQueryButton.width = 150;
            runQueryButton.height = 45;
            runQueryButton.x = stage.stageWidth / 2;
            runQueryButton.y = 275;
            runQueryButton.label = "run query";
            runQueryButton.center();
            runQueryButton.addEventListener(Event.TRIGGERED,runQuery);
            stage.addChild(runQueryButton);  
            
			openConnection();

/*
			prepareStatement("CREATE TABLE test_table(id int, name varchar(255))");
			statement.step();
			prepareStatement("INSERT INTO test_table(id , name) VALUES (1, 'kevin')");
			statement.step();

		*/

		//	insert();

			prepareStatement("SELECT * FROM test_table");

			while (statement.step() == 100)
				testTrace();
        }

        private function createOutputGrid()
        {
        	var label = new Label();
            label.text = "sdawasd";
            label.y=300;
            label.x = stage.stageWidth / 2;
            stage.addChild(label);
    		row1.push(label); 
        }

        private function update()
        {
        	prepareStatement("UPDATE test_table SET id=?, name=? WHERE id=?");

			statement.bindInt(1, 34);
			statement.bindString(2, "update_string");
			statement.bindInt(1, 666);

			statement.step();
			statement.finalize();
        }

        private function insert()
        {
        	prepareStatement("insert into test_table values (?,?)");

        	var bytes = new ByteArray();
        	bytes.writeDouble(1234);
        	bytes.writeString("byte_test");

			statement.bindInt(1, 111);
			statement.bindBytes(2, bytes);

			statement.step();
			statement.finalize();
        }

        private function runQuery()
        {
        	prepareStatement(queryInput.text);
			statement.step();
			testTrace();
        }

		private function openConnection()
		{
		    connection = Connection.open("MyTestDB.db", null,  Connection.FLAG_CREATE | Connection.FLAG_READWRITE );
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
			var bytes = statement.columnBytes(1);
			trace (bytes.readDouble() + " " + bytes.readString());
			//trace (statement.columnType(0) + " " + statement.columnType(1));
			//trace (statement.columnBytes(0) + " " + statement.columnBytes(1));
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
						case DataType.SQLITE_NULL		: i = 5;
							break;
					}
				};	
				rowCount++;
			}
		}
		*/
	}
}