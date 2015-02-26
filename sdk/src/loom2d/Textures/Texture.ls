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
    import loom.graphics.Texture2D;
    import loom.graphics.TextureInfo;

    import loom2d.events.Event;
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    import loom2d.textures.ConcreteTexture;
    
    import loom2d.utils.VertexData;

    delegate TextureUpdateDelegate();

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
        protected var mFrame:Rectangle;

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

        public var textureInfo:TextureInfo;

        /**
         * Fired when the texture's state has updated.
         */
        public var update:TextureUpdateDelegate;
        
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
                assetPathCache[(this as ConcreteTexture).assetPath] = null;
            
        }

        public function get nativeID():int
        {
            if (!textureInfo)
                return -1;

            return textureInfo.id;
        }
        
        protected static var assetPathCache = new Dictionary.<String, Texture>();

        /** Creates a texture object from a bitmap. */
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
        
        /** Creates a texture object from compressed image bytes.
         * 
         *  The supported image types are JPEG (baseline), PNG (8-bit),
         *  TGA, BMP (non-1bpp, non-RLE), PSD (composited only), GIF,
         *  HDR (radiance rgbE), PIC (Softimage).
         */
        public static function fromBytes(bytes:ByteArray):Texture
        {
            var textureInfo = Texture2D.initFromBytes(bytes);
            if(textureInfo == null)
            {
                Console.print("WARNING: Unable to load texture from bytes"); 
                return null;
            }
            
            // And set up the concrete texture.
            var tex:ConcreteTexture = new ConcreteTexture("", textureInfo.width, textureInfo.height);
            tex.mFrame = new Rectangle(0, 0, textureInfo.width, textureInfo.height);
            tex.setTextureInfo(textureInfo);
            return tex;
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