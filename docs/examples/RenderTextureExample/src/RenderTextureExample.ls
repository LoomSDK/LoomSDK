package
{
    import loom.Application;
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;
    import loom2d.display.Graphics;
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

    public class RenderTextureExample extends Application
    {
        private var logo:loom2d.display.Image;
        private var image:loom2d.display.Image;
        private var tex:RenderTexture;
        
        private var gt:Number = 0;
        private var t:Number = 0;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            //var textureInfo:TextureInfo = Texture2D.initRenderTexture();
            
            //var tex:ConcreteTexture = new ConcreteTexture("", textureInfo.width, textureInfo.height);
            //tex.mFrame = new Rectangle(0, 0, textureInfo.width, textureInfo.height);
            //tex.setTextureInfo(textureInfo);
            
            var outlines = new Shape();
            var g:Graphics = outlines.graphics;
            g.lineStyle(1, 0x53C109);
            
            tex = new RenderTexture(200, 200, true, 1, "bgra", false);
            
            image = new Image(tex);
            image.x = 50;
            image.y = 50;
            stage.addChild(image);
            
            g.drawRect(image.x, image.y, tex.width, tex.height);
            
            var container = new Sprite();
            
            var logoTex = Texture.fromAsset("assets/logo.png");
            //logoTex.smoothing = TextureSmoothing.NONE;
            logo = new Image(logoTex);
            
            container.x = 80;
            container.y = 80;
            container.scale = 0.7;
            
            logo.x = 20;
            logo.y = 20;
            
            container.addChild(logo);
            
            //stage.addChild(logo);
            
            tex.draw(container);
            g.drawRect(image.x+container.x+logo.x*container.scale, image.y+container.y+logo.y*container.scale, logo.width*container.scale, logo.height*container.scale);
            
            var m = new Matrix();
            m.scale(0.5, 0.5);
            m.translate(30, 10);
            
            tex.draw(container, m);
            g.drawRect(image.x+logo.x*0.5+30, image.y+logo.y*0.5+10, logo.width*0.5, logo.height*0.5);
            
            stage.addChild(outlines);
            
            //stage.addChild(logo);
            
            //var rt = Texture

        }
        
        override public function onTick() {
            /*
            for (var b:int = 0; b < 200; b++) {
                var radius = 256;
                var angle = t*0.5*Math.TWOPI;
                
                //logo.x = radius+Math.cos(angle)*radius;
                //logo.y = radius+Math.sin(angle*0.97)*radius;
                
                logo.x = t*0.1*tex.width;
                
                //logo.x = tex.width*0.5;
                logo.y = tex.height*0.5;
                
                
                logo.rotation = t*Math.sin(gt*0.2*Math.TWOPI)*3+(Math.sin(t*0.3)*0.5)*0.07;
                
                logo.scale = (Math.sin(t*0.1*Math.TWOPI+Math.sin(gt*0.3*Math.TWOPI)*10)*0.5+0.5)*0.8+0.2;
                
                //logo.x = 20;
                //logo.y = 20;
                
                Texture2D.render(tex.nativeID, logo);
                
                t += 1/60;
            
                if (logo.x > tex.width) {
                    t = 0;
                    gt += 1/60;
                    logo.x = 0;
                }
                
            }
            */
            return super.onTick();
        }
        
        override public function onFrame() {
            
            return super.onFrame();
        }
    }
}