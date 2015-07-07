package
{
    import loom.Application;
    import loom.platform.LoomKey;
    import loom2d.display.Graphics;
    import loom2d.display.Quad;
    import loom2d.display.Shape;
    import loom2d.display.Stage;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.SVG;
    import loom2d.display.TextAlign;
    import loom2d.display.TextFormat;
    import loom2d.events.Event;
    import loom2d.events.ScrollWheelEvent;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.events.KeyboardEvent;
    import loom2d.Loom2D;
    import loom2d.math.Rectangle;
    import loom2d.text.BitmapFont;
    import loom2d.text.TextField;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.platform.Platform;
    import system.Void;

    public class NanoVG extends Application
    {
        private var g:Graphics;
        private var s:Graphics;
        private var d:Graphics;

        var sg:Shape;
        var sd:Shape;
        var q:Quad;
        var logo:Image;

        private function beginBounds(gfx:Graphics):void
        {
            gfx.clearBounds();
        }

        private function endBounds(gfx:Graphics, s:float):void
        {
            var bounds = gfx.getBounds();
            d.lineStyle(0.5, 0xFF0000);
            d.drawRect(bounds.x * s, bounds.y * s, bounds.width * s, bounds.height * s);
        }

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            //stage.scaleMode = StageScaleMode.NONE;
            stage.color = 0xE1E1E1;

            // This should crash with a nice explanation
            //new Graphics();

            // Background
            q = new Quad(460, 300, 0xF3F3F3); q.x = 10; q.y = 10; stage.addChild(q);

            // Most of the test shapes
            sg = new Shape();
            sg.x = 50;
            sg.y = 50;
            stage.addChild(sg);

            // Scaled shape
            var ss = new Shape();
            ss.x = 50;
            ss.y = 50;
            ss.scale = 10;
            stage.addChild(ss);

            // Bounds
            sd = new Shape();
            sd.x = 50;
            sd.y = 50;
            stage.addChild(sd);

            // Store references to Graphics objects for easier use
            g = sg.graphics;
            s = ss.graphics;
            d = sd.graphics;

            var x = 0, y = 0;
            var b:Rectangle;

            // Fill before clearing
            g.beginFill(0xFF2424, 1);
            g.drawRect(0, y, 500, 500);
            g.endFill();
            g.clear();

            // SVG
            var svg = new SVG();
            svg.loadFile("assets/nano.svg");
            beginBounds(g);
            g.drawSVG(svg, 220, 60, 0.2);
            endBounds(g, sg.scale);

            // SVG Loom Logo
            beginBounds(g);
            g.drawSVG(SVG.fromFile("assets/loom_vector_logo_mod.svg"), 290, 112, 0.45);
            endBounds(g, sg.scale);

            // Hand by Cy21 from Wikimedia Commons
            var svgLines = SVG.fromFile("assets/Hand_left.svg");
            // Draw hands with various line thickness multipliers
            var ln = 6;
            var lv:Vector.<Number> = [0.5, 1, 1.5, 2, 3, 4];
            for (var li = 0; li < ln; li++)
            {
                beginBounds(g);
                g.drawSVG(svgLines, 220, 95+li*5, 0.2, lv[li]);
                endBounds(g, sg.scale);
            }

            //sg.pivotX = 220; sg.pivotY = 30; sg.scale *= 5;
            //return;

            // Fill
            g.beginFill(0x3EA80B, 1);
            beginBounds(g);
            g.drawRect(110, y, 100, 10);
            endBounds(g, sg.scale);
            g.endFill();
            y += 20;

            // Set default line style
            g.lineStyle(1);

            // Implicit moveTo(0,0)
            beginBounds(g);
            g.lineTo(100, 0);
            endBounds(g, sg.scale);

            // Explicit moveTo
            beginBounds(g);
            g.moveTo(0, 0);
            g.lineTo(0, 100);
            endBounds(g, sg.scale);

            // Shape rendering
            beginBounds(g);
            g.drawCircle(50, 50, 50);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawEllipse(50, 50, 50, 20);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawRect(25, 25, 50, 50);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawRoundRect(35, 35, 30, 30, 10, 15);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawRoundRectComplex(50-2.5-5, 50-2.5-3.5, 5, 5, 4, 0, 0, 0);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawRoundRectComplex(50-2.5-5, 50-2.5+3.5, 5, 5, 0, 0, 4, 0);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawRoundRectComplex(50-2.5+5, 50-2.5-3.5, 5, 5, 0, 4, 0, 0);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawRoundRectComplex(50-2.5+5, 50-2.5+3.5, 5, 5, 0, 0, 0, 4);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawArc(25, 25, 23,  1.5*Math.PI, 1.0*Math.PI, 1);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawArc(75, 25, 23, -0.5*Math.PI, 0.0*Math.PI, 2);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawArc(25, 75, 23,  0.5*Math.PI, 1.0*Math.PI, 2);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawArc(75, 75, 23,  0.5*Math.PI, 0.0*Math.PI, 1);
            endBounds(g, sg.scale);

            // arcTo with implicit initial moveTo after shapes

            beginBounds(g);
            g.arcTo(  0,  75, 25, 75, 25);
            endBounds(g, sg.scale);

            g.moveTo(100, 100);
            beginBounds(g);
            g.arcTo(100,  75, 75, 75, 25);
            endBounds(g, sg.scale);

            g.moveTo(100,   0);
            beginBounds(g);
            g.arcTo(100,  25, 75, 25, 25);
            endBounds(g, sg.scale);

            g.moveTo(  0,   0);
            beginBounds(g);
            g.arcTo(  0,  25, 25, 25, 25);
            endBounds(g, sg.scale);

            TextFormat.load("sans", "assets/SourceSansPro-Regular.ttf");
            // Simple text with default format
            beginBounds(g);
            g.drawTextLine(220, 0, "hello");
            endBounds(g, sg.scale);

            // Custom text format
            var format = new TextFormat();
            format.color = 0xA60000;
            format.size = 30;
            g.textFormat(format);

            beginBounds(g);
            g.drawTextLine(220, 0, "world");
            endBounds(g, sg.scale);

            // Text alignment
            format.color = 0xFF5959;
            format.size = 14;
            format.lineHeight = 1;
            format.align = TextAlign.CENTER | TextAlign.BASELINE;
            g.textFormat(format);

            g.moveTo(300, 0);

            beginBounds(g);
            g.lineTo(400, 0);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawTextBox(300, 14, 100, "The five boxing wizards jump quickly.");
            endBounds(g, sg.scale);

            // Text wrapping
            format.color = 0x2F66F9;
            format.size = 10;
            beginBounds(g);
            g.textFormat(format);
            endBounds(g, sg.scale);

            g.moveTo(300, 50);
            beginBounds(g);
            g.lineTo(330, 50);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawTextBox(300, 64, 30, "The five boxing wizards jump quickly.");
            endBounds(g, sg.scale);

            g.moveTo(330, 50);
            beginBounds(g);
            g.lineTo(400, 50);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawTextBox(330, 64, 70, "The five boxing wizards jump quickly.");
            endBounds(g, sg.scale);

            // Custom different font
            TextFormat.load("lobster", "assets/Lobster-Regular.ttf");
            format.font = "lobster";
            format.color = 0xFF4848;
            format.size = 30;
            format.align = TextAlign.TOP | TextAlign.LEFT;
            g.textFormat(format);

            beginBounds(g);
            g.drawTextLine(225, 25, "Lobster");
            endBounds(g, sg.scale);

            // Non-scaled vs. scaled text
            format.size = 30;
            g.textFormat(format);

            beginBounds(g);
            g.drawTextLine(80, 200, "Non-scaled");
            endBounds(g, sg.scale);

            format.size /= ss.scale;
            s.textFormat(format);

            beginBounds(s);
            s.drawTextLine((80+115)/ss.scale, 200/ss.scale, "Scaled");
            endBounds(s, ss.scale);

            // Mixed line and shape rendering
            g.moveTo(100, 0);

            beginBounds(g);
            g.lineTo(100, 100);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.drawCircle(50, 50, 40);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.lineTo(0, 100);
            endBounds(g, sg.scale);

            // Curve rendering
            g.moveTo(0, 50);

            beginBounds(g);
            g.curveTo(50, 50 - 30, 100, 50);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.curveTo(50, 50 + 30, 0, 50);
            endBounds(g, sg.scale);

            g.moveTo(50, 50 - 5);

            beginBounds(g);
            g.cubicCurveTo(50 - 5, 50 - 5 + 1 / 3 * 10, 50 + 5, 50 - 5 + 2 / 3 * 10, 50, 50 + 5);
            endBounds(g, sg.scale);

            beginBounds(g);
            g.cubicCurveTo(50-5, 50-5+2/3*10, 50+5, 50-5+1/3*10, 50, 50-5);
            endBounds(g, sg.scale);

            g.moveTo(05, 110);
            beginBounds(g);
            // Cap styles
            g.lineStyle(10, 0x000000, 1, false, "", "round", "round", 0);  g.moveTo(05, 110); g.lineTo(25, 110);
            g.lineStyle(10, 0x000000, 1, false, "", "square", "round", 0); g.moveTo(40, 110); g.lineTo(60, 110);
            g.lineStyle(10, 0x000000, 1, false, "", "none", "round", 0);   g.moveTo(75, 110); g.lineTo(95, 110);
            // Skeleton
            g.lineStyle(01, 0xDADADA, 1, false, "", "round", "round", 0);  g.moveTo(05, 110); g.lineTo(25, 110);
            g.lineStyle(01, 0xDADADA, 1, false, "", "square", "round", 0); g.moveTo(40, 110); g.lineTo(60, 110);
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "round", 0);   g.moveTo(75, 110); g.lineTo(95, 110);

            // Joint styles
            g.lineStyle(10, 0x000000, 1, false, "", "none", "round", 0);  g.moveTo(05, 130); g.lineTo(25, 130); g.lineTo(05, 150);
            g.lineStyle(10, 0x000000, 1, false, "", "none", "bevel", 0);  g.moveTo(40, 130); g.lineTo(60, 130); g.lineTo(40, 150);
            g.lineStyle(10, 0x000000, 1, false, "", "none", "miter", 3);  g.moveTo(75, 130); g.lineTo(95, 130); g.lineTo(75, 150);
            // Skeleton
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "round", 0);  g.moveTo(05, 130); g.lineTo(25, 130); g.lineTo(05, 150);
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "bevel", 0);  g.moveTo(40, 130); g.lineTo(60, 130); g.lineTo(40, 150);
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "miter", 3);  g.moveTo(75, 130); g.lineTo(95, 130); g.lineTo(75, 150);

            // Miter joint angles
            g.lineStyle(10, 0x000000, 1, false, "", "none", "miter", 3);  g.moveTo(05, 170); g.lineTo(25, 170); g.lineTo(05, 175);
            g.lineStyle(10, 0x000000, 1, false, "", "none", "miter", 3);  g.moveTo(40, 170); g.lineTo(60, 170); g.lineTo(40, 185);
            g.lineStyle(10, 0x000000, 1, false, "", "none", "miter", 3);  g.moveTo(75, 170); g.lineTo(95, 170); g.lineTo(75, 190);
            // Skeleton
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "miter", 3);  g.moveTo(05, 170); g.lineTo(25, 170); g.lineTo(05, 175);
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "miter", 3);  g.moveTo(40, 170); g.lineTo(60, 170); g.lineTo(40, 185);
            g.lineStyle(01, 0xDADADA, 1, false, "", "none", "miter", 3);  g.moveTo(75, 170); g.lineTo(95, 170); g.lineTo(75, 190);
            endBounds(g, sg.scale);


            // Line scale mode
            s.lineStyle(1, 0x000000, 1, false, "normal");
            s.moveTo(0.5, 21);

            beginBounds(s);
            s.lineTo(2.5, 21);
            endBounds(s, ss.scale);
            beginBounds(g);
            s.lineTo(0.5, 21);
            endBounds(s, ss.scale);

            s.lineStyle(1, 0x000000, 1, false, "none");
            s.moveTo(4, 21);

            beginBounds(s);
            s.lineTo(6, 21);
            endBounds(s, ss.scale);
            beginBounds(s);
            s.lineTo(4, 21);
            endBounds(s, ss.scale);

            // Various line styles

            g.lineStyle(0, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(0.1, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            beginBounds(g);
            g.lineStyle(0.2, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(0.5, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(1, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(2, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(3, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(4, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(5, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(8, 0x0000FF, 1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            g.lineStyle(8, 0x0000FF, 0.5);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);

            y += 10;
            g.lineStyle(8, 0x0000FF, 0.1);
            g.moveTo(110, y);
            beginBounds(g);
            g.lineTo(210, y);
            endBounds(g, sg.scale);
            y += 10;

            // Fill with linestyle
            g.lineStyle(4, 0xFFFF00, 1);
            g.beginFill(0xF40B74, 1);
            beginBounds(g);
            g.drawRect(110, y, 100, 10);
            g.endFill();
            endBounds(g, sg.scale);
            y += 16;

            // Non-stroked fill after linestyle
            g.lineStyle(NaN, 0, 0);
            g.beginFill(0xC90A60, 1);
            beginBounds(g);
            g.drawRect(110, y, 100, 10);
            g.endFill();
            endBounds(g, sg.scale);
            y += 12;

            // Implicit endFill
            g.beginFill(0x940746, 1);
            beginBounds(g);
            g.drawRect(110, y, 100, 10);
            endBounds(g, sg.scale);

            // Add touch listener
            stage.addEventListener(TouchEvent.TOUCH, onTouch);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }

        /**
         * Touch to cycle over different vector rendering qualities
         */
        private function onTouch(e:TouchEvent):void
        {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;
            switch (stage.vectorQuality) {
                case Stage.VECTOR_QUALITY_ANTIALIAS | Stage.VECTOR_QUALITY_STENCIL_STROKES:
                    stage.vectorQuality = Stage.VECTOR_QUALITY_ANTIALIAS;
                    trace("Vector quality set to ANTIALIAS");
                    break;
                case Stage.VECTOR_QUALITY_ANTIALIAS:
                    stage.vectorQuality = Stage.VECTOR_QUALITY_STENCIL_STROKES;
                    trace("Vector quality set to STENCIL");
                    break;
                case Stage.VECTOR_QUALITY_STENCIL_STROKES:
                    stage.vectorQuality = Stage.VECTOR_QUALITY_NONE;
                    trace("Vector quality set to NONE");
                    break;
                default:
                    stage.vectorQuality = Stage.VECTOR_QUALITY_ANTIALIAS | Stage.VECTOR_QUALITY_STENCIL_STROKES;
                    trace("Vector quality set to ANTIALIAS and STENCIL");
            }
        }

        /**
         * Toggle bounds with spacebar
         */
        function keyDownHandler(event:KeyboardEvent):void
        {
            var keycode = event.keyCode;
            if(keycode == LoomKey.SPACE)
                sd.visible = !sd.visible;;
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
            //////////////////////////////////////////////////////////////
            //  Animate a curve and draw some basic shapes every frame  //
            /* // Comment this line to enable
            var t = Loom2D.juggler.elapsedTime;
            g.clear();
            g.lineStyle(1, 0xBD55F4, 1);
            g.moveTo(0, 0);
            g.cubicCurveTo(Math.cos(t*2.5)*100, Math.sin(t*2.1)*100, Math.cos(t*1.51)*100, Math.sin(t*1.11)*100, 0, 100);
            g.drawCircle(20, 20, 10);
            g.drawEllipse(50, 20, 10, 20);
            g.drawRect(80, 0, 40, 60);
            g.drawRoundRect(140, 0, 40, 60, 10, 10);
            return super.onFrame();
            //*/



            ///////////////////////////
            //  Animated line waves  //
            /* // Comment this line to enable
            g.clear();
            g.lineStyle(1, 0x000000, 1);
            var n = 500;
            var w = 460-sg.x*2;
            var h = 300-sg.y*2;

            var t = Loom2D.juggler.elapsedTime;

            var cx = w / 2;
            var cy = h / 2;
            var r = 100;

            g.moveTo(cx, cy);
            for (var i:int = 0; i < n; i++) {
                var a:Number = t + i / (n-1) * Math.TWOPI * (1000 + Math.cos(t*0.000001)*10);
                var b:Number = t + i / (n-1) * Math.TWOPI * (1000 + Math.sin(t*0.00001)*10);
                // Horizontal wave
                g.lineTo(0+i/(n-1)*w, h/2+Math.sin(a)*h/2);
                // Vertical wave
                //g.lineTo(cx+Math.cos(a)*r, cy+Math.sin(b)*r);
            }
            //*/



            ////////////////////////////
            //  Swirly spiral screen  //
            /* // Comment this line to enable
            g.clear();
            s.clear();
            d.clear();

            g.lineStyle(1, 0xFFFFFF, 0.1);
            //var n = 200;
            var n = 400;
            var w = 460-sg.x*2;
            var h = 300-sg.y*2;

            // Different initial color times
            //var t = Loom2D.juggler.elapsedTime;
            //var t = (Math.cos(Loom2D.juggler.elapsedTime*Math.PI*2/10-Math.PI))/2*10;
            var t = 3;

            var cx = w / 2;
            var cy = h / 2;

            // Different begin and end lines, used in conjunction with non-constant time above
            //var a = Math.floor((0.25+0.25*Math.sin(t*1.1+Math.PI/2))*n);
            //var b = Math.floor((0.75+0.25*Math.sin(t*1.3-Math.PI/2))*n);
            var a = 0;
            var b = n;

            // Different spiral types, more interesting when used in conjunction with non-constant time
            //var spiral = (Math.sin(t*0.01)+1)*0.5*80;
            //var spiral = (Math.sin(t*0.02)+1)*0.5*140;
            var spiral = 1.61803398875;

            // Rotation type (constant or wiggly)
            var rot = Loom2D.juggler.elapsedTime/spiral*10;
            //var rot = (Math.cos(Loom2D.juggler.elapsedTime*Math.PI*2/2-Math.PI))/2*2/spiral;

            var sa = 0.01;
            var sb = 0.05;

            g.moveTo(cx, cy);
            for (var i:int = a; i < b; i++) {
                var r = i/(n-1)*500;
                //var ang = (i/(n-1)*spiral+t*0.5+rot) * Math.TWOPI;
                var ang = spiral*i+rot*i/n;
                //var ang = 1/sb*Math.log(r/sa)+rot;
                g.lineStyle(3 + 1*Math.sin(1000*i/(n-1)*Math.TWOPI + t*50), hsvToRgb((i/n*360*3 + t*200)%360, 0.8, 1), 1);
                g.lineTo(cx+Math.cos(ang)*r, cy+Math.sin(ang)*r);
            }
            //*/


            /////////////////////////
            //  Why not Zoidberg?  //
            /* // Comment this line to enable
            g.clear();
            s.clear();
            d.clear();

            var sans = new TextFormat("sans", 60, 0xfe5552);
            sans.align = TextAlign.CENTER;
            g.textFormat(sans);
            g.drawTextLine(stage.stageWidth/2-sg.x, 50, "(\\/) (°,,°) (\\/)");

            var lobster = new TextFormat("lobster", 60, 0xfe5552);
            lobster.align = TextAlign.CENTER;
            g.textFormat(lobster);
            g.drawTextLine(stage.stageWidth/2-sg.x, 170, "Why not Zoidberg?");
            //*/
        }

    }
}
