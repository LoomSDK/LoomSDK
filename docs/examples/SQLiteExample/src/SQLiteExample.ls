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

            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
      //      stage.addChild(bg);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "SQLite Example";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

            queryInput = new TextInput();
            queryInput.width = stage.stageWidth - 25;
            queryInput.height = 100;
            queryInput.x = 12.5;
            queryInput.y = 150;            
            queryInput.prompt = "SQL query";                        
            queryInput.maxChars = 100; 
            queryInput.isEditable = true;                                
            stage.addChild(queryInput);

            var loginButton = new Button();
            loginButton.width = 150;
            loginButton.height = 45;
            loginButton.x = stage.stageWidth / 2;
            loginButton.y = 275;
            loginButton.label = "run query";
            loginButton.center();
            loginButton.addEventListener(Event.TRIGGERED,runQuery);
            stage.addChild(loginButton);  

            var userLabel = new Label();
            userLabel.text = "sdawasd";
            userLabel.y=300;
            userLabel.x = stage.stageWidth / 2;
            stage.addChild(userLabel);
            
			openConnection();

		//	prepareStatement("CREATE TABLE test_table(id int, name varchar(255))");
		//	statement.step();

		//	prepareStatement("INSERT INTO test_table(id , name) VALUES (1, 'kevin')");
		//	statement.step();

		//	prepareStatement("SELECT * FROM test_table");
	//		statement.step();

	//		testTrace();
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

        private function runQuery()
        {
        	prepareStatement(queryInput.text);
			statement.step();
			testTrace();
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
			//trace (statement.columnType(0) + " " + statement.columnType(1));
			trace (statement.columnDouble(0) + statement.columnString(1));
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