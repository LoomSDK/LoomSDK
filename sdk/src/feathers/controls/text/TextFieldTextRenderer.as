/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.text
{
    import feathers.core.FeathersControl;
    import feathers.core.ITextRenderer;
    import feathers.text.BitmapFontTextFormat;

    import Loom2D.Math.Matrix;
    import Loom2D.Math.Point;

    import Loom2D.Loom2D;
    import Loom2D.Display.Image;
    import Loom2D.Events.Event;
    import Loom2D.Textures.ConcreteTexture;
    import Loom2D.Textures.Texture;
    
    /**
     * Renders text with a native `flash.text.TextField`.
     *
     * @see http://wiki.starling-framework.org/feathers/text-renderers
     * @see flash.text.TextField
     */
    public class TextFieldTextRenderer extends FeathersControl implements ITextRenderer
    {
        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        private static const HELPER_MATRIX:Matrix = new Matrix();

        /**
         * Constructor.
         */
        public function TextFieldTextRenderer()
        {
            this.isQuickHitAreaEnabled = true;
            this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
        }

        /**
         * @private
         */
        protected var _previousTextFieldWidth:Number = NaN;

        /**
         * @private
         */
        protected var _previousTextFieldHeight:Number = NaN;

        /**
         * @private
         */
        protected var _snapshotWidth:int = 0;

        /**
         * @private
         */
        protected var _snapshotHeight:int = 0;

        /**
         * @private
         */
        protected var _needsNewBitmap:Boolean = false;

        /**
         * @private
         */
        protected var _text:String = "";

        /**
         * @inheritDoc
         */
        public function get text():String
        {
            return this._text;
        }

        /**
         * @private
         */
        protected var _isHTML:Boolean = false;

        /**
         * Determines if the TextField should display the text as HTML or not.
         *
         * @see flash.text.TextField#htmlText
         */
        public function get isHTML():Boolean
        {
            return this._isHTML;
        }

        /**
         * @private
         */
        public function set isHTML(value:Boolean):void
        {
            if(this._isHTML == value)
            {
                return;
            }
            this._isHTML = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        public function set text(value:String):void
        {
            if(this._text == value)
            {
                return;
            }
            if(value === null)
            {
                //flash.text.TextField won't accept a null value
                value = "";
            }
            this._text = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _textFormat:BitmapFontTextFormat;

        /**
         * The font and styles used to draw the text.
         *
         * @see flash.text.TextFormat
         */
        public function get textFormat():BitmapFontTextFormat
        {
            return this._textFormat;
        }

        /**
         * @private
         */
        public function set textFormat(value:BitmapFontTextFormat):void
        {
            if(this._textFormat == value)
            {
                return;
            }
            this._textFormat = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }


        /**
         * @private
         */
        protected var _embedFonts:Boolean = false;

        /**
         * Determines if the TextField should use an embedded font or not.
         */
        public function get embedFonts():Boolean
        {
            return this._embedFonts;
        }

        /**
         * @private
         */
        public function set embedFonts(value:Boolean):void
        {
            if(this._embedFonts == value)
            {
                return;
            }
            this._embedFonts = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @inheritDoc
         */
        public function get baseline():Number
        {
            //2 is the gutter Flash Player adds
            return 2 + this.textField.getLineMetrics(0).ascent;
        }

        /**
         * @private
         */
        protected var _wordWrap:Boolean = false;

        /**
         * Determines if the TextField wraps text to the next line.
         */
        public function get wordWrap():Boolean
        {
            return this._wordWrap;
        }

        /**
         * @private
         */
        public function set wordWrap(value:Boolean):void
        {
            if(this._wordWrap == value)
            {
                return;
            }
            this._wordWrap = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _snapToPixels:Boolean = true;

        /**
         * Determines if the text should be snapped to the nearest whole pixel
         * when rendered. When this is `false`, text may be displayed
         * on sub-pixels, which often results in blurred rendering.
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
            this._snapToPixels = value;
        }

        /**
         * @private
         */
        private var _background:Boolean = false;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#background
         */
        public function get background():Boolean
        {
            return this._background;
        }

        /**
         * @private
         */
        public function set background(value:Boolean):void
        {
            if(this._background == value)
            {
                return;
            }
            this._background = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _backgroundColor:uint = 0xffffff;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#backgroundColor
         */
        public function get backgroundColor():uint
        {
            return this._backgroundColor;
        }

        /**
         * @private
         */
        public function set backgroundColor(value:uint):void
        {
            if(this._backgroundColor == value)
            {
                return;
            }
            this._backgroundColor = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _border:Boolean = false;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#border
         */
        public function get border():Boolean
        {
            return this._border;
        }

        /**
         * @private
         */
        public function set border(value:Boolean):void
        {
            if(this._border == value)
            {
                return;
            }
            this._border = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _borderColor:uint = 0x000000;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#borderColor
         */
        public function get borderColor():uint
        {
            return this._borderColor;
        }

        /**
         * @private
         */
        public function set borderColor(value:uint):void
        {
            if(this._borderColor == value)
            {
                return;
            }
            this._borderColor = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _condenseWhite:Boolean = false;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#condenseWhite
         */
        public function get condenseWhite():Boolean
        {
            return this._condenseWhite;
        }

        /**
         * @private
         */
        public function set condenseWhite(value:Boolean):void
        {
            if(this._condenseWhite == value)
            {
                return;
            }
            this._condenseWhite = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _displayAsPassword:Boolean = false;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#displayAsPassword
         */
        public function get displayAsPassword():Boolean
        {
            return this._displayAsPassword;
        }

        /**
         * @private
         */
        public function set displayAsPassword(value:Boolean):void
        {
            if(this._displayAsPassword == value)
            {
                return;
            }
            this._displayAsPassword = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        private var _sharpness:Number = 0;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#sharpness
         */
        public function get sharpness():Number
        {
            return this._sharpness;
        }

        /**
         * @private
         */
        public function set sharpness(value:Number):void
        {
            if(this._sharpness == value)
            {
                return;
            }
            this._sharpness = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        private var _thickness:Number = 0;

        /**
         * Same as the TextField property with the same name.
         *
         * @see flash.text.TextField#thickness
         */
        public function get thickness():Number
        {
            return this._thickness;
        }

        /**
         * @private
         */
        public function set thickness(value:Number):void
        {
            if(this._thickness == value)
            {
                return;
            }
            this._thickness = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        override public function dispose():void
        {
            this.disposeContent();
            super.dispose();
        }

        /**
         * @private
         */
        override public function render(support:RenderSupport, parentAlpha:Number):void
        {
            /* if(this.textSnapshot)
            {
                if(this._snapToPixels)
                {
                    this.getTransformationMatrix(this.stage, HELPER_MATRIX);
                    this.textSnapshot.x = Math.round(HELPER_MATRIX.tx) - HELPER_MATRIX.tx;
                    this.textSnapshot.y = Math.round(HELPER_MATRIX.ty) - HELPER_MATRIX.ty;
                }
                else
                {
                    this.textSnapshot.x = this.textSnapshot.y = 0;
                }
            } */
            super.render(support, parentAlpha);
        }

        /**
         * @inheritDoc
         */
        public function measureText(result:Point = null):Point
        {
            if(!result)
            {
                result = new Point();
            }

            /*if(!this.textField)
            {
                result.x = result.y = 0;
                return result;
            }*/

            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                result.x = this.explicitWidth;
                result.y = this.explicitHeight;
                return result;
            }

            this.commit();

            result = this.measure(result);

            return result;
        }

        /**
         * @private
         */
        override protected function initialize():void
        {
            if(!this.textField)
            {
                /*this.textField = new TextField();
                this.textField.mouseEnabled = this.textField.mouseWheelEnabled = false;
                this.textField.selectable = false;
                this.textField.multiline = true; */
            }
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);

            this.commit();

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            this.layout(sizeInvalid);
        }

        /**
         * @private
         */
        protected function commit():void
        {
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);

            if(stylesInvalid)
            {
                /*this.textField.antiAliasType = this._antiAliasType;
                this.textField.background = this._background;
                this.textField.backgroundColor = this._backgroundColor;
                this.textField.border = this._border;
                this.textField.borderColor = this._borderColor;
                this.textField.condenseWhite = this._condenseWhite;
                this.textField.displayAsPassword = this._displayAsPassword;
                this.textField.gridFitType = this._gridFitType;
                this.textField.sharpness = this._sharpness;
                this.textField.thickness = this._thickness; */
            }

            if(dataInvalid || stylesInvalid)
            {
                /*this.textField.wordWrap = this._wordWrap;
                this.textField.embedFonts = this._embedFonts;
                if(this._textFormat)
                {
                    this.textField.defaultTextFormat = this._textFormat;
                }
                this.textField.styleSheet = this._styleSheet;
                if(this._isHTML)
                {
                    this.textField.htmlText = this._text;
                }
                else
                {
                    this.textField.text = this._text;
                }*/
            }
        }

        /**
         * @private
         */
        protected function measure(result:Point = null):Point
        {
            if(!result)
            {
                result = new Point();
            }

            const needsWidth:Boolean = isNaN(this.explicitWidth);
            const needsHeight:Boolean = isNaN(this.explicitHeight);

            //this.textField.autoSize = TextFieldAutoSize.LEFT;
            //this.textField.wordWrap = false;

            var newWidth:Number = this.explicitWidth;
            if(needsWidth)
            {
                newWidth = Math.max(this._minWidth, Math.min(this._maxWidth, this.textField.width));
            }

            //this.textField.width = newWidth;
            //this.textField.wordWrap = this._wordWrap;
            var newHeight:Number = this.explicitHeight;
            if(needsHeight)
            {
                newHeight = Math.max(this._minHeight, Math.min(this._maxHeight, this.textField.height));
            }

            //this.textField.autoSize = TextFieldAutoSize.NONE;

            //put the width and height back just in case we measured without
            //a full validation
            //this.textField.width = this.actualWidth;
            //this.textField.height = this.actualHeight;

            result.x = newWidth;
            result.y = newHeight;

            return result;
        }

        /**
         * @private
         */
        protected function layout(sizeInvalid:Boolean):void
        {
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);

            if(sizeInvalid)
            {
                this.textField.width = this.actualWidth;
                this.textField.height = this.actualHeight;
                this._snapshotWidth = getNextPowerOfTwo(this.actualWidth * Starling.contentScaleFactor);
                this._snapshotHeight = getNextPowerOfTwo(this.actualHeight * Starling.contentScaleFactor);
                this._needsNewBitmap = this._needsNewBitmap || !this.textSnapshot || !this._textSnapshotBitmapData || this._snapshotWidth != this._textSnapshotBitmapData.width || this._snapshotHeight != this._textSnapshotBitmapData.height;
            }

            //instead of checking sizeInvalid, which will often be triggered by
            //changing maxWidth or something for measurement, we check against
            //the previous actualWidth/Height used for the snapshot.
            if(stylesInvalid || dataInvalid || this._needsNewBitmap ||
                this.actualWidth != this._previousTextFieldWidth ||
                this.actualHeight != this._previousTextFieldHeight)
            {
                this._previousTextFieldWidth = this.actualWidth;
                this._previousTextFieldHeight = this.actualHeight;
                const hasText:Boolean = this._text.length > 0;
                if(hasText)
                {
                    //we need to wait a frame for the TextField to render
                    //properly. sometimes two, and this is a known issue.
                    this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
                }
                if(this.textSnapshot)
                {
                    this.textSnapshot.visible = hasText;
                }
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

            this.measure(HELPER_POINT);
            return this.setSizeInternal(HELPER_POINT.x, HELPER_POINT.y, false);
        }

        /**
         * @private
         */
        protected function refreshSnapshot():void
        {
            if(this.textField.width == 0 || this.textField.height == 0)
            {
                return;
            }
            if(this._needsNewBitmap || !this._textSnapshotBitmapData)
            {
                if(this._textSnapshotBitmapData)
                {
                    this._textSnapshotBitmapData.dispose();
                }
                this._textSnapshotBitmapData = new BitmapData(this._snapshotWidth, this._snapshotHeight, true, 0x00ff00ff);
            }
            if(!this._textSnapshotBitmapData)
            {
                return;
            }
            HELPER_MATRIX.identity();
            HELPER_MATRIX.scale(Starling.contentScaleFactor, Starling.contentScaleFactor);
            this._textSnapshotBitmapData.fillRect(this._textSnapshotBitmapData.rect, 0x00ff00ff);
            this._textSnapshotBitmapData.draw(this.textField, HELPER_MATRIX);
            if(!this.textSnapshot)
            {
                this.textSnapshot = new Image(starling.textures.Texture.fromBitmapData(this._textSnapshotBitmapData, false, false, Starling.contentScaleFactor));
                this.addChild(this.textSnapshot);
            }
            else
            {
                if(this._needsNewBitmap)
                {
                    this.textSnapshot.texture.dispose();
                    this.textSnapshot.texture = starling.textures.Texture.fromBitmapData(this._textSnapshotBitmapData, false, false, Starling.contentScaleFactor);
                    this.textSnapshot.readjustSize();
                }
                else
                {
                    //this is faster if we haven't resized the bitmapdata
                    const texture:starling.textures.Texture = this.textSnapshot.texture;
                    if(Starling.handleLostContext && texture is ConcreteTexture)
                    {
                        ConcreteTexture(texture).restoreOnLostContext(this._textSnapshotBitmapData);
                    }
                    flash.display3D.textures.Texture(texture.base).uploadFromBitmapData(this._textSnapshotBitmapData);
                }
            }
            this._needsNewBitmap = false;
        }

        /**
         * @private
         */
        protected function disposeContent():void
        {
            if(this._textSnapshotBitmapData)
            {
                this._textSnapshotBitmapData.dispose();
                this._textSnapshotBitmapData = null;
            }

            if(this.textSnapshot)
            {
                //avoid the need to call dispose(). we'll create a new snapshot
                //when the renderer is added to stage again.
                this.textSnapshot.texture.dispose();
                this.removeChild(this.textSnapshot, true);
                this.textSnapshot = null;
            }

            this._previousTextFieldWidth = NaN;
            this._previousTextFieldHeight = NaN;

            this._needsNewBitmap = false;
            this._snapshotWidth = 0;
            this._snapshotHeight = 0;
        }

        /**
         * @private
         */
        protected function addedToStageHandler(event:Event):void
        {
            //we need to invalidate in order to get a fresh snapshot
            this.invalidate(INVALIDATION_FLAG_SIZE);
        }

        /**
         * @private
         */
        protected function removedFromStageHandler(event:Event):void
        {
            this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);

            this.disposeContent();
        }

        /**
         * @private
         */
        protected function enterFrameHandler(event:Event):void
        {
            this.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
            this.refreshSnapshot();
        }
    }
}
