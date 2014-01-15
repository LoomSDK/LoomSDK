package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom.gameframework.Logger;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.KeyboardEvent;
    import loom2d.events.TouchPhase;    
    import loom.platform.VideoControlMode;
    import loom.platform.VideoScaleMode;
    import loom.platform.Video;
    import feathers.display.TiledImage;
    import loom2d.display.Sprite;
    import loom.animation.LoomTween;
    import loom.animation.LoomEaseType;

    public class LoomVids extends Application
    {
        protected var imageScale:Number = 1.0;
        protected var loomMovieCard:Sprite;
        protected var contraptionMovieCard:Sprite;
        protected var whackMovieCard:Sprite;

        //-----------------------------------------------------------------------------------------------------------------------
        // Utility function that loads an image from an asset path and applies the imageScale
        //-----------------------------------------------------------------------------------------------------------------------
        private function LoadScaledImage(imageAssetPath:String):Image
        {
            var scaledImage = new Image(Texture.fromAsset(imageAssetPath));
            scaledImage.width *= this.imageScale;
            scaledImage.height *= this.imageScale;
            return scaledImage;
        }

        //-----------------------------------------------------------------------------------------------------------------------
        // ENTRY POINT
        //-----------------------------------------------------------------------------------------------------------------------
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Create a tiled background using TiledImage from feathers
            var background = new TiledImage(Texture.fromAsset("assets/Background.png"));
            background.setSize(stage.stageWidth, stage.stageHeight);
            stage.addChild(background);

            // Add a header Image
            var header = new Image(Texture.fromAsset("assets/Header.png"));
            header.width = stage.stageWidth;
            header.height *= this.imageScale;
            stage.addChild(header);

            // Add the orange "The Engine Co" logo to top right
            var theEngineCo = this.LoadScaledImage("assets/TheEngineCo.png");
            theEngineCo.y = (header.height * 0.5 - theEngineCo.height * 0.5) + 2;
            theEngineCo.x = 20 * this.imageScale;
            stage.addChild(theEngineCo);

            // Add the main "Loom SDK" logo
            var loomLogo = this.LoadScaledImage("assets/LoomSdk.png");
            loomLogo.x = stage.stageWidth * 0.5 - loomLogo.width * 0.5;
            stage.addChild(loomLogo);

            // Add a footer Image
            var footer = this.LoadScaledImage("assets/Footer.png");
            footer.width = stage.stageWidth;
            footer.y = stage.stageHeight - footer.height;
            stage.addChild(footer);

            // Add a Copyright marker to the footer
            var copyright = this.LoadScaledImage("assets/Copyright.png");
            copyright.x = stage.stageWidth - copyright.width - (10 * this.imageScale);
            copyright.y = stage.stageHeight - copyright.height * 1.5;
            stage.addChild(copyright);
            
            // Initialize the Loom Video callbacks
            Video.onComplete = function() 
            {
                trace("Video complete!");
                TweenMovieCards();
            };

            Video.onFail = function()
            {
                trace("Video failed :(");
                TweenMovieCards();
            };

            // Add a "MovieCard" for each loom video to the stage
            // ----------------------------------------------------------
            
            // Whack a Potato
            this.whackMovieCard = CreateMovieCard("Whack a Potato", "assets/WhackPreview.png", Video.RootFolder + "whackapotato.mp4");
            stage.addChild(this.whackMovieCard);

             // Contraption Maker
            this.contraptionMovieCard = CreateMovieCard("Contraption Maker", "assets/ContraptionMakerPreview.png", Video.RootFolder + "contraptionmaker.mp4");
            stage.addChild(this.contraptionMovieCard);
            
            // The Loom Demo
            this.loomMovieCard = CreateMovieCard("The Loom Demo", "assets/LoomDemoPreview.png", Video.RootFolder + "theloomdemo.mp4");
            stage.addChild(this.loomMovieCard);

            // Move the MovieCards into position
            this.TweenMovieCards();
        }

        //-----------------------------------------------------------------------------------------------------------------------
        // Tweens the 3 movie cards back to their starting locations from wherever they are currently
        //-----------------------------------------------------------------------------------------------------------------------
        protected function TweenMovieCards()
        {
            LoomTween.to(this.loomMovieCard, 0.2, {"x": stage.stageWidth * 0.18, "ease": LoomEaseType.EASE_OUT});
            LoomTween.to(this.contraptionMovieCard, 0.3, {"x": stage.stageWidth * 0.5, "ease": LoomEaseType.EASE_OUT});
            LoomTween.to(this.whackMovieCard, 0.4, {"x": stage.stageWidth * 0.82, "ease": LoomEaseType.EASE_OUT});
        }

        //-----------------------------------------------------------------------------------------------------------------------
        // Creates a Sprite containing all the child elements for a MovieCard
        //-----------------------------------------------------------------------------------------------------------------------
        private function CreateMovieCard(name:String, imageAssetPath:String, movieAssetPath:String):Sprite
        {
            // Create the Sprite Container & add the card Background
            var sprite = new Sprite();
            var cardImage = this.LoadScaledImage("assets/MovieCard.png");
            sprite.addChild(cardImage);
            sprite.center();

            // Add and position the Preview Image for the video
            var previewImage = this.LoadScaledImage(imageAssetPath);
            previewImage.x = cardImage.width / 2 - previewImage.width / 2;
            sprite.addChild(previewImage);

            // Overlay a PlayButton Image
            var playButton = this.LoadScaledImage("assets/PlayButton.png");
            playButton.x = cardImage.width / 2 - playButton.width / 2;
            playButton.y = previewImage.height / 2 - playButton.height / 2;
            sprite.addChild(playButton);

            // Create and position a label containing the video name
            var label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = name;
            label.scaleX = 0.3 * this.imageScale;
            label.scaleY = 0.3 * this.imageScale;
            label.x = cardImage.width / 2;
            label.y = previewImage.height + (label.height /2  * label.scaleY);
            label.center();
            sprite.addChild(label);

            // Shift the card image up just a wee, so that it frames everything else nicely
            cardImage.y -= 15 * this.imageScale;

            // Position the Sprite to a default y location close to the vertical center
            sprite.y = stage.stageHeight / 1.8;

            // Add a touch delegate to listen to a touch Event and launch the specified movie
            sprite.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) 
            { 
                var touch = e.getTouch(sprite, TouchPhase.BEGAN);
                if (touch)
                {
                    trace("Touched: '" + name + "' MovieCard. Playing: " + imageAssetPath);

                    // Move the loom video's out of the way  (so we can tween them back in)
                    this.loomMovieCard.x = 0;
                    this.contraptionMovieCard.x = 0;
                    this.whackMovieCard.x = 0;

                    if(Video.supported)
                    {
                        // Play the video if supported
                        Video.playFullscreen(movieAssetPath, VideoScaleMode.FitAspect, VideoControlMode.StopOnTouch, 0xFF000000 );
                    }
                    else
                    {
                        // Log a warning otherwise (and restore the MovieCards)
                        Logger.warn(this, "CreateMovieCard()", "Video not supported on this platform!");
                        this.TweenMovieCards();
                    }
                }
            } );     

            return sprite;
        }
    }
}