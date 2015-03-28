//
// Flump - Copyright 2013 Flump Authors

package flump.mold {
    import flump.Flump;

/** @private */
public class LibraryMold
{
    // The frame rate of movies in this library
    public var frameRate :Number;

    // The MD5 of the published library SWF
    public var md5 :String;

    // the format of the atlases. Default is "png"
    public var textureFormat :String;

    public var movies :Vector.<MovieMold> = new <MovieMold>[];

    public var textureGroups :Vector.<TextureGroupMold> = new <TextureGroupMold>[];

    // True if this library is the result of combining multiple source FLAs
    public var isNamespaced :Boolean = false;

    public static function fromJSON (o :JSON) :LibraryMold {
        const mold :LibraryMold = new LibraryMold();
        mold.frameRate = Flump.requireNumber(o, "frameRate");
        mold.md5 = Flump.requireString(o, "md5");
        mold.textureFormat = o.getString("textureFormat"); if (mold.textureFormat == null || mold.textureFormat == "") mold.textureFormat = "png";
        mold.isNamespaced = o.getBoolean("isNamespaced"); // default false
        
        for each (var movie :JSON in Flump.requireVector(o, "movies")) mold.movies.push(MovieMold.fromJSON(movie));
        for each (var tg :JSON in Flump.requireVector(o, "textureGroups")) mold.textureGroups.push(TextureGroupMold.fromJSON(tg));
        return mold;
    }

    public function toJSON (_:Object) :Object {
        return {
            frameRate: frameRate,
            md5: md5,
            movies: movies,
            textureGroups: textureGroups,
            isNamespaced: isNamespaced
        };
    }

    public function bestTextureGroupForScaleFactor (scaleFactor :int) :TextureGroupMold {
        if (textureGroups.length == 0) {
            return null;
        }

        // sort by scale factor
        textureGroups.sort(function (a :TextureGroupMold, b :TextureGroupMold) :int {
            return compareInts(a.scaleFactor, b.scaleFactor);
        });

        // find the group with the highest scale factor <= our desired scale factor, if one exists
        for (var ii :int = textureGroups.length - 1; ii >= 0; --ii) {
            if (textureGroups[ii].scaleFactor <= scaleFactor) {
                return textureGroups[ii];
            }
        }

        // return the group with the smallest scale factor
        return textureGroups[0];
    }

    protected static function compareInts (a :int, b :int) :int {
        return (a > b) ? 1 : (a == b ? 0 : -1);
    }
}
}
