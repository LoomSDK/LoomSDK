package
{
    import loom.Application;
    import loom2d.display.BlendMode;
    import loom2d.display.Graphics;
    import loom2d.display.Image;
    import loom2d.display.Shape;
    import loom2d.display.Sprite;
    import loom2d.display.StageScaleMode;
    import loom2d.display.TextFormat;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.textures.Texture;
    import system.platform.Platform;
    
    /**
     * Example benchmarking and showing off cacheAsBitmap functionality
     */
    public class CacheAsBitmapExample extends Application
    {
        private var debug:Shape;
        private var debugFormat:TextFormat;
        private var container:Sprite = new Sprite();
        
        // Time at the previous onFrame
        private var past:Number = 0;
        
        // Logo texture
        private var texture:Texture;
        
        // true when benchmarking reaches a stable target delta
        private var steady = false;
        
        // Delta time target for the benchmark
        private var benchDeltaTarget = 30;
        
        // The number of frames the frame delta has to
        // remain above the target for it to be considered steady
        private var benchWaitFrames = 60;
        
        // The base batch size when adding images
        // (this is scaled down linearly as delta time approaches target)
        private var benchImageBatch = 50;
        
        // The base batch size when adding vector lines
        private var benchVectorBatch = 175;
        
        // The contained width of the image centers
        private var containedWidth:Number;
        
        // The contained height of the image centers
        private var containedHeight:Number;
        
        // Vector container used for testing nested cached textures
        private var vectorContainer:Sprite;
        // Shape containing the vector lines drawn
        private var vectors:Shape;
        
        // The number of lines to be drawn (this is automatically adjusted while benchmarking)
        private var vectorNum = 0;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Setup background
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            // Load logo texture
            texture = Texture.fromAsset("assets/logo.png");
            
            // Setup image container
            var padding = 0.2;
            var sw = stage.stageWidth;
            var sh = stage.stageHeight;
            containedWidth = sh*(1-padding*2);
            containedHeight = sh*(1-padding*2);
            container.x = 0.5*sh;
            container.y = 0.5*sh;
            container.pivotX = containedWidth*0.5;
            container.pivotY = containedHeight*0.5;
            stage.addChild(container);
            
            
            // Setup shape for lines
            vectorContainer = new Sprite();
            vectorContainer.x = sh;
            stage.addChild(vectorContainer);
            vectors = new Shape();
            vectors.x = sh*0.25;
            vectors.y = sh*0.5;
            // Uncomment to overlap with logos
            //vectors.x = sh*0.5;
            //vectors.alpha = 0.3;
            vectorContainer.addChild(vectors);
            
            // Uncomment to immediately initialize 5k images
            //addImageBatch(5000);
            
            // Add debug text
            debug = new Shape();
            debugFormat = new TextFormat("", 24);
            stage.addChild(debug);
        }
        
        /**
         * Add a batch of randomly positioned images
         * @param batchNum  The number of images in the batch
         */
        private function addImageBatch(batchNum:int) {
            for (var i:int = 0; i < batchNum; i++) {
                var logo:Image = new Image(texture);
                
                // Randomly sample in a disc [-1, 1]
                do {
                    logo.x = Math.randomRange(-1, 1);
                    logo.y = Math.randomRange(-1, 1);
                } while ((logo.x*logo.x + logo.y*logo.y) > 1);
                
                // Transform disc into [0, containedWidth]
                logo.x = (logo.x+1)*0.5*containedWidth;
                logo.y = (logo.y+1)*0.5*containedHeight;
                
                logo.scale = 1;
                logo.center();
                
                logo.addEventListener(TouchEvent.TOUCH, onLogoTouch);
                
                container.addChild(logo);
            }
        }
        
        /**
         * Add a batch of vector lines. This currently just
         * redraws all the lines, but that is fairly quick compared to rendering
         * and shouldn't affect the end result.
         * @param batchNum
         */
        private function addVectorBatch(batchNum:int) {
            vectorNum += batchNum;
            drawVectors();
        }
        
        /**
         * Spin the logo on touch and invalidate the bitmap cache
         */
        private function onLogoTouch(e:TouchEvent):void {
            var logo = e.currentTarget as Image;
            var invalidate = false;
            for each (var touch:Touch in e.getTouches(logo, TouchPhase.BEGAN)) {
                logo.rotation += Math.PI*0.5;
                invalidate = true;
            }
            if (invalidate) container.invalidateBitmapCache();
        }
        
        /**
         * Draw spiraly vector lines
         */
        private function drawVectors() {
            var g:Graphics = vectors.graphics;
            g.clear();
            
            var now = Platform.getTime();
            
            var w = stage.stageHeight;
            var h = stage.stageHeight;
            
            // How much to spin the angle every point
            var angleDelta = Math.PI*0.7;
            
            // Max radius of the spiral
            var radius = w*0.5*0.9;
            
            // Current angle
            var angle = 0;
            
            // Center point marked as a white and black circle
            g.lineStyle(NaN);
            g.beginFill(0x000000, 1);
            g.drawCircle(0, 0, 6);
            g.beginFill(0xFFFFFF, 1);
            g.drawCircle(0, 0, 3);
            
            var px = 0;
            var py = 0;
            var n = vectorNum;
            for (var i:int = 0; i < n; i++) {
                var r = i/n*radius;
                var x = Math.cos(angle) * r;
                var y = Math.sin(angle) * r;
                
                // Dynamically construct a color and set a style based on
                // some made up math formulas
                var cr = i/n;
                var cg = (Math.sin(i/n*Math.TWOPI*0.1+Math.PI)+1)*0.5;
                var cb = (Math.tan(angle*6.0005)+1)/2;
                g.lineStyle(2, (cr*0xFF << 16) | (cg*0xFF << 8) | cb*0xFF);
                
                // Draw the line
                g.moveTo(px, py);
                g.lineTo(x, y);
                
                // Remember this position for next time
                px = x;
                py = y;
                angle += angleDelta;
            }
        }
        
        override public function onFrame() {
            
            var g:Graphics = debug.graphics;
            var now = Platform.getTime();
            var delta = now - past;
            
            var status = "";
            
            if (benchWaitFrames > 0) {
                if (delta < benchDeltaTarget) {
                    var attenuation = 1-delta/benchDeltaTarget;
                    var batchImageNum = 1 + Math.floor(benchImageBatch*attenuation);
                    var batchVectorNum = 1 + Math.floor(benchVectorBatch*attenuation);
                    addImageBatch(batchImageNum);
                    addVectorBatch(batchVectorNum);
                    status = "Increasing load (" + batchImageNum + " / " + batchVectorNum + ")";
                    now = Platform.getTime();
                } else {
                    benchWaitFrames--;
                    status = "Waiting (" + benchWaitFrames + ")";
                }
                container.touchable = false;
            } else {
                steady = true;
            }
            
            if (steady) {
                status = "Steady";
                container.touchable = true;
                container.rotation += 0.01;
                vectors.rotation += 0.01;
                var cache = Math.sin(now*Math.TWOPI*1e-4);
                container.cacheAsBitmap = cache > 0;
                vectors.cacheAsBitmap = cache > 0;
                status += " ("+(container.cacheAsBitmap || vectors.cacheAsBitmap ? "cached" : "not cached")+")";
            }
            
            g.clear();
            g.beginFill(0xAB7503);
            g.textFormat(debugFormat);
            g.drawTextLine(5, 5, (
                steady ? "Touch logo to spin" : "Please wait") + " | " +
                container.numChildren + " images | " +
                vectorNum + " lines | " +
                delta + "ms | " +
                status
            );
            
            past = Platform.getTime();
        }
    }
}