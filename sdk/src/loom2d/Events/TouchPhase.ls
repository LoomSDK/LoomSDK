// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.events
{
    /** A class that provides constant values for the phases of a touch object. 
     *  
     *  A touch moves through at least the following phases in its life:
     *  
     *  `BEGAN -> MOVED -> ENDED`
     *  
     *  Furthermore, a touch can enter a `STATIONARY` phase. That phase does not
     *  trigger a touch event itself, and it can only occur in multitouch environments. Picture a 
     *  situation where one finger is moving and the other is stationary. A touch event will
     *  be dispatched only to the object under the _moving_ finger. In the list of touches
     *  of that event, you will find the second touch in the stationary phase.
     *  
     *  Finally, there's the `HOVER` phase, which is exclusive to mouse input. It is
     *  the equivalent of a `MouseOver` event in Flash when the mouse button is
     *  _not_ pressed. 
     */
    public class TouchPhase
    {
        /** @private */
        public function TouchPhase() { Debug.assert(false, "Abstract class!"); }
        
        /** Only available for mouse input: the cursor hovers over an object _without_ a 
         *  pressed button. */
        public static const HOVER:String = "hover";
        
        /** The finger touched the screen just now, or the mouse button was pressed. */
        public static const BEGAN:String = "began";
        
        /** The finger moves around on the screen, or the mouse is moved while the button is 
         *  pressed. */
        public static const MOVED:String = "moved";
        
        /** The finger or mouse (with pressed button) has not moved since the last frame. */
        public static const STATIONARY:String = "stationary";
        
        /** The finger was lifted from the screen or from the mouse button. */
        public static const ENDED:String = "ended";
    }
}