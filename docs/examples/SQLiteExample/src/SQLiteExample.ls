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

		var grid:Vector.<Vector.<Label>> =[];
		



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
            queryInput.height = 200;
            queryInput.x = 12.5;
            queryInput.y = 50;            
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


		//	prepareStatement("CREATE TABLE test_table(id int, name varchar(255), surname varchar(255), age int)");
		//	statement.step();

		//	insert();

		//	update();

			selectAll();	

			createOutputGrid();
			displayData();
		//var time =  timeQuery(function(){statement = connection.prepare("SELECT * FROM test_table");}, 1000);
        }

        private function createOutputGrid()
        {
        	var label:Label;
        	for (var j = 0; j < 4; j++) 
        	{
        		var row:Vector.<Label> = [];
	        	for (var i = 0; i < 4; i++) 
	        	{
					label = new Label();
		            label.text = "";
		            label.width = 75;
		            label.y = 300 + (40 * j);
		            label.x = label.width * i;
		            stage.addChild(label);
		    		row.push(label);      	
	        	}
	        	grid.push(row);
        	}
        }

        private function update()
        {
        	prepareStatement("UPDATE test_table SET id=1, name='Kevin' WHERE id=1");
			statement.step();
			statement.finalize();
        }

        private function timeQuery(f:Function, runCount:int):Number
        {
        	var start = Platform.getTime();

        	for (var i = 0; i < runCount; i++) 
        	{
        		f.call();
        	};

        	return Platform.getTime() - start;
        }

        private function selectAll()
        {
        	prepareStatement("SELECT * FROM test_table");	
        }

        private function insert()
        {
        	prepareStatement("insert into test_table values (?,?,?,?)");

			statement.bindInt(1, 2);
			statement.bindString(2, "Joe");
			statement.bindString(3, "Soap");
			statement.bindInt(4, 45);

			statement.step();
			statement.finalize();
        }

        private function runQuery()
        {
        	prepareStatement(queryInput.text);
			statement.step();
			statement.reset();
			displayData();
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

		private function displayData()
		{
			clearGrid();
			getColumnNames();
			var rowCount = 1;
			while (statement.step() == ResultCode.SQLITE_ROW && rowCount < 4)
			{
				for (var i = 0; i < 4; i++) 
				{
					var currentColType = statement.columnType(i);

					switch (currentColType)
					{
						case DataType.SQLITE_INTEGER 	: grid[rowCount][i].text = statement.columnInt(i).toString();
							break;
						case DataType.SQLITE_FLOAT 		: grid[rowCount][i].text = statement.columnDouble(i).toString();
							break;
						case DataType.SQLITE_TEXT 		: grid[rowCount][i].text = statement.columnString(i);
							break;
						case DataType.SQLITE_BLOB		: grid[rowCount][i].text = "BLOB";
							break;
						case DataType.SQLITE_NULL		: grid[rowCount][i].text = "";
							break;
					}
				};	
				rowCount++;
			}
			statement.finalize();
		}

		private function getColumnNames()
		{
			for (var i = 0; i < 4; i++) 
			{
				grid[0][i].text = statement.columnName(i) ;
			};
		}

		private function clearGrid()
		{
			for (var i = 0; i < 4; i++) 
			{
				for (var j = 0; j < 4; j++) 
				{
					grid[i][j].text = "";
				};
			};
		}
		
	}
}