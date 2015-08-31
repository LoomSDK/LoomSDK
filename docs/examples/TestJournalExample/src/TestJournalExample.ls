package
{
    import loom2d.display.Shape;
    import testjournal.TestJournal;
    
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.platform.Platform;
    
    import loom.graphics.Graphics;

    public class TestJ extends Application
    {
        private const APP_ID:String = "testApp";
        
        var bg:Image;
        var sprite:Image;
        var shape:Shape;
        var label:SimpleLabel;
        
        private var lastEpoch:Number = 0;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            bg.center();
            stage.addChild(bg);
            
            shape = new Shape();
            shape.x = stage.stageWidth;
            shape.y = stage.stageHeight;
            shape.graphics.beginFill(0xFF0000);
            shape.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            shape.center();
            stage.addChild(shape);
            
            sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            stage.addChild(sprite);
            
            label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = Platform.getEpochTime().toString();
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);
            
            // Initialize the Test Journal!
            TestJournal.init(APP_ID, "testing");
        }
        
        override public function onTick():void
        {
            // Spin and move stuff, and display a timestamp
            sprite.rotation += 0.1;
            bg.rotation -= 0.07;
            shape.rotation += 0.06;
            
            label.text = Platform.getEpochTime().toString();
            
            // Randomly generate log
            if (lastEpoch != Platform.getEpochTime() && Random.randRangeInt(1, 10) < 6)
                TestJournal.log(Platform.getEpochTime());
            
            // Randomly call takeScreen
            if (lastEpoch != Platform.getEpochTime() && Random.randRangeInt(1, 10) <= 1)
            {
                TestJournal.log("Taking Manual Screenshot");
                TestJournal.takeScreen();
            }
                
            lastEpoch = Platform.getEpochTime();
        }
    }
}