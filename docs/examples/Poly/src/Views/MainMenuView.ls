package poly.views
{
    import poly.ui.View;
    import poly.ui.ViewCallback;

    import loom.lml.LML;
    import loom.lml.LMLDocument;

    import loom2d.Loom2D;
    import loom2d.animation.Transitions;

    import loom2d.display.DisplayObjectContainer;

    import loom2d.ui.SimpleButton;
    import loom2d.ui.TextureAtlasSprite;

    /**
     * Startup view; provides main menu.
     */
    class MainMenuView extends View
    {
        [Bind]
        public var playButton:SimpleButton;

        [Bind]
        public var helpButton:TextureAtlasSprite;

        [Bind]
        public var aboutButton:TextureAtlasSprite;

        [Bind]
        public var logo:TextureAtlasSprite;

        public var onPlayClick:ViewCallback;

        public function MainMenuView()
        {
            super();

            var doc = LML.bind("assets/main.lml", this);
            doc.onLMLCreated += onLMLCreated;
            doc.apply();
        }

        public function enter(owner:DisplayObjectContainer):void
        {
            // add to the screen
            super.enter(owner);

            // do some tweens based on their existing positions
            playButton.x = -500;
            Loom2D.juggler.tween(playButton, 0.4, {"x": playButtonX, "transition": Transitions.EASE_OUT_BACK});

            helpButton.x = -500;
            Loom2D.juggler.tween(helpButton, 0.4, {"x": helpButtonX, "transition": Transitions.EASE_OUT_BACK, "delay": 0.1});

            aboutButton.x = -500;
            Loom2D.juggler.tween(aboutButton, 0.4, {"x": aboutButtonX, "transition": Transitions.EASE_OUT_BACK, "delay": 0.2});

            logo.y = 850;
            Loom2D.juggler.tween(logo, 0.4, {"y": logoY, "transition": Transitions.EASE_OUT_BACK, "delay": 0.2});
            
        }

        public function exit():void
        {
            // Tween out
            Loom2D.juggler.tween(playButton, 0.3, {"x": -500, "transition": Transitions.EASE_IN_BACK});
            Loom2D.juggler.tween(helpButton, 0.3, {"x": -500, "transition": Transitions.EASE_IN_BACK, "delay": 0.1});
            Loom2D.juggler.tween(aboutButton, 0.3, {"x": -500, "transition": Transitions.EASE_IN_BACK, "delay": 0.2});
            Loom2D.juggler.tween(logo, 0.3, {"y": 850, "transition": Transitions.EASE_IN_BACK, "delay": 0.2, "onComplete": onExitComplete});
        }

        protected function onExitComplete():void
        {
            // really exit
            super.exit();
        }

        protected function playClick()
        {
            onPlayClick();
        }

        // stores the original location of the elements 
        private var playButtonX:int;
        private var helpButtonX:int;
        private var aboutButtonX:int;
        private var logoY:int;

        protected function onLMLCreated()
        {
            if (playButton)
            {
                playButton.onClick += playClick;
                playButtonX = playButton.x;
            }

            if (helpButton)
                helpButtonX = helpButton.x;

            if (aboutButton)
                aboutButtonX = aboutButton.x;

            if (logo)
                logoY = logo.y;
        }
    }
}