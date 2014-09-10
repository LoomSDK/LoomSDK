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
        private var g:Shape;
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
            /*
            q = new Quad(200, 200, 0xBDC5F9); q.x = 10; q.y = 10; stage.addChild(q);
            q = new Quad(200, 200, 0xA8B1F7); q.x = 40; q.y = 40; stage.addChild(q);
            q = new Quad(200, 200, 0x8A98F4); q.x = 80; q.y = 80; stage.addChild(q);
            q = new Quad(200, 200, 0x596CF0); q.x = 120; q.y = 120; stage.addChild(q);
            */
            
            q = new Quad(400, 300, 0xBDC5F9); q.x = 10; q.y = 10; stage.addChild(q);
            
            g = new Shape();
            g.x = 50;
            g.y = 50;
            stage.addChild(g);
            
            //gfx.moveTo(0, 0);
            //gfx.lineTo(50, 0);
            //gfx.lineTo(0, 50);
            //gfx.clear();
            //gfx.moveTo(0, 0);
            //gfx.lineTo(50, -50);
            //gfx.cubicCurveTo(0, 0, 20, 20, 50, 50);
            /*
            gfx.moveTo(10, 40);
            gfx.lineTo(40, 40);
            gfx.drawCircle(40, 40, 20);
            gfx.lineTo(40, 80);
            
            gfx.lineStyle(10, 0xF1AD0E, 1);
            gfx.moveTo(50, 50);
            gfx.lineTo(100, 50);
            gfx.lineStyle(20, 0x0B0BF4, 0.5);
            gfx.lineTo(100, 100);
            gfx.lineTo(50, 100);
            */
            
            
            var x = 0, y = 0;
            
            // Fill
            g.beginFill(0x3EA80B, 1);
            g.drawRect(110, y, 100, 30);
            g.endFill();
            y += 40;
            
            g.lineStyle(1, 0x000000, 1);
            
            // Implicit moveTo(0,0)
            g.lineTo(100, 0);
            
            // Explicit moveTo
            g.moveTo(0, 0);
            g.lineTo(0, 100);
            
            // Shape rendering
            g.drawCircle(50, 50, 50);
            g.drawEllipse(50, 50, 20, 50);
            g.drawRect(25, 25, 50, 50);
            g.drawRoundRect(35, 35, 30, 30, 10, 10);
            
            // Mixed line and shape rendering
            g.moveTo(100, 0);
            g.lineTo(100, 100);
            g.drawCircle(50, 50, 40);
            
            return;
            g.lineTo(0, 100);
            
            // Line styles
            g.lineStyle(1, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(8, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(8, 0x0000FF, 0.5); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(8, 0x0000FF, 0.1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            
            // Continuous line style switching
            g.lineStyle(8, 0x0000FF, 0.1);
            x = 110;
            g.moveTo(x, y); x += 10;
            g.lineStyle(8, 0x000000, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0xFF0000, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0xFF7F00, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0xFFFF00, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0x00FF00, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0x0000FF, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0x4B0082, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0x8B00FF, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0x8F8F8F, 1); g.lineTo(x, y); x += 10;
            g.lineStyle(8, 0xFFFFFF, 1); g.lineTo(x, y); x += 10;
            
            //*/
            
            //stage.addEventListener(TouchEvent.TOUCH, onTouch);
            
        }
        
        private function onTouch(e:TouchEvent):void 
        {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;
            g.lineTo(t.globalX, t.globalY);
        }
        
        override public function onFrame() 
        {
            /*
            var t = Loom2D.juggler.elapsedTime;
            gfx.clear();
            gfx.moveTo(0, 0);
            gfx.cubicCurveTo(Math.cos(t*2.5)*100, Math.sin(t*2.1)*100, Math.cos(t*1.51)*100, Math.sin(t*1.11)*100, 0, 100);
            gfx.drawCircle(20, 20, 10);
            gfx.drawEllipse(50, 20, 10, 20);
            gfx.drawRect(80, 0, 40, 60);
            gfx.drawRoundRect(140, 0, 40, 60, 10, 10);
            return super.onFrame();
            */
        }
        
    }
}