package flump.display {

import loom2d.display.DisplayObject;
import loom2d.display.Image;
import loom2d.textures.Texture;

class LibraryImpl implements Library {
    public function LibraryImpl (baseTextures :Vector.<Texture>, creators :Dictionary,
            isNamespaced :Boolean) {
        _baseTextures = baseTextures;
        _creators = creators;
        _isNamespaced = isNamespaced;
    }

    public function createMovie (symbol :String) :Movie {
        return Movie(createDisplayObject(symbol));
    }

    public function createImage (symbol :String) :Image {
        const disp :DisplayObject = createDisplayObject(symbol);
        Debug.assert(!(disp is Movie), symbol + " is not an Image");
        return Image(disp);
    }

    public function getImageTexture (symbol :String) :Texture {
        checkNotDisposed();
        var creator :SymbolCreator = requireSymbolCreator(symbol);
        Debug.assert(creator is ImageCreator, symbol + " is not an Image");
        return ImageCreator(creator).texture;
    }

    public function get movieSymbols () :Vector.<String> {
        checkNotDisposed();
        const names :Vector.<String> = new <String>[];
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is MovieCreator) names.push(creatorName);
        }
        return names;
    }

    public function get imageSymbols () :Vector.<String> {
        checkNotDisposed();
        const names :Vector.<String> = new <String>[];
        for (var creatorName :String in _creators) {
            if (_creators[creatorName] is ImageCreator) names.push(creatorName);
        }
        return names;
    }

    public function get isNamespaced () :Boolean {
        return _isNamespaced;
    }

    public function createDisplayObject (name :String) :DisplayObject {
        checkNotDisposed();
        return requireSymbolCreator(name).create(this);
    }

    public function dispose () :void {
        checkNotDisposed();
        for each (var tex :Texture in _baseTextures) {
            tex.dispose();
        }
        _baseTextures = null;
        _creators = null;
    }

    protected function requireSymbolCreator (name :String) :SymbolCreator {
        var creator :SymbolCreator = _creators[name];
        Debug.assert(creator != null, "No such id '" + name + "'");
        return creator;
    }

    protected function checkNotDisposed () :void {
        Debug.assert(_baseTextures != null, "This Library has been disposed");
    }

    protected var _creators :Dictionary.<String, SymbolCreator>;
    protected var _baseTextures :Vector.<Texture>;
    protected var _isNamespaced :Boolean;
}
}
