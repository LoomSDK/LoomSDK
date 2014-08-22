package
{
    import loom.Application;
    import loom2d.display.Quad;
    import loom2d.display.Shape;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.Void;

    public class NanoVG extends Application
    {
        private var gfx:Shape;
        override public function run():void
        {
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
            
            var q:Quad;
            //*
            q = new Quad(200, 200, 0xBDC5F9); q.x = 10; q.y = 10; stage.addChild(q);
            q = new Quad(200, 200, 0xA8B1F7); q.x = 40; q.y = 40; stage.addChild(q);
            
            gfx = new Shape();
            gfx.x = 100;
            gfx.y = 70;
            gfx.moveTo(0, 0);
            gfx.lineTo(50, 200);
            stage.addChild(gfx);
            
            q = new Quad(200, 200, 0x8A98F4); q.x = 80; q.y = 80; stage.addChild(q);
            q = new Quad(200, 200, 0x596CF0); q.x = 120; q.y = 120; stage.addChild(q);
            //*/
            
            
            
        }
        
        override public function onFrame() 
        {
            return super.onFrame();
        }
        
    }
}