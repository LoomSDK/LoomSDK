// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.display
{    
    import loom2d.math.Point;
    import loom2d.math.Rectangle;
    
    [Native(managed)]
    public native class Shape extends DisplayObject
    {
        /** Helper objects. */
        private static var sHelperPoint:Point = new Point();
        
        protected var _clipRect:Rectangle = null;
        
        
        public function Shape() { }
        
        public native function setClipRect(x:system.Number, y:system.Number, width:system.Number, height:system.Number);
        public function get clipRect():Rectangle
        {
            return _clipRect;
        }
        public function set clipRect(value:Rectangle)
        {            
            if(value)
            {
                _clipRect = value.clone();
                setClipRect(value.x, value.y, value.width, value.height);
            }
            else
            {
                _clipRect = null;
                setClipRect(0,0,-1,-1);
            }
        }
        
        public native function get graphics():Graphics;
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if(!resultRect)
            {
                resultRect = new Rectangle();
            }
            
            var bounds:Rectangle = graphics.getBounds();
            
            var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
            var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
            
            if (targetSpace == this) // optimization
            {
                minX = bounds.x;
                minY = bounds.y;
                maxX = bounds.x + bounds.width;
                maxY = bounds.y + bounds.height;
            }
            else
            {
                this.getTargetTransformationMatrix(targetSpace, sHelperMatrix);

                sHelperPoint = sHelperMatrix.transformCoord(bounds.x, bounds.y);
               
                minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
                maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
                minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
                maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;

                sHelperPoint = sHelperMatrix.transformCoord(bounds.x, bounds.y + bounds.height);
                minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
                maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
                minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
                maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;

                sHelperPoint = sHelperMatrix.transformCoord(bounds.x + bounds.width, bounds.y);
                minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
                maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
                minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
                maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;

                sHelperPoint = sHelperMatrix.transformCoord(bounds.x + bounds.width, bounds.y + bounds.height);
                minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
                maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
                minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
                maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;
            }
            
            resultRect.x = minX;
            resultRect.y = minY;
            resultRect.width  = maxX - minX;
            resultRect.height = maxY - minY;
            
            return resultRect;
        }

    }
}