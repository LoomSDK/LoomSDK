package
{
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
     * Shows example usage of the render texture API.
     */
    public class RenderTextureExample extends Application
    {
        private var outlines:Shape;
        private var container:Sprite;
        private var logo:Image;
        private var shape:Shape;
        private var image:Image;
        
        private var renderTexture:RenderTexture;
        
        private var roll:RenderTexture;
        private var rollDisplay:Image;
        
        private var persistent:RenderTexture;
        private var persistentDisplay:Image;
        
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
           
            // Create an empty, transparent render texture
            // that is 200px wide and 200px high
            renderTexture = new RenderTexture(200, 200);
            
            // Create an image that will display the render texture
            image = new Image(renderTexture);
            image.x = 10;
            image.y = 10;
            
            container = new Sprite();
            
            var logoTex = Texture.fromAsset("assets/logo.png");
            logo = new Image(logoTex);
            logo.center();
            
            shape = new Shape();
            
            container.x = 85;
            container.y = 80;
            container.scale = 0.7;
            
            container.addChild(logo);
            
            stage.addChild(image);
            stage.addChild(outlines);
            
            draw();
            
            // The bottom roll texture
            roll = new RenderTexture(stage.stageWidth, 110, false);
            
            rollDisplay = new Image(roll);
            rollDisplay.y = stage.stageHeight-roll.height;
            stage.addChild(rollDisplay);
            
            // The right persistent drawing texture
            persistent = new RenderTexture(renderTexture.width, renderTexture.height, true);
            persistentDisplay = new Image(persistent);
            persistentDisplay.x = image.x+renderTexture.width+10;
            persistentDisplay.y = image.y;
            stage.addChild(persistentDisplay);
            
            stage.addEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        private function onTouch(e:TouchEvent):void {
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
        
        function draw() {
            // Clear the texture in case the function
            // is called multiple times.
            renderTexture.clear();
            
            // Set the logo state we want to work from
            // This is needed in case we change logo elsewhere
            // (e.g. in a loop below)
            logo.x = 25;
            logo.y = 70;
            logo.alpha = 0.8;
            logo.rotation = 0;
            logo.scale = 1;
            
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
            
            // Draw the container using the provided `m` transform matrix
            renderTexture.draw(container, m);
            g.drawRect(image.x+(logo.x-logo.width/2)*0.5+55, image.y+(logo.y-logo.height/2)*0.5+20, logo.width*0.5, logo.height*0.5);
            
            // Offset Poly with different alpha
            m.translate(65, 0);
            renderTexture.draw(container, m, 0.5);
            g.drawRect(image.x+(logo.x-logo.width/2)*0.5+120, image.y+(logo.y-logo.height/2)*0.5+20, logo.width*0.5, logo.height*0.5);
            
            
            m.identity();
            m.scale(0.25, 0.25);
            m.translate(12.5, renderTexture.height-30);
            
            renderTexture.drawBundled(function() {
                for (var i:int = 0; i < 10; i++) {
                    renderTexture.draw(container, m);
                    m.translate((renderTexture.width-container.width*0.25)/10, 0);
                }
            });
        }
        
        override public function onTick() {
            // Uncomment to draw the static test every frame
            //draw();
            
            ///*
            
            // Draw a funky evolving shape
            t = 0;
            logo.x = 0;
            logo.alpha = 1;
            
            // Begin drawing into the `roll` texture
            // This will set `roll` to be the current render
            // texture, so the only valid `draw` calls
            // will be the ones made on the `roll` texture.
            roll.drawBundledLock();
            
            while (logo.x-logo.width/2 < roll.width) {
                var radius = 256;
                var angle = t*0.5*Math.TWOPI;
                
                logo.x = t*0.3*roll.width;
                //logo.x = t*3*roll.width;
                logo.y = roll.height*0.5;
                
                logo.rotation = t*Math.sin(gt*0.1*Math.TWOPI)*3+(Math.sin(t*0.3)*0.5)*0.07;
                
                logo.scale = (Math.sin(t*0.3*Math.TWOPI+Math.sin(gt*0.03*Math.TWOPI)*10)*0.5+0.5)*0.8+0.2;
                
                roll.draw(logo);
                
                t += 1/60;
            }
            
            // End drawing into the texture
            // This submits all the batched `draw` calls
            // to the GPU and draws them into the `roll` texture.
            roll.drawBundledUnlock();
            
            // Draw into a persistent buffer
            // Random position in texture
            logo.x = Math.random()*persistent.width;
            logo.y = Math.random()*persistent.height;
            // Random rotation
            logo.rotation = Math.random()*Math.TWOPI;
            // Random scale with a bias towards smaller ones
            logo.scale = 0.2+0.8*(1-Math.exp(-Math.pow(Math.random(), 10)))*2;
            // Alternate between drawing and erasing
            logo.blendMode = gt%3 < 2 ? BlendMode.NORMAL : BlendMode.ERASE;
            persistent.draw(logo);
            
            var g = shape.graphics;
            g.clear();
            g.beginFill(Math.random()*0xFFFFFF);
            g.drawCircle(Math.random()*persistent.width, Math.random()*persistent.height, 10);
            persistent.draw(shape);
            
            // Restore blendmode
            logo.blendMode = BlendMode.NORMAL;
            
            gt += 1/60;
            
            //*/
        }
    }
}