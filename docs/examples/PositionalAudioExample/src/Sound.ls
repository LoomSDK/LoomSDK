package loom.sound
{
	[Native(managed)]
	public native class Sound
	{
		public static native function load(assetPath:String):Sound;

		public native function setPosition(x:Number, y:Number, z:Number):void;
		public native function setVelocity(x:Number, y:Number, z:Number):void;
		public native function setListenerRelative(isRelative:Boolean):void;

		public native function setFalloffRadius(radius:Number):void;
		public native function setGain(gainFactor:Number):void;
		
		public native function setLooping(loop:Boolean):void;
		public native function setPitch(pitchFactor:Number):void;
		
		public native function play():void;
		public native function pause():void;
		public native function stop():void;
		public native function rewind():void;

		public native function isPlaying():Boolean;
	}

	[Native(managed)]
	public static native class Listener
	{
		public static native function setGain(gainFactor:Number):void;
		public static native function setPosition(x:Number, y:Number, z:Number):void;
		public static native function setVelocity(x:Number, y:Number, z:Number):void;
		public static native function setOrientation(atX:Number, atY:Number, atZ:Number, upX:Number, upY:Number, upZ:Number):void;
	}
}