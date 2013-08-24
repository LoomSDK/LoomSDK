package
{
    import loom.Application;
    import loom2d.Loom2D;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.MovieClip;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.math.Rectangle;
    import loom2d.math.Point;

    public class MovieClipExample extends Application
    {
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);

            // Create textures from the spritesheet. This can also be loaded
            // from a spritesheet, which will do the same thing but 
            var sheet = Texture.fromAsset("assets/spritesheet.png");

            // The dimensions of each tile in the spritesheet.
            var spriteWidth:int = 60, spriteHeight:int = 60;

            // How many total sprites?
            var spriteCount:int = 30;

            // How many sprites in a row?
            var spriteRowCount:int = 5;

            // Generate frames based on the above parameters.
            var frames = new Vector.<Texture>();
            for(var i:int; i<spriteCount; i++)
            {
                var spriteX:int = i % spriteRowCount;
                var spriteY:int = Math.floor(i / spriteRowCount);

                frames.push(Texture.fromTexture(sheet, 
                    new Rectangle(spriteX * spriteWidth, 
                                  spriteY * spriteHeight,
                                  spriteWidth, spriteHeight)));

            }
            
            // Set up the MovieClip.
            var clip = new MovieClip(frames, 12);
            Loom2D.juggler.add(clip);
            clip.play();
            clip.center();
            clip.x = stage.stageWidth / 2;
            clip.y = stage.stageHeight / 2 + 50;
            stage.addChild(clip);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Hello MovieClip!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);

        }
    }
}