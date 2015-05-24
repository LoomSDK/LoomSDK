package
{
    import feathers.controls.Button;
    import feathers.controls.List;
    import feathers.layout.MultiColumnGridLayout;
    import loom.Application;
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;
    import loom2d.display.BlendMode;
    import loom2d.display.Graphics;
    import loom2d.display.Shape;
    import loom2d.display.Sprite;
    import loom2d.display.Stage;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.SVG;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
    import loom2d.math.Matrix;
    import loom2d.math.Rectangle;
    import loom2d.textures.ConcreteTexture;
    import loom2d.textures.RenderTexture;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;
    import loom2d.ui.SimpleLabel;
    import system.platform.Platform;
    import system.Void;
    
    /**
     */
    public class FlattenExample extends Application
    {
        private var display = new Sprite();
        private var flattened:Boolean = false;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            
            
            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            //grid.x = 20;
            stage.addChild(display);
            initButtons();
            
            stage.addEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        private function initButtons() {
            var radius = 1;
            var svg = SVG.fromFile("assets/tiger.svg");
            var shape = new Shape();
            var g:Graphics = shape.graphics;
            g.clear();
            display.addChild(shape);
            var canvasWidth = stage.stageWidth;
            var canvasHeight = stage.stageHeight;
            var gx = 3;
            var gy = 3;
            var scale = 0.1;
            for (var iy:int = 0; iy < gy; iy++) {
                for (var ix:int = 0; ix < gx; ix++) {
                    //var b = new Shape();
                    //b.label = ""+ix+" "+iy;
                    //b.width = 20;
                    //b.height = 20;
                    //b.x = ix*(radius*2+1);
                    //b.y = iy*(radius*2+1);
                    g.drawSVG(svg, (ix+0.5)/gx*canvasWidth-svg.width*0.5*scale, (iy+0.5)/gy*canvasHeight-svg.height*0.5*scale, scale);
                    //b.graphics.beginFill(0x0000FF);
                    //b.graphics.drawCircle(radius, radius, radius);
                    //grid.addChild(b);
                }
            }
        }
        
        private function onTouch(e:TouchEvent):void {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;
            flattened = !flattened;
            if (flattened) {
                display.flatten();
            } else {
                display.unflatten();
            }
        }
        
        override public function onFrame() {
            var angle = Platform.getTime()*1e-3*Math.TWOPI;
            //var angle = 0;
            display.x = Math.cos(angle)*50;
            display.y = Math.sin(angle)*50;
            //display.flatten();
            return super.onFrame();
        }
        
    }
}