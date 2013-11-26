/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.utils
{
    import loom2d.display.DisplayObject;
    
    public class FeathersDisplayUtils
    {
        /**
         * Calculates a scale value to maintain aspect ratio and fill the required
         * bounds (with the possibility of cutting of the edges a bit).
         */
        public static function calculateScaleRatioToFill(originalWidth:Number, originalHeight:Number, targetWidth:Number, targetHeight:Number):Number
        {
            var widthRatio:Number = targetWidth / originalWidth;
            var heightRatio:Number = targetHeight / originalHeight;
            return Math.max(widthRatio, heightRatio);
        }
        
        /**
         * Calculates a scale value to maintain aspect ratio and fit inside the
         * required bounds (with the possibility of a bit of empty space on the
         * edges).
         */
        public static function calculateScaleRatioToFit(originalWidth:Number, originalHeight:Number, targetWidth:Number, targetHeight:Number):Number
        {
            var widthRatio:Number = targetWidth / originalWidth;
            var heightRatio:Number = targetHeight / originalHeight;
            return Math.min(widthRatio, heightRatio);
        }
        
        /**
         * Calculates how many levels deep the target object is on the display list,
         * starting from the Starling stage. If the target object is the stage, the
         * depth will be <code>0</code>. A direct child of the stage will have a
         * depth of <code>1</code>, and it increases with each new level. If the
         * object does not have a reference to the stage, the depth will always be
         * <code>-1</code>, even if the object has a parent.
         */
        public static function getDisplayObjectDepthFromStage(target:DisplayObject):int
        {
            if(!target.stage)
            {
                return -1;
            }
            var count:int = 0;
            while(target.parent)
            {
                target = target.parent;
                count++;
            }
            return count;
        }        
        
    }
}