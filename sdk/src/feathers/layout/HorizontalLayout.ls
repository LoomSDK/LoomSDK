/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.layout
{
    import feathers.core.IFeathersControl;

    import loom2d.math.Point;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.EventDispatcher;

    /**
     * Dispatched when a property of the layout changes, indicating that a
     * redraw is probably needed.
     *
     * @eventType loom2d.events.Event.CHANGE
     */
    [Event(name="change",type="loom2d.events.Event")]

    /**
     * Positions items from left to right in a single row.
     *
     * @see http://wiki.starling-framework.org/feathers/horizontal-layout
     */
    public class HorizontalLayout extends EventDispatcher implements IVariableVirtualLayout, ITrimmedVirtualLayout
    {
        /**
         * The items will be aligned to the top of the bounds.
         */
        public static const VERTICAL_ALIGN_TOP:String = "top";

        /**
         * The items will be aligned to the middle of the bounds.
         */
        public static const VERTICAL_ALIGN_MIDDLE:String = "middle";

        /**
         * The items will be aligned to the bottom of the bounds.
         */
        public static const VERTICAL_ALIGN_BOTTOM:String = "bottom";

        /**
         * The items will fill the height of the bounds.
         */
        public static const VERTICAL_ALIGN_JUSTIFY:String = "justify";

        /**
         * If the total item width is smaller than the width of the bounds, the
         * items will be aligned to the left.
         */
        public static const HORIZONTAL_ALIGN_LEFT:String = "left";

        /**
         * If the total item width is smaller than the width of the bounds, the
         * items will be aligned to the center.
         */
        public static const HORIZONTAL_ALIGN_CENTER:String = "center";

        /**
         * If the total item width is smaller than the width of the bounds, the
         * items will be aligned to the right.
         */
        public static const HORIZONTAL_ALIGN_RIGHT:String = "right";

        /**
         * Constructor.
         */
        public function HorizontalLayout()
        {
        }

        /**
         * @private
         */
        protected var _widthCache:Vector.<int> = [];

        /**
         * @private
         */
        private static const HELPER_POINT:Point;


        /**
         * @private
         */
        protected var _discoveredItemsCache:Vector.<DisplayObject> = new <DisplayObject>[];

        /**
         * @private
         */
        protected var _gap:Number = 0;

        /**
         * The space, in pixels, between items.
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
            this.dispatchEventWith(Event.CHANGE);
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
         * The minimum space, in pixels, above the items.
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
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _paddingRight:Number = 0;

        /**
         * The space, in pixels, after the last item.
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
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _paddingBottom:Number = 0;

        /**
         * The minimum space, in pixels, above the items.
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
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _paddingLeft:Number = 0;

        /**
         * The space, in pixels, before the first item.
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
            this.dispatchEventWith(Event.CHANGE);
        }


        /**
         * @private
         */
        protected var _verticalAlign:String = VERTICAL_ALIGN_TOP;

        [Inspectable(type="String",enumeration="top,middle,bottom,justify")]
        /**
         * The alignment of the items vertically, on the y-axis.
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
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _horizontalAlign:String = HORIZONTAL_ALIGN_LEFT;

        [Inspectable(type="String",enumeration="left,center,right")]
        /**
         * If the total item width is less than the bounds, the positions of
         * the items can be aligned horizontally.
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
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _useVirtualLayout:Boolean = true;

        /**
         * @inheritDoc
         */
        public function get useVirtualLayout():Boolean
        {
            return this._useVirtualLayout;
        }

        /**
         * @private
         */
        public function set useVirtualLayout(value:Boolean):void
        {
            if(this._useVirtualLayout == value)
            {
                return;
            }
            this._useVirtualLayout = value;
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _hasVariableItemDimensions:Boolean = false;

        /**
         * @inheritDoc
         */
        public function get hasVariableItemDimensions():Boolean
        {
            return this._hasVariableItemDimensions;
        }

        /**
         * @private
         */
        public function set hasVariableItemDimensions(value:Boolean):void
        {
            if(this._hasVariableItemDimensions == value)
            {
                return;
            }
            this._hasVariableItemDimensions = value;
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * Determines if items will be set invisible if they are outside the
         * view port. Can improve performance, especially for non-virtual
         * layouts. If `true`, you will not be able to manually
         * change the `visible` property of any items in the layout.
         */
        public var manageVisibility:Boolean = false;

        /**
         * @private
         */
        protected var _beforeVirtualizedItemCount:int = 0;

        /**
         * @inheritDoc
         */
        public function get beforeVirtualizedItemCount():int
        {
            return this._beforeVirtualizedItemCount;
        }

        /**
         * @private
         */
        public function set beforeVirtualizedItemCount(value:int):void
        {
            if(this._beforeVirtualizedItemCount == value)
            {
                return;
            }
            this._beforeVirtualizedItemCount = value;
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _afterVirtualizedItemCount:int = 0;

        /**
         * @inheritDoc
         */
        public function get afterVirtualizedItemCount():int
        {
            return this._afterVirtualizedItemCount;
        }

        /**
         * @private
         */
        public function set afterVirtualizedItemCount(value:int):void
        {
            if(this._afterVirtualizedItemCount == value)
            {
                return;
            }
            this._afterVirtualizedItemCount = value;
            this.dispatchEventWith(Event.CHANGE);
        }

        /**
         * @private
         */
        protected var _typicalItemWidth:Number = 0;

        /**
         * @inheritDoc
         */
        public function get typicalItemWidth():Number
        {
            return this._typicalItemWidth;
        }

        /**
         * @private
         */
        public function set typicalItemWidth(value:Number):void
        {
            if(this._typicalItemWidth == value)
            {
                return;
            }
            this._typicalItemWidth = value;
        }

        /**
         * @private
         */
        protected var _typicalItemHeight:Number = 0;

        /**
         * @inheritDoc
         */
        public function get typicalItemHeight():Number
        {
            return this._typicalItemHeight;
        }

        /**
         * @private
         */
        public function set typicalItemHeight(value:Number):void
        {
            if(this._typicalItemHeight == value)
            {
                return;
            }
            this._typicalItemHeight = value;
        }

        /**
         * @private
         */
        protected var _scrollPositionHorizontalAlign:String = HORIZONTAL_ALIGN_CENTER;

        [Inspectable(type="String",enumeration="left,center,right")]
        /**
         * When the scroll position is calculated for an item, an attempt will
         * be made to align the item to this position.
         */
        public function get scrollPositionHorizontalAlign():String
        {
            return this._scrollPositionHorizontalAlign;
        }

        /**
         * @private
         */
        public function set scrollPositionHorizontalAlign(value:String):void
        {
            this._scrollPositionHorizontalAlign = value;
        }

        /**
         * @inheritDoc
         */
        public function layout(items:Vector.<DisplayObject>, viewPortBounds:ViewPortBounds = null, result:LayoutBoundsResult = null):LayoutBoundsResult
        {
            const scrollX:Number = viewPortBounds ? viewPortBounds.scrollX : 0;
            const scrollY:Number = viewPortBounds ? viewPortBounds.scrollY : 0;
            const boundsX:Number = viewPortBounds ? viewPortBounds.x : 0;
            const boundsY:Number = viewPortBounds ? viewPortBounds.y : 0;
            const minWidth:Number = viewPortBounds ? viewPortBounds.minWidth : 0;
            const minHeight:Number = viewPortBounds ? viewPortBounds.minHeight : 0;
            const maxWidth:Number = viewPortBounds ? viewPortBounds.maxWidth : Number.POSITIVE_INFINITY;
            const maxHeight:Number = viewPortBounds ? viewPortBounds.maxHeight : Number.POSITIVE_INFINITY;
            const explicitWidth:Number = viewPortBounds ? viewPortBounds.explicitWidth : NaN;
            const explicitHeight:Number = viewPortBounds ? viewPortBounds.explicitHeight : NaN;

            if(!this._useVirtualLayout || this._hasVariableItemDimensions ||
                this._verticalAlign != VERTICAL_ALIGN_JUSTIFY || isNaN(explicitHeight))
            {
                this.validateItems(items);
            }

            this._discoveredItemsCache.length = 0;
            var maxItemHeight:Number = this._useVirtualLayout ? this._typicalItemHeight : 0;
            var positionX:Number = boundsX + this._paddingLeft;
            if(this._useVirtualLayout && !this._hasVariableItemDimensions)
            {
                positionX += (this._beforeVirtualizedItemCount * (this._typicalItemWidth + this._gap));
            }
            const itemCount:int = items.length;
            for(var i:int = 0; i < itemCount; i++)
            {
                var item:DisplayObject = items[i];
                var iNormalized:int = i + this._beforeVirtualizedItemCount;
                if(this._useVirtualLayout && !item)
                {
                    if(!this._hasVariableItemDimensions || isNaN(this._widthCache[iNormalized]))
                    {
                        positionX += this._typicalItemWidth + this._gap;
                    }
                    else
                    {
                        positionX += this._widthCache[iNormalized] + this._gap;
                    }
                }
                else
                {
                    if(item is ILayoutDisplayObject)
                    {
                        var layoutItem:ILayoutDisplayObject = ILayoutDisplayObject(item);
                        if(!layoutItem.includeInLayout)
                        {
                            continue;
                        }
                    }
                    item.x = positionX;
                    if(this._useVirtualLayout)
                    {
                        if(this._hasVariableItemDimensions)
                        {
                            if(isNaN(this._widthCache[iNormalized]))
                            {
                                this._widthCache[iNormalized] = item.width;
                                this.dispatchEventWith(Event.CHANGE);
                            }
                        }
                        ///LOOM-1786: This was >= 0 back when _typicalItemWidth defaulted to -1. This change should be OK, but it is untested throroughly...
                        else if(this._typicalItemWidth > 0)
                        {
                            item.width = this._typicalItemWidth;
                        }
                    }
                    positionX += item.width + this._gap;
                    maxItemHeight = Math.max(maxItemHeight, item.height);
                    if(this._useVirtualLayout)
                    {
                        this._discoveredItemsCache.push(item);
                    }
                }
            }
            if(this._useVirtualLayout && !this._hasVariableItemDimensions)
            {
                positionX += (this._afterVirtualizedItemCount * (this._typicalItemWidth + this._gap));
            }

            const discoveredItems:Vector.<DisplayObject> = this._useVirtualLayout ? this._discoveredItemsCache : items;
            const discoveredItemCount:int = discoveredItems.length;

            const totalHeight:Number = maxItemHeight + this._paddingTop + this._paddingBottom;
            const availableHeight:Number = isNaN(explicitHeight) ? Math.min(maxHeight, Math.max(minHeight, totalHeight)) : explicitHeight;
            const totalWidth:Number = positionX - this._gap + this._paddingRight - boundsX;
            const availableWidth:Number = isNaN(explicitWidth) ? Math.min(maxWidth, Math.max(minWidth, totalWidth)) : explicitWidth;

            if(totalWidth < availableWidth)
            {
                var horizontalAlignOffsetX:Number = 0;
                if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
                {
                    horizontalAlignOffsetX = availableWidth - totalWidth;
                }
                else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
                {
                    horizontalAlignOffsetX = (availableWidth - totalWidth) / 2;
                }
                if(horizontalAlignOffsetX != 0)
                {
                    for(i = 0; i < discoveredItemCount; i++)
                    {
                        item = discoveredItems[i];
                        item.x += horizontalAlignOffsetX;
                    }
                }
            }

            for(i = 0; i < discoveredItemCount; i++)
            {
                item = discoveredItems[i];
                switch(this._verticalAlign)
                {
                    case VERTICAL_ALIGN_BOTTOM:
                    {
                        item.y = boundsY + availableHeight - this._paddingBottom - item.height;
                        break;
                    }
                    case VERTICAL_ALIGN_MIDDLE:
                    {
                        item.y = boundsY + this._paddingTop + (availableHeight - this._paddingTop - this._paddingBottom - item.height) / 2;
                        break;
                    }
                    case VERTICAL_ALIGN_JUSTIFY:
                    {
                        item.y = boundsY + this._paddingTop;
                        item.height = availableHeight - this._paddingTop - this._paddingBottom;
                        break;
                    }
                    default: //top
                    {
                        item.y = boundsY + this._paddingTop;
                    }
                }
                if(this.manageVisibility)
                {
                    item.visible = ((item.x + item.width) >= (boundsX + scrollX)) && (item.x < (scrollX + availableWidth));
                }
            }
            this._discoveredItemsCache.length = 0;

            if(!result)
            {
                result = new LayoutBoundsResult();
            }
            result.contentWidth = totalWidth;
            result.contentHeight = this._verticalAlign == VERTICAL_ALIGN_JUSTIFY ? availableHeight : totalHeight;
            result.viewPortWidth = availableWidth;
            result.viewPortHeight = availableHeight;
            return result;
        }

        /**
         * @inheritDoc
         */
        public function measureViewPort(itemCount:int, viewPortBounds:ViewPortBounds = null):Point
        {
            const explicitWidth:Number = viewPortBounds ? viewPortBounds.explicitWidth : NaN;
            const explicitHeight:Number = viewPortBounds ? viewPortBounds.explicitHeight : NaN;
            const needsWidth:Boolean = isNaN(explicitWidth);
            const needsHeight:Boolean = isNaN(explicitHeight);
            if(!needsWidth && !needsHeight)
            {
                HELPER_POINT.x = explicitWidth;
                HELPER_POINT.y = explicitHeight;
                return HELPER_POINT;
            }

            const minWidth:Number = viewPortBounds ? viewPortBounds.minWidth : 0;
            const minHeight:Number = viewPortBounds ? viewPortBounds.minHeight : 0;
            const maxWidth:Number = viewPortBounds ? viewPortBounds.maxWidth : Number.POSITIVE_INFINITY;
            const maxHeight:Number = viewPortBounds ? viewPortBounds.maxHeight : Number.POSITIVE_INFINITY;

            var maxItemHeight:Number = this._typicalItemHeight;
            var positionX:Number = 0;

            if(!this._hasVariableItemDimensions)
            {
                positionX += ((this._typicalItemWidth + this._gap) * itemCount);
            }
            else
            {
                for(var i:int = 0; i < itemCount; i++)
                {
                    if(isNaN(this._widthCache[i]))
                    {
                        positionX += this._typicalItemWidth + this._gap;
                    }
                    else
                    {
                        positionX += this._widthCache[i] + this._gap;
                    }
                }
            }

            if(needsWidth)
            {
                HELPER_POINT.x = Math.min(maxWidth, Math.max(minWidth, positionX - this._gap + this._paddingLeft + this._paddingRight));
            }
            else
            {
                HELPER_POINT.x = explicitWidth;
            }

            if(needsHeight)
            {
                HELPER_POINT.y = Math.min(maxHeight, Math.max(minHeight, maxItemHeight + this._paddingTop + this._paddingBottom));
            }
            else
            {
                HELPER_POINT.y = explicitHeight;
            }

            return HELPER_POINT;
        }

        /**
         * @inheritDoc
         */
        public function resetVariableVirtualCache():void
        {
            this._widthCache.length = 0;
        }

        /**
         * @inheritDoc
         */
        public function resetVariableVirtualCacheAtIndex(index:int, item:DisplayObject = null):void
        {
            //delete this._widthCache[index];
            _widthCache[index] = null;
            if(item)
            {
                this._widthCache[index] = item.width;
                this.dispatchEventWith(Event.CHANGE);
            }
        }

        /**
         * @inheritDoc
         */
        public function addToVariableVirtualCacheAtIndex(index:int, item:DisplayObject = null):void
        {
            const widthValue:Number = item ? item.width : null;
            this._widthCache.splice(index, 0, widthValue);
        }

        /**
         * @inheritDoc
         */
        public function removeFromVariableVirtualCacheAtIndex(index:int):void
        {
            this._widthCache.splice(index, 1);
        }

        /**
         * @inheritDoc
         */
        public function getVisibleIndicesAtScrollPosition(scrollX:Number, scrollY:Number, width:Number, height:Number, itemCount:int, result:Vector.<int> = null):Vector.<int>
        {
            if(!result)
            {
                result = new <int>[];
            }
            result.length = 0;
            const singleItemWidth:int = Math.max(1, (this._typicalItemWidth + this._gap));
            const visibleTypicalItemCount:int = Math.ceil(width / singleItemWidth);
            if(!this._hasVariableItemDimensions)
            {
                //this case can be optimized because we know that every item has
                //the same width
                var totalItemWidth:Number = itemCount * (this._typicalItemWidth + this._gap) - this._gap;
                var indexOffset:int = 0;
                if(totalItemWidth < width)
                {
                    if(this._horizontalAlign == HORIZONTAL_ALIGN_RIGHT)
                    {
                        indexOffset = Math.ceil((width - totalItemWidth) / singleItemWidth);
                    }
                    else if(this._horizontalAlign == HORIZONTAL_ALIGN_CENTER)
                    {
                        indexOffset = Math.ceil(((width - totalItemWidth) / singleItemWidth) / 2);
                    }
                }
                var minimum:int = -indexOffset + Math.max(0, int((scrollX - this._paddingLeft) / singleItemWidth));
                //if we're scrolling beyond the final item, we should keep the
                //indices consistent so that items aren't destroyed and
                //recreated unnecessarily
                var maximum:int = Math.min(itemCount - 1, minimum + visibleTypicalItemCount);
                minimum = Math.max(0, maximum - visibleTypicalItemCount);
                for(var i:int = minimum; i <= maximum; i++)
                {
                    result.push(i);
                }
                return result;
            }
            const maxPositionX:Number = scrollX + width;
            var positionX:Number = this._paddingLeft;
            for(i = 0; i < itemCount; i++)
            {
                if(isNaN(this._widthCache[i]))
                {
                    var itemWidth:Number = this._typicalItemWidth;
                }
                else
                {
                    itemWidth = this._widthCache[i];
                }
                var oldPositionX:Number = positionX;
                positionX += itemWidth + this._gap;
                if(positionX > scrollX && oldPositionX < maxPositionX)
                {
                    result.push(i);
                }

                if(positionX >= maxPositionX)
                {
                    break;
                }
            }

            //similar to above, in order to avoid costly destruction and
            //creation of item renderers, we're going to fill in some extra
            //indices
            var resultLength:int = result.length;
            var visibleItemCountDifference:int = visibleTypicalItemCount - resultLength;
            if(visibleItemCountDifference > 0 && resultLength > 0)
            {
                //add extra items before the first index
                const firstExistingIndex:int = result[0];
                const lastIndexToAdd:int = Math.max(0, firstExistingIndex - visibleItemCountDifference);
                for(i = firstExistingIndex - 1; i >= lastIndexToAdd; i--)
                {
                    result.unshift(i);
                }
            }
            resultLength = result.length;
            visibleItemCountDifference = visibleTypicalItemCount - resultLength;
            if(visibleItemCountDifference > 0)
            {
                //add extra items after the last index
                const startIndex:int = resultLength > 0 ? (result[resultLength - 1] + 1) : 0;
                const endIndex:int = Math.min(itemCount, startIndex + visibleItemCountDifference);
                for(i = startIndex; i < endIndex; i++)
                {
                    result.push(i);
                }
            }
            return result;
        }

        /**
         * @inheritDoc
         */
        public function getScrollPositionForIndex(index:int, items:Vector.<DisplayObject>, x:Number, y:Number, width:Number, height:Number):Point
        {

            var positionX:Number = x + this._paddingLeft;
            var startIndexOffset:int = 0;
            var endIndexOffset:Number = 0;
            if(this._useVirtualLayout && !this._hasVariableItemDimensions)
            {
                startIndexOffset = this._beforeVirtualizedItemCount;
                positionX += (this._beforeVirtualizedItemCount * (this._typicalItemWidth + this._gap));

                endIndexOffset = Math.max(0, index - items.length - this._beforeVirtualizedItemCount + 1);
                positionX += (endIndexOffset * (this._typicalItemWidth + this._gap));
            }
            index -= (startIndexOffset + endIndexOffset);
            var lastWidth:Number = 0;
            for(var i:int = 0; i <= index; i++)
            {
                var item:DisplayObject = items[i];
                var iNormalized:int = i + startIndexOffset;
                if(this._useVirtualLayout && !item)
                {
                    if(!this._hasVariableItemDimensions || isNaN(this._widthCache[iNormalized]))
                    {
                        lastWidth = this._typicalItemWidth;
                    }
                    else
                    {
                        lastWidth = this._widthCache[iNormalized];
                    }
                }
                else
                {
                    if(this._hasVariableItemDimensions)
                    {
                        if(isNaN(this._widthCache[iNormalized]))
                        {
                            this._widthCache[iNormalized] = item.width;
                            this.dispatchEventWith(Event.CHANGE);
                        }
                    }
                    ///LOOM-1786: This was >= 0 back when _typicalItemWidth defaulted to -1. This change should be OK, but it is untested throroughly...
                    else if(this._typicalItemWidth > 0)
                    {
                        item.width = this._typicalItemWidth;
                    }
                    lastWidth = item.width;
                }
                positionX += lastWidth + this._gap;
            }
            positionX -= (lastWidth + this._gap);
            if(this._scrollPositionHorizontalAlign == HORIZONTAL_ALIGN_CENTER)
            {
                positionX -= (width - lastWidth) / 2;
            }
            else if(this._scrollPositionHorizontalAlign == HORIZONTAL_ALIGN_RIGHT)
            {
                positionX -= (width - lastWidth);
            }
            HELPER_POINT.x = positionX;
            HELPER_POINT.y = 0;

            return HELPER_POINT;
        }

        /**
         * @private
         */
        protected function validateItems(items:Vector.<DisplayObject>):void
        {
            const itemCount:int = items.length;
            for(var i:int = 0; i < itemCount; i++)
            {
                var control:IFeathersControl = items[i] as IFeathersControl;
                if(control)
                {
                    control.validate();
                }
            }
        }
    }
}
