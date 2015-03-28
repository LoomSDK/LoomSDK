package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;
    import loom2d.ui.ButtonClickCallback;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;


    public class AppDataExample extends Application
    {
        //private vars
        private var _playerOneData:PlayerData = null;
        private var _playerTwoData:PlayerData = null;
        private var _clickLabel1:SimpleLabel = null;
        private var _clickLabel2:SimpleLabel = null;


        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //create new PlayerData class to track saved player data
            _playerOneData = new PlayerData("playerOneData.json", "AppDataExample", true, false);
            _playerTwoData = new PlayerData("playerTwoData.json", "AppDataExample", true, false);


            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);

            //labels            
            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Num Clicks: ";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 130;
            label.touchable = false;
            stage.addChild(label);

            //clickable lables to increment values for each player data
            //player one
            _clickLabel1 = new SimpleLabel("assets/Curse-hd.fnt");
            _clickLabel1.text = _playerOneData.NumClicks.toString();
            _clickLabel1.center();
            _clickLabel1.x = stage.stageWidth / 2 - 50;
            _clickLabel1.y = stage.stageHeight / 2 - 30;
            _clickLabel1.addEventListener(TouchEvent.TOUCH, playerOneTouch);
            stage.addChild(_clickLabel1);

            //player two
            _clickLabel2 = new SimpleLabel("assets/Curse-hd.fnt");
            _clickLabel2.text = _playerTwoData.NumClicks.toString();
            _clickLabel2.center();
            _clickLabel2.x = stage.stageWidth / 2 + 50;
            _clickLabel2.y = stage.stageHeight / 2 - 30;
            _clickLabel2.addEventListener(TouchEvent.TOUCH, playerTwoTouch);
            stage.addChild(_clickLabel2);

            //buttons to clear, load, and purge
            var clearButton:SimpleButton = createButton(10, stage.stageHeight - 70, "CLEAR", onClearAppData);
            var loadButton:SimpleButton = createButton(stage.stageWidth / 2 - 32, stage.stageHeight - 70, "LOAD", onLoadAppData);
            var purgeButton:SimpleButton = createButton(stage.stageWidth - 74, stage.stageHeight - 70, "PURGE", onPurgeAppData);
        }

        //create button
        private function createButton(x:int, y:int, text:String, cb:ButtonClickCallback):SimpleButton
        {
            var button:SimpleButton = new SimpleButton();
            button.scale = 0.25;
            button.x = x;
            button.y = y;
            button.upImage = "assets/up.png";
            button.downImage = "assets/down.png";
            button.onClick += cb;
            stage.addChild(button);

            //add label?
            if(!String.isNullOrEmpty(text))
            {
                var label:SimpleLabel = new SimpleLabel("assets/Curse-hd.fnt");
                label.touchable = false;
                label.text = text;
                label.scale = 0.2;
                label.x = button.x + 12;
                label.y = button.y + 20;
                stage.addChild(label);                   
            }

            return button;
        }


        //input handler to catch touches to add to clicks and set new value
        private function playerOneTouch(e:TouchEvent)
        {
            var touch:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if(!touch)
            {
                return;
            }

            //increment the touch counter
            _playerOneData.NumClicks++;
            _playerOneData.setInteger("NumClicks", _playerOneData.NumClicks);

            //update text
            _clickLabel1.text = _playerOneData.NumClicks.toString();
        }


        //input handler to catch touches to add to clicks and set new value
        private function playerTwoTouch(e:TouchEvent)
        {
            var touch:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if(!touch)
            {
                return;
            }

            //increment the touch counter
            _playerTwoData.NumClicks++;
            _playerTwoData.setInteger("NumClicks", _playerTwoData.NumClicks);

            //update text
            _clickLabel2.text = _playerTwoData.NumClicks.toString();
        }


        //button callback to clear all AppData
        private function onClearAppData()
        {
            _playerOneData.clear();
            _playerTwoData.clear();
            _clickLabel1.text = _playerOneData.NumClicks.toString();
            _clickLabel2.text = _playerTwoData.NumClicks.toString();
        }


        //button callback to load all AppData
        private function onLoadAppData()
        {
            _playerOneData.load();
            _playerTwoData.load();
            _clickLabel1.text = _playerOneData.NumClicks.toString();
            _clickLabel2.text = _playerTwoData.NumClicks.toString();
        }


        //button callback to purge all AppData
        private function onPurgeAppData()
        {
            _playerOneData.purge();
            _playerTwoData.purge();
            _clickLabel1.text = _playerOneData.NumClicks.toString();
            _clickLabel2.text = _playerTwoData.NumClicks.toString();
        }
    }
}