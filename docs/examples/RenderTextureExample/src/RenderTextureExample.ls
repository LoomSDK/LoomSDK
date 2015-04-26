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
        private var outlines:Shape;
        private var container:Sprite;
        private var logo:Image;
        private var image:Image;
        private var renderTexture:RenderTexture;
        private var roll:RenderTexture;
        private var rollDisplay:Image;
        
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
            
            outlines = new Shape();
            
            renderTexture = new RenderTexture(200, 200);
            
            image = new Image(renderTexture);
            image.x = 10;
            image.y = 10;
            
            container = new Sprite();
            
            var logoTex = Texture.fromAsset("assets/logo.png");
            logo = new Image(logoTex);
            logo.center();
            logo.alpha = 0.8;
            
            container.x = 85;
            container.y = 80;
            container.scale = 0.7;
            
            logo.x = 25;
            logo.y = 70;
            
            container.addChild(logo);
            
            stage.addChild(image);
            stage.addChild(outlines);
            
            draw();
            
            roll = new RenderTexture(stage.stageWidth, 110);
            
            rollDisplay = new Image(roll);
            rollDisplay.y = stage.stageHeight-roll.height;
            stage.addChild(rollDisplay);
        }
        
        function draw() {
            renderTexture.clear();
            
            // Outlines of bounds
            var g:Graphics = outlines.graphics;
            g.clear();
            g.lineStyle(1, 0x53C109);
            
            var m = new Matrix();
            
            // Setup background matrix
            m.translate(-logo.width/2, -logo.height/2);
            m.scale(4, 4);
            m.translate(renderTexture.width/2, renderTexture.height/2);
            
            // Draw background
            renderTexture.draw(logo, m);
            g.drawRect(image.x, image.y, renderTexture.width, renderTexture.height);
            
            // No matrix default draw
            renderTexture.draw(container);
            g.drawRect(image.x+container.x+(logo.x-logo.width/2)*container.scale, image.y+container.y+(logo.y-logo.height/2)*container.scale, logo.width*container.scale, logo.height*container.scale);
            
            // Smaller matrix
            m.identity();
            m.scale(0.5, 0.5);
            m.translate(55, 20);
            
            renderTexture.draw(container, m);
            g.drawRect(image.x+(logo.x-logo.width/2)*0.5+55, image.y+(logo.y-logo.height/2)*0.5+20, logo.width*0.5, logo.height*0.5);
            
            // Offset Poly with different alpha
            m.translate(65, 0);
            renderTexture.draw(container, m, 0.5);
            g.drawRect(image.x+(logo.x-logo.width/2)*0.5+120, image.y+(logo.y-logo.height/2)*0.5+20, logo.width*0.5, logo.height*0.5);
            
        }
        
        override public function onTick() {
            // Uncomment to draw every frame
            //draw();
            
            ///*
            roll.clear();
            t = 0;
            gt += 1/60;
            logo.x = 0;
            
            while (logo.x-logo.width/2 < roll.width) {
                var radius = 256;
                var angle = t*0.5*Math.TWOPI;
                
                logo.x = t*0.4*roll.width;
                //logo.x = t*20*roll.width;
                logo.y = roll.height*0.5;
                
                logo.rotation = t*Math.sin(gt*0.1*Math.TWOPI)*3+(Math.sin(t*0.3)*0.5)*0.07;
                
                logo.scale = (Math.sin(t*0.3*Math.TWOPI+Math.sin(gt*0.03*Math.TWOPI)*10)*0.5+0.5)*0.8+0.2;
                
                roll.draw(logo);
                
                t += 1/60;
            }
            //*/
        }
    }
}