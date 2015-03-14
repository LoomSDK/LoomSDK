// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.display
{
    import loom2d.Loom2D;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAsyncLoadCompleteDelegate;
    import loom2d.animation.IAnimatable;
    import loom2d.display.MovieClip;


    /** An AsyncImage is an extension of Image that provides an interface to load its texture
     *  asynchronously, either via HTTP or from disk as an asset.  While it is waiting for loading
     *  to complete, it can display an animated MovieClip of the users choosing.
     *  
     */    
    public class AsyncImage extends Image implements IAnimatable
    {
        /** constants that track the status of the texture for this image */
        public static const TEXTURE_NOTLOADED  = 0;
        public static const TEXTURE_LOADING    = 1;
        public static const TEXTURE_LOADED     = 2;


        private var _loadingClip:MovieClip;
        private var _errorTexture:Texture;
        private var _width:int;
        private var _height:int;
        private var _asyncTexture:Texture;
        private var _loadingFrame0:Texture;
        private var _userAsyncLoadComplete:TextureAsyncLoadCompleteDelegate;
        private var _userHTTPLoadFail:Function;
        private var _textureStatus:int;


        /** Returns the current status of the texture load */
        public function get loadStatus():int { return _textureStatus; }

        /** Override for setting the texture on the Image, to make sure that the correct dimensions are set */
        override public function set texture(value:Texture):void 
        {
            if(super.texture != value)
            { 
                super.texture = value;
                setSize(_width, _height);
            }
        }

        
        /** Creates an Image that can manage it's own asynchronously loaded textures and display
         *  a loading animation via a MovieClip while the loading is happening.  It also uses
         *  a fixed width/height so that any image loaded into it will adhere to these predefined
         *  dimensions.
         *
         *  @param loadingAnim MovieClip to play while waiting for the texture to load. Can be null.
         *  @param errorTex Optional texture to display for the image if there was an error loading 
         *                 or if it was cancelled.
         *  @param width Fixed width of this image.
         *  @param width height height of this image.
         */
        public function AsyncImage(loadingAnim:MovieClip, errorTex:Texture, width:int, height:int)
        {
            _loadingClip = loadingAnim;
            _loadingFrame0 = (_loadingClip) ? _loadingClip.getFrameTexture(0) : null;
            _errorTexture = errorTex;
            _width = width;
            _height = height;
            _textureStatus = TEXTURE_NOTLOADED;
            _asyncTexture = null;

            //image starts with the 1st frame of the movie clip
            super(_loadingFrame0);

            //resize to be our desired size
            setSize(_width, _height);

            //add ourselves to the Juggler so we can update, but only if we have a MovieClip to update!
            if(_loadingClip != null)
            {
                Loom2D.juggler.add(this);
            }
        }

        /** custom dispose to handle internals before parent */
        public override function dispose()
        {
            //remove ourselves from the Juggler if necessary
            if(_loadingClip != null)
            {
                Loom2D.juggler.remove(this);
            }

            //Image dispose
            super.dispose();
        }
        

        /** Starts the asynchronous load of the specfied texture via an HTTPRequest. If the desired texture
         *  is already in memory, it will be returned immediately and the 'asyncLoadCompleteCB' will not be
         *  called.
         *
         *  @param url URL of the texture to load via HTTP.
         *  @param asyncLoadCompleteCB Custom callback to be triggered when the texture completes loading.
         *  @param httpLoadFailCB Custom callback to be triggered in the case of an HTTPRequest failure.
         *  @param cacheOnDisk Whether or not the texture should be cached on disk locally when it 
         *                    completes the HTTPRequest.
         *  @param highPriority Whether or not the texture should be inserted into the front of the async 
         *                     texture load queue, or slot in at the back.
         *  @return The Texture object that will hold the texture data upon load completion.
         */
        public function loadTextureFromHTTP(url:String, 
                                            asyncLoadCompleteCB:TextureAsyncLoadCompleteDelegate, 
                                            httpLoadFailCB:Function, 
                                            cacheOnDisk:Boolean, 
                                            highPriority:Boolean):Texture
        {
            //kick the HTTP request
            _userAsyncLoadComplete = asyncLoadCompleteCB;
            _userHTTPLoadFail = httpLoadFailCB;
            _asyncTexture = Texture.fromHTTP(url, onAsyncLoadComplete, onHTTPLoadFail, cacheOnDisk, highPriority);
            if(_asyncTexture == null)
            {
                //assign the error texture if one was given, otherwise go back to the 1st frame of the loading animation
                texture = (_errorTexture != null) ? _errorTexture : _loadingFrame0;
                _textureStatus = TEXTURE_NOTLOADED;
                return null;
            }

            //if it's already valid, it means that it was able to use an already cached 
            //texture so we don't need to wait for it to actually load now
            if(!_asyncTexture.isTextureValid())
            {
                //flag as loading and make sure that the clip is playing
                if(_loadingClip)
                {
                    _loadingClip.play();
                }
                _textureStatus = TEXTURE_LOADING;
            }
            else
            {
                //just update our texture now
                texture = _asyncTexture;
                _textureStatus = TEXTURE_LOADED;
            }            

            return _asyncTexture;
        }


        /** Starts the asynchronous load of the specfied texture as an asset from the local disk. If the 
         *  desired texture is already in memory, it will be returned immediately and the 'asyncLoadCompleteCB' 
         *  will not be called.
         *
         *  @param path Local path of the texture to load via the asset system.
         *  @param asyncLoadCompleteCB Custom callback to be triggered when the texture completes loading.
         *  @param highPriority Whether or not the texture should be inserted into the front of the async 
         *                     texture load queue, or slot in at the back.
         *  @return The Texture object that will hold the texture data upon load completion.
         */
        public function loadTextureFromAsset(path:String, 
                                             asyncLoadCompleteCB:TextureAsyncLoadCompleteDelegate, 
                                             highPriority:Boolean):Texture
        {
            //kick the HTTP request
            _userAsyncLoadComplete = asyncLoadCompleteCB;
            _asyncTexture = Texture.fromAssetAsync(path, onAsyncLoadComplete, highPriority);
            if(_asyncTexture == null)
            {
                //assign the error texture if one was given, otherwise go back to the 1st frame of the loading animation
                texture = (_errorTexture != null) ? _errorTexture : _loadingFrame0;
                return null;
            }

            //if it's already valid, it means that it was able to use an already cached 
            //texture so we don't need to wait for it to actually load now
            if(!_asyncTexture.isTextureValid())
            {
                //flag as loading and make sure that the clip is playing
                if(_loadingClip)
                {
                    _loadingClip.play();
                }
                _textureStatus = TEXTURE_LOADING;
            }
            else
            {
                //just update our texture now
                texture = _asyncTexture;
                _textureStatus = TEXTURE_LOADED;
            }            

            return _asyncTexture;
        }


        /** Used to cancel an in progress HTTP load started via loadTextureFromHTTP(). 
         *  Note that this will prevent the TextureAsyncLoadCompleteDelegate from being 
         *  called upon texture load completion. 
         */
        public function cancelHTTPLoad():void
        {
            _asyncTexture.cancelHTTPRequest();
            _textureStatus = TEXTURE_NOTLOADED;
            texture = (_errorTexture != null) ? _errorTexture : _loadingFrame0;
        }

        /** The internal callback that is triggered when async loading of the texture completed. */
        private function onAsyncLoadComplete(tex:Texture):void
        {
            //flag no longer loading
            _textureStatus = TEXTURE_LOADED;

            //set new texture
            texture = _asyncTexture;

            //call user callback
            if(_userAsyncLoadComplete != null)
            {
                _userAsyncLoadComplete(_asyncTexture);
            }
        }


        /** The internal callback that is triggered in cases where the HTTP loading of the texture fails. */
        private function onHTTPLoadFail():void
        {
            //flag no longer loading
            _textureStatus = TEXTURE_NOTLOADED;

            //assign the error texture if one was given, otherwise go back to the 1st frame of the loading animation
            texture = (_errorTexture != null) ? _errorTexture : _loadingFrame0;

            //call user callback
            if(_userHTTPLoadFail != null)
            {
                _userHTTPLoadFail();
            }
        }



        // IAnimatable
        
        /** @inheritDoc */
        private function advanceTime(passedTime:Number):void
        {
            //assign the latest texture from our clip to us if we are busy loading
            if(_textureStatus == TEXTURE_LOADING)
            {
                texture = _loadingClip.texture;
            }
        }
    }
}