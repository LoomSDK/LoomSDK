package
{
    import game.GameConfig;
    import loom.Application;
    import loom.gameframework.TimeManager;
    import loom.sound.Listener;
    import loom2d.display.Sprite;
    import loom2d.display.StageScaleMode;
    import loom2d.events.Event;
    import loom2d.textures.TextureSmoothing;
    import loom2d.ui.TextureAtlasManager;
    import ui.Theme;
    import ui.views.ConfigView;
    import ui.views.game.AdView;
    import ui.views.game.CreditsView;
    import ui.views.game.DifficultyView;
    import ui.views.game.EndView;
    import ui.views.game.GameView;
    import ui.views.game.IntroView;
    import ui.views.game.ModeView;
    import ui.views.View;
    
    /**
     * Main application class containing all the views and transitions between them.
     * The game involves a full gameplay loop from the intro screen (IntroView)
     * to picking game modes (ModeView, DifficultyView),
     * the actual game itself (GameView),
     * the game over (EndView) and ad (AdView) screens.
     */
    public class KrushBlokk extends Application
    {
        public var config:GameConfig = new GameConfig();
        
        private var intro = new IntroView();
        private var credits = new CreditsView();
        private var mode = new ModeView();
        private var difficulty = new DifficultyView();
        private var game = new GameView();
        private var end = new EndView();
        private var ad = new AdView();
        
        private var display:Sprite = new Sprite();
        private var currentView:View;
        
        private var contentWidth = 450;
        private var contentHeight = 580;
        private var pixelScale = 4;
        
        
        // Gets injected automatically before run() is called
        [Inject] private var timeManager:TimeManager;
        
        
        override public function run()
        {
            // No scaling for stage for custom scaling logic in resize()
            stage.scaleMode = StageScaleMode.NONE;
            
            // Don't interpolate pixels - rough pixel art look
            TextureSmoothing.defaultSmoothing = TextureSmoothing.NONE;
            
            SplashLoader.init(stage, timeManager, load);
        }
        
        private function load() 
        {
            // Load the sprite atlas containing textures
            TextureAtlasManager.register("tiles", "assets/tiles/sprites.xml");
            
            // Instantiates the custom theme contained in the Theme class,
            // setting up the fonts and custom label, button and checkbox styles.
            new Theme();
            
            config.reset();
            
            // View initialization
            var views:Vector.<View> = new <View>[intro, credits, mode, difficulty, game, end, ad];
            for each (var view:View in views) {
                if (view is ConfigView) (view as ConfigView).config = config;
                view.init();
            }
            
            // Transitions between views
            intro.onStart += function() { switchView(mode); };
            intro.onCredits += function() { switchView(credits); };
            intro.onBack += function() { Process.exit(0); };
            credits.onBack += function() { switchView(intro); };
            mode.onPick += function() {
                if (config.duration == -1) {
                    switchView(game);
                } else {
                    switchView(difficulty);
                }
            };
            mode.onDemo += function() {
                switchView(game);
                game.demo();
            };
            mode.onBack += function() { switchView(intro); };
            difficulty.onPick += function() {
                switchView(game);
            };
            difficulty.onBack += function() { switchView(mode); };
            game.onQuit += function() {
                if (game.demoMode) {
                    switchView(mode);
                    return;
                }
                end.gameScore = game.score;
                end.quitManually = true;
                switchView(end);
            };
            game.onTimeout += function() {
                end.gameScore = game.score;
                end.quitManually = false;
                switchView(end);
            };
            end.onContinue += function() {
                switchView(ad);
            };
            end.onBack += function() {
                switchView(ad);
            };
            ad.onContinue += function() {
                switchView(intro);
            };
            ;
            
            // Handle app pausing
            applicationActivated += onActivated;
            applicationDeactivated += onDeactivated;
            
            stage.addChild(display);
            stage.addEventListener(Event.RESIZE, resize);
            
            // View on startup
            // You can uncomment a different view to start from that one.
            // Note that this can lead to uninitialized state (i.e. for game config),
            // so it's good to have sensible implicit defaults of values.
            // Even better, Loom allows for state persistence,
            // but that is out of scope for this example (see PersistenceExample).
            switchView(intro);
            //switchView(credits);
            //switchView(mode);
            //switchView(difficulty);
            //switchView(game);
            //switchView(end);
            //switchView(ad);
        }
        
        /**
         * Mute sounds when the app is paused
         */
        private function onDeactivated():void 
        {
            Listener.setGain(0);
            game.deactivate();
        }
        
        /**
         * Unmute sounds when the app is resumed
         */
        private function onActivated():void 
        {
            Listener.setGain(1);
            game.activate();
        }
        
        /**
         * Responsive layout! Scale display so it's contained within stage
         */
        private function resize(e:Event = null)
        {
            var scale:Number;
            if (stage.stageWidth/stage.stageHeight < contentWidth/contentHeight) {
                scale = stage.stageWidth/contentWidth;
            } else {
                scale = stage.stageHeight/contentHeight;
            }
            // Scale to whole multiples, unless it's too small
            if (stage.stageWidth >= contentWidth) {
                display.scale = Math.max(1, Math.floor(pixelScale*scale));
            } else {
                display.scale = pixelScale * scale;
            }
            var w = stage.stageWidth/display.scale;
            var h = stage.stageHeight/display.scale;
            currentView.resize(w, h);
        }
        
        /**
         * State machine transition for views
         */
        private function switchView(newView:View)
        {
            if (currentView) currentView.exit();
            currentView = newView;
            currentView.enter(display);
            resize();
        }
        
        /**
         * Pass on onTick to the current view
         */
        override public function onTick()
        {
            if (currentView) currentView.tick();
            return super.onTick();
        }
        
        /**
         * Pass on onFrame to the current view
         */
        override public function onFrame()
        {
            if (currentView) currentView.render();
            return super.onFrame();
        }
        
    }
}