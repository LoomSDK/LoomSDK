// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package loom2d.utils
{
    //import loom2d.errors.AbstractClassError;

    /** A class that provides constant values for horizontal alignment of objects. */
    public final class HAlign
    {
        /** @private */
        public function HAlign() { throw new Error("Abstract class"); }
        
        /** Left alignment. */
        public static const LEFT:String   = "left";
        
        /** Centered alignement. */
        public static const CENTER:String = "center";
        
        /** Right alignment. */
        public static const RIGHT:String  = "right";
        
        /** Indicates whether the given alignment string is valid. */
        public static function isValid(hAlign:String):Boolean
        {
            return hAlign == LEFT || hAlign == CENTER || hAlign == RIGHT;
        }
    }
}