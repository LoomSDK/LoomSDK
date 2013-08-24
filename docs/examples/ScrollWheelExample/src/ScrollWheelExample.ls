package
{

    import loom.Application;    
    import loom2d.events.ScrollWheelEvent;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.math.Point;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    public class ScrollWheelExample extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Hello Scroll Wheel!";

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = 240;
            sprite.y = 120;
            stage.addChild(sprite);

            stage.addEventListener( ScrollWheelEvent.SCROLLWHEEL, function(e:ScrollWheelEvent) { 

                label.y += e.delta*5;
                sprite.y += e.delta*5;

            } );            


        }
    }
}    
