/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package data
{
    import feathers.controls.Slider;

    public class SliderSettings
    {
        public function SliderSettings()
        {
        }

        public var direction:String = Slider.DIRECTION_HORIZONTAL;
        public var step:Number = 1;
        public var page:Number = 10;
        public var liveDragging:Boolean = true;
    }
}
