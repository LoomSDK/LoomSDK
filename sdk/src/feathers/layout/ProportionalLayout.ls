package feathers.layout
{
    import loom2d.events.EventDispatcher;
    import loom2d.math.Point;
    import loom2d.display.DisplayObject;

    protected enum DecomposedDimensionType
    {
        DDT_PIXEL,
        DDT_PERCENT
    }

    /// Utility class to decompose a string like "100px" or "100%"" into a
    /// format that can be easily processed. 
    protected class DecomposedDimension
    {
        public var type:DecomposedDimensionType;
        public var value:Number;

        public function toString():String
        {
            var typeStr = "unknown";
            switch(type)
            {
                case DecomposedDimensionType.DDT_PIXEL: typeStr = "px"; break;
                case DecomposedDimensionType.DDT_PERCENT: typeStr = "%"; break;
            }
            return "[DecomposedDimension type=" + typeStr + ", value=" + value + "]";
        }

        public static function fromString(dim:String):DecomposedDimension
        {
            // Trivial cases.
            if(dim == null || dim == "")
                return null;

            // Get the last couple characters.
            var charLast1 = dim.charAt(dim.length-1);
            var charLast2 = (dim.length > 1) ? dim.charAt(dim.length-2) : "";

            var ddt:DecomposedDimension = new DecomposedDimension();

            // Is it a percentage?
            if(charLast1 == "%")
            {
                ddt.type = DecomposedDimensionType.DDT_PERCENT;

                // Awesome, get the number.
                var numeric = dim.slice(0, dim.length-1);
                ddt.value = Number.fromString(numeric);

                // And return.
                return ddt;
            }

            // Must be px value - strip the px if it's there.
            if(dim.indexOf("px") == dim.length-2)
                dim = dim.slice(0, dim.length-2);

            // And parse.
            ddt.type = DecomposedDimensionType.DDT_PIXEL;
            ddt.value = Number.fromString(dim);

            return ddt;
        }
    }

    /**
     * Lay out along vertically or horizontally using a mix of pixel and 
     * percentage sizing information.
     *
     * Assign this as the layout for a container, then set ProportionalLayoutData 
     * on all the children that you wish to be laid out using the algorithm.
     *
     * This lays out vertically by default, but set isVertical to false and it will
     * lay out horizontally.
     */
    public class ProportionalLayout extends EventDispatcher implements ILayout
    {
        /**
         * If true, layout is done vertically (with alignment happening horizontally).
         * If false, layout is done horizontally (with alignment happening 
         * vertically).
         */
        public var isVertical:Boolean = true;

        /**
         * Set align to LEFT to align controls to the left of the free space.
         */
        public static const LEFT:String = "left";

        /**
         * Set align to CENTER to align controls to the center of the free space.
         */
        public static const CENTER:String = "center";

        /**
         * Set align to RIGHT to align controls to the right of the free space.
         */
        public static const RIGHT:String = "right";

        /**
         * Controls alignment of controls on the secondary axis.
         */
        public var align:String = "center";

        public var paddingTop:Number = 0;
        public var paddingBottom:Number = 0;
        public var paddingLeft:Number = 0;
        public var paddingRight:Number = 0;

        /**
         * Sets empty space in pixels around the laid out controls.
         */
        public function set padding(value:Number):void
        {
            paddingTop = paddingBottom = paddingLeft = paddingRight = value;
        }

        /**
         * Space in pixels to maintain between controls along the layout axis.
         */
        public var gap:Number = 0;

        /**
         * Calculate the position to be aligned properly in the given space.
         */
        public function calculateAlignPadding(itemWidth:Number, containerWidth:Number, type:String):Number
        {
            // TODO: Feathers already has this logic.
            switch(type)
            {
                case LEFT:
                return 0;

                case RIGHT:
                return (containerWidth - itemWidth);

                case CENTER:
                return (containerWidth - itemWidth) / 2;

                default:
                Debug.assert(false, "Unknown align type.");
                break;
            }

            return 0;
        }

        function layout(items:Vector.<DisplayObject>, viewPortBounds:ViewPortBounds = null, result:LayoutBoundsResult = null):LayoutBoundsResult
        {
            Debug.assert(viewPortBounds, "Cannot do proportional layout with no view port bounds!");

            public var goalWidth = viewPortBounds.explicitWidth;
            public var goalHeight = viewPortBounds.explicitHeight;

            //trace("Goal layout size: " + goalWidth + "x" + goalHeight);

            // Determine our budget of fixed and percentage size items.
            var totalFixedPx:Number = 0;
            var totalPercent:Number = 0;

            // We have two axes, the stacked axis and the loose axis. isVertical
            // controls the stacked axis - so true means we stack vertically,
            // false stacks horizontally.

            var paddingCombinedTB:Number = paddingTop + paddingBottom;
            var paddingCombinedLR:Number = paddingLeft + paddingRight;

            var paddingCombinedStackedAxis:Number = isVertical ? paddingCombinedTB : paddingCombinedLR;

            for(var i:int=0; i<items.length; i++)
            {
                // Determine if this item is eligible for layout.
                var curItem = items[i] as ILayoutDisplayObject;
                if(!curItem)
                    continue;

                var curLayoutData = curItem.layoutData as ProportionalLayoutData;
                if(!curLayoutData)
                    continue;

                // Parse height.
                var stackedDimLiteral = isVertical ? curLayoutData.height : curLayoutData.width;
                var stackedDim = DecomposedDimension.fromString(stackedDimLiteral);

                // Accumulate the gap if not at end...
                if(i != items.length - 1)
                    totalFixedPx += gap;

                // and the item's space.
                if(stackedDim.type == DecomposedDimensionType.DDT_PIXEL)
                {
                    totalFixedPx += stackedDim.value;

                }
                else if(stackedDim.type == DecomposedDimensionType.DDT_PERCENT)
                {
                    totalPercent += stackedDim.value;
                }
                else
                {
                    trace("Failed to parse control dimension '" + stackedDimLiteral + "'");
                }
            }

            // Determine our remaining free space, if any.
            var remainingFixedPx = (isVertical ? goalHeight : goalWidth) - totalFixedPx - paddingCombinedStackedAxis;
            if(remainingFixedPx < 0)
            {
                trace("WARNING: Not enough space to perform layout!");
                remainingFixedPx = 0;
            }

            // Walk the items and lay them out, top to bottom, based on available space.
            var currentStackedPos:Number = isVertical ? paddingTop : paddingLeft;
            for(i=0; i<items.length; i++)
            {
                // Determine if this item is eligible for layout.
                curItem = items[i] as ILayoutDisplayObject;
                if(!curItem)
                    continue;

                curLayoutData = curItem.layoutData as ProportionalLayoutData;
                if(!curLayoutData)
                    continue;

                // Parse height and width.
                var looseDimLiteral = isVertical ? curLayoutData.width : curLayoutData.height;
                var looseDim = DecomposedDimension.fromString(looseDimLiteral);

                stackedDimLiteral = isVertical ? curLayoutData.height : curLayoutData.width;
                stackedDim = DecomposedDimension.fromString(stackedDimLiteral);

                // Assign width and height.
                var calculatedStackedSize = 0, calculatedLooseSize = 0;

                if(stackedDim.type == DecomposedDimensionType.DDT_PIXEL)
                    calculatedStackedSize = stackedDim.value;
                else if(stackedDim.type == DecomposedDimensionType.DDT_PERCENT)
                    calculatedStackedSize = (stackedDim.value / totalPercent) * remainingFixedPx;

                if(looseDim.type == DecomposedDimensionType.DDT_PIXEL)
                    calculatedLooseSize = looseDim.value;
                else if(looseDim.type == DecomposedDimensionType.DDT_PERCENT)
                    calculatedLooseSize = (looseDim.value / 100.0) * (isVertical ? goalWidth - paddingCombinedLR : goalHeight - paddingCombinedTB);

                // And store it with correct loose axis alignment.
                if(isVertical)
                {
                    curItem.x = calculateAlignPadding(calculatedLooseSize, goalWidth - paddingCombinedLR, align) + paddingLeft;
                    curItem.y = currentStackedPos;
                    curItem.width = calculatedLooseSize;
                    curItem.height = calculatedStackedSize;
                }
                else
                {
                    curItem.x = currentStackedPos;
                    curItem.y = calculateAlignPadding(calculatedLooseSize, goalHeight - paddingCombinedTB, align) + paddingTop;
                    curItem.width = calculatedStackedSize;
                    curItem.height = calculatedLooseSize;
                }
                currentStackedPos += calculatedStackedSize + gap;
            }

            // All done!
            if(!result)
                result = new LayoutBoundsResult();

            result.viewPortWidth = goalWidth;
            result.viewPortHeight = goalHeight;
            result.contentWidth = goalWidth;
            result.contentHeight = goalHeight;

            return result;
        }

        function getScrollPositionForIndex(index:int, items:Vector.<DisplayObject>, x:Number, y:Number, width:Number, height:Number):Point
        {
            HELPER_POINT.x = 0;
            HELPER_POINT.y = 0;
            return HELPER_POINT;
        }

        /**
         * @private
         */
        private static const HELPER_POINT:Point;
        

    }
}