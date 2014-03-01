package poly.views
{
    import loom2d.events.TouchEvent;
    import loom2d.events.Event;
    import poly.ui.View;
    import poly.ui.ViewCallback;
    import loom2d.ui.SimpleButton;
    import loom2d.ui.TextureAtlasSprite;

    import loom.lml.LML;
    import loom.lml.LMLDocument;

    import loom2d.Loom2D;
    import loom2d.animation.Transitions;

    import loom2d.display.DisplayObjectContainer;

    /**
     * View implementing pause menu.
     */
    class PauseView extends View
    {
        [Bind]
        public var bg:TextureAtlasSprite;

        [Bind]
        public var pausedText:TextureAtlasSprite;

        [Bind]
        public var backToMenu:SimpleButton;

        [Bind]
        public var restartButton:SimpleButton;

        [Bind]
        public var resumeButton:SimpleButton;

        // delegates
        public var onBackToMenu:ViewCallback;
        public var onRestart:ViewCallback;
        public var onResume:ViewCallback;
        public var exiting:Boolean;

        public function PauseView()
        {
            super();

            var doc = LML.bind("assets/pause.lml", this);
            doc.onLMLCreated += onLMLCreated;
            doc.apply();
        }

        public function enter(owner:DisplayObjectContainer):void
        {
            trace("enter pause score");

            super.enter(owner);

            bg.x = -128;
            bg.y = -128;
            bg.width = owner.stage.stageWidth + 256;            
            bg.height = owner.stage.stageHeight + 256;            
            
            bg.alpha = 0;
            Loom2D.juggler.tween(bg, 0.2, {"alpha": 0.5});

            pausedText.y = 800;
            Loom2D.juggler.tween(pausedText, 0.2, {"y": 100, "delay": 0.1, "transition": Transitions.EASE_OUT});

            backToMenu.y = -150;
            Loom2D.juggler.tween(backToMenu, 0.2, {"y": 480, "delay": 0.1, "transition": Transitions.EASE_OUT});

            restartButton.x = 1300;
            Loom2D.juggler.tween(restartButton, 0.2, {"x": 520, "delay": 0.1, "transition": Transitions.EASE_OUT});

            resumeButton.x = -300;
            Loom2D.juggler.tween(resumeButton, 0.2, {"x": 280, "delay": 0.1, "transition": Transitions.EASE_OUT});
        }

        public function exit():void
        {
            if(exiting)
                return;

            exiting = true;

            Loom2D.juggler.tween(bg, 0.2, {"alpha": 0});
            Loom2D.juggler.tween(pausedText, 0.2, {"y": 800, "delay": 0.1, "transition": Transitions.EASE_OUT});
            Loom2D.juggler.tween(backToMenu, 0.2, {"y": -150, "delay": 0.1, "transition": Transitions.EASE_OUT});
            Loom2D.juggler.tween(restartButton, 0.2, {"x": 1300, "delay": 0.1, "transition": Transitions.EASE_OUT});
            Loom2D.juggler.tween(resumeButton, 0.2, {"x": -300, "delay": 0.1, "transition": Transitions.EASE_OUT, "onComplete": onExitComplete});
        }

        public function onExitComplete():void
        {
            exiting = false;

            // really exit
            super.exit();
        }

        protected function onBackToMenuClick()
        {
            onBackToMenu();
        }

        protected function onRestartClick()
        {
            onRestart();
        }

        protected function onResumeClick()
        {
            onResume();
        }

        protected function onLMLCreated()
        {
            backToMenu.onClick += onBackToMenuClick;
            restartButton.onClick += onRestartClick;
            resumeButton.onClick += onResumeClick;

            // Block clicks on background.
            bg.touchable = true;
            bg.addEventListener(TouchEvent.TOUCH, 
                function(e:Event):void 
                {
                    trace("Eating curtain click."); 
                    e.stopPropagation(); 
                } );
        }
    }
}