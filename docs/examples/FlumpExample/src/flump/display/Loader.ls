//
// Flump - Copyright 2013 Flump Authors

package flump.display {

import deng.fzip.FZip;
import deng.fzip.FZipErrorEvent;
import deng.fzip.FZipEvent;
import deng.fzip.FZipFile;
import loom2d.Loom2D;

import loom2d.events.Event;
//import loom2d.events.IOErrorEvent;
//import loom2d.events.ProgressEvent;
import loom2d.math.Point;
import loom2d.math.Rectangle;
//import loom2d.net.URLRequest;

import flump.executor.Executor;
import flump.executor.Future;
import flump.executor.FutureTask;
//import flump.executor.load.ImageLoader;
//import flump.executor.load.LoadedImage;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;
import flump.mold.TextureGroupMold;

import loom2d.textures.Texture;

class Loader {
    public function Loader (toLoad :Object, libLoader :LibraryLoader) {
        _scaleFactor = (libLoader.scaleFactor > 0 ? libLoader.scaleFactor :
            Loom2D.contentScaleFactor);
        _libLoader = libLoader;
        _toLoad = toLoad;
    }

    public function load (future :FutureTask) :void {
        _future = future;

        _zip.addEventListener(Event.COMPLETE, onZipLoadingComplete);
        //_zip.addEventListener(IOErrorEvent.IO_ERROR, _future.fail);
        _zip.addEventListener(FZipErrorEvent.PARSE_ERROR, _future.fail);
        _zip.addEventListener(FZipEvent.FILE_LOADED, onFileLoaded);
        //_zip.addEventListener(ProgressEvent.PROGRESS, _future.monitoredCallback(onProgress));

        //if (_toLoad is String) _zip.load(new URLRequest(String(_toLoad)));
        //else
        
        if (!(_toLoad is ByteArray)) Debug.assert("Non-ByteArray loading not supported");
        
        trace("LOAD "+_toLoad);
        
        _zip.loadBytes(ByteArray(_toLoad));
    }

    //protected function onProgress (e :ProgressEvent) :void {
        //_libLoader.urlLoadProgressed.emit(e);
    //}

    protected function onFileLoaded (e :FZipEvent) :void {
        const loaded :FZipFile = _zip.removeFileAt(_zip.getFileCount() - 1);
        const name :String = loaded.filename;
        if (name == LibraryLoader.LIBRARY_LOCATION) {
            const jsonString :String = loaded.content.readUTFBytes(loaded.content.length);
            _lib = LibraryMold.fromJSON(JSON.parse(jsonString));
            _libLoader.libraryMoldLoaded(_lib);
        } else if (name.indexOf(PNG, name.length - PNG.length) != -1) {
            _atlasBytes[name] = loaded.content;
        } else if (name.indexOf(ATF, name.length - ATF.length) != -1) {
            _atlasBytes[name] = loaded.content;
            _libLoader.atfAtlasLoaded({name: name, bytes: loaded.content});
        } else if (name == LibraryLoader.VERSION_LOCATION) {
            const zipVersion :String = loaded.content.readUTFBytes(loaded.content.length);
            if (zipVersion != LibraryLoader.VERSION) {
                Debug.assert("Zip is version " + zipVersion + " but the code needs " +
                    LibraryLoader.VERSION);
            }
            _versionChecked = true;
        } else if (name == LibraryLoader.MD5_LOCATION ) { // Nothing to verify
        } else {
            _libLoader.fileLoaded({name: name, bytes: loaded.content});
        }
    }

    protected function onZipLoadingComplete (..._) :void {
        _zip = null;
        if (_lib == null) Debug.assert(LibraryLoader.LIBRARY_LOCATION + " missing from zip");
        if (!_versionChecked) Debug.assert(LibraryLoader.VERSION_LOCATION + " missing from zip");
        //const loader :ImageLoader = _lib.textureFormat == "atf" ? null : new ImageLoader();
        _pngLoaders.terminated += onPngLoadingComplete;

        // Determine the scale factor we want to use
        var textureGroup :TextureGroupMold = _lib.bestTextureGroupForScaleFactor(_scaleFactor);
        if (textureGroup != null) {
            for each (var atlas :AtlasMold in textureGroup.atlases) {
                loadAtlas(atlas);
            }
        }
        // free up extra atlas bytes immediately
        for (var leftover :String in _atlasBytes) {
            if (_atlasBytes.hasOwnProperty(leftover)) {
                ByteArray(_atlasBytes[leftover]).clear();
                _atlasBytes.deleteKey(leftover);
                //delete (_atlasBytes[leftover]);
            }
        }
        trace("HERE!");
        _pngLoaders.shutdown();
    }

    protected function loadAtlas ( atlas :AtlasMold) :void {
        const bytes :ByteArray = _atlasBytes[atlas.file];
        _atlasBytes.deleteKey(atlas.file);
        //delete _atlasBytes[atlas.file];
        if (bytes == null) {
            Debug.assert("Expected an atlas '" + atlas.file + "', but it wasn't in the zip");
        }
        
        bytes.position = 0; // reset the read head
        var scale :Number = atlas.scaleFactor;
        
        baseTextureLoaded(Texture.fromBytes(bytes), atlas);
        
        /*
        if (_lib.textureFormat == "atf") {
            baseTextureLoaded(Texture.fromAtfData(bytes, scale, _libLoader.generateMipMaps), atlas);
            if (!Starling.handleLostContext) {
                ByteArray(bytes).clear();
            }
        } else {
            const atlasFuture :Future = loader.loadFromBytes(bytes, _pngLoaders);
            atlasFuture.failed.connect(onPngLoadingFailed);
            atlasFuture.succeeded.connect(function (img :LoadedImage) :void {
                _libLoader.pngAtlasLoaded.emit({atlas: atlas, image: img});
                baseTextureLoaded(Texture.fromBitmapData(
                    img.bitmapData,
                    _libLoader.generateMipMaps,
                    false,  // optimizeForRenderToTexture
                    scale), atlas);
                if (!Starling.handleLostContext) {
                    img.bitmapData.dispose();
                }
                ByteArray(bytes).clear();
            });

        }
        */
    }

    protected function baseTextureLoaded (baseTexture :Texture, atlas :AtlasMold) :void {
        _baseTextures.push(baseTexture);

        _libLoader.creatorFactory.consumingAtlasMold(atlas);
        var scale :Number = atlas.scaleFactor;
        for each (var atlasTexture :AtlasTextureMold in atlas.textures) {
            var bounds :Rectangle = atlasTexture.bounds;
            var offset :Point = atlasTexture.origin;

            // Starling expects subtexture bounds to be unscaled
            if (scale != 1) {
                bounds = bounds.clone();
                bounds.x /= scale;
                bounds.y /= scale;
                bounds.width /= scale;
                bounds.height /= scale;

                offset = offset.clone();
                offset.x /= scale;
                offset.y /= scale;
            }

            trace("BASE TEXTURE LOADED", atlasTexture.symbol, atlasTexture, baseTexture, bounds, offset);
            _creators[atlasTexture.symbol] = _libLoader.creatorFactory.createImageCreator(
                atlasTexture,
                Texture.fromTexture(baseTexture, bounds),
                offset,
                atlasTexture.symbol);
        }
    }

    protected function onPngLoadingComplete (e:Executor) :void {
        for each (var movie :MovieMold in _lib.movies) {
            movie.fillLabels();
            _creators[movie.id] = _libLoader.creatorFactory.createMovieCreator(
                movie, _lib.frameRate);
        }
        _future.succeed(new LibraryImpl(_baseTextures, _creators, _lib.isNamespaced));
    }

    protected function onPngLoadingFailed (e :Object) :void {
        if (_future.isComplete) return;
        _future.fail(e);
        _pngLoaders.shutdownNow();
    }

    protected var _toLoad :Object;
    protected var _scaleFactor :Number;
    protected var _libLoader :LibraryLoader;
    protected var _future :FutureTask;
    protected var _versionChecked :Boolean;

    protected var _zip :FZip = new FZip();
    protected var _lib :LibraryMold;

    protected const _baseTextures :Vector.<Texture> = new <Texture>[];
    protected const _creators = new Dictionary.<String, SymbolCreator>();//<name, ImageCreator/MovieCreator>
    protected const _atlasBytes = new Dictionary.<String, ByteArray>();//<String name, ByteArray>
    protected const _pngLoaders :Executor = new Executor(1);

    protected static const PNG :String = ".png";
    protected static const ATF :String = ".atf";
}
}
