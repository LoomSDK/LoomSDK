package
{
    import loom.platform.Timer;
    import loom.gameframework.LoomGroup;
    import loom.gameframework.TimeManager;
    import loom.gameframework.ITicked;

    import loom.Application;

    import loom2d.events.Event;
    import loom2d.events.ResizeEvent;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;

    private class TickedObject implements ITicked
    {
        var count = 0;
        function onTick():void
        {
            trace("tick", count++);
        }

    }

    /**
     * Show how to listen to activate/deactivate events and display size changes.
     */
    public class ApplicationFocusDemo extends Application 
    {
        public var label:SimpleLabel;

        public var timeManager:TimeManager;
        public var tickedObject = new TickedObject();
        public var timer:Timer;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth; 
            bg.height = stage.stageHeight; 
            stage.addChild(bg);

            label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Waiting...";
            label.x = stage.stageWidth/2 - label.size.x/2;
            label.y = stage.stageHeight - 120;
            stage.addChild(label);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.x = stage.stageWidth/2 - sprite.width/2;
            sprite.y = stage.stageHeight/2 - sprite.height/2;
            stage.addChild(sprite);

            Application.applicationActivated += gainFocus;
            Application.applicationDeactivated += loseFocus;

            // add a ticked object to the time manager, which we will pause on losing focus
            timeManager = LoomGroup.rootGroup.getManager(TimeManager) as TimeManager;
            timeManager.addTickedObject(tickedObject);

            // create a new Timer which will be paused/restarted on losing/gaining focus
            timer = new Timer(10000);
            timer.onComplete = function() { trace("timer fired!"); };
            timer.start();

            stage.addEventListener( Event.RESIZE, function(e:ResizeEvent) { 

                // display the native side as the ResizeEvent stores 
                // our pre-scaled width/height when using scale modes

                var str = "Size: " + stage.nativeStageWidth + "x" + stage.nativeStageHeight;
                label.text = str;
                label.x = stage.stageWidth/2 - label.size.x/2;
                trace(str);

            } );                        

        }

        public function gainFocus():void
        {
            trace("Gained focus!");
            label.text = "Active!";

            // restart timeManager and our timer
            timeManager.start();
            timer.start();
        }

        public function loseFocus():void
        {
            trace("Lost focus!");
            label.text = "Inactive.";

            // pause timeManager and our timer
            timeManager.stop();
            timer.pause();
        }

    }
}