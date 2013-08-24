package poly.views
{
    import loom2d.display.Stage;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.events.Event;
    import loom2d.events.TouchEvent;
    import poly.ui.View;
    import poly.ui.ViewCallback;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;
    import loom2d.ui.TextureAtlasSprite;

    import loom.lml.LML;
    import loom.lml.LMLDocument;

    import loom.animation.LoomTween;
    import loom.animation.LoomEaseType;

    /**
     * View implementing after-game score screen.
     */
    class ScoreView extends View
    {
        [Bind]
        public var bg:TextureAtlasSprite;

        [Bind]
        public var scoreLabel:SimpleLabel;

        [Bind]
        public var backToMenu:SimpleButton;

        [Bind]
        public var restartButton:SimpleButton;

        // delegates
        public var onBackToMenu:ViewCallback;
        public var onRestart:ViewCallback;

        public function ScoreView()
        {
            var doc = LML.bind("assets/score.lml", this);
            doc.onLMLCreated += onLMLCreated;
            doc.apply();
            
            name = "ScoreView";
        }

        public function enter(parent:DisplayObjectContainer):void
        {
            super.enter(parent);

            var stage = parent.stage;

            bg.alpha = 0;
            bg.x = -128;
            bg.y = -128;
            bg.width = parent.stage.stageWidth + 256;            
            bg.height = parent.stage.stageHeight + 256;            
            LoomTween.to(bg, 0.2, {"alpha": 0.5});            

            // center score on stage
            scoreLabel.x = stage.stageWidth/2 - scoreLabel.size.x/2;
            scoreLabel.y = -100;
            LoomTween.to(scoreLabel, 0.3, {"y": 100, "ease": LoomEaseType.EASE_OUT});

            backToMenu.y = 1000;
            LoomTween.to(backToMenu, 0.3, {"y": 480, "ease": LoomEaseType.EASE_OUT});

            restartButton.x = -200;
            LoomTween.to(restartButton, 0.3, {"x": 400, "ease": LoomEaseType.EASE_OUT});
        }

        public function exit():void
        {   
            LoomTween.to(bg, 0.4, {"alpha": 0});
            LoomTween.to(scoreLabel, 0.3, {"y": -100, "ease": LoomEaseType.EASE_IN});
            LoomTween.to(backToMenu, 0.3, {"y": -150, "ease": LoomEaseType.EASE_IN});
            LoomTween.to(restartButton, 0.3, {"x": -200, "ease": LoomEaseType.EASE_IN}).onComplete += onExitComplete;
        }

        public function setScore(score:Number, total:Number):void
        {
            scoreLabel.text = (total - score).toString() + " out of " + total + " polys";
        }

        public function onLMLCreated():void
        {
            
            backToMenu.onClick += onBackToMenuClick;
            restartButton.onClick += onRestartButtonClick;

            // Block clicks on background.
            bg.name = "bg";
            bg.touchable = true;
            bg.addEventListener(TouchEvent.TOUCH, 
                function(e:Event):void 
                {
                    trace("Eating curtain click."); 
                    e.stopPropagation(); 
                } );
        }

        public function onBackToMenuClick():void
        {
            onBackToMenu();
        }
        
        public function onRestartButtonClick():void
        {
            onRestart();
        }

        public function onExitComplete(tween:LoomTween):void
        {
            super.exit();
        }
    }
}