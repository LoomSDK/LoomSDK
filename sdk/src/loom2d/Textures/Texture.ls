// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.textures
{
    import loom2d.Loom2D;
    import system.utils.Base64;
    import loom.HTTPRequest;
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;

    import loom2d.events.Event;
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.textures.ConcreteTexture;
    
    import loom2d.utils.VertexData;

    delegate TextureUpdateDelegate();
    delegate TextureAsyncLoadCompleteDelegate(tex:Texture);
    delegate TextureHTTPFailDelegate(tex:Texture);

    /** A texture stores the information that represents an image. It cannot be added to the
     *  display list directly; instead it has to be mapped onto a display object. In Loom, 
     *  that display object is the class "Image".
     * 
     *  **Texture Formats**
     *  
     *  Loom uses stb_image to load images, which supports: JPEG, PNG, BMP, TGA, and PSD.
     *  
     *  **Mip Mapping**
     *  
     *  MipMaps are scaled down versions of a texture. When an image is displayed smaller than
     *  its natural size, the GPU may display the mip maps instead of the original texture. This
     *  reduces aliasing and accelerates rendering. It does, however, also need additional memory;
     *  for that reason, you can choose if you want to create them or not.  
     *  
     *  **Texture Frame**
     *  
     *  The frame property of a texture allows you let a texture appear inside the bounds of an
     *  image, leaving a transparent space around the texture. The frame rectangle is specified in 
     *  the coordinate system of the texture (not the image):
     *  
     *  ~~~as3
     *  var frame:Rectangle = new Rectangle(-10, -10, 30, 30); 
     *  var texture:Texture = Texture.fromTexture(anotherTexture, null, frame);
     *  var image:Image = new Image(texture);
     *  ~~~
     *  
     *  This code would create an image with a size of 30x30, with the texture placed at 
     *  `x=10, y=10` within that image (assuming that 'anotherTexture' has a width and 
     *  height of 10 pixels, it would appear in the middle of the image).
     *  
     *  The texture atlas makes use of this feature, as it allows to crop transparent edges
     *  of a texture and making up for the changed size by specifying the original texture frame.
     *  Tools like [TexturePacker](http://www.texturepacker.com/) use this to  
     *  optimize the atlas.
     * 
     *  **Texture Coordinates**
     *  
     *  If, on the other hand, you want to show only a part of the texture in an image
     *  (i.e. to crop the the texture), you can either create a subtexture (with the method 
     *  'Texture.fromTexture()' and specifying a rectangle for the region), or you can manipulate 
     *  the texture coordinates of the image object. The method 'image.setTexCoords' allows you 
     *  to do that.
     *  
     *  @see Loom.Display.Image
     *  @see TextureAtlas
     */ 
    public class Texture
    {
        public static var DownloadTempPostfix = ".part";
        
        public var mFrame:Rectangle;

        /**
         * See @TextureSmoothing for modes
         */        
        protected var mSmoothing:int = TextureSmoothing.defaultSmoothing;
        
        /**
         * See @TextureWrap for modes
         */        
        protected var mWrapU:int = TextureWrap.defaultWrap;
        
        /**
         * See @TextureWrap for modes
         */        
        protected var mWrapV:int = TextureWrap.defaultWrap;
        
        /** helper object */
        private static var sOrigin:Point = new Point();

        /** 
         * Information for the texture from the loaded Texture2D Asset. 
         */
        protected var textureInfo:TextureInfo;

        /**
         * Fired when the texture's state has updated.
         */
        public var update:TextureUpdateDelegate;
        
        /**
         * For asynchonously loaded Textures, fired when the texture has completed loading its data.
         * Note that if texture.dispose() is called before the async load has completed, the texture
         * will be destroyed and 'asyncLoadComplete' will NOT get called.
         */
        public var asyncLoadComplete:TextureAsyncLoadCompleteDelegate;

        /**
         * For HTTP requested Textures, fired if the texture has failed to load.
         */
        public var httpLoadFail:TextureHTTPFailDelegate;

        /*
         * Tracks the HTTPRequest object being used to load this Texture if it was via HTTP.
         */
        protected var httpRequest:HTTPRequest;

        /*
         * Indicates that we which to stop the current HTTP load request of this texture ASAP.
         */
        protected var mCancelHTTP:Boolean;
        

        /** @private */
        public function Texture()
        {
            Debug.assert(getType() != Texture, "Texture is abstract; please use a subclass like ConcreteTexture or SubTexture.");
        }
        
        /** Disposes the underlying texture data. Note that not all textures need to be disposed: 
         *  SubTextures (created with 'Texture.fromTexture') just reference other textures and
         *  and do not take up resources themselves; this is also true for textures from an 
         *  atlas. */
        public function dispose():void
        { 
            // override in subclasses
            if (textureInfo)
            {
                Texture2D.dispose(textureInfo.id);    
            }

            textureInfo = null;

            // Remove from the cache.
            if(this is ConcreteTexture)
            {
                var path = (this as ConcreteTexture).assetPath;
                if(path != null)
                {
                    assetPathCache[path] = null;
                }
            }
        }

        public function get nativeID():int
        {
            if (!textureInfo)
            {
                return -1;
            }

            return textureInfo.id;
        }
        
        protected static var assetPathCache = new Dictionary.<String, Texture>();

        /** vector of supported image type extensions, as defined by the asset system */
        protected static var supportedImageTypes:Vector.<String> = [".jpg", ".jpeg", ".bmp", ".png", ".psd", ".pic", ".tga", ".gif"];


        /** Checks the handle ID of the textureInfo to see if the texture is valid and ready for use. */
        public function isTextureValid():Boolean
        {
            return ((textureInfo == null) || 
                    (textureInfo.handleID == TextureInfo.HANDLE_INVALID) ||
                    (textureInfo.handleID == TextureInfo.HANDLE_LOADING) ||
                    (!textureInfo.visible)) ? false : true;
        }

        /** Blocking function that creates a texture object from a bitmap on disk. */
        public static function fromAsset(path:String):Texture
        {
            if(assetPathCache[path])
                return assetPathCache[path];

            var textureInfo = Texture2D.initFromAsset(path);
            if(textureInfo == null)
            {
                Console.print("WARNING: Unable to load texture from asset: " + path); 
                return null;
            }

            // And set up the concrete texture.
            var tex:ConcreteTexture = new ConcreteTexture(path, textureInfo.width, textureInfo.height);
            tex.mFrame = new Rectangle(0, 0, textureInfo.width, textureInfo.height);
            tex.setTextureInfo(textureInfo);
            assetPathCache[path] = tex;
            return tex;
        }
    
        /** Non-blocking function that creates a texture object from a bitmap file on disk. */
        public static function fromAssetAsync(path:String, cb:TextureAsyncLoadCompleteDelegate, highPriority:Boolean=false):Texture
        {
            //if already cached, just return that texture without calling the CB
            if(assetPathCache[path])
            {
                return assetPathCache[path];
            }

            //kick off the async load and return our holding texture
            var textureInfo = Texture2D.initFromAssetAsync(path, highPriority);
            if(textureInfo == null)
            {
                Console.print("WARNING: Unable to load texture from asset: " + path); 
                return null;
            }

            //create the ConcreteTexture, but don't fill it out fully as we don't have all of the TextureInfo yet!
            var tex:ConcreteTexture = new ConcreteTexture(path, -1, -1);
            tex.textureInfo = textureInfo;
            assetPathCache[path] = tex;

            //set up delgates to be called
            tex.asyncLoadComplete = cb;
            textureInfo.asyncLoadComplete += tex.onAsyncLoadComplete;

            return tex;
        }
        
        public function updateFromHTTP(url:String, 
                                        onSuccess:TextureAsyncLoadCompleteDelegate, 
                                        onFailure:TextureHTTPFailDelegate,
                                        cacheOnDisk:Boolean=true, 
                                        highPriority:Boolean=false)
        {
            Texture.fromHTTP(url, onSuccess, onFailure, cacheOnDisk, highPriority, this);
        }

        /** Non-blocking function that creates a texture object from a remote bitmap file via HTTP. */
        public static function fromHTTP(url:String, 
                                        onSuccess:TextureAsyncLoadCompleteDelegate, 
                                        onFailure:TextureHTTPFailDelegate,
                                        cacheOnDisk:Boolean=true, 
                                        highPriority:Boolean=false,
                                        existingTexture:Texture = null):Texture
        {
            //turn the url into an SHA2 so we have a nice small but unique filename to save to disk
            var urlsha2:String = url.toSHA2();

            //if already cached, just return that texture without calling the CB
            if(!existingTexture && assetPathCache[urlsha2])
            {
                return assetPathCache[urlsha2];
            }

            //make sure that the image requested is one of our supported image types!
            var ext:String = null;
            for(var i=0;i<supportedImageTypes.length;i++)
            {
                if(url.indexOf(supportedImageTypes[i]) != -1)
                {
                    ext = supportedImageTypes[i];
                    break;
                }
            }
            if(ext == null)
            {
                Console.print("WARNING: Unsuppported image format requested at url: " + url); 
                return null;
            }

            //build the local cache folder path and create it on disk if it doesn't exist yet
            var cacheFile:String = null;
            if (cacheOnDisk) {
                var writePath:String = Path.normalizePath(Path.getWritablePath() + "/TextureCache");
                if(!Path.dirExists(writePath))
                {
                    Path.makeDir(writePath);
                }
                
                var prenorm = writePath + "/" + urlsha2 + ext;
                cacheFile = Path.normalizePath(prenorm);
                
                // check if file already cached locally
                if (File.fileExists(cacheFile))
                {
                    //file already downloaded previously, so queue up an async load of it right now
                    Debug.assert(existingTexture == null, "Texture update from file cache currently unsupported");
                    return Texture.fromAssetAsync(cacheFile, onSuccess);
                }
            }
            
            var tex:Texture = null;
            if (existingTexture == null) {
                //create the ConcreteTexture, but don't fill it out fully as we don't have all of the TextureInfo yet!
                tex = new ConcreteTexture(urlsha2, -1, -1);
                assetPathCache[urlsha2] = tex;
            } else {
                tex = existingTexture;
                if (tex.textureInfo) tex.textureInfo.visible = false;
            }

            //create and fire off the HTTPRequest
            tex.httpLoadFail = onFailure;
            sendHTTPTextureRequest(url, urlsha2, cacheFile, tex, onSuccess, cacheOnDisk, highPriority, existingTexture ? existingTexture.nativeID : -1);
            return tex;
        }

        // TODO: Update supported types
        /** Creates a texture object from compressed image bytes.  An optional unique name string 
         *  can be supplied if you wish the resulting image to be cacheable, otherwise null can be specified.
         * 
         *  The supported image types are JPEG (baseline), PNG (8-bit),
         *  TGA, BMP (non-1bpp, non-RLE), PSD (composited only), GIF,
         *  HDR (radiance rgbE), PIC (Softimage).
         */
        public static function fromBytes(bytes:ByteArray, uniqueName:String=null):Texture
        {
            //if already cached, just return that texture without calling the CB
            if(!String.isNullOrEmpty(uniqueName))
            {        
                if(assetPathCache[uniqueName])
                {
                    return assetPathCache[uniqueName];
                }
            }

            var textureInfo = Texture2D.initFromBytes(bytes, uniqueName);
            if(textureInfo == null)
            {
                Console.print("WARNING: Unable to load texture from bytes"); 
                return null;
            }
            
            // And set up the concrete texture.
            var tex:ConcreteTexture = new ConcreteTexture(uniqueName, textureInfo.width, textureInfo.height);
            tex.mFrame = new Rectangle(0, 0, textureInfo.width, textureInfo.height);
            tex.setTextureInfo(textureInfo);
            if(!String.isNullOrEmpty(uniqueName))
            {        
                assetPathCache[uniqueName] = tex;
            }
            return tex;
        }
        
        /** Creates an empty texture of a certain size.
         *  Beware that the texture can only be used after you either upload some color data
         *  ("texture.root.upload...") or clear the texture ("texture.root.clear()").
         *
         *  @param width   in points; number of pixels depends on scale parameter
         *  @param height  in points; number of pixels depends on scale parameter
         *  @param premultipliedAlpha  the PMA format you will use the texture with. If you will
         *                 use the texture for bitmap data, use "true"; for ATF data, use "false".
         *  @param mipMapping  indicates if mipmaps should be used for this texture. When you upload
         *                 bitmap data, this decides if mipmaps will be created; when you upload ATF
         *                 data, this decides if mipmaps inside the ATF file will be displayed.
         *  @param optimizeForRenderToTexture  indicates if this texture will be used as render target
         *  @param scale   if you omit this parameter, 'Starling.contentScaleFactor' will be used.
         *  @param format  the context3D texture format to use. Pass one of the packed or
         *                 compressed formats to save memory (at the price of reduced image quality).
         *  @param repeat  the repeat mode of the texture. Only useful for power-of-two textures.
         */
        public static function empty(width:Number, height:Number, premultipliedAlpha:Boolean=true,
                                     mipMapping:Boolean=true, optimizeForRenderToTexture:Boolean=false,
                                     scale:Number=-1, format:String="bgra", repeat:Boolean=false):Texture
        {
            if (scale <= 0) scale = Loom2D.contentScaleFactor;

            var actualWidth:int, actualHeight:int;
            
            var origWidth:Number  = width  * scale;
            var origHeight:Number = height * scale;
            var useRectTexture:Boolean = true;

            actualWidth  = Math.ceil(origWidth  - 0.000000001); // avoid floating point errors
            actualHeight = Math.ceil(origHeight - 0.000000001);
                
            var concreteTexture:ConcreteTexture = new ConcreteTexture("", actualWidth, actualHeight, optimizeForRenderToTexture);
            concreteTexture.mFrame = new Rectangle(0, 0, actualWidth, actualHeight);
            concreteTexture.setTextureInfo(Texture2D.initEmptyTexture(actualWidth, actualHeight));
            
            if (actualWidth - origWidth < 0.001 && actualHeight - origHeight < 0.001)
                return concreteTexture;
            else
                return new SubTexture(concreteTexture, new Rectangle(0, 0, width, height), true);
        }
        
        /** Creates a texture that contains a region (in pixels) of another texture. The new
         *  texture will reference the base texture; no data is duplicated. */
        public static function fromTexture(texture:Texture, region:Rectangle=null, frame:Rectangle=null):Texture
        {
            var subTexture:SubTexture = new SubTexture(texture, region);
            subTexture.mFrame = frame;
            subTexture.setTextureInfo(texture.textureInfo);
            return subTexture;
        }
        
        /** Converts texture coordinates and vertex positions of raw vertex data into the format 
         *  required for rendering. */
        public function adjustVertexData(vertexData:VertexData, vertexID:int, count:int):void
        {
            if (mFrame)
            {
                Debug.assert (count == 4, "Textures with a frame can only be used on quads");
                
                var deltaRight:Number  = mFrame.width  + mFrame.x - width;
                var deltaBottom:Number = mFrame.height + mFrame.y - height;
                
                vertexData.translateVertex(vertexID,     -mFrame.x, -mFrame.y);
                vertexData.translateVertex(vertexID + 1, -deltaRight, -mFrame.y);
                vertexData.translateVertex(vertexID + 2, -mFrame.x, -deltaBottom);
                vertexData.translateVertex(vertexID + 3, -deltaRight, -deltaBottom);
            }
        }
        
        // properties
        
        /** The texture frame (see class description). */
        public function get frame():Rectangle 
        { 
            return mFrame ? mFrame.clone() : new Rectangle(0, 0, width, height);
            
            // the frame property is readonly - set the frame in the 'fromTexture' method.
            // why is it readonly? To be able to efficiently cache the texture coordinates on
            // rendering, textures need to be immutable.
        }

        private static var tmpRect:Rectangle = new Rectangle();

        /** 
          *  The texture frame as a read only temporary Rectangle 
          *  The returned Rectangle is only valid between calls.
          */
        public function get frameReadOnly():Rectangle 
        { 
            if (mFrame)
            {
                tmpRect.x = mFrame.x;
                tmpRect.y = mFrame.y;
                tmpRect.width = mFrame.width;
                tmpRect.height = mFrame.height;
                return tmpRect;
            }

            tmpRect.x = 0;
            tmpRect.y = 0;
            tmpRect.width = width;
            tmpRect.height = height;
            return tmpRect;
        }


        /**
          *  Helper function to warn about dodgy wrap mode usage
          */
        private function wrapModeWarning(mode:int):void
        {
            if(mode != TextureWrap.CLAMP)
            {
                if(!(this is ConcreteTexture))
                {
                    Console.print("WARNING: Use of TextureWrap other than CLAMP on a Texture that is not a ConcreteTexture will probably not do what you expect: " + assetPath); 
                }
                else if(!Math.isPowerOf2(width) || !Math.isPowerOf2(height))
                {
                    Console.print("WARNING: Use of TextureWrap other than CLAMP on a Non Power of 2 Texture is not advised: " + assetPath); 
                }
            }            
        }


        /** Delegate that is called to finalize the initialization of an asynchronously loaded texture */
        private function onAsyncLoadComplete():void
        {
            Debug.assert(textureInfo);
            
            //remove ourselves from the delegate
            if (textureInfo) textureInfo.asyncLoadComplete -= onAsyncLoadComplete;

            //if the HTTP request was cancelled after it completed, but prior to the async load completion, we need to dispose of it now
            if(mCancelHTTP)
            {
                if (textureInfo && textureInfo.visible) dispose();
                return;
            }
            
            if (textureInfo) textureInfo.visible = true;

            //check for errors
            if(isTextureValid())
            {
                // Complete the filling in of our ConcreateTexture data
                mFrame = new Rectangle(0, 0, textureInfo.width, textureInfo.height);
                root.setTextureInfo(textureInfo);
            }
            else
            {
                Console.print("WARNING: Unable to asynchronously load texture from asset"); 
            }

            //call our assigned load complete callback
            if(asyncLoadComplete != null)
            {
                asyncLoadComplete(this);
                asyncLoadComplete = null;
            }
        }       


        /** Helper function that handles HTTP Texture Requests and the onSuccess/onFailure delegates */
        private static function sendHTTPTextureRequest(url:String, 
                                                        urlsha2:String,
                                                        cacheFile:String, 
                                                        tex:Texture,
                                                        onSuccess:TextureAsyncLoadCompleteDelegate, 
                                                        cacheOnDisk:Boolean,
                                                        highPriority:Boolean,
                                                        existingNativeID:int = -1):void
        {
            //create the HTTPRequest to obtain the texture data remotely
            var req:HTTPRequest = new HTTPRequest(url);
            req.method = "GET";
            req.cacheFileName = (cacheOnDisk) ? (cacheFile + DownloadTempPostfix) : null;

            //setup onSuccess
            var success:Function = function(result:ByteArray):void
            {
                var tInfo:TextureInfo = null;
                //Console.print("Successfull download of HTTP texture from url: " + url); 

                //remove reference to the request so it can now be GCed
                tex.httpRequest = null;

                //were we cancelled while off busy with the HTTP?
                if(tex.mCancelHTTP)
                {
                    // We don't have to and probably shouldn't remove the
                    // file here, because it's at a temporary path and will
                    // get overwritten anyway.
                }
                else
                {
                    //cached or non-cached
                    if(cacheOnDisk)
                    {
                        File.move(req.cacheFileName, cacheFile);
                    }
                    //load the bytes Async
                    if (existingNativeID  == -1) {
                        tInfo = Texture2D.initFromBytesAsync(result, urlsha2, highPriority);
                        if(tInfo == null)
                        {
                            Console.print("WARNING: Unable to load texture from bytes given data from url: " + url); 
                        }
                    } else {
                        //Texture2D.updateFromBytes(existingNativeID, texBytes);
                        Texture2D.updateFromBytesAsync(existingNativeID, result, highPriority);
                        tInfo = tex.textureInfo;
                    }
                }
                
                //unable to create our textureInfo so we failed
                if(tInfo == null)
                {                  
                    //dispose the texture and call the failure delegate (don't call onFailure if the load was cancelled)
                    if((tex.httpLoadFail != null) && (!tex.mCancelHTTP))
                    {
                        tex.httpLoadFail(tex);
                    }
                    if (existingNativeID == -1) tex.dispose();
                    return;
                }
                
                //register the textureInfo and async complete CB
                tex.textureInfo = tInfo;
                tex.asyncLoadComplete = onSuccess;
                tInfo.asyncLoadComplete += tex.onAsyncLoadComplete;
            };
            req.onSuccess += success;


            //setup onFailure
            var fail:Function = function(result:ByteArray):void
            {
                //Console.print("ERROR: Failed download of HTTP texture from url: " + url);
                //remove reference to the request so it can now be GCed
                tex.httpRequest = null;

                //dispose the texture and call the failure delegate (don't call onFailure if the load was cancelled)
                if((tex.httpLoadFail != null) && (!tex.mCancelHTTP))
                {
                    tex.httpLoadFail(tex);
                }
                if (existingNativeID == -1) tex.dispose();
            };       
            req.onFailure += fail;

            //store and fire off the HTTP request now
            tex.httpRequest = req;
            tex.httpRequest.send();
        }

        /** Called to indicate that an HTTP texture load via fromHTTP() should be 
          * cancelled at the 1st possible opportunity.  NOTE that this will also dipose
          * the Texture returned by fromHTTP(), so consider it invalid after calling this.
          */
        public function cancelHTTPRequest():void 
        { 
            if(httpRequest != null)
            {
                httpRequest.cancel();
            }
            mCancelHTTP = true;
        }

        /** 
          *  Indicates if the texture do smooth filtering when it is scaled (BILINEAR) or just choose the nearest pixel (NONE)
          *  @default TextureSmoothing.BILINEAR
          */
        public function get smoothing():int { return mSmoothing; }
        public function set smoothing(mode:int)
        {
            mSmoothing = mode;

            if (textureInfo)
                textureInfo.smoothing = mode;
        }

        /** 
          *  Indicates if the texture should repeat like a wallpaper or stretch the outermost horizontal pixels.
          *  Note: this only works in textures with dimensions that are powers of two and 
          *  that are not loaded from a texture atlas (i.e. no subtextures). 
          *  @default TextureWrap.CLAMP
          */
        public function get wrapU():int { return mWrapU; }
        public function set wrapU(mode:int)
        {
            mWrapU = mode;

            if (textureInfo)
                textureInfo.wrapU = mode;

            ///warn if texture is NPOT or isn't a ConcreteTexture!
            wrapModeWarning(mode);
        }

        /** 
          *  Indicates if the texture should repeat like a wallpaper or stretch the outermost vertical pixels.
          *  Note: this only works in textures with dimensions that are powers of two and 
          *  that are not loaded from a texture atlas (i.e. no subtextures). 
          *  @default TextureWrap.CLAMP
          */
        public function get wrapV():int { return mWrapV; }
        public function set wrapV(mode:int)
        {
            mWrapV = mode;

            if (textureInfo)
                textureInfo.wrapV = mode;

            ///warn if texture is NPOT or isn't a ConcreteTexture!
            wrapModeWarning(mode);
        }

        /** The width of the texture in points. */
        public function get width():Number { return 0; }
        
        /** The height of the texture in points. */
        public function get height():Number { return 0; }

        /** The width of the texture in pixels (without scale adjustment). */
        public function get nativeWidth():Number { return 0; }
        
        /** The height of the texture in pixels (without scale adjustment). */
        public function get nativeHeight():Number { return 0; }
        
        /** The scale factor, which influences width and height properties. */
        public function get scale():Number { return 1.0; }
        
        /** The Stage3D texture object the texture is based on. */
        //public function get base():TextureBase { return null; }
        
        /** The concrete (power-of-two) texture the texture is based on. */
        public function get root():ConcreteTexture { return null; }
        
        /** Indicates if the texture contains mip maps. */ 
        public function get mipMapping():Boolean { return true; }
        
        /** Indicates if the alpha values are premultiplied into the RGB values. */
        public function get premultipliedAlpha():Boolean { return false; }

        /** Returns the path of the texture asset */
        public function get assetPath():String { return ""; }
    }
}