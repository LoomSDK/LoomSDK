// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package extensions
{
	import loom2d.math.Color;
    public class PDParticle extends Particle
    {
        public var colorArgb:Color;
        public var colorArgbDelta:Color;
        public var startX:Number, startY:Number;
        public var velocityX:Number, velocityY:Number;
        public var radialAcceleration:Number;
        public var tangentialAcceleration:Number;
        public var emitRadius:Number, emitRadiusDelta:Number;
        public var emitRotation:Number, emitRotationDelta:Number;
        public var rotationDelta:Number;
        public var scaleDelta:Number;
        
        public function PDParticle()
        {
            colorArgb = new Color();
            colorArgbDelta = new Color();
        }
    }
}