package flump.display {

import flump.mold.MovieMold;

import loom2d.display.DisplayObject;

public class MovieCreator
    implements SymbolCreator
{
    public var mold :MovieMold;
    public var frameRate :Number;

    public function MovieCreator (mold :MovieMold, frameRate :Number) {
        this.mold = mold;
        this.frameRate = frameRate;
    }

    public function create (library :Library) :DisplayObject {
        return new Movie(mold, frameRate, library);
    }
}
}
