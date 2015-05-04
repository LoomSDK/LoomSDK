package
{
    import loom.Application;
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;
    import loom2d.display.BlendMode;
    import loom2d.display.DisplayObject;
    import loom2d.display.Graphics;
    import loom2d.display.Quad;
    import loom2d.display.Shape;
    import loom2d.display.Sprite;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
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

    public class VectorQuadSwitch extends Application
    {
        private var gw:int;
        private var gh:int;
        
        private var lastFrame:Number = 0;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            //gw = 15;
            //gh = 8;
            
            gw = 11;
            gh = 11;
            
            for (var iy:int = 0; iy < gh; iy++) {
                for (var ix:int = 0; ix < gw; ix++) {
                    var count:int = ix+iy*gw;
                    if (count%2 == 0) {
                        var shape = new Shape();
                        var g:Graphics = shape.graphics;
                        g.beginFill(0xE4CA10);
                        g.drawRect(0, 0, 100, 100);
                        place(shape, ix, iy);
                    } else {
                        var quad = new Quad(100, 100, 0x0C9BF1);
                        place(quad, ix, iy);
                    }
                }
            }
            
        }
        
        private function place(d:DisplayObject, ix:int, iy:int) {
            var count = ix+iy*gw;
            d.x = 10+ix*((stage.stageWidth-20)/gw);
            d.y = 10+iy*((stage.stageHeight-20)/gh);
            stage.addChild(d);
        }
        
        override public function onFrame() {
            var time:Number = Platform.getTime();
            trace((time-lastFrame)+"ms");
            lastFrame = time;
        }
    }
}