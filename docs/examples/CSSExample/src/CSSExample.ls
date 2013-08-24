package
{
    import loom.lml.LML;
    import loom.Application;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;    
    import loom2d.display.Sprite;    
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;

    /**
     * Example of Loom CSS features, please note that on tablets
     * DisplayProfile.LARGE will be used in the CSS which will change the formatting
     * and display differently than when run on the Desktop
     */
    class CSSExample extends Application
    {
        override public function run()
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var view:MainView = new MainView();
            stage.addChild(view);

            LML.bind("assets/main.lml", view);

            view.myButton.onClick += function() {
                trace("Button 1 clicked");                
            };
        }
    }

    // class to bind to the main.lml file
    class MainView extends Sprite
    {
        [Bind]
        public var background:Image;

        [Bind]
        public var myButton:SimpleButton;
    }
}
