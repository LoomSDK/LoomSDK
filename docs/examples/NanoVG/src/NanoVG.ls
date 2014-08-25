package
{
    import loom.Application;
    import loom2d.display.Quad;
    import loom2d.display.Shape;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
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
            
            q = new Quad(200, 200, 0x8A98F4); q.x = 80; q.y = 80; stage.addChild(q);
            
            gfx = new Shape();
            gfx.x = 100;
            gfx.y = 50;
            gfx.moveTo(0, 0);
            gfx.lineTo(50, 0);
            gfx.lineTo(0, 50);
            gfx.clear();
            gfx.moveTo(0, 0);
            gfx.lineTo(50, -50);
            gfx.cubicCurveTo(0, 0, 20, 20, 50, 50);
            stage.addChild(gfx);
            
            
            q = new Quad(200, 200, 0x596CF0); q.x = 120; q.y = 120; stage.addChild(q);
            //*/
            
            stage.addEventListener(TouchEvent.TOUCH, onTouch);
            
        }
        
        private function onTouch(e:TouchEvent):void 
        {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;
            gfx.lineTo(t.globalX, t.globalY);
        }
        
        override public function onFrame() 
        {
            var t = Loom2D.juggler.elapsedTime;
            gfx.clear();
            gfx.moveTo(0, 0);
            gfx.cubicCurveTo(Math.cos(t*2.5)*100, Math.sin(t*2.1)*100, Math.cos(t*1.51)*100, Math.sin(t*1.11)*100, 0, 100);
            gfx.drawCircle(20, 20, 10);
            gfx.drawEllipse(50, 20, 10, 20);
            gfx.drawRect(80, 0, 40, 60);
            gfx.drawRoundRect(140, 0, 40, 60, 10, 10);
            return super.onFrame();
        }
        
    }
}