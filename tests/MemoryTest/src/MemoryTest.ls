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

    /*
     * Tests GC performance 
     */
    public class TestMemory extends Application
    {

        var memory:Vector.<Memory> = [];

        var sprite:Image;
        var label:SimpleLabel;
        var dir = false;

        var allocationCount = 0;
        var allocating = false;
        var reportTimer = 120;

        override public function onTick():void
        {

            var i = 0;

            if (allocating && allocationCount < 100000)
            {

                for (i = 0; i < 512; i++)
                {
                    memory[allocationCount] = new Memory;
                    memory[allocationCount].myfunction();

                    allocationCount++;

                    if (allocationCount == 100000)
                    {
                        break;
                    }

                }

                trace("Allocated: " + allocationCount);

            }

            if (sprite)
            {
                if (!dir && sprite.x < 0)
                {
                    dir = true;                    
                }
                else if (dir && sprite.x > stage.stageWidth)
                {
                    dir = false;
                }

                sprite.x = dir ? sprite.x + 1 : sprite.x - 1;
            }

            reportTimer--;
            if (reportTimer < 0)
            {
                reportTimer = 120;
                trace("VM usage: " + GC.getAllocatedMemory() + "MB");
            }
        }

        override public function run():void
        {

            setMemoryWarningLevel(128);

            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            stage.addChild(sprite);

            label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Hello Loom!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {
                    if (!allocating && allocationCount <= 0)
                    {
                        allocating = true;
                        allocationCount = 0;
                        label.text = "Allocating";
                    }
                    else if (allocationCount > 0)
                    {
                        allocating = false;
                        
                        for (var i = 0; i < allocationCount; i++)
                            memory[i] = null;

                        allocationCount = 0;

                        label.text = "Deallocated";   

                    }
                    
                }
            } );            


        }
    }
}