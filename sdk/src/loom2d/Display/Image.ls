package loom2d.display 
{
    
    import loom2d.textures.Texture;
    import loom2d.utils.VertexData;

    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.math.Matrix;
    
    /** An Image is a quad with a texture mapped onto it.
     *  
     *  The Image class is the Starling equivalent of Flash's Bitmap class. Instead of 
     *  BitmapData, Starling uses textures to represent the pixels of an image. To display a 
     *  texture, you have to map it onto a quad - and that's what the Image class is for.
     *  
     *  As "Image" inherits from "Quad", you can give it a color. For each pixel, the resulting  
     *  color will be the result of the multiplication of the color of the texture with the color of 
     *  the quad. That way, you can easily tint textures with a certain color. Furthermore, images 
     *  allow the manipulation of texture coordinates. That way, you can move a texture inside an 
     *  image without changing any vertex coordinates of the quad. You can also use this feature
     *  as a very efficient way to create a rectangular mask. 
     *  
     *  @see Loom.Textures.Texture
     *  @see Quad
     */ 

    [Native(managed)] 
    public native class Image extends Quad
    {
        private var mTexture:Texture;
        private var mVertexDataCache:VertexData;
        private var mVertexDataCacheInvalid:Boolean;
        private var _textureFile:String = null;
        private static var resultPoint:Point;
        
        public function Image(_texture:Texture = null):void
        {
            if(!_texture)
                _texture = Texture.fromAsset("assets/tile.png");

            Debug.assert(_texture, "Must provide a texture!");
        
            var frame:Rectangle = _texture.frame;
            var width:Number  = frame ? frame.width  : _texture.width;
            var height:Number = frame ? frame.height : _texture.height;
            var pma:Boolean = _texture.premultipliedAlpha;
            
            super(width, height, 0xffffff, pma);
            
            mVertexData.setTexCoords(0, 0.0, 0.0);
            mVertexData.setTexCoords(1, 1.0, 0.0);
            mVertexData.setTexCoords(2, 0.0, 1.0);
            mVertexData.setTexCoords(3, 1.0, 1.0);
            
            mTexture = _texture;

            nativeTextureID = mTexture.nativeID;

            mVertexDataCache = new VertexData(4, pma);
            mVertexDataCacheInvalid = true;
            nativeVertexDataInvalid = true;
            
        }
        
        /** @inheritDoc */
        protected override function onVertexDataChanged():void
        {
            mVertexDataCacheInvalid = true;
            nativeVertexDataInvalid = true;
        }
        
        
        /** Readjusts the dimensions of the image according to its current texture. Call this method 
         *  to synchronize image and texture size after assigning a texture with a different size.*/
        public function readjustSize():void
        {
            var frame:Rectangle = texture.frameReadOnly;
            var width:Number  = frame ? frame.width  : texture.width;
            var height:Number = frame ? frame.height : texture.height;
            
            mVertexData.setPosition(0, 0.0,   0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0,   height);
            mVertexData.setPosition(3, width, height); 
            
            onVertexDataChanged();
        }
        
        /** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
        public function setTexCoords(vertexID:int, coords:Point):void
        {
            mVertexData.setTexCoords(vertexID, coords.x, coords.y);
            onVertexDataChanged();
        }
        
        /** Gets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. 
         *  If you pass a 'resultPoint', the result will be stored in this point instead of 
         *  creating a new object.*/
        public function getTexCoords(vertexID:int):Point
        {            
            mVertexData.getTexCoords(vertexID, resultPoint);
            return resultPoint;
        }
        
        /** Copies the raw vertex data to a VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */ 
        public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            if (mVertexDataCacheInvalid)
            {
                mVertexDataCacheInvalid = false;
                mVertexData.copyTo(mVertexDataCache);
                mTexture.adjustVertexData(mVertexDataCache, 0, 4);
            }
            
            mVertexDataCache.copyTo(targetData, targetVertexID);
        }
        
        /** The texture that is displayed on the quad. */
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            Debug.assert(value != null, "Texture cannot be null!");
            
            if (value != mTexture)
            {
                if(mTexture)
                    mTexture.update -= onTextureUpdate;

                mTexture = value;

                if(mTexture)
                    mTexture.update += onTextureUpdate;

                if (mTexture)
                    nativeTextureID = mTexture.nativeID;
                    
                mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
                mVertexDataCache.setPremultipliedAlpha(mTexture.premultipliedAlpha, false);
                onVertexDataChanged();

                readjustSize();
            }
        }

        protected function onTextureUpdate():void
        {
            mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
            mVertexDataCache.setPremultipliedAlpha(mTexture.premultipliedAlpha, false);
            onVertexDataChanged();
            readjustSize();
        }

        public function set source(value:String):void
        {
            var tex = Texture.fromAsset(value);
            if(!tex)
            {
                trace("Image.set source - could not load texture '" + value + "'");
                return;
            }
            texture = tex;
        }
        
        /**
         * True means linear filtering is applied to textures; false means point filtering is used.
         */
        public function get smoothing():Boolean
        {
            return false;
        }
        
        public function set smoothing(value:Boolean):void
        {
            //TODO: smoothing
            Debug.assert( false, ".smoothing is not implemented on Image. Use loom2d.textures.Texture.smoothing instead." );
        }

        private function updateVertexData()
        {
            Debug.assert(mVertexDataCacheInvalid, "updateVertexData called with valid cache");
            mVertexDataCacheInvalid = false;
            mVertexData.copyTo(mVertexDataCache);
            mTexture.adjustVertexData(mVertexDataCache, 0, 4);
        }


        public function toString():String
        {
            return "[" + getTypeName() + " " + _textureFile + "]";
        }
    }
    
}