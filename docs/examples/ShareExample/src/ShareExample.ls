package
{
    import loom.Application;
    import loom.platform.Mobile;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;
    import loom2d.ui.ButtonClickCallback;

    /*
     * A simple example showing how you can do social sharing of text on 
     * Mobile devices through apps like Twitter or Facebook
    */
    public class ShareExample extends Application
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
            
            var button = new SimpleButton();
            button.downImage = "assets/logo.png";
            button.upImage = "assets/logo.png";
            button.onClick = share;
            button.center();
            button.x = stage.stageWidth / 2;
            button.y = stage.stageHeight / 2 + 50;
            stage.addChild(button);

            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Press Poly to Share!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);
        }

        private function share():void
        {
            Mobile.shareText("Loom!", "Using Loom to make great games and awesome apps? If not, go to www.loomsdk.com for details on how to go Turbo with Loom!");
        }
    }
}