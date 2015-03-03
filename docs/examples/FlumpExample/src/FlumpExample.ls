package
{
    import flump.display.Library;
    import flump.display.LibraryLoader;
    import flump.display.Movie;
    import flump.executor.Future;
    import loom.Application;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.display.StageScaleMode;
    import loom2d.events.Event;
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import system.platform.File;
    import system.Void;
    
    public class FlumpTest extends Application
    {
        
        private var movieCreator:MovieCreator;
        
        private var header:Movie;
        private var display:Sprite = new Sprite();
        private var movies = new Vector.<Vector.<Movie>>();
        
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            Profiler.enable();
            
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            var label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Hello Flump!";
            label.x = stage.stageWidth - 640;
            label.y = 30;
            stage.addChild(label);
            
            display.x = 100;
            display.y = 320;
            display.scale = 0.6;
            stage.addChild(display);
            
            //const loader:Future = LibraryLoader.fromBytes(File.loadBinaryFile("assets/mascot.zip"));
            const loader:Future = LibraryLoader.fromURL("assets/mascot.zip");
            loader.succeeded += onLibraryLoaded;
            loader.failed += function (e:Object) :void { Debug.assert(false, ""+e); };
        }
        
        private function onLibraryLoaded(lib:Object) {
            var library = lib as Library;
            
            trace("Library loaded!");
            trace("Image symbols:", library.imageSymbols);
            trace("Movie symbols:", library.movieSymbols);
            
            movieCreator = new MovieCreator(library);
            
            if (header) {
                header.removeEventListeners(Event.ADDED_TO_STAGE);
                header.removeFromParent(true);
                header = null;
            }
            
            header = movieCreator.createMovie("walk");
            header.x = stage.stageWidth-120;
            header.y = 180;
            stage.addChild(header);
            
            display.removeChildren(0, display.numChildren-1, true);
            movies.clear();
            
            var speeds = 9;
            var spacingX = 225;
            var spacingY = 200;
            var anims:Vector.<String> = ["idle", "walk", "attack", "defeat"];
            for (var mi:int = 0; mi < anims.length; mi++) {
                var name = anims[mi];
                var manim = new Vector.<Movie>();
                for (var i:int = 0; i < speeds; i++) {
                    var m:Movie = library.createMovie(name);
                    m.x = i*spacingX;
                    m.y = mi*spacingY;
                    display.addChild(m);
                    manim.push(m);
                }
                movies.push(manim);
            }
        }
        
        override public function onTick() {
            var dt:Number = 1/60;
            var spread = 2;
            for (var mi:int = 0; mi < movies.length; mi++) {
                var manim:Vector.<Movie> = movies[mi];
                for (var i:int = 0; i < manim.length; i++) {
                    var m:Movie = manim[i];
                    var mid:Number = Math.floor(manim.length/2);
                    var off:Number = (i-mid)/mid*spread;
                    var mdt:Number = off == 0 ? dt : off < 0 ? dt/(1-off) : dt*(1+off);
                    m.advanceTime(mdt);
                }
            }
            
            return super.onTick();
        }
        
    }
}