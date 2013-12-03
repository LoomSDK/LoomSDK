package
{

    import loom.Application;

    import system.platform.Platform;
    import loom2d.display.StageScaleMode;    
    import loom2d.display.Image;
    import loom2d.display.QuadBatch;
    import loom2d.textures.Texture;

    import loom2d.text.BitmapFont;

    import loom.box2d;

    public class Box2DExample extends Application
    {
        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;

            var bg = new Image(Texture.fromAsset("assets/bg.png"));

            var ascale_w:Number = stage.stageWidth / bg.width;
            var ascale_h:Number = stage.stageHeight / bg.height;
            var assetScale:Number = (ascale_w > ascale_h) ? ascale_w : ascale_h;

            bg.x = 0;
            bg.y = 0;
            bg.scale = assetScale;
            stage.addChild(bg);

            var gravity:b2Vec2 = new b2Vec2(0,-10);

        }

    }
}