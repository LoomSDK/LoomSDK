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
    	var connection:Connection;
		var statement:Statement;
		var queryInput:TextInput;
		var countInput:TextInput;
		var timeLabel:Label;
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

            initTemplateButtons();
            initInputControls();
            
            var runQueryButton = new Button();
            runQueryButton.width = 150;
            runQueryButton.height = 45;
            runQueryButton.x = 12.5;
            runQueryButton.y = 215;
            runQueryButton.label = "run query";
            runQueryButton.addEventListener(Event.TRIGGERED,startQuery);
            stage.addChild(runQueryButton);  

            timeLabel = new Label();
            timeLabel.width = 150;
            timeLabel.height = 45;
            timeLabel.x = 12.5;
            timeLabel.y = 270;
            timeLabel.text = "";
            stage.addChild(timeLabel);

            
            outputLabel = new Label();
            outputLabel.width = stage.stageWidth-25;;
            outputLabel.height = 45;
            outputLabel.x = 12.5;
            outputLabel.y = 440;
            outputLabel.text = "";
            stage.addChild(outputLabel);

			createOutputGrid();
            
            loadingOverlay = new Image(Texture.fromAsset("assets/loading_bg.png"));
            loadingOverlay.alpha = 0;
            stage.addChild(loadingOverlay);

			openConnection();
        }

       
        private function initTemplateButtons()
        {
    	   	var createQueryButton = new Button();
            createQueryButton.width = 95;
            createQueryButton.height = 40;
            createQueryButton.x = 12.5;
            createQueryButton.y = 5;
            createQueryButton.label = "create";
            createQueryButton.addEventListener(Event.TRIGGERED, function(){queryInput.text = "CREATE TABLE example_table(id int, name varchar(255), surname varchar(255))";});
            stage.addChild(createQueryButton);

            var selectQueryButton = new Button();
            selectQueryButton.width = 95;
            selectQueryButton.height = 40;
            selectQueryButton.x = 112.5;
            selectQueryButton.y = 5;
            selectQueryButton.label = "select";
            selectQueryButton.addEventListener(Event.TRIGGERED, function(){queryInput.text = "SELECT * FROM example_table";});
            stage.addChild(selectQueryButton);

            var insertQueryButton = new Button();
            insertQueryButton.width = 95;
            insertQueryButton.height = 40;
            insertQueryButton.x = 212.5;
            insertQueryButton.y = 5;
            insertQueryButton.label = "insert";
            insertQueryButton.addEventListener(Event.TRIGGERED, insertTemplate);
            stage.addChild(insertQueryButton);
        }

        private function initInputControls()
        {
        	queryInput = new TextInput();
            queryInput.width = stage.stageWidth - 25;
            queryInput.height = 100;
            queryInput.x = 12.5;
            queryInput.y = 50;            
            queryInput.prompt = "SQL query";                        
            queryInput.maxChars = 100; 
            queryInput.isEditable = true;                                
            stage.addChild(queryInput);

            param1Input = new TextInput();
            param1Input.width = 90;
            param1Input.height = 40;
            param1Input.x = 12.5;
            param1Input.y = 165;            
            param1Input.prompt = "param1";                        
            param1Input.maxChars = 100; 
            param1Input.isEditable = true;                                
            stage.addChild(param1Input);

            param2Input = new TextInput();
            param2Input.width = 90;
            param2Input.height = 40;
            param2Input.x = 107.5;
            param2Input.y = 165;            
            param2Input.prompt = "param2";                        
            param2Input.maxChars = 100; 
            param2Input.isEditable = true;                                
            stage.addChild(param2Input);

            param3Input = new TextInput();
            param3Input.width = 90;
            param3Input.height = 40;
            param3Input.x = 202.5;
            param3Input.y = 165;            
            param3Input.prompt = "param3";                        
            param3Input.maxChars = 100; 
            param3Input.isEditable = true;                                
            stage.addChild(param3Input);

            countInput = new TextInput();
            countInput.width = 100;
            countInput.height = 45;
            countInput.x = 175;
            countInput.y = 215;            
            countInput.prompt = "run count";                        
            countInput.maxChars = 7; 
            countInput.isEditable = true;                                
            stage.addChild(countInput);
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

			var queryString = queryInput.text;
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
                if (prepareStatement("SELECT * FROM example_table") == 0)
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

			timeLabel.text = time + "ms";
			loadingOverlay.alpha = 0;
        }

		private function openConnection()
		{
		    connection = Connection.open("MyTestDB.db", Connection.FLAG_CREATE | Connection.FLAG_READWRITE );
		}

		private function prepareStatement(sqlString:String):int
		{
			statement = connection.prepare(sqlString);
		    if(connection.errorCode != ResultCode.SQLITE_OK)
		    {
				outputLabel.text = "prepare ERROR: " + connection.errorMessage;
                trace ("prepare ERROR: " + connection.errorMessage);
                loadingOverlay.alpha = 0;
                clearGrid();
                return 0;
		    }
		    else
		    {
			    outputLabel.text = "prepare SUCCESS!";
                return 1;
		    }
		}


        //all that follows is for display purposes only
		private function displayData()
		{
			clearGrid();
			getColumnNames();
            statement.reset();
			var rowCount = 1;
			while (statement.step() == ResultCode.SQLITE_ROW && rowCount < 4)
			{
				for (var i = 0; i < 3; i++) 
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
			for (var i = 0; i < 3; i++) 
			{
				grid[0][i].label = statement.columnName(i) ;
			};
		}

		private function clearGrid()
		{
			for (var i = 0; i < 4; i++) 
			{
				for (var j = 0; j < 3; j++) 
				{
					grid[i][j].label = "";
				};
			};
		}

		 private function createOutputGrid()
        {
        	for (var j = 0; j < 4; j++) 
        	{
        		var row:Vector.<Button> = [];
	        	for (var i = 0; i < 3; i++) 
	        	{
					var button = new Button();
                    button.isEnabled = false;
		            button.label = "";
		            button.width = 100;
                    button.height = 30;
		            button.y = 305 + (30 * j);
		            button.x = button.width * i + 10;
		            stage.addChild(button);
		    		row.push(button);      	
	        	}
	        	grid.push(row);
        	}
        }
	}
}