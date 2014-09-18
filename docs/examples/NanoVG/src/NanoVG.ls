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
            
            //q = new Quad(400, 300, 0xBDC5F9); q.x = 10; q.y = 10; stage.addChild(q);
            q = new Quad(460, 300, 0xF3F3F3); q.x = 10; q.y = 10; stage.addChild(q);
            
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
            g.drawRect(110, y, 100, 10);
            g.endFill();
            y += 20;
            
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
            
            g.lineTo(0, 100);
            
            // curveTo
            g.moveTo(0, 50);
            g.cubicCurveTo(1/3*100, 50-50, 2/3*100, 50+50, 100, 50);
            g.cubicCurveTo(2/3*100, 50-50, 1/3*100, 50+50, 0, 50);
            
            // Line styles
            g.lineStyle(0, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(0.1, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(0.2, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(0.5, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(1, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(2, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(3, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(4, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
            g.lineStyle(5, 0x0000FF, 1); g.moveTo(110, y); g.lineTo(210, y); y += 10;
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
            y += 10;
            
            // Fill with linestyle
            g.lineStyle(4, 0xFFFF00, 1);
            g.beginFill(0xF40B74, 1);
            g.drawRect(110, y, 100, 10);
            g.endFill();
            y += 16;
            
            // Non-stroked fill after linestyle
            g.lineStyle(NaN, 0, 0);
            g.beginFill(0xC90A60, 1);
            g.drawRect(110, y, 100, 10);
            g.endFill();
            y += 12;
            
            // Implicit endFill
            g.beginFill(0x940746, 1);
            g.drawRect(110, y, 100, 10);
            y += 12;
            
            
            /*
            
            g.clear();
            g.lineStyle(1, 0xFFFFFF, 0.01);
            var n = 5000;
            var w = 460-g.x*2;
            var h = 300-g.y*2;
            
            var t = 0;
            
            var cx = w / 2;
            var cy = h / 2;
            var r = 130;
            
            g.moveTo(cx, cy);
            
            for (var it:int = 0; it < 10; it++) {
                for (var i:int = 0; i < n; i++) {
                    var a:Number = t + i / (n-1) * Math.TWOPI * (1000 + Math.cos(t*0.000001)*10);
                    var b:Number = t + i / (n-1) * Math.TWOPI * (1000 + Math.sin(t*0.00001)*10);
                    //var l:Number = Math.sqrt(a*a + b*b);
                    //a /= l;
                    //b /= l;
                    //g.lineTo(0+i/(n-1)*w, h/2+Math.sin(a)*h/2);
                    g.lineTo(cx+Math.cos(a)*r, cy+Math.sin(b)*r);
                }
                t += 1/60;
            }
            
            //*/
            
            /*
            g.clear();
            g.lineStyle(1, 0xFFFFFF, 0.1);
            var n = 4000;
            var w = 460-g.x*2;
            var h = 300-g.y*2;
            
            var t = Loom2D.juggler.elapsedTime;
            
            var cx = w / 2;
            var cy = h / 2;
            
            g.moveTo(cx, cy);
            for (var i:int = 0; i < n; i++) {
                var r = i/(n-1)*120;
                var a = (i/(n-1)*30+t*0.02) * Math.TWOPI;
                g.lineTo(cx+Math.cos(a)*r, cy+Math.sin(a)*r);
            }
            */
            
            //stage.addEventListener(TouchEvent.TOUCH, onTouch);
            
        }
        
        private function onTouch(e:TouchEvent):void 
        {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;
            g.lineTo(t.globalX, t.globalY);
        }
        
        private function hsvToRgb(h:Number, s:Number, v:Number):uint {
			var hi:int = int(h/60)%60;
			var f:Number = h/60-Math.floor(h/60);
			var p:Number = v*(1-s);
			var q:Number = v*(1-f*s);
			var t:Number = v*(1-(1-f)*s);
			switch (hi) {
				case 0: return ((int(v*255) << 16) | (int(t*255) << 8) | int(p*255));
				case 1: return ((int(q*255) << 16) | (int(v*255) << 8) | int(p*255));
				case 2: return ((int(p*255) << 16) | (int(v*255) << 8) | int(t*255));
				case 3: return ((int(p*255) << 16) | (int(q*255) << 8) | int(v*255));
				case 4: return ((int(t*255) << 16) | (int(p*255) << 8) | int(v*255));
				case 5: return ((int(v*255) << 16) | (int(p*255) << 8) | int(q*255));
			}
			return 0;
		}
        
        override public function onFrame() 
        {
            /*
            var t = Loom2D.juggler.elapsedTime;
            g.clear();
            g.lineStyle(1, 0xBD55F4, 1);
            g.moveTo(0, 0);
            g.moveTo(0, 0);
            g.moveTo(0, 0);
            g.moveTo(0, 0);
            g.cubicCurveTo(Math.cos(t*2.5)*100, Math.sin(t*2.1)*100, Math.cos(t*1.51)*100, Math.sin(t*1.11)*100, 0, 100);
            g.drawCircle(20, 20, 10);
            g.drawEllipse(50, 20, 10, 20);
            g.drawRect(80, 0, 40, 60);
            g.drawRoundRect(140, 0, 40, 60, 10, 10);
            return super.onFrame();
            //*/
            
            /*
            g.clear();
            g.lineStyle(1, 0xFFFFFF, 0.1);
            var n = 5000;
            var w = 460-g.x*2;
            var h = 300-g.y*2;
            
            var t = Loom2D.juggler.elapsedTime;
            
            var cx = w / 2;
            var cy = h / 2;
            var r = 130;
            
            g.moveTo(cx, cy);
            for (var i:int = 0; i < n; i++) {
                var a:Number = t + i / (n-1) * Math.TWOPI * (1000 + Math.cos(t*0.000001)*10);
                var b:Number = t + i / (n-1) * Math.TWOPI * (1000 + Math.sin(t*0.00001)*10);
                //var l:Number = Math.sqrt(a*a + b*b);
                //a /= l;
                //b /= l;
                //g.lineTo(0+i/(n-1)*w, h/2+Math.sin(a)*h/2);
                g.lineTo(cx+Math.cos(a)*r, cy+Math.sin(b)*r);
            }
            //*/
            
            /*
            g.clear();
            g.lineStyle(1, 0xFFFFFF, 0.1);
            var n = 200;
            var w = 460-g.x*2;
            var h = 300-g.y*2;
            
            var t = Loom2D.juggler.elapsedTime;
            
            var cx = w / 2;
            var cy = h / 2;
            
            //var a = Math.floor((0.25+0.25*Math.sin(t*1.1+Math.PI/2))*n);
            //var b = Math.floor((0.75+0.25*Math.sin(t*1.3-Math.PI/2))*n);
            
            var a = 0;
            var b = n;
            
            g.moveTo(cx, cy);
            for (var i:int = a; i < b; i++) {
                var r = i/(n-1)*500;
                var ang = (i/(n-1)*50+t*0.5) * Math.TWOPI;
                g.lineStyle(3 + 1*Math.sin(1000*i/(n-1)*Math.TWOPI + t*50), hsvToRgb((i/n*360*3 + t*200)%360, 1, 1), 1);
                g.lineTo(cx+Math.cos(ang)*r, cy+Math.sin(ang)*r);
            }
            //*/
        }
        
    }
}