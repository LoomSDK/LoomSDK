package
{

    import loom.Application;    
    import loom2d.Loom2D;
    import loom2d.animation.Transitions;
    import loom2d.math.Point;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    public class TweenExample extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/fonts/Curse-hd.fnt", 320, 128);
            label.text = "Hello Tween!";

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = 240;
            sprite.y = 120;
            stage.addChild(sprite);

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {
                    var point:Point;    
                    point = touch.getLocation(stage);
                    Loom2D.juggler.tween(sprite, 1, {"x": point.x, "y": point.y, "transition": Transitions.EASE_OUT_ELASTIC});    
                }
            } );            


        }
    }
}