/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.events.FeathersEventType;

    import loom2d.math.Matrix;
    import loom2d.math.Rectangle;

    import loom2d.Loom2D;
    import loom2d.display.Image;
    import loom2d.events.Event;
    import loom2d.textures.Texture;
//    import loom2d.textures.TextureSmoothing;
//    import Loom2D.Utils.RectangleUtil;
//    import Loom2D.Utils.ScaleMode;

    /**
     * Dispatched when the source content finishes loading.
     *
     * @eventType loom2d.events.Event.COMPLETE
     */
    [Event(name="complete",type="loom2d.events.Event")]

    /**
     * Dispatched if an error occurs while loading the source content.
     *
     * @eventType feathers.events.FeathersEventType.ERROR
     */
    [Event(name="error",type="loom2d.events.Event")]

    /**
     * Displays an image, either from a `Texture` or loaded from a
     * URL.
     */
    public class ImageLoader extends FeathersControl
    {
        /**
         * @private
         */
        private static const HELPER_MATRIX:Matrix = new Matrix();

        /**
         * @private
         */
        private static const HELPER_RECTANGLE:Rectangle = new Rectangle();

        /**
         * @private
         */
        private static const HELPER_RECTANGLE2:Rectangle = new Rectangle();

        /**
         * @private
         */
        //private static const LOADER_CONTEXT:LoaderContext = new LoaderContext(true);
        //LOADER_CONTEXT.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;

        /**
         * Constructor.
         */
        public function ImageLoader()
        {
            this.isQuickHitAreaEnabled = true;
        }

        /**
         * The internal `loom2d.display.Image` child.
         */
        protected var image:Image;

        /**
         * The internal `flash.display.Loader` used to load textures
         * from URLs.
         */
        //protected var loader:Loader;

        /**
         * @private
         */
        protected var _lastURL:String;

        /**
         * @private
         */
        protected var _textureFrame:Rectangle;

        /**
         * @private
         */
        protected var _texture:Texture;
        
        /**
         * @private
         */
        //protected var _textureBitmapData:BitmapData;

        /**
         * @private
         */
        protected var _isTextureOwner:Boolean = false;

        /**
         * @private
         */
        protected var _source:Object;

        /**
         * The texture to display, or a URL to load the image from to create the
         * texture.
         */
        public function get source():Object
        {
            return this._source;
        }

        /**
         * @private
         */
        public function set source(value:Object):void
        {
            if(this._source == value)
            {
                return;
            }
            this._source = value;
            this.cleanupTexture();
            if(this.image)
            {
                this.image.visible = false;
            }
            this._lastURL = null;
            this._isLoaded = false;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _isLoaded:Boolean = false;

        /**
         * Indicates if the source has fully loaded.
         */
        public function get isLoaded():Boolean
        {
            return this._isLoaded;
        }

        /**
         * @private
         */
        private var _textureScale:Number = 1;

        /**
         * The scale of the texture.
         */
        public function get textureScale():Number
        {
            return this._textureScale;
        }

        /**
         * @private
         */
        public function set textureScale(value:Number):void
        {
            if(this._textureScale == value)
            {
                return;
            }
            this._textureScale = value;
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        //private var _smoothing:String = TextureSmoothing.BILINEAR;

        /**
         * The smoothing value to use on the internal `Image`.
         *
         * @see loom2d.textures.TextureSmoothing
         * @see loom2d.display.Image#smoothing
         */
        public function get smoothing():String
        {
            return ""; //this._smoothing;
        }

        /**
         * @private
         */
        public function set smoothing(value:String):void
        {
/*            if(this._smoothing == value)
            {
                return;
            }
            this._smoothing = value; */
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _color:uint = 0xffffff;

        /**
         * The tint value to use on the internal `Image`.
         *
         * @see loom2d.display.Image#color
         */
        public function get color():uint
        {
            return this._color;
        }

        /**
         * @private
         */
        public function set color(value:uint):void
        {
            if(this._color == value)
            {
                return;
            }
            this._color = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _snapToPixels:Boolean = false;

        /**
         * Determines if the image should be snapped to the nearest global whole
         * pixel when rendered. Turning this on helps to avoid blurring.
         */
        public function get snapToPixels():Boolean
        {
            return this._snapToPixels;
        }

        /**
         * @private
         */
        public function set snapToPixels(value:Boolean):void
        {
            if(this._snapToPixels == value)
            {
                return;
            }
            this._snapToPixels = value;
        }

        /**
         * @private
         */
        private var _maintainAspectRatio:Boolean = true;

        /**
         * Determines if the aspect ratio of the texture is maintained when the
         * aspect ratio of the component is different.
         */
        public function get maintainAspectRatio():Boolean
        {
            return this._maintainAspectRatio;
        }

        /**
         * @private
         */
        public function set maintainAspectRatio(value:Boolean):void
        {
            if(this._maintainAspectRatio == value)
            {
                return;
            }
            this._maintainAspectRatio = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * The original width of the source content, in pixels. This value will
         * be `0` until the source content finishes loading. If the
         * source is a texture, this value will be `0` until the
         * `ImageLoader` validates.
         */
        public function get originalSourceWidth():Number
        {
            if(this._textureFrame)
            {
                return this._textureFrame.width;
            }
            return 0;
        }

        /**
         * The original height of the source content, in pixels. This value will
         * be `0` until the source content finishes loading. If the
         * source is a texture, this value will be `0` until the
         * `ImageLoader` validates.
         */
        public function get originalSourceHeight():Number
        {
            if(this._textureFrame)
            {
                return this._textureFrame.height;
            }
            return 0;
        }

        /**
         * @private
         */
        //protected var _pendingTexture:BitmapData;

        /**
         * @private
         */
        protected var _delayTextureCreation:Boolean = false;

        /**
         * Determines if a loaded bitmap may be converted to a texture
         * immediately after loading. If `true`, the loaded bitmap
         * will be saved until this property is set to `false`, and
         * only then it will be used to create the texture.
         *
         * This property is intended to be used while a parent container,
         * such as a `List`, is scrolling in order to keep scrolling
         * as smooth as possible. Creating textures is expensive and performance
         * can be affected by it. Set this property to `true` when
         * the `List` dispatches `FeathersEventType.SCROLL_START`
         * and set back to false when the `List` dispatches
         * `FeathersEventType.SCROLL_COMPLETE`. You may also need
         * to set to false if the `isScrolling` property of the
         * `List` is `true` before you listen to those
         * events.
         *
         * @see feathers.controls.Scroller#event:scrollStart
         * @see feathers.controls.Scroller#event:scrollComplete
         * @see feathers.controls.Scroller#isScrolling
         */
        public function get delayTextureCreation():Boolean
        {
            return this._delayTextureCreation;
        }

        /**
         * @private
         */
        public function set delayTextureCreation(value:Boolean):void
        {
            if(this._delayTextureCreation == value)
            {
                return;
            }
            this._delayTextureCreation = value;
            //if(!this._delayTextureCreation && this._pendingTexture)
            //{
                //const bitmapData:BitmapData = this._pendingTexture;
                //this._pendingTexture = null;
                //this.replaceTexture(bitmapData);
            //}
        }

        /**
         * Quickly sets all padding properties to the same value. The
         * `padding` getter always returns the value of
         * `paddingTop`, but the other padding values may be
         * different.
         */
        public function get padding():Number
        {
            return this._paddingTop;
        }

        /**
         * @private
         */
        public function set padding(value:Number):void
        {
            this.paddingTop = value;
            this.paddingRight = value;
            this.paddingBottom = value;
            this.paddingLeft = value;
        }

        /**
         * @private
         */
        protected var _paddingTop:Number = 0;

        /**
         * The minimum space, in pixels, between the control's top edge and the
         * control's content. Value may be negative to extend the content
         * outside the edges of the control. Useful for skinning.
         */
        public function get paddingTop():Number
        {
            return this._paddingTop;
        }

        /**
         * @private
         */
        public function set paddingTop(value:Number):void
        {
            if(this._paddingTop == value)
            {
                return;
            }
            this._paddingTop = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingRight:Number = 0;

        /**
         * The minimum space, in pixels, between the control's right edge and the
         * control's content. Value may be negative to extend the content
         * outside the edges of the control. Useful for skinning.
         */
        public function get paddingRight():Number
        {
            return this._paddingRight;
        }

        /**
         * @private
         */
        public function set paddingRight(value:Number):void
        {
            if(this._paddingRight == value)
            {
                return;
            }
            this._paddingRight = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingBottom:Number = 0;

        /**
         * The minimum space, in pixels, between the control's bottom edge and the
         * control's content. Value may be negative to extend the content
         * outside the edges of the control. Useful for skinning.
         */
        public function get paddingBottom():Number
        {
            return this._paddingBottom;
        }

        /**
         * @private
         */
        public function set paddingBottom(value:Number):void
        {
            if(this._paddingBottom == value)
            {
                return;
            }
            this._paddingBottom = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _paddingLeft:Number = 0;

        /**
         * The minimum space, in pixels, between the control's left edge and the
         * control's content. Value may be negative to extend the content
         * outside the edges of the control. Useful for skinning.
         */
        public function get paddingLeft():Number
        {
            return this._paddingLeft;
        }

        /**
         * @private
         */
        public function set paddingLeft(value:Number):void
        {
            if(this._paddingLeft == value)
            {
                return;
            }
            this._paddingLeft = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        /*override public function render(support:RenderSupport, parentAlpha:Number):void
        {
            if(this._snapToPixels)
            {
                this.getTransformationMatrix(this.stage, HELPER_MATRIX);
                support.translateMatrix(Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx, Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty);
            }
            super.render(support, parentAlpha);
            if(this._snapToPixels)
            {
                support.translateMatrix(-(Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx), -(Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty));
            }
        }*/
        
        /**
         * @private
         */
        override public function dispose():void
        {
            /*if(this.loader)
            {
                this.loader.contentLoaderInfo.removeEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
                this.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
                this.loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
                try
                {
                    this.loader.close();
                }
                catch(error:Error)
                {
                    //no need to do anything in response
                }
                this.loader = null;
            } */
            this.cleanupTexture();
            super.dispose();
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const layoutInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_LAYOUT);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);

            if(dataInvalid)
            {
                this.commitData();
            }

            if(dataInvalid || stylesInvalid)
            {
                this.commitStyles();
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(dataInvalid || layoutInvalid || sizeInvalid)
            {
                this.layout();
            }
        }

        /**
         * @private
         */
        protected function autoSizeIfNeeded():Boolean
        {
            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                return false;
            }

            var newWidth:Number = this.explicitWidth;
            if(needsWidth)
            {
                if(this._textureFrame)
                {
                    newWidth = this._textureFrame.width * this._textureScale;
                    if(!needsHeight)
                    {
                        const heightScale:Number = this.explicitHeight / (this._textureFrame.height * this._textureScale);
                        newWidth *= heightScale;
                    }
                }
                else
                {
                    newWidth = 0;
                }
                newWidth += this._paddingLeft + this._paddingRight;
            }

            var newHeight:Number = this.explicitHeight;
            if(needsHeight)
            {
                if(this._textureFrame)
                {
                    newHeight = this._textureFrame.height * this._textureScale;
                    if(!needsWidth)
                    {
                        const widthScale:Number = this.explicitWidth / (this._textureFrame.width * this._textureScale);
                        newHeight *= widthScale;
                    }
                }
                else
                {
                    newHeight = 0;
                }
                newHeight += this._paddingTop + this._paddingBottom;
            }

            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function commitData():void
        {
            if(this._source is Texture)
            {
                this._lastURL = null;
                this._texture = Texture(this._source);
                this.commitTexture();
                this._isLoaded = true;
            }
            else
            {
                const sourceURL:String = this._source as String;
                if(!sourceURL)
                {
                    this._lastURL = sourceURL;
                    this.commitTexture();
                    return;
                }

                if(sourceURL == this._lastURL)
                {
                    //if it's not loaded yet, we'll come back later
                    if(this._isLoaded)
                    {
                        this.commitTexture();
                    }
                }
                else
                {
                    this._lastURL = sourceURL;

/*                    if(this.loader)
                    {
                        this.loader.contentLoaderInfo.removeEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
                        this.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
                        this.loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
                        try
                        {
                            this.loader.close();
                        }
                        catch(error:Error)
                        {
                            //no need to do anything in response
                        }
                    }
                    else
                    {
                        this.loader = new Loader();
                    }
                    this.loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
                    this.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
                    this.loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
                    this.loader.load(new URLRequest(sourceURL), LOADER_CONTEXT); */
                }
            }
        }

        /**
         * @private
         */
        protected function commitStyles():void
        {
            if(!this.image)
            {
                return;
            }
            //this.image.smoothing = this._smoothing;
            //this.image.color = this._color;
        }

        /**
         * @private
         */
        protected function layout():void
        {
            if(!this.image || !this._texture)
            {
                return;
            }
            if(this._maintainAspectRatio)
            {
                HELPER_RECTANGLE.x = 0;
                HELPER_RECTANGLE.y = 0;
                HELPER_RECTANGLE.width = this._textureFrame.width * this._textureScale;
                HELPER_RECTANGLE.height = this._textureFrame.height * this._textureScale;
                HELPER_RECTANGLE2.x = 0;
                HELPER_RECTANGLE2.y = 0;
                HELPER_RECTANGLE2.width = this.actualWidth - this._paddingLeft - this._paddingRight;
                HELPER_RECTANGLE2.height = this.actualHeight - this._paddingTop - this._paddingBottom;
                //RectangleUtil.fit(HELPER_RECTANGLE, HELPER_RECTANGLE2, ScaleMode.SHOW_ALL, false, HELPER_RECTANGLE);
                this.image.x = HELPER_RECTANGLE.x + this._paddingLeft;
                this.image.y = HELPER_RECTANGLE.y + this._paddingTop;
                this.image.width = HELPER_RECTANGLE.width;
                this.image.height = HELPER_RECTANGLE.height;
            }
            else
            {
                this.image.x = this._paddingLeft;
                this.image.y = this._paddingTop;
                this.image.width = this.actualWidth - this._paddingLeft - this._paddingRight;
                this.image.height = this.actualHeight - this._paddingTop - this._paddingBottom;
            }
        }

        /**
         * @private
         */
        protected function commitTexture():void
        {
            if(!this._texture)
            {
                if(this.image)
                {
                    this.removeChild(this.image, true);
                    this.image = null;
                }
                return;
            }

            //save the texture's frame so that we don't need to create a new
            //rectangle every time that we want to access it.
            this._textureFrame = this._texture.frame;
            if(!this.image)
            {
                this.image = new Image(this._texture);
                this.addChild(this.image);
            }
            else
            {
                this.image.texture = this._texture;
                this.image.readjustSize();
            }
            this.image.visible = true;
        }
        
        /**
         * @private
         */
        protected function cleanupTexture():void
        {
            if(this._isTextureOwner)
            {
                /*if(this._textureBitmapData)
                {
                    this._textureBitmapData.dispose();
                }
                if(this._texture)
                {
                    this._texture.dispose();
                }*/
            }
/*            if(this._pendingTexture)
            {
                this._pendingTexture.dispose();
                this._pendingTexture = null;
            }
            this._textureFrame = null;
            this._textureBitmapData = null;
            this._texture = null;
            this._isTextureOwner = false; */
        }

        /**
         * @private
         */
        //protected function replaceTexture(bitmapData:BitmapData):void
        //{
/*            this._texture = Texture.fromBitmapData(bitmapData, false);
            if(Starling.handleLostContext)
            {
                this._textureBitmapData = bitmapData;
            }
            else
            {
                //since Starling isn't handling the lost context, we don't need
                //to save the texture bitmap data.
                bitmapData.dispose();
            }
            this._isTextureOwner = true;
            this.commitTexture();
            this._isLoaded = true;
            this.invalidate(INVALIDATION_FLAG_SIZE);
            this.dispatchEventWith(loom2d.events.Event.COMPLETE); */
        //}

        /**
         * @private
         */
/*        protected function loader_completeHandler(event:flash.events.Event):void
        {
            const bitmap:Bitmap = Bitmap(this.loader.content);
            this.loader.contentLoaderInfo.removeEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
            this.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
            this.loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
            this.loader = null;
            
            this.cleanupTexture();
            const bitmapData:BitmapData = bitmap.bitmapData;
            if(this._delayTextureCreation)
            {
                this._pendingTexture = bitmapData;
            }
            else
            {
                this.replaceTexture(bitmapData);
            }
        } */

        /**
         * @private
         */
/*        protected function loader_errorHandler(event:ErrorEvent):void
        {
            this.loader.contentLoaderInfo.removeEventListener(flash.events.Event.COMPLETE, loader_completeHandler);
            this.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loader_errorHandler);
            this.loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_errorHandler);
            this.loader = null;
            
            this.cleanupTexture();
            this.commitTexture();
            this.invalidate(INVALIDATION_FLAG_SIZE);
            this.dispatchEventWith(FeathersEventType.ERROR, false, event);
        }*/
    }
}
