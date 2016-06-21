package
{

    import loom.Application;

    import system.platform.Platform;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.QuadBatch;
    import loom2d.textures.Texture;

    import loom2d.text.BitmapFont;

    import loom.gameframework.TimeManager;

    public class BitmapFontExample extends Application
    {
        var fontBatch:QuadBatch;

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var font = BitmapFont.load("assets/Curse-hd.fnt");

            fontBatch = new QuadBatch();
            trace(fontBatch);
            stage.addChild(fontBatch);

            font.fillQuadBatch(fontBatch, 500, 50, "Loom2D is Groovy!");

            fontBatch.x = stage.stageWidth / 2;
            fontBatch.y = stage.stageHeight / 2;

            fontBatch.pivotX = fontBatch.width/2;
            fontBatch.pivotY = fontBatch.height/2;
        }

        override public function onTick():void
        {
            fontBatch.rotation += 2;
            fontBatch.scale = Math.sin(Platform.getTime()/1000);
        }

    }
}