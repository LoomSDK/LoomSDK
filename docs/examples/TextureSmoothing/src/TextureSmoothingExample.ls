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

    //https://theengineco.atlassian.net/browse/LOOM-1801

    public class TextureSmoothingExample extends Application
    {

        var noneSprite:Image;
        var bilinearSprite:Image;
        var trilinearSprite:Image;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/fonts/Curse-hd.fnt", 320, 128);
            label.text = "Texture Smoothing";

            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            var check1 = Texture.fromAsset("assets/check1.jpg");            
            var check2 = Texture.fromAsset("assets/check2.jpg");
            var check3 = Texture.fromAsset("assets/check3.jpg");

            check1.smoothing = TextureSmoothing.NONE;
            check2.smoothing = TextureSmoothing.BILINEAR;
            check3.smoothing = TextureSmoothing.TRILINEAR;

            noneSprite = new Image(check1);
            noneSprite.x = 32;
            noneSprite.y = 60;
            stage.addChild(noneSprite);

            bilinearSprite = new Image(check1);
            bilinearSprite.x = 176;
            bilinearSprite.y = 60;
            stage.addChild(bilinearSprite);

            trilinearSprite = new Image(check1);
            trilinearSprite.x = 320;
            trilinearSprite.y = 60;
            stage.addChild(trilinearSprite);

        }

        override public function onFrame():void
        {
            var scale = Math.abs(Math.sin(Platform.getTime()/2000));
            noneSprite.scale = bilinearSprite.scale = trilinearSprite.scale = scale;
        }
    }
}