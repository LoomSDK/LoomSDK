package
{
    import loom.Application;
    import loom.platform.Accelerometer;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    /**
     *  Simple example to showcase using the accelerometer on Android or iOS
     */
    public class AccelerometerExample extends Application
    {
        protected var directionX = 0;
        protected var directionY = 0;
        protected var sprite:Image;

        override public function run():void
        {
            var width = stage.stageWidth;
            var height = stage.stageHeight;

            stage.scaleMode = StageScaleMode.FILL;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = width; 
            bg.height = height; 
            stage.addChild(bg);

            var label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Tilt Me!";
            label.x = width/2 - 320/2;
            label.y = height - 164;
            stage.addChild(label);
            
            sprite = new Image(Texture.fromAsset("assets/logo.png"));            
            sprite.x = width/2 - sprite.width/2;
            sprite.y = height/2 - sprite.height/2;
            sprite.center();
            stage.addChild(sprite);

            // Check if the Accelerometer is indeed supported on device.
            if(Accelerometer.isSupported)
                // Wire up the accelerated delegate to call onAcclerometerData
                Accelerometer.accelerated += onAcclerometerData;
        }

        override protected function onTick()
        {
            // Move the sprite based on direction set by acclerometer
            sprite.x += directionX * 10;
            sprite.y += directionY * 10;

            // clamp the values to the screen
            sprite.x = Math.clamp(sprite.x, 0, stage.stageWidth);
            sprite.y = Math.clamp(sprite.y, 0, stage.stageHeight);
        }

        protected function onAcclerometerData(x:Number, y:Number, z:Number) 
        {
            directionX = x;
            directionY = -y; 
        }
    }
}