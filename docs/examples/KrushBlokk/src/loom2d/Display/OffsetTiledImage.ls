package loom2d.Display {
    import feathers.display.TiledImage2;
    import loom2d.math.Rectangle;
    import loom2d.textures.Texture;
    
    public class OffsetTiledImage extends TiledImage2 {
        
        private static const HELPER_RECTANGLE:Rectangle = new Rectangle();
        
        private var _scrollX:Number = 0;
        private var _scrollY:Number = 0;
        
        public function OffsetTiledImage(texture:Texture, textureScale:Number = 1) {
            super(texture, textureScale);
        }
        
        /**
         * Offset the tiles on the X axis.
         */
        public function get scrollX():Number
        {
            return _scrollX;
        }
        
        /**
         * @private
         */
        public function set scrollX(value:Number):void
        {
            this._scrollX = value;
            this._propertiesChanged = true;
            this.valid = false;
        }
        
        /**
         * Offset the tiles on the Y axis.
         */
        public function get scrollY():Number
        {
            return _scrollY;
        }
        
        /**
         * @private
         */
        public function set scrollY(value:Number):void
        {
            this._scrollY = value;
            this._propertiesChanged = true;
            this.valid = false;
        }
        
        /**
         * Set both the x and y scroll values in one call.
         */
        public function setScroll(x:Number, y:Number):void
        {
            this.scrollX = x;
            this.scrollY = y;
        }
        
        /**
         * @private
         */
        public function validate():void
        {
            const scaledTextureWidth:Number = this._originalImageWidth * this._textureScale;
            const scaledTextureHeight:Number = this._originalImageHeight * this._textureScale;
            if(this._propertiesChanged)
            {
                this._image.color = this._color;
                this._batch.x = -(this._scrollX%scaledTextureWidth);
                this._batch.y = -(this._scrollY%scaledTextureHeight);
            }
            if(this._propertiesChanged || this._layoutChanged)
            {
                this._batch.reset();
                this._image.scaleX = this._image.scaleY = this._textureScale;
                
                HELPER_RECTANGLE.width = this._width;
                HELPER_RECTANGLE.height = this._height;
				this.clipRect = HELPER_RECTANGLE;
                
                const batchWidth:Number = this._width + scaledTextureWidth;
                const batchHeight:Number = this._height + scaledTextureHeight;
                updateBatch(batchWidth, batchHeight, scaledTextureWidth, scaledTextureHeight);
            }
            this._layoutChanged = false;
            this._propertiesChanged = false;
        }
        
    }
    
}