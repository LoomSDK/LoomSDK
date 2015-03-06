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
    
    /**
     * This example shows basic usage of Flump
     * using the example Flump animation.
     * Based on the Flump demo by Flump Authors.
     */
    public class FlumpExample extends Application
    {
        
        private var movieCreator:MovieCreator;
        
        private var header:Movie;
        private var display:Sprite = new Sprite();
        private var movies = new Vector.<Vector.<Movie>>();
        
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Background
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            // Flump text
            var label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Hello Flump!";
            label.x = stage.stageWidth - 640;
            label.y = 30;
            stage.addChild(label);
            
            // display holds all the movies that are displayed.
            // It's used to scale down and position them.
            display.x = 100;
            display.y = 320;
            display.scale = 0.6;
            stage.addChild(display);
            
            // Creates a new library loader with the provided URL.
            // The returned object is a Future that you set event handlers on.
            // This also enables live reloading, so onLibraryLoaded gets
            // called every time the library zip file changes.
            // It's also possible to load from bytes with `LibraryLoader.fromBytes`.
            const loader:Future = LibraryLoader.fromURL("assets/mascot.zip");
            // Sets the callbacks for library load, `onLibraryLoaded` gets the loaded
            // library as an Object argument.
            loader.succeeded += onLibraryLoaded;
            loader.failed += function (e:Object) :void { Debug.assert(false, ""+e); };
        }
        
        private function onLibraryLoaded(lib:Object) {
            var library = lib as Library;
            
            trace("Library loaded!");
            trace("Image symbols:", library.imageSymbols);
            trace("Movie symbols:", library.movieSymbols);
            
            // MovieCreator is a part of the example and it makes
            // it simpler to create movies that automatically add
            // themselves to a juggler when added onto the stage.
            movieCreator = new MovieCreator(library);
            
            // Removes the header movie if it exists already.
            if (header) {
                header.removeEventListeners(Event.ADDED_TO_STAGE);
                header.removeFromParent(true);
                header = null;
            }
            
            // Create the header walk animation, positioned at the top right.
            header = movieCreator.createMovie("walk");
            header.x = stage.stageWidth-120;
            header.y = 180;
            stage.addChild(header);
            
            // Remove the movie grid if it exists already.
            display.removeChildren(0, display.numChildren-1, true);
            movies.clear();
            
            // Create a grid of animations, rows being different animations,
            // columns having different speeds.
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
            // The base delta time for the middle base animation.
            var dt:Number = 1/60;
            // Defines how much faster/slower the very left and right animations are.
            var spread = 2;
            for (var mi:int = 0; mi < movies.length; mi++) {
                var manim:Vector.<Movie> = movies[mi];
                for (var i:int = 0; i < manim.length; i++) {
                    var m:Movie = manim[i];
                    // Mid-point of the different animation speeds.
                    var mid:Number = Math.floor(manim.length/2);
                    // Normalized offset of animation with spread.
                    var off:Number = (i-mid)/mid*spread;
                    // Modified delta time so that animations
                    // on the left are slower and animations
                    // on the right are faster.
                    var mdt:Number = off == 0 ? dt : off < 0 ? dt/(1-off) : dt*(1+off);
                    // Advance the movie time by the new modified delta time.
                    m.advanceTime(mdt);
                }
            }
            
            return super.onTick();
        }
        
    }
}