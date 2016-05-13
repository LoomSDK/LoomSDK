package
{
    import loom.Application;
    import system.platform.Platform;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Shape;
    import loom2d.display.Graphics;
    import loom2d.display.TextFormat;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    
    import loom2d.math.Point;

    /**
     *  Example demonstrating various Platform class functionality.
     */
    public class PlatformExample extends Application
    {
        private var format:TextFormat = new TextFormat(null, 30, 0x505050);
        private var g:Graphics;
        
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.x = 10;
            bg.y = 10;
            bg.width = stage.stageWidth - 20;
            bg.height = stage.stageHeight - 20;
            stage.addChild(bg);
            
            var shape = new Shape();
            g = shape.graphics;
            shape.x = 10;
            shape.y = 10;
            shape.touchable = false;
            stage.addChild(shape);
            
            bg.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 
                var touch = e.getTouch(stage, TouchPhase.BEGAN);
                if (touch)
                {   
                    var point:Point;
                    point = touch.getLocation(stage);
                    trace(point);
                    Platform.openURL("http://loomsdk.com");
                }
            } );            
        }
        
        override public function onFrame():void
        {
            var status = "";
            
            status += "getTime()              " + Platform.getTime() + "ms\n";
            status += "getEpochTime()    " + Platform.getEpochTime() + "s\n";
            
            var platformName = "unknown";
            switch (Platform.getPlatform()) {
                case PlatformType.WINDOWS: platformName = "WINDOWS"; break;
                case PlatformType.OSX: platformName = "OSX"; break;
                case PlatformType.IOS: platformName = "IOS"; break;
                case PlatformType.ANDROID: platformName = "ANDROID"; break;
                case PlatformType.LINUX: platformName = "LINUX"; break;
            }
            status += "getPlatform()         " + platformName + "\n";
            
            var displayProfile = "unknown";
            switch (Platform.getProfile()) {
                case DisplayProfile.DESKTOP: displayProfile = "DESKTOP"; break;
                case DisplayProfile.SMALL: displayProfile = "SMALL"; break;
                case DisplayProfile.NORMAL: displayProfile = "NORMAL"; break;
                case DisplayProfile.LARGE: displayProfile = "LARGE"; break;
            }
            status += "getDisplayProfile() " + displayProfile + "\n";
            
            status += "getDPI()                  " + Platform.getDPI() + "\n";
            
            status += "isForcingDPI()        " + Platform.isForcingDPI() + "\n";
            
            status += "\nTouch to open URL!";
            
            g.clear();
            g.textFormat(format);
            g.drawTextBox(10, 10, stage.stageWidth, status);
            
        }
    }
}