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
    import loom2d.math.Rectangle;
    
    [Native(managed)]
    public native class Shape extends DisplayObject
    {
        public function Shape() {}
        
        public native function get graphics():Graphics;
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            // TODO fix
            resultRect.setTo(0, 0, 100, 100);
            
            return resultRect;
        }

    }
}