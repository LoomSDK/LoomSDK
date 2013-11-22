/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.renderers
{
    import feathers.controls.GroupedList;
    import feathers.controls.ImageLoader;
    import feathers.core.FeathersControl;
    import feathers.core.ITextRenderer;

    import loom2d.display.DisplayObject;

    /**
     * The default renderer used for headers and footers in a GroupedList
     * control.
     */
    public class DefaultGroupedListHeaderOrFooterRenderer extends FeathersControl implements IGroupedListHeaderOrFooterRenderer
    {
        /**
         * The content will be aligned horizontally to the left edge of the renderer.
         *
         * @see #horizontalAlign
         */
        public static const HORIZONTAL_ALIGN_LEFT:String = "left";

        /**
         * The content will be aligned horizontally to the center of the renderer.
         *
         * @see #horizontalAlign
         */
        public static const HORIZONTAL_ALIGN_CENTER:String = "center";

        /**
         * The content will be aligned horizontally to the right edge of the renderer.
         *
         * @see #horizontalAlign
         */
        public static const HORIZONTAL_ALIGN_RIGHT:String = "right";

        /**
         * The content will be aligned vertically to the top edge of the renderer.
         *
         * @see #verticalAlign
         */
        public static const VERTICAL_ALIGN_TOP:String = "top";

        /**
         * The content will be aligned vertically to the middle of the renderer.
         *
         * @see #verticalAlign
         */
        public static const VERTICAL_ALIGN_MIDDLE:String = "middle";

        /**
         * The content will be aligned vertically to the bottom edge of the renderer.
         *
         * @see #verticalAlign
         */
        public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";

        /**
         * The default value added to the `nameList` of the content
         * label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        public static const DEFAULT_CHILD_NAME_CONTENT_LABEL:String = "feathers-header-footer-renderer-content-label";

        /**
         * @private
         */
        protected static function defaultImageLoaderFactory():ImageLoader
        {
            return new ImageLoader();
        }

        /**
         * The value added to the `nameList` of the content label.
         *
         * @see feathers.core.IFeathersControl#nameList
         */
        protected var contentLabelName:String = DEFAULT_CHILD_NAME_CONTENT_LABEL;

        /**
         * Constructor.
         */
        public function DefaultGroupedListHeaderOrFooterRenderer()
        {
        }

        /**
         * @private
         */
        protected var contentImage:ImageLoader;

        /**
         * @private
         */
        protected var contentLabel:ITextRenderer;

        /**
         * @private
         */
        protected var content:DisplayObject;

        /**
         * @private
         */
        protected var _data:Object;

        /**
         * @inheritDoc
         */
        public function get data():Object
        {
            return this._data;
        }

        /**
         * @private
         */
        public function set data(value:Object):void
        {
            if(this._data == value)
            {
                return;
            }
            this._data = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _groupIndex:int = -1;

        /**
         * @inheritDoc
         */
        public function get groupIndex():int
        {
            return this._groupIndex;
        }

        /**
         * @private
         */
        public function set groupIndex(value:int):void
        {
            this._groupIndex = value;
        }

        /**
         * @private
         */
        protected var _layoutIndex:int = -1;

        /**
         * @inheritDoc
         */
        public function get layoutIndex():int
        {
            return this._layoutIndex;
        }

        /**
         * @private
         */
        public function set layoutIndex(value:int):void
        {
            this._layoutIndex = value;
        }

        /**
         * @private
         */
        protected var _owner:GroupedList;

        /**
         * @inheritDoc
         */
        public function get owner():GroupedList
        {
            return this._owner;
        }

        /**
         * @private
         */
        public function set owner(value:GroupedList):void
        {
            if(this._owner == value)
            {
                return;
            }
            this._owner = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _horizontalAlign:String = HORIZONTAL_ALIGN_LEFT;

        /**
         * The location where the renderer's content is aligned horizontally
         * (on the x-axis).
         */
        public function get horizontalAlign():String
        {
            return this._horizontalAlign;
        }

        /**
         * @private
         */
        public function set horizontalAlign(value:String):void
        {
            if(this._horizontalAlign == value)
            {
                return;
            }
            this._horizontalAlign = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _verticalAlign:String = VERTICAL_ALIGN_MIDDLE;

        /**
         * The location where the renderer's content is aligned vertically (on
         * the y-axis).
         */
        public function get verticalAlign():String
        {
            return _verticalAlign;
        }

        /**
         * @private
         */
        public function set verticalAlign(value:String):void
        {
            if(this._verticalAlign == value)
            {
                return;
            }
            this._verticalAlign = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _contentField:String = "content";

        /**
         * The field in the item that contains a display object to be positioned
         * in the content position of the renderer. If you wish to display a
         * texture in the content position, it's better for performance to use
         * `contentSourceField` instead.
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentSourceFunction`
         *     2. `contentSourceField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         *
         * @see #contentSourceField
         * @see #contentFunction
         * @see #contentSourceFunction
         * @see #contentLabelField
         * @see #contentLabelFunction
         */
        public function get contentField():String
        {
            return this._contentField;
        }

        /**
         * @private
         */
        public function set contentField(value:String):void
        {
            if(this._contentField == value)
            {
                return;
            }
            this._contentField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _contentFunction:Function;

        /**
         * A function that returns a display object to be positioned in the
         * content position of the renderer. If you wish to display a texture in
         * the content position, it's better for performance to use
         * `contentSourceFunction` instead.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):DisplayObject`
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentSourceFunction`
         *     2. `contentSourceField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         *
         * @see #contentField
         * @see #contentSourceField
         * @see #contentSourceFunction
         * @see #contentLabelField
         * @see #contentLabelFunction
         */
        public function get contentFunction():Function
        {
            return this._contentFunction;
        }

        /**
         * @private
         */
        public function set contentFunction(value:Function):void
        {
            if(this._contentFunction == value)
            {
                return;
            }
            this._contentFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _contentSourceField:String = "texture";

        /**
         * The field in the data that contains a `loom2d.textures.Texture`
         * or a URL that points to a bitmap to be used as the renderer's
         * content. The renderer will automatically manage and reuse an internal
         * `ImageLoader` sub-component and this value will be passed
         * to the `source` property. The `ImageLoader` may
         * be customized by changing the `contentLoaderFactory`.
         *
         * Using an content source will result in better performance than
         * passing in an `ImageLoader` or `Image` through
         * `contentField` or `contentFunction` because the
         * renderer can avoid costly display list manipulation.
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentSourceFunction`
         *     2. `contentSourceeField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         *
         * @see feathers.controls.ImageLoader#source
         * @see #contentLoaderFactory
         * @see #contentSourceFunction
         * @see #contentField
         * @see #contentFunction
         * @see #contentLabelField
         * @see #contentLabelFunction
         */
        public function get contentSourceField():String
        {
            return this._contentSourceField;
        }

        /**
         * @private
         */
        public function set contentSourceField(value:String):void
        {
            if(this._contentSourceField == value)
            {
                return;
            }
            this._contentSourceField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _contentSourceFunction:Function;

        /**
         * A function used to generate a `loom2d.textures.Texture`
         * or a URL that points to a bitmap to be used as the renderer's
         * content. The renderer will automatically manage and reuse an internal
         * `ImageLoader` sub-component and this value will be passed
         * to the `source` property. The `ImageLoader` may
         * be customized by changing the `contentLoaderFactory`.
         *
         * Using an content source will result in better performance than
         * passing in an `ImageLoader` or `Image` through
         * `contentField` or `contentFunction` because the
         * renderer can avoid costly display list manipulation.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):Object`
         *
         * The return value is a valid value for the `source`
         * property of an `ImageLoader` component.
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentSourceFunction`
         *     2. `contentSourceField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         *
         * @see feathers.controls.ImageLoader#source
         * @see #contentLoaderFactory
         * @see #contentSourceField
         * @see #contentField
         * @see #contentFunction
         * @see #contentLabelField
         * @see #contentLabelFunction
         */
        public function get contentSourceFunction():Function
        {
            return this._contentSourceFunction;
        }

        /**
         * @private
         */
        public function set contentSourceFunction(value:Function):void
        {
            if(this.contentSourceFunction == value)
            {
                return;
            }
            this._contentSourceFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _contentLabelField:String = "label";

        /**
         * The field in the item that contains a string to be displayed in a
         * renderer-managed `Label` in the content position of the
         * renderer. The renderer will automatically reuse an internal
         * `Label` and swap the text when the data changes. This
         * `Label` may be skinned by changing the
         * `contentLabelFactory`.
         *
         * Using an content label will result in better performance than
         * passing in a `Label` through a `contentField`
         * or `contentFunction` because the renderer can avoid
         * costly display list manipulation.
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentTextureFunction`
         *     2. `contentTextureField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         *
         * @see #contentLabelFactory
         * @see #contentLabelFunction
         * @see #contentField
         * @see #contentFunction
         * @see #contentSourceField
         * @see #contentSourceFunction
         */
        public function get contentLabelField():String
        {
            return this._contentLabelField;
        }

        /**
         * @private
         */
        public function set contentLabelField(value:String):void
        {
            if(this._contentLabelField == value)
            {
                return;
            }
            this._contentLabelField = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _contentLabelFunction:Function;

        /**
         * A function that returns a string to be displayed in a
         * renderer-managed `Label` in the content position of the
         * renderer. The renderer will automatically reuse an internal
         * `Label` and swap the text when the data changes. This
         * `Label` may be skinned by changing the
         * `contentLabelFactory`.
         *
         * Using an content label will result in better performance than
         * passing in a `Label` through a `contentField`
         * or `contentFunction` because the renderer can avoid
         * costly display list manipulation.
         *
         * The function is expected to have the following signature:
         * `function( item:Object ):String`
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentTextureFunction`
         *     2. `contentTextureField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         *
         * @see #contentLabelFactory
         * @see #contentLabelField
         * @see #contentField
         * @see #contentFunction
         * @see #contentSourceField
         * @see #contentSourceFunction
         */
        public function get contentLabelFunction():Function
        {
            return this._contentLabelFunction;
        }

        /**
         * @private
         */
        public function set contentLabelFunction(value:Function):void
        {
            if(this._contentLabelFunction == value)
            {
                return;
            }
            this._contentLabelFunction = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * Uses the content fields and functions to generate content for a
         * specific group header or footer.
         *
         * All of the content fields and functions, ordered by priority:
         * 
         *     1. `contentTextureFunction`
         *     2. `contentTextureField`
         *     3. `contentLabelFunction`
         *     4. `contentLabelField`
         *     5. `contentFunction`
         *     6. `contentField`

         */
        protected function itemToContent(item:Object):DisplayObject
        {
            if(this._contentSourceFunction != null)
            {
                var source:Object = this._contentSourceFunction.call(null, item);
                this.refreshContentSource(source);
                return this.contentImage;
            }
            else if(this._contentSourceField != null && item && item.hasOwnProperty(this._contentSourceField))
            {
                //source = item[this._contentSourceField];
                source = item.getType().getFieldOrPropertyValueByName(item, this._contentSourceField);
                this.refreshContentSource(source);
                return this.contentImage;
            }
            else if(this._contentLabelFunction != null)
            {
                var label:String = this._contentLabelFunction.call(null, item) as String;
                this.refreshContentLabel(label);
                return DisplayObject(this.contentLabel);
            }
            else if(this._contentLabelField != null && item && item.hasOwnProperty(this._contentLabelField))
            {
                //label = item[this._contentLabelField] as String;
                label = item.getType().getFieldOrPropertyValueByName(item, this._contentLabelField) as String;
                this.refreshContentLabel(label);
                return DisplayObject(this.contentLabel);
            }
            else if(this._contentFunction != null)
            {
                return this._contentFunction.call(null, item) as DisplayObject;
            }
            else if(this._contentField != null && item && item.hasOwnProperty(this._contentField))
            {
                //return item[this._contentField] as DisplayObject;
                return item.getType().getFieldOrPropertyValueByName(item, this._contentField) as DisplayObject;
            }
            else if(item)
            {
                this.refreshContentLabel(item.toString());
                return DisplayObject(this.contentLabel);
            }

            return null;
        }

        /**
         * @private
         */
        protected var _contentLoaderFactory:Function = defaultImageLoaderFactory;

        /**
         * A function that generates an `ImageLoader` that uses the result
         * of `contentSourceField` or `contentSourceFunction`.
         * Useful for transforming the `ImageLoader` in some way. For
         * example, you might want to scale it for current DPI or apply pixel
         * snapping.
         *
         * @see feathers.controls.ImageLoader
         * @see #contentSourceField
         * @see #contentSourceFunction
         */
        public function get contentLoaderFactory():Function
        {
            return this._contentLoaderFactory;
        }

        /**
         * @private
         */
        public function set contentLoaderFactory(value:Function):void
        {
            if(this._contentLoaderFactory == value)
            {
                return;
            }
            this._contentLoaderFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _contentLabelFactory:Function;

        /**
         * A function that generates an `ITextRenderer` that uses the result
         * of `contentLabelField` or `contentLabelFunction`.
         * Can be used to set properties on the `ITextRenderer`.
         *
         * @see feathers.core.ITextRenderer
         * @see feathers.core.FeathersControl#defaultTextRendererFactory
         * @see #contentLabelField
         * @see #contentLabelFunction
         */
        public function get contentLabelFactory():Function
        {
            return this._contentLabelFactory;
        }

        /**
         * @private
         */
        public function set contentLabelFactory(value:Function):void
        {
            if(this._contentLabelFactory == value)
            {
                return;
            }
            this._contentLabelFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _contentLabelProperties:Dictionary.<String, Object>;

        /**
         * A set of key/value pairs to be passed down to a content label.
         *
         * If the subcomponent has its own subcomponents, their properties
         * can be set too, using attribute `&#64;` notation. For example,
         * to set the skin on the thumb of a `SimpleScrollBar`
         * which is in a `Scroller` which is in a `List`,
         * you can use the following syntax:
         * `list.scrollerProperties.&#64;verticalScrollBarProperties.&#64;thumbProperties.defaultSkin = new Image(texture);`
         *
         * @see feathers.core.ITextRenderer
         * @see #contentLabelField
         * @see #contentLabelFunction
         */
        public function get contentLabelProperties():Dictionary.<String, Object>
        {
            if(!this._contentLabelProperties)
            {
                this._contentLabelProperties = new Dictionary.<String, Object>;
            }
            return this._contentLabelProperties;
        }

        /**
         * @private
         */
        public function set contentLabelProperties(value:Dictionary.<String, Object>):void
        {
            if(this._contentLabelProperties == value)
            {
                return;
            }
            this._contentLabelProperties = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var originalBackgroundWidth:Number = NaN;

        /**
         * @private
         */
        protected var originalBackgroundHeight:Number = NaN;

        /**
         * @private
         */
        protected var currentBackgroundSkin:DisplayObject;

        /**
         * @private
         */
        protected var _backgroundSkin:DisplayObject;

        /**
         * A background to behind the component's content.
         */
        public function get backgroundSkin():DisplayObject
        {
            return this._backgroundSkin;
        }

        /**
         * @private
         */
        public function set backgroundSkin(value:DisplayObject):void
        {
            if(this._backgroundSkin == value)
            {
                return;
            }

            if(this._backgroundSkin && this._backgroundSkin != this._backgroundDisabledSkin)
            {
                this.removeChild(this._backgroundSkin);
            }
            this._backgroundSkin = value;
            if(this._backgroundSkin && this._backgroundSkin.parent != this)
            {
                this._backgroundSkin.visible = false;
                this.addChildAt(this._backgroundSkin, 0);
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _backgroundDisabledSkin:DisplayObject;

        /**
         * A background to display when the component is disabled.
         */
        public function get backgroundDisabledSkin():DisplayObject
        {
            return this._backgroundDisabledSkin;
        }

        /**
         * @private
         */
        public function set backgroundDisabledSkin(value:DisplayObject):void
        {
            if(this._backgroundDisabledSkin == value)
            {
                return;
            }

            if(this._backgroundDisabledSkin && this._backgroundDisabledSkin != this._backgroundSkin)
            {
                this.removeChild(this._backgroundDisabledSkin);
            }
            this._backgroundDisabledSkin = value;
            if(this._backgroundDisabledSkin && this._backgroundDisabledSkin.parent != this)
            {
                this._backgroundDisabledSkin.visible = false;
                this.addChildAt(this._backgroundDisabledSkin, 0);
            }
            this.invalidate(INVALIDATION_FLAG_STYLES);
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
         * The minimum space, in pixels, between the component's top edge and
         * the component's content.
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
         * The minimum space, in pixels, between the component's right edge
         * and the component's content.
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
         * The minimum space, in pixels, between the component's bottom edge
         * and the component's content.
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
         * The minimum space, in pixels, between the component's left edge
         * and the component's content.
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
        override public function dispose():void
        {
            //the content may have come from outside of this class. it's up
            //to that code to dispose of the content. in fact, if we disposed
            //of it here, we might screw something up!
            if(this.content)
            {
                this.content.removeFromParent();
            }

            //however, we need to dispose these, if they exist, since we made
            //them here.
            if(this.contentImage)
            {
                this.contentImage.dispose();
                this.contentImage = null;
            }
            if(this.contentLabel)
            {
                DisplayObject(this.contentLabel).dispose();
                this.contentLabel = null;
            }
            super.dispose();
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
            var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);

            if(stylesInvalid || stateInvalid)
            {
                this.refreshBackgroundSkin();
            }

            if(dataInvalid)
            {
                this.commitData();
            }

            if(dataInvalid || stylesInvalid)
            {
                this.refreshContentLabelStyles();
            }

            sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

            if(dataInvalid || stylesInvalid || sizeInvalid)
            {
                this.layout();
            }

            if(sizeInvalid || stylesInvalid || stateInvalid)
            {
                if(this.currentBackgroundSkin)
                {
                    this.currentBackgroundSkin.width = this.actualWidth;
                    this.currentBackgroundSkin.height = this.actualHeight;
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
            if(this.content is FeathersControl)
            {
                FeathersControl(this.content).validate();
            }
            if(!this.content)
            {
                return this.setSizeInternal(0, 0, false);
            }
            var newWidth:Number = this.explicitWidth;
            var newHeight:Number = this.explicitHeight;
            if(needsWidth)
            {
                newWidth = this.content.width + this._paddingLeft + this._paddingRight;
                if(!isNaN(this.originalBackgroundWidth))
                {
                    newWidth = Math.max(newWidth, this.originalBackgroundWidth);
                }
            }
            if(needsHeight)
            {
                newHeight = this.content.height + this._paddingTop + this._paddingBottom;
                if(!isNaN(this.originalBackgroundHeight))
                {
                    newHeight = Math.max(newHeight, this.originalBackgroundHeight);
                }
            }
            return this.setSizeInternal(newWidth, newHeight, false);
        }

        /**
         * @private
         */
        protected function refreshBackgroundSkin():void
        {
            this.currentBackgroundSkin = this._backgroundSkin;
            if(!this._isEnabled && this._backgroundDisabledSkin)
            {
                if(this._backgroundSkin)
                {
                    this._backgroundSkin.visible = false;
                }
                this.currentBackgroundSkin = this._backgroundDisabledSkin;
            }
            else if(this._backgroundDisabledSkin)
            {
                this._backgroundDisabledSkin.visible = false;
            }
            if(this.currentBackgroundSkin)
            {
                if(isNaN(this.originalBackgroundWidth))
                {
                    this.originalBackgroundWidth = this.currentBackgroundSkin.width;
                }
                if(isNaN(this.originalBackgroundHeight))
                {
                    this.originalBackgroundHeight = this.currentBackgroundSkin.height;
                }
                this.currentBackgroundSkin.visible = true;
            }
        }

        /**
         * @private
         */
        protected function commitData():void
        {
            if(this._owner)
            {
                const newContent:DisplayObject = this.itemToContent(this._data);
                if(newContent != this.content)
                {
                    if(this.content)
                    {
                        this.content.removeFromParent();
                    }
                    this.content = newContent;
                    if(this.content)
                    {
                        this.addChild(this.content);
                    }
                }
            }
            else
            {
                if(this.content)
                {
                    this.content.removeFromParent();
                    this.content = null;
                }
            }
        }

        /**
         * @private
         */
        protected function refreshContentSource(source:Object):void
        {
            if(!this.contentImage)
            {
                this.contentImage = this._contentLoaderFactory.call() as ImageLoader;
            }
            this.contentImage.source = source;
        }

        /**
         * @private
         */
        protected function refreshContentLabel(label:String):void
        {
            if(label != null)
            {
                if(!this.contentLabel)
                {
                    const factory:Function = this._contentLabelFactory != null ? this._contentLabelFactory : FeathersControl.defaultTextRendererFactory;
                    this.contentLabel = ITextRenderer(factory.call());
                    FeathersControl(this.contentLabel).nameList.add(this.contentLabelName);
                }
                this.contentLabel.text = label;
            }
            else if(this.contentLabel)
            {
                DisplayObject(this.contentLabel).removeFromParent(true);
                this.contentLabel = null;
            }
        }

        /**
         * @private
         */
        protected function refreshContentLabelStyles():void
        {
            if(!this.contentLabel)
            {
                return;
            }
            const displayContentLabel:DisplayObject = DisplayObject(this.contentLabel);
            Dictionary.mapToObject(this._contentLabelProperties, displayContentLabel);
        }

        /**
         * @private
         */
        protected function layout():void
        {
            if(!this.content)
            {
                return;
            }

            switch(this._horizontalAlign)
            {
                case HORIZONTAL_ALIGN_CENTER:
                {
                    this.content.x = this._paddingLeft + (this.actualWidth - this._paddingLeft - this._paddingRight - this.content.width) / 2;
                    break;
                }
                case HORIZONTAL_ALIGN_RIGHT:
                {
                    this.content.x = this.actualWidth - this._paddingRight - this.content.width;
                    break;
                }
                default: //left
                {
                    this.content.x = this._paddingLeft;
                }
            }

            switch(this._verticalAlign)
            {
                case VERTICAL_ALIGN_TOP:
                {
                    this.content.y = this._paddingTop;
                    break;
                }
                case VERTICAL_ALIGN_BOTTOM:
                {
                    this.content.y = this.actualHeight - this._paddingBottom - this.content.height;
                    break;
                }
                default: //middle
                {
                    this.content.y = this._paddingTop + (this.actualHeight - this._paddingTop - this._paddingBottom - this.content.height) / 2;
                }
            }
        }
    }
}
