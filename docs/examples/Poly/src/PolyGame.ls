package
{
    import loom.Application;
    
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Sprite;
    import loom2d.display.StageScaleMode;
    
    import loom2d.ui.TextureAtlasManager;
    import loom2d.ui.TextureAtlasSprite;

    import poly.views.MainMenuView;
    import poly.views.PauseView;
    import poly.views.GameOverlayView;
    import poly.views.GamePlayView;
    import poly.views.ScoreView;    
    
    import loom.sound.SimpleAudioEngine;

    /**
     * PolyGame manages the overall logic for Poly.
     *
     * It is responsible for instantiating and sequencing UI; UI eventually
     * triggers the game simulation.
     */
    class PolyGame extends Application
    {
        public var uiLayer:DisplayObjectContainer;
        
        public var mainMenu:MainMenuView;
        public var pauseMenu:PauseView;
        public var gameView:GamePlayView;
        public var overlay:GameOverlayView;
        public var scoreView:ScoreView;
        
        override public function run():void 
        {
            // register our UI Atlas
            TextureAtlasManager.register("PolyUI", "assets/PolyUI.xml");
            TextureAtlasManager.register("polySprites", "assets/data/polySprites.xml");

            // Play Background music
            //SimpleAudioEngine.sharedEngine().playBackgroundMusic("assets/sound/bg_music.mp3");

            // game layer
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // add the background
            var bg:TextureAtlasSprite = new TextureAtlasSprite();
            bg.name = "background";
            bg.atlasName = "PolyUI";
            bg.textureName = "bg.png";
            bg.x = -100;
            bg.y = -100;
            bg.width = 960 + 200;
            bg.height = 640 + 200;
            bg.touchable = false;
            stage.addChild(bg);
            
            var playfield = new Sprite();
            stage.addChild(playfield);
            stage.touchable = true;
            group.registerManager(playfield, null, "playfield");

            uiLayer = new Sprite();
            stage.addChild(uiLayer);
            group.registerManager(uiLayer, null, "overlay");
            
            // Create our views
            mainMenu = new MainMenuView();
            mainMenu.onPlayClick += onPlayGame;

            pauseMenu = new PauseView();
            pauseMenu.onBackToMenu += onBackToMenu;
            pauseMenu.onResume += onResume;
            pauseMenu.onRestart += onRestart;

            gameView = new GamePlayView();
            gameView.group = group;
            
            overlay = new GameOverlayView();
            overlay.onPause += onPauseGame;

            scoreView = new ScoreView();
            scoreView.onBackToMenu += onBackToMenu;
            scoreView.onRestart += onRestart;

            // show the main menu
            mainMenu.enter(uiLayer);
        }

        protected function onBackToMenu()
        {
            if (pauseMenu.parent) 
            {
                pauseMenu.onExit += onPauseExit;
                pauseMenu.exit();
            }

            if (scoreView.parent) 
            {
                scoreView.exit();
            }

            overlay.exit();
            gameView.exit();
        }

        protected function onResume()
        {
            gameView.level.pause(false);
            pauseMenu.exit();
        }

        protected function onRestart()
        {
            scoreView.onExit -= onScoreExit;
            gameView.exit();
            pauseMenu.exit();
            scoreView.exit();
            gameView.enter(stage);
            gameView.level.onFinished += onGameFinished;
        }

        protected function onPlayGame()
        {
            mainMenu.exit();
            mainMenu.onExit += onMenuExit;
        }

        protected function onPauseGame()
        {
            gameView.level.pause(true);

            if(!pauseMenu.parent)
                pauseMenu.enter(uiLayer);
        }

        protected function onMenuExit()
        {
            gameView.enter(stage);
            gameView.level.onFinished += onGameFinished;
            overlay.enter(uiLayer);
            mainMenu.onExit -= onMenuExit;
        }

        protected function onPauseExit()
        {
            pauseMenu.onExit -= onPauseExit;
            mainMenu.enter(uiLayer);
        }

        protected function onScoreExit()
        {
            scoreView.onExit -= onScoreExit;
            mainMenu.enter(uiLayer);
        }

        protected function onGameFinished(score:Number, total:Number)
        {
            scoreView.setScore(score, total);
            scoreView.enter(uiLayer);
            scoreView.onExit += onScoreExit;
            
        }
    }
}