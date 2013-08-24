package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;

    import loom2d.events.KeyboardEvent;
    import loom.platform.LoomKey;

    /**
     * Simple example showing keyboard input driven behavior. Move the sprite
     * with W, A, S, and D.
     */
    public class KeyboardExample extends Application
    {
        public var sprite:Image;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth; 
            bg.height = stage.stageHeight; 
            stage.addChild(bg);

            var label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Hello WASD!";
            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 140;
            stage.addChild(label);
            
            sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.x = stage.stageWidth/2 - sprite.width/2;
            sprite.y = stage.stageHeight/2 - sprite.height/2;
            stage.addChild(sprite);

            this.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
            this.stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);

        }

        function keyDownHandler(event:KeyboardEvent):void
        {   
            var keycode = event.keyCode;
            if(keycode == LoomKey.W)
                sprite.y -= 10;
            if(keycode == LoomKey.S)
                sprite.y += 10;
            if(keycode == LoomKey.A)
                sprite.x -= 10;
            if(keycode == LoomKey.D)
                sprite.x += 10;
        }

        function keyUpHandler(event:KeyboardEvent):void
        {
            trace("Key released: " + event.keyCode);
        }


    }
}