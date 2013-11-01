package
{

    import loom.Application;    
    import loom.animation.LoomTween;
    import loom.animation.LoomEaseType;
    import loom2d.math.Point;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;
    import loom2d.ui.SimpleLabel;

    /**
     * Example of TextureSmoothing modes
     *     
     * This application allows the user to switch between nearest neighbor 
     * and bilinear filtering modes
     */

    public class TextureSmoothingExample extends Application
    {

        var checkerboard:Texture;
        var sprite:Image;
        var label:SimpleLabel;
        var currentSmoothing = TextureSmoothing.NONE;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            label = new SimpleLabel("assets/fonts/Curse-hd.fnt", 320, 128);            

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            checkerboard = Texture.fromAsset("assets/checkerboard.jpg");            
            checkerboard.smoothing = currentSmoothing;
            label.text = "Texture Smoothing: None";

            sprite = new Image(checkerboard);
            sprite.center();
            sprite.x = 240;
            sprite.y = 120;
            stage.addChild(sprite);

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {
                    currentSmoothing++;

                    if (currentSmoothing > TextureSmoothing.MAX)
                        currentSmoothing = TextureSmoothing.NONE;

                    switch(currentSmoothing)
                    {
                        case TextureSmoothing.NONE:
                            label.text = "Texture Smoothing: None";
                            break;
                        case TextureSmoothing.BILINEAR:
                            label.text = "Texture Smoothing: Bilinear";
                            break;
                    }

                    checkerboard.smoothing = currentSmoothing;

                }
            } );            

        }

        override public function onFrame():void
        {
            sprite.scale = Math.abs(Math.sin(Platform.getTime()/3000));
        }
    }
}