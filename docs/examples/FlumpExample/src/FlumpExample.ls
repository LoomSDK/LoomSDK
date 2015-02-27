package
{
    import flump.display.Library;
    import flump.display.LibraryLoader;
    import flump.display.Movie;
    import flump.executor.Future;
    import loom.Application;
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.events.Event;
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.errors.Error;
    import system.platform.File;
    
    public class FlumpTest extends Application
    {
        
        protected var _movieCreator :MovieCreator;
    
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            const loader :Future = LibraryLoader.fromBytes(File.loadBinaryFile("assets/mascot.zip"));
            loader.succeeded += onLibraryLoaded;
            loader.failed += function (e:Object) :void { Debug.assert(e); };
            
        }
        
        private function onLibraryLoaded(library :Object) {
            _movieCreator = new MovieCreator(library as Library);
            
            var movie :Movie = _movieCreator.createMovie("walk");
            movie.x = 160;
            movie.y = 180;
            stage.addChild(movie);

            // Clean up after ourselves when the screen goes away.
            //addEventListener(Event.REMOVED_FROM_STAGE, function (..._) :void {
                //_movieCreator.library.dispose();
            //});
        }
        
    }
}