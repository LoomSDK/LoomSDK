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
    import loom.platform.Timer; 
    import loom2d.text.BitmapFont;
	
	/**
     *  Simple example to demonstrate SQLite
     */
	
    public class SQLiteExample extends Application
    {
        const numRows:int = 6;
        const numColumns:int = 5;

    	var connection:Connection;
		var statement:Statement;
		var queryInput:TextInput;
		var countInput:TextInput;
		var timeLabel:Label;
        var tableNameLabel:Label;
        var outputLabel:Label;
        var param1Input:TextInput;
        var param2Input:TextInput;
        var param3Input:TextInput;
		var loadingOverlay:Image;
		var grid:Vector.<Vector.<Button>> =[];		
        var theme:MetalWorksMobileTheme;

        override public function run():void
        {
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansPro");
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansProSemibold");
            theme = new MetalWorksMobileTheme();  

            stage.scaleMode = StageScaleMode.LETTERBOX;

            //initialize the UI
            initTemplateButtons();
            initInputControls();
			initOutputGrid();
            initRestOfUI();
            
            loadingOverlay = new Image(Texture.fromAsset("assets/loading_bg.png"));
            loadingOverlay.alpha = 0;
            stage.addChild(loadingOverlay);


            //create / open connection
			openConnection();
        }

        private function newLabel(width:Number, height:Number, x:Number, y:Number, text:String=""):Label
        {
            var label = new Label();
            label.width = width;
            label.height = height;
            label.x = x;
            label.y = y;
            label.text = text;
            stage.addChild(label);

            return label;
        }


        private function newButton(width:Number, height:Number, x:Number, y:Number, label:String="", f:Function=null):Button
        {
            var button = new Button();
            button.width = width;
            button.height = height;
            button.x = x;
            button.y = y;
            button.label = label;
            button.addEventListener(Event.TRIGGERED,f);
            stage.addChild(button);

            return button;
        }


        private function newInputBox(width:Number, height:Number, x:Number, y:Number, prompt:String=""):TextInput
        {
            var inputBox = new TextInput();
            inputBox.width = width;
            inputBox.height = height;
            inputBox.x = x;
            inputBox.y = y;    
            inputBox.prompt = prompt;
            inputBox.maxChars = 100; 
            inputBox.isEditable = true;  

            stage.addChild(inputBox);

            return inputBox;
        }

        private function initRestOfUI()
        {
            var runQueryButton = newButton(150, 45, 12.5, 215, "run query", startQuery);
            timeLabel = newLabel(250, 45, 300, 225, "Query duration:");
            tableNameLabel = newLabel(500, 55, 12.5, 275, "Table name:");
            outputLabel = newLabel(stage.stageWidth-25, 45, 12.5, 600, "");
        }

        private function initTemplateButtons()
        {
            var createQueryButton = newButton(100, 40, 12, 5, "CREATE", function(){queryInput.text = "CREATE TABLE example_table(id int, name varchar(255), surname varchar(255))";});
            var selectQueryButton = newButton(100, 40, 117, 5, "SELECT", function(){queryInput.text = "SELECT * FROM example_table";});
            var insertQueryButton = newButton(100, 40, 222, 5, "INSERT",insertTemplate);
            var dropQueryButton = newButton(100, 40, 327, 5, "DROP", function(){queryInput.text = "DROP TABLE example_table";});
        }

        private function initInputControls()
        {
            queryInput = newInputBox(stage.stageWidth - 25, 100, 12.5, 50, "SQL query");

            param1Input = newInputBox(90, 40, 12.5, 165, "param1");
            param2Input = newInputBox(90, 40, 107.5, 165, "param2");
            param3Input = newInputBox(90, 40, 202.5, 165, "param3");           
   //         param4Input = newInputBox(90, 40, 297, 165, "param4");
   //         param5Input = newInputBox(90, 40, 392.5, 165, "param5");
   //         param6Input = newInputBox(90, 40, 487.5, 165, "param6");

            countInput = newInputBox(100, 45, 175, 215, "run count");                    
            countInput.maxChars = 7; 
        }

        private function insertTemplate()
        {
    		queryInput.text = "INSERT INTO example_table VALUES (?,?,?)";
    		param1Input.text = "1";
    		param2Input.text = "Joe";
    		param3Input.text = "Soap";
        }

        private function startQuery()
        {
        	loadingOverlay.alpha = 0.75;
        	var timer = new Timer(50);
        	timer.start();
        	timer.onComplete = function(){runQuery();};
        }

        private function runQuery()
        {
            //Get the run count from the input box and validate it
        	var runCount = 1;
			if (!String.isNullOrEmpty(countInput.text))
			{
				runCount = Number.fromString(countInput.text);
			}
            if (runCount == 0)
            {
                runCount = 1;
                countInput.text = "1";
            }

			var queryString = queryInput.text.toLocaleUpperCase();
			var start = 0;
			var time = 0;

            //if the query is not a select, check if it is an insert so we can bind the parameters
			if (queryString.indexOf("SELECT ") == -1)
			{
				start = Platform.getTime();
				 if (queryString.indexOf("INSERT ") > -1)
				 {
					var param1:Number = Number.fromString(param1Input.text);
					var param2:String = param2Input.text;
					var param3:String = param3Input.text;

					for (var i = 0; i < runCount; i++) 
					{
						if (prepareStatement(queryString) == 0)
                            return;
						statement.bindInt(1, param1);
						statement.bindString(2, param2);
						statement.bindString(3, param3);

				 		statement.step();
						statement.finalize();
				 	}
					time = Platform.getTime() - start;
				 }
				 else //Other SQLite functions
				 {
					if (prepareStatement(queryString)== 0)
                            return;
			 		statement.step();
				 }

                //select the whole table to display in our grid
                if (prepareStatement("SELECT * FROM EXAMPLE_TABLE", false) == 0)
                    return;
                displayData(); 
			}
			else
			{
				start = Platform.getTime();
				if (prepareStatement(queryString)== 0)
                    return;
				for (var j = 0; j < runCount; j++) 
				{
					if (statement.step() != ResultCode.SQLITE_ROW)
					{
						statement.reset();
					}
				};
				time = Platform.getTime() - start;
				displayData(); 
			}

			timeLabel.text = "Query duration: " +  time + "ms";
			loadingOverlay.alpha = 0; 
            
        }

		private function openConnection()
		{
		    connection = Connection.open("MyTestDB.db", Connection.FLAG_CREATE | Connection.FLAG_READWRITE );
		}

		private function prepareStatement(sqlString:String, display:Boolean=true):int
		{
			statement = connection.prepare(sqlString);
		    if(connection.errorCode != ResultCode.SQLITE_OK)
		    {
                if (display)
				    outputLabel.text = "prepare ERROR: " + connection.errorMessage;
                trace ("prepare ERROR: " + connection.errorMessage);
                loadingOverlay.alpha = 0;
                clearGrid();
                return 0;
		    }
		    else
		    {
                var outputString:String;

                if (sqlString.indexOf("SELECT") > -1)
                {
                    outputString = "SELECT SUCCESS";
                    tableNameLabel.text = "Table Name: " + getTableName(sqlString);
                }
                else  if (sqlString.indexOf("INSERT") > -1)
                {
                    outputString = "INSERT SUCCESS";
                }
                else  if (sqlString.indexOf("DROP") > -1)
                {
                    outputString = "TABLE DROP SUCCESS";
                }   
                else  if (sqlString.indexOf("CREATE") > -1)
                {
                    outputString = "TABLE CREATE SUCCESS";
                }
                else
                    outputString = "prepare SUCCESS!";

                if (display)
                {
			        outputLabel.text = outputString;
                }
                return 1;
		    }
		}

        private function getTableName(sqlString:String):String
        {
            var index = sqlString.indexOf("FROM") + 5;
            return sqlString.substr(index, sqlString.length - index);
        }

        //all that follows is for display purposes only
		private function displayData()
		{
			clearGrid();
			getColumnNames();
            statement.reset();
			var rowCount = 1;
			while (statement.step() == ResultCode.SQLITE_ROW && rowCount < numRows)
			{
				for (var i = 0; i < numColumns; i++) 
				{
					var currentColType = statement.columnType(i);

					switch (currentColType)
					{
						case DataType.SQLITE_INTEGER 	: grid[rowCount][i].label = statement.columnInt(i).toString();
							break;
						case DataType.SQLITE_FLOAT 		: grid[rowCount][i].label = statement.columnDouble(i).toString();
							break;
						case DataType.SQLITE_TEXT 		: grid[rowCount][i].label = statement.columnString(i);
							break;
						case DataType.SQLITE_BLOB		: grid[rowCount][i].label = "BLOB";
							break;
						case DataType.SQLITE_NULL		: grid[rowCount][i].label = "";
							break;
					}
				};	
				rowCount++;
			}
			statement.finalize(); 
		}

		private function getColumnNames()
		{
			for (var i = 0; i < numColumns; i++) 
			{
				grid[0][i].label = statement.columnName(i) ;
			};
		}

		private function clearGrid()
		{
			for (var i = 0; i < numRows; i++) 
			{
				for (var j = 0; j < numColumns; j++) 
				{
					grid[i][j].label = "";
				};
			};
		}

		 private function initOutputGrid()
        {
        	for (var j = 0; j < numRows; j++) 
        	{
        		var row:Vector.<Button> = [];
	        	for (var i = 0; i < numColumns; i++) 
	        	{
					var button = newButton(120, 30, 120 * i + 10, 305 + (30 * j));
                    button.isEnabled = false;
		    		row.push(button);      	
	        	}
	        	grid.push(row);
        	}
        }
	}
}