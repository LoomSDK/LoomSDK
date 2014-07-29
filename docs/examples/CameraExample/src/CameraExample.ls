package
{
    import loom.Application;
    import loom.ApplicationEvents;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.ui.SimpleLabel;
    import loom2d.math.Point;

    /**
     * Example showing how to capture and display images using the native
     * camera, if present. Will not work on OS X/Windows as they don't have mobile
     * camera UIs.
     */
    public class CameraExample extends Application
    {
        public var cameraShot:Image;
        public var label:SimpleLabel;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            stage.addChild(sprite);

            label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Touch for Picture!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            stage.addChild(label);
            
            // Add to the stage to capture touches for the entire stage,
            // allowing for a touch anywhere to open up the camera.
            stage.addEventListener(TouchEvent.TOUCH, onTouch);
            
            // Listen for application events, ie, if the camera succeeds.
            Application.event += onAppEvent;
        }

        protected function onAppEvent(type:String, payload:String)
        {
            if(type == ApplicationEvents.CAMERA_SUCCESS)
            {
                label.text = "Camera succeeded!";
                if(cameraShot)
                    cameraShot.parent.removeChild(cameraShot);

                cameraShot = new Image(Texture.fromAsset(payload));
                stage.addChild(cameraShot);

                // Scale to fit.
                cameraShot.scaleX = cameraShot.scaleY = Math.min(stage.stageWidth / cameraShot.width, stage.stageHeight / cameraShot.height);
            }
            else if(type == ApplicationEvents.CAMERA_FAIL)
            {
                label.text = "Camera failed!";
            }
        }

        protected function onTouch(te:TouchEvent):void
        {
            if(te.getTouch(stage, TouchPhase.BEGAN))
            {
                // Trigger camera native UI if present.
                trace("Triggering native camera!");
                Application.fireGenericEvent(ApplicationEvents.CAMERA_REQUEST);
            }
        }
    }
}