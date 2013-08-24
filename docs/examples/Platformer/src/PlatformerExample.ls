package
{

    import loom.Application;

    import system.platform.Platform;
    import loom2d.display.StageScaleMode;    
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;

    import loom2d.text.BitmapFont;

    // The PlatformerExample needs to be ported to Loom2D
    // the original Cocos2D verstion is in the loom2dportrequired folder
    // of the example
    public class PlatformerExample extends Application
    {
        var fontSprite:Sprite; 

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;

            var font = BitmapFont.load("assets/Curse-hd.fnt");

            fontSprite = font.createSprite(480, 100, "Loom2D Platformer is under construction!");
            stage.addChild(fontSprite);            

        }

    }
}