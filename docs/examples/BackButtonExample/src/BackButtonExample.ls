package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;

    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.KeyboardEvent;
    import loom2d.events.TouchPhase;        

    import loom.animation.LoomTween;
    import loom.animation.LoomEaseType;

    /**
     *  Simple example to showcase the handling of back-button presses on Android
     */
    public class BackButtonExample extends Application
    {
        protected var sprite:Image;
        protected var label:SimpleLabel;
        protected var backLabel:SimpleLabel;

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth; 
            bg.height = stage.stageHeight; 
            stage.addChild(bg);

            label = new SimpleLabel("assets/Curse-hd.fnt", 240, 128);            
            label.text = "Click the Poly!";
            label.x = stage.stageWidth/2 - 120;
            label.y = 180;
            stage.addChild(label);

            backLabel = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            backLabel.text = "Now click the back button!";
            backLabel.x = 720;
            backLabel.y = 180;
            stage.addChild(backLabel);
            
            sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = 240;
            sprite.y = 120;
            stage.addChild(sprite);

            sprite.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(sprite, TouchPhase.BEGAN);
                if (touch)
                    goToNextScreen();
            } );            

            // listen for when we click the back button
            this.stage.addEventListener(KeyboardEvent.BACK_PRESSED, goToPreviousScreen);
        }

        protected function goToNextScreen()
        {
            LoomTween.to(sprite, 0.5, {"x": -300, "ease": LoomEaseType.EASE_IN_BACK});
            LoomTween.to(label, 0.5, {"x": -300, "ease": LoomEaseType.EASE_IN_BACK});
            LoomTween.to(backLabel, 0.5, {"x": stage.stageWidth/2 - 160, "ease": LoomEaseType.EASE_IN_BACK});
        }

        protected function goToPreviousScreen(event:KeyboardEvent)
        {
            LoomTween.to(sprite, 0.5, {"x": 240, "ease": LoomEaseType.EASE_OUT_BACK});
            LoomTween.to(label, 0.5, {"x": stage.stageWidth/2 - 120, "ease": LoomEaseType.EASE_OUT_BACK});
            LoomTween.to(backLabel, 0.5, {"x": 720, "ease": LoomEaseType.EASE_OUT_BACK});
        }
    }
}