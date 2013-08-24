// =================================================================================================
//
//  Starling Framework
//  Copyright 2011 Gamua OG. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.events
{
    import loom2d.math.Point;
    
    /** A ResizeEvent is dispatched by the Stage when the size of the application window changes.
     */
    public class ResizeEvent extends Event
    {        
        /** Creates a new ResizeEvent. */
        public function ResizeEvent(type:String, width:int, height:int, bubbles:Boolean=false)
        {
            super(type, bubbles, new Point(width, height));
        }
        
        /** The updated width of the player. */
        public function get width():int { return (data as Point).x; }
        
        /** The updated height of the player. */
        public function get height():int { return (data as Point).y; }
    }
}