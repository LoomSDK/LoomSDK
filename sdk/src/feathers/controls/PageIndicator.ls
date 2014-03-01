/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import feathers.core.FeathersControl;
    import feathers.core.IFeathersControl;
    import feathers.layout.HorizontalLayout;
    import feathers.layout.ILayout;
    import feathers.layout.IVirtualLayout;
    import feathers.layout.LayoutBoundsResult;
    import feathers.layout.VerticalLayout;
    import feathers.layout.ViewPortBounds;

    import loom2d.math.Point;

    import loom2d.display.DisplayObject;
    import loom2d.display.Quad;
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    /**
     * Dispatched when the selected item changes.
     *
     * @eventType starling.events.Event.CHANGE
     */
    [Event(name="change",type="starling.events.Event")]

    /**
     * Displays a selected index, usually corresponding to a page index in
     * another UI control, using a highlighted symbol.
     *
     * @see http://wiki.starling-framework.org/feathers/page-indicator
     */
    public class PageIndicator extends FeathersControl
    {
        /**
         * @private
         */
        private static const LAYOUT_RESULT:LayoutBoundsResult = new LayoutBoundsResult();

        /**
         * @private
         */
        private static const SUGGESTED_BOUNDS:ViewPortBounds = new ViewPortBounds();

        /**
         * @private
         */
        private static const HELPER_POINT:Point = new Point();

        /**
         * @private
         */
        private static const HELPER_TOUCHES_VECTOR:Vector.<Touch> = new <Touch>[];

        /**
         * The page indicator's symbols will be positioned vertically, from top
         * to bottom.
         */
        public static const DIRECTION_VERTICAL:String = "vertical";

        /**
         * The page indicator's symbols will be positioned horizontally, from
         * left to right.
         */
        public static const DIRECTION_HORIZONTAL:String = "horizontal";

        /**
         * The symbols will be vertically aligned to the top.
         */
        public static const VERTICAL_ALIGN_TOP:String = "top";

        /**
         * The symbols will be vertically aligned to the middle.
         */
        public static const VERTICAL_ALIGN_MIDDLE:String = "middle";

        /**
         * The symbols will be vertically aligned to the bottom.
         */
        public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";

        /**
         * The symbols will be horizontally aligned to the left.
         */
        public static const HORIZONTAL_ALIGN_LEFT:String = "left";

        /**
         * The symbols will be horizontally aligned to the center.
         */
        public static const HORIZONTAL_ALIGN_CENTER:String = "center";

        /**
         * The symbols will be horizontally aligned to the right.
         */
        public static const HORIZONTAL_ALIGN_RIGHT:String = "right";

        /**
         * @private
         */
        protected static function defaultSelectedSymbolFactory():Quad
        {
            return new Quad(25, 25, 0xffffff);
        }

        /**
         * @private
         */
        protected static function defaultNormalSymbolFactory():Quad
        {
            return new Quad(25, 25, 0xcccccc);
        }

        /**
         * Constructor.
         */
        public function PageIndicator()
        {
            this.isQuickHitAreaEnabled = true;
            this.addEventListener(TouchEvent.TOUCH, touchHandler);
        }

        /**
         * @private
         */
        protected var selectedSymbol:DisplayObject;

        /**
         * @private
         */
        protected var cache:Vector.<DisplayObject> = new <DisplayObject>[];

        /**
         * @private
         */
        protected var unselectedSymbols:Vector.<DisplayObject> = new <DisplayObject>[];

        /**
         * @private
         */
        protected var symbols:Vector.<DisplayObject> = new <DisplayObject>[];

        /**
         * @private
         */
        protected var touchPointID:int = -1;

        /**
         * @private
         */
        protected var _pageCount:int = 1;

        /**
         * The number of available pages.
         */
        public function get pageCount():int
        {
            return this._pageCount;
        }

        /**
         * @private
         */
        public function set pageCount(value:int):void
        {
            if(this._pageCount == value)
            {
                return;
            }
            this._pageCount = value;
            this.invalidate(INVALIDATION_FLAG_DATA);
        }

        /**
         * @private
         */
        protected var _selectedIndex:int = 0;

        /**
         * The currently selected index.
         */
        public function get selectedIndex():int
        {
            return this._selectedIndex;
        }

        /**
         * @private
         */
        public function set selectedIndex(value:int):void
        {
            value = Math.max(0, Math.min(value, this._pageCount - 1));
            if(this._selectedIndex == value)
            {
                return;
            }
            this._selectedIndex = value;
            this.invalidate(INVALIDATION_FLAG_SELECTED);
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _layout:ILayout;

        /**
         * @private
         */
        protected var _direction:String = DIRECTION_HORIZONTAL;

        [Inspectable(type="String",enumeration="horizontal,vertical")]
        /**
         * The symbols may be positioned vertically or horizontally.
         */
        public function get direction():String
        {
            return this._direction;
        }

        /**
         * @private
         */
        public function set direction(value:String):void
        {
            if(this._direction == value)
            {
                return;
            }
            this._direction = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _horizontalAlign:String = HORIZONTAL_ALIGN_CENTER;

        [Inspectable(type="String",enumeration="horizontal,vertical")]
        /**
         * The alignment of the symbols on the horizontal axis.
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
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _verticalAlign:String = VERTICAL_ALIGN_MIDDLE;

        [Inspectable(type="String",enumeration="top,middle,bottom")]
        /**
         * The alignment of the symbols on the vertical axis.
         */
        public function get verticalAlign():String
        {
            return this._verticalAlign;
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
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
        }

        /**
         * @private
         */
        protected var _gap:Number = 0;

        /**
         * The spacing, in pixels, between symbols.
         */
        public function get gap():Number
        {
            return this._gap;
        }

        /**
         * @private
         */
        public function set gap(value:Number):void
        {
            if(this._gap == value)
            {
                return;
            }
            this._gap = value;
            this.invalidate(INVALIDATION_FLAG_LAYOUT);
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
         * The minimum space, in pixels, between the top edge of the component
         * and the top edge of the content.
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
         * The minimum space, in pixels, between the right edge of the component
         * and the right edge of the content.
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
         * The minimum space, in pixels, between the bottom edge of the component
         * and the bottom edge of the content.
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
         * The minimum space, in pixels, between the left edge of the component
         * and the left edge of the content.
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
        protected var _normalSymbolFactory:Function = defaultNormalSymbolFactory;

        /**
         * A function used to create a normal symbol. May be any Starling
         * display object.
         *
         * This function should have the following signature:
         * `function():DisplayObject`
         *
         * @see starling.display.DisplayObject
         * @see #selectedSymbolFactory
         */
        public function get normalSymbolFactory():Function
        {
            return this._normalSymbolFactory;
        }

        /**
         * @private
         */
        public function set normalSymbolFactory(value:Function):void
        {
            if(this._normalSymbolFactory == value)
            {
                return;
            }
            this._normalSymbolFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        protected var _selectedSymbolFactory:Function = defaultSelectedSymbolFactory;

        /**
         * A function used to create a selected symbol. May be any Starling
         * display object.
         *
         * This function should have the following signature:
         * `function():DisplayObject`
         *
         * @see starling.display.DisplayObject
         * @see #normalSymbolFactory
         */
        public function get selectedSymbolFactory():Function
        {
            return this._selectedSymbolFactory;
        }

        /**
         * @private
         */
        public function set selectedSymbolFactory(value:Function):void
        {
            if(this._selectedSymbolFactory == value)
            {
                return;
            }
            this._selectedSymbolFactory = value;
            this.invalidate(INVALIDATION_FLAG_STYLES);
        }

        /**
         * @private
         */
        override protected function draw():void
        {
            const dataInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_DATA);
            const selectionInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SELECTED);
            const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
            const layoutInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_LAYOUT);

            if(dataInvalid || selectionInvalid || stylesInvalid)
            {
                this.refreshSymbols(stylesInvalid);
            }

            this.layoutSymbols(layoutInvalid);
        }

        /**
         * @private
         */
        protected function refreshSymbols(symbolsInvalid:Boolean):void
        {
            this.symbols.length = 0;
            const temp:Vector.<DisplayObject> = this.cache;
            if(symbolsInvalid)
            {
                var symbolCount:int = this.unselectedSymbols.length;
                for(var i:int = 0; i < symbolCount; i++)
                {
                    var symbol:DisplayObject = this.unselectedSymbols.shift();
                    this.removeChild(symbol, true);
                }
                if(this.selectedSymbol)
                {
                    this.removeChild(this.selectedSymbol, true);
                    this.selectedSymbol = null;
                }
            }
            this.cache = this.unselectedSymbols;
            this.unselectedSymbols = temp;
            for(i = 0; i < this._pageCount; i++)
            {
                if(i == this._selectedIndex)
                {
                    if(!this.selectedSymbol)
                    {
                        this.selectedSymbol = this._selectedSymbolFactory() as DisplayObject;
                        this.addChild(this.selectedSymbol);
                    }
                    this.symbols.push(this.selectedSymbol);
                    if(this.selectedSymbol is IFeathersControl)
                    {
                        IFeathersControl(this.selectedSymbol).validate();
                    }
                }
                else
                {
                    if(this.cache.length > 0)
                    {
                        symbol = this.cache.shift();
                    }
                    else
                    {
                        symbol = this._normalSymbolFactory() as DisplayObject;
                        this.addChild(symbol);
                    }
                    this.unselectedSymbols.push(symbol);
                    this.symbols.push(symbol);
                    if(symbol is IFeathersControl)
                    {
                        IFeathersControl(symbol).validate();
                    }
                }
            }

            symbolCount = this.cache.length;
            for(i = 0; i < symbolCount; i++)
            {
                symbol = this.cache.shift();
                this.removeChild(symbol, true);
            }

        }

        /**
         * @private
         */
        protected function layoutSymbols(layoutInvalid:Boolean):void
        {
            if(layoutInvalid)
            {
                if(this._direction == DIRECTION_VERTICAL && !(this._layout is VerticalLayout))
                {
                    this._layout = new VerticalLayout();
                    IVirtualLayout(this._layout).useVirtualLayout = false;
                }
                else if(this._direction != DIRECTION_VERTICAL && !(this._layout is HorizontalLayout))
                {
                    this._layout = new HorizontalLayout();
                    IVirtualLayout(this._layout).useVirtualLayout = false;
                }
                if(this._layout is VerticalLayout)
                {
                    const verticalLayout:VerticalLayout = VerticalLayout(this._layout);
                    verticalLayout.paddingTop = this._paddingTop;
                    verticalLayout.paddingRight = this._paddingRight;
                    verticalLayout.paddingBottom = this._paddingBottom;
                    verticalLayout.paddingLeft = this._paddingLeft;
                    verticalLayout.gap = this._gap;
                    verticalLayout.horizontalAlign = this._horizontalAlign;
                    verticalLayout.verticalAlign = this._verticalAlign;
                }
                if(this._layout is HorizontalLayout)
                {
                    const horizontalLayout:HorizontalLayout = HorizontalLayout(this._layout);
                    horizontalLayout.paddingTop = this._paddingTop;
                    horizontalLayout.paddingRight = this._paddingRight;
                    horizontalLayout.paddingBottom = this._paddingBottom;
                    horizontalLayout.paddingLeft = this._paddingLeft;
                    horizontalLayout.gap = this._gap;
                    horizontalLayout.horizontalAlign = this._horizontalAlign;
                    horizontalLayout.verticalAlign = this._verticalAlign;
                }
            }
            SUGGESTED_BOUNDS.x = SUGGESTED_BOUNDS.y = 0;
            SUGGESTED_BOUNDS.scrollX = SUGGESTED_BOUNDS.scrollY = 0;
            SUGGESTED_BOUNDS.explicitWidth = this.explicitWidth;
            SUGGESTED_BOUNDS.explicitHeight = this.explicitHeight;
            SUGGESTED_BOUNDS.maxWidth = this._maxWidth;
            SUGGESTED_BOUNDS.maxHeight = this._maxHeight;
            SUGGESTED_BOUNDS.minWidth = this._minWidth;
            SUGGESTED_BOUNDS.minHeight = this._minHeight;
            this._layout.layout(this.symbols, SUGGESTED_BOUNDS, LAYOUT_RESULT);
            this.setSizeInternal(LAYOUT_RESULT.contentWidth, LAYOUT_RESULT.contentHeight, false);
        }

        /**
         * @private
         */
        protected function touchHandler(event:TouchEvent):void
        {
            if(!this._isEnabled)
            {
                this.touchPointID = -1;
                return;
            }

            const touches:Vector.<Touch> = event.getTouches(this, null, HELPER_TOUCHES_VECTOR);
            if(touches.length == 0)
            {
                //end of hover
                return;
            }
            if(this.touchPointID >= 0)
            {
                var touch:Touch;
                for each(var currentTouch:Touch in touches)
                {
                    if(currentTouch.id == this.touchPointID)
                    {
                        touch = currentTouch;
                        break;
                    }
                }

                if(!touch)
                {
                    //end of hover
                    HELPER_TOUCHES_VECTOR.length = 0;
                    return;
                }

                if(touch.phase == TouchPhase.ENDED)
                {
                    this.touchPointID = -1;
                    HELPER_POINT = touch.getLocation(this.stage);
                    const isInBounds:Boolean = this.contains(this.stage.hitTest(HELPER_POINT, true));
                    if(isInBounds)
                    {
                        HELPER_POINT = this.globalToLocal(HELPER_POINT);
                        if(this._direction == DIRECTION_VERTICAL)
                        {
                            if(HELPER_POINT.y < this.selectedSymbol.y)
                            {
                                this.selectedIndex = Math.max(0, this._selectedIndex - 1);
                            }
                            if(HELPER_POINT.y > (this.selectedSymbol.y + this.selectedSymbol.height))
                            {
                                this.selectedIndex = Math.min(this._pageCount - 1, this._selectedIndex + 1);
                            }
                        }
                        else
                        {
                            if(HELPER_POINT.x < this.selectedSymbol.x)
                            {
                                this.selectedIndex = Math.max(0, this._selectedIndex - 1);
                            }
                            if(HELPER_POINT.x > (this.selectedSymbol.x + this.selectedSymbol.width))
                            {
                                this.selectedIndex = Math.min(this._pageCount - 1, this._selectedIndex + 1);
                            }
                        }
                    }
                }
            }
            else //if we get here, we don't have a saved touch ID yet
            {
                for each(touch in touches)
                {
                    if(touch.phase == TouchPhase.BEGAN)
                    {
                        this.touchPointID = touch.id;
                        break;
                    }
                }
            }
            HELPER_TOUCHES_VECTOR.length = 0;
        }

    }
}
