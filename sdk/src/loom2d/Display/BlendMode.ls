// =================================================================================================
//
//  Starling Framework
//  Copyright 2011-2014 Gamua. All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.display
{    
    /** 
     *  An enumeration that defines the supported visual blend mode effects
     */
    public enum BlendMode
    {
        /** Inherits the blend mode from this display object's parent. */
        AUTO        = 0,
        
        /** Deactivates blending, i.e. disabling any transparency. */
        NONE        = 1,
        
        /** The display object appears in front of the background. */
        NORMAL      = 2,
        
        /** Adds the values of the colors of the display object to the colors of its background. */
        ADD         = 3,
        
        /** Multiplies the values of the display object colors with the the background color. */
        MULTIPLY    = 4,

        /** Multiplies the complement (inverse) of the display object color with the complement of 
          * the background color, resulting in a bleaching effect. */
        SCREEN      = 5,
        
        /** Clears the area underneath the object to black. */
        ERASE       = 6,

        /** Draws under/below existing objects, based on the alpha of those objects */
        BELOW       = 7
    };
}
