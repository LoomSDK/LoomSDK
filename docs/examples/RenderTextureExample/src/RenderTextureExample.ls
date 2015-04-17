package
{
    import loom.Application;
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.math.Rectangle;
    import loom2d.textures.ConcreteTexture;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    public class RenderTextureExample extends Application
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
            
            var textureInfo:TextureInfo = Texture2D.initRenderTexture();
            
            //var tex:ConcreteTexture = new ConcreteTexture("", textureInfo.width, textureInfo.height);
            //tex.mFrame = new Rectangle(0, 0, textureInfo.width, textureInfo.height);
            //tex.setTextureInfo(textureInfo);
            
            //var image = new Image
            
            //var rt = Texture

        }
    }
}