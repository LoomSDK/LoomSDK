package
{

    import system.platform.Platform;
    import loom.Application;    
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.display.Sprite;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;

    /**
     *  Simple example to showcase the handling of clip rectangles
     */
    public class ClipRectExample extends Application
    {
        // setup some vars which will be modulated per tick

        // our clip rect!
        var clipRect = new Rectangle();

        // the size of the clip rect, set from the source image
        var clipRectSize = 0;

        // whether we are using the clip rect or not
        var clipRectToggle = false;

        // the container sprite
        var sprite:Sprite;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/fonts/Curse-hd.fnt", 320, 128);
            label.text = "Tap to Toggle the ClipRect!";

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 120;
            stage.addChild(label);

            // Create our container sprite which will have the clip rect assigned
            sprite = new Sprite();
            sprite.x = 0;
            sprite.y = 0;
            sprite.width = stage.stageWidth;
            sprite.height = stage.stageHeight;
            stage.addChild(sprite);

            // add an image (which will be clipped)
            var image = new Image(Texture.fromAsset("assets/logo.png"));

            clipRectSize = image.height;

            image.x = stage.stageWidth/2 - clipRectSize/2;
            image.y = stage.stageHeight/2 - clipRectSize/2;

            sprite.addChild(image);

            // listen in for touches, and toggle the clip rect if we tap
            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {
                    clipRectToggle = !clipRectToggle;
                }
            } );            


        }

        override public function onTick():void
        {            
            // animate the clip rect based on time and the size
            var size = Math.abs(Math.sin(Platform.getTime()/500))  * clipRectSize;

            // the clip rect is based off the position of the sprite so offset it
            clipRect.x = stage.stageWidth/2 - size/2;
            clipRect.y = stage.stageHeight/2 - size/2;
            clipRect.width = size;
            clipRect.height = size;

            // set or clean depending on our toggle!
            sprite.clipRect = clipRectToggle ? clipRect : null;

        }


    }
}