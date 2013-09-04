package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    


    class Memory
    {
        var someValue = 1;

        public function myfunction(...args)
        {
            args[0] = null;

            var stype:Type = Type.getTypeByName("Memory");

            stype.setFieldOrPropertyValueByName(this, "someValue", 100);

            if (someValue != 100)
                trace("Error!");


        }
    }

    public class TestMemory extends Application
    {

        var memory:Vector.<Memory> = [];

        override public function run():void
        {

            //GC.collect(GC.STOP);

            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            stage.addChild(sprite);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Hello Loom!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {
                    trace("Allocating");
                    for (var i = 0; i < 100000;i++)
                    {
                        memory[i] = new Memory;
                        memory[i].myfunction();
                    }

                    trace("Deallocating");
                    for (i = 0; i < 100000;i++)
                    {
                        memory[i] = null;
                    }
                }
            } );            


        }
    }
}