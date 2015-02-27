//
// Flump - Copyright 2013 Flump Authors

package {

import flump.display.Library;
import flump.display.Movie;
import loom2d.Loom2D;

import loom2d.animation.Juggler;
import loom2d.events.Event;

/**
 * Movie creation and Juggler management
 */
public class MovieCreator
{
    /**
     * Creates a new MovieCreator instance associated with the given library and Juggler
     * If Juggler is not specified, the MovieCreator will use the default Starling Juggler.
     */
    public function MovieCreator (library :Library, juggler :Juggler = null) {
        _library = library;
        _juggler = juggler == null ? Loom2D.juggler : juggler;
    }

    /**
     * Creates a new movie instance from the library. The movie will be added to the juggler
     * when it's added to the stage. Movies automatically remove themselves from their
     * jugglers when removed from the stage.
     */
    public function createMovie (name :String) :Movie {
        var movie :Movie = _library.createMovie(name);
        var listener:Function = function(e :Event) :void {
            e.target.removeEventListener(e.type, listener);
            _juggler.add(movie);
        };
        movie.addEventListener(Event.ADDED_TO_STAGE, listener);
        return movie;
    }

    public function get library () :Library {
        return _library;
    }

    protected var _library :Library;
    protected var _juggler :Juggler;
}
}
