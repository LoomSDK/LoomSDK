package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;


    import loom.platform.Video;
    import loom.platform.VideoScaleMode;
    import loom.platform.VideoControlMode;


    /**
     * Example for full screen video playback in Loom
     *
     * WARNING: This example only works on iOS and Android mobile devices.  You 
     * use Video.supported to check if video playback is enabled on the current platform.
     *
     * This application launches and plays back a specified .mp4 video file fullscreen on device.
     * You can modify the Video.onComplete delegate, as well as the various parameters of
     * Video.playFullscreen() to test different methods of playback
     */


    public class VideoExample extends Application
    {
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            if(Video.supported)
            {
                ///set up delegates
                Video.onComplete += videoComplete;
                Video.onFail += videoFail;

                ///start video playback
                Video.playFullscreen("bigbuckbunny", VideoScaleMode.FitAspect, VideoControlMode.Show, 0xff000000);
            }
            else
            {
                startGame("Video Playback Not Supported!", 50);
            }
        }


        ///starts the game
        private function startGame(message:String, x:int):void
        {
            ///background image
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth; 
            bg.height = stage.stageHeight; 
            stage.addChild(bg);

            ///set game message
            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = message;
            label.x = x;
            label.y = 200;
            stage.addChild(label);
        }

        
        ///delegate called when the video has completed
        private function videoComplete(type:String, payload:String):void
        {
            ///remove global video callbacks now that we have completed
            Video.onComplete -= videoComplete;
            Video.onFail -= videoComplete;

            startGame("Video Completed!", 250);
        }


        ///delegate called when the video has completed
        private function videoFail(type:String, payload:String):void
        {
            ///remove global video callbacks now that we have completed
            Video.onComplete -= videoComplete;
            Video.onFail -= videoComplete;

            startGame("Video Failed!", 300);
        }       
    }
}