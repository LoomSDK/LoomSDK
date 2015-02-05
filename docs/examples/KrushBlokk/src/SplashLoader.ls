package  
    {
    import loom.gameframework.TimeManager;
    import loom.platform.Mobile;
    import loom2d.display.Image;
    import loom2d.display.Stage;
    import loom2d.textures.Texture;

    /**
     * Displays a splash screen and uses the provided callback
     * to load the rest of the application.
     */
    public class SplashLoader 
    {
        private static var splash:Image;
        
        public static function init(stage:Stage, timeManager:TimeManager, callback:Function) 
        {
            Mobile.allowScreenSleep(false);
            splash = new Image(Texture.fromAsset("assets/splash.png"));
            splash.x = (stage.stageWidth-splash.width)/2;
            splash.y = (stage.stageHeight-splash.height)/2;
            stage.addChild(splash);
            timeManager.callLater(loaded, [callback]);
        }
        
        private static function loaded(callback:Function)
        {
            splash.texture.dispose();
            splash.removeFromParent(true);
            splash = null;
            Mobile.allowScreenSleep(true);
            callback();
        }
        
    }
}