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
        private var benchBatch = 50;
        
        // The contained width of the image centers
        private var containedWidth:Number;
        
        // The contained height of the image centers
        private var containedHeight:Number;
        
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
            container.x = 0.5*sw;
            container.y = 0.5*sh;
            container.pivotX = containedWidth*0.5;
            container.pivotY = containedHeight*0.5;
            stage.addChild(container);
            
            // Uncomment to immediately initialize 5k images
            addBatch(5000);
            
            // Add debug text
            debug = new Shape();
            debugFormat = new TextFormat("", 24);
            stage.addChild(debug);
        }
        
        /**
         * Add a batch of randomly positioned images
         * @param batchNum  The number of images in the batch
         */
        private function addBatch(batchNum:int) {
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
        
        override public function onFrame() {
            
            var g:Graphics = debug.graphics;
            var now = Platform.getTime();
            var delta = now - past;
            
            var status = "";
            
            if (benchWaitFrames > 0) {
                if (delta < benchDeltaTarget) {
                    var batchNum = 1 + Math.floor(benchBatch*(1-delta/benchDeltaTarget));
                    addBatch(batchNum);
                    status = "Increasing load (" + batchNum + ")";
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
                var cache = Math.sin(now*Math.TWOPI*1e-4);
                container.cacheAsBitmap = cache > 0;
                status += " ("+(container.cacheAsBitmap ? "cached" : "not cached")+")";
            }
            
            g.clear();
            g.beginFill(0xAB7503);
            g.textFormat(debugFormat);
            g.drawTextLine(5, 5, (steady ? "Touch logo to spin" : "Please wait") + " | " + container.numChildren + " images | " + delta + "ms | " + status);
            
            past = Platform.getTime();
        }
    }
}