package
{
    import loom.platform.UserDefault;
    
    import loom.Application;    
    import loom.animation.LoomTween;
    import loom.animation.LoomEaseType;
    import loom2d.math.Point;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    /**
     *  Simple example demostrating saving persistent data across app sessions.
     */
    public class PersistenceExample extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var userDefaults = UserDefault.sharedUserDefault();

            var label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Tap to save!";

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = userDefaults.getFloatForKey("polyX", 240);
            sprite.y = userDefaults.getFloatForKey("polyY", 120);
            stage.addChild(sprite);

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {   
                    var point:Point;
                    point = touch.getLocation(stage);
                    LoomTween.to(sprite, 1, {"x": point.x, "y": point.y, "ease":LoomEaseType.EASE_OUT_ELASTIC});
                    label.text = "Saved!";
                    trace("Saving Position (x: ", point.x, " y:", point.y, ")");
                    userDefaults.setFloatForKey("polyX", point.x);
                    userDefaults.setFloatForKey("polyY", point.y);
                }
            } );            
        }
    }
}