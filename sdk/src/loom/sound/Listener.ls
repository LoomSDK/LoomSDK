package loom.sound
{

    [Native(managed)]
    /**
     * Audio system state related to the listener.
     *
     * An audio system is made up of a listener and sounds. By changing the
     * listener's position, orientation, and gain, you can globally control
     * how sounds play.
     *
     * @see Sound
     */
    public static native class Listener
    {
        /**
         * Apply a global gain setting to all sound playback. 1.0 leaves
         * volume the same, while 0.0 mutes it completely. Each division by 2
         * equals an attenuation of -6dB, and each multiplication by 2 equals an
         * amplification of +6dB.
         */
        public static native function setGain(gainFactor:Number):void;

        /**
         * Set the position of the listener. This is in meters relative to the
         * origin.
         */
        public static native function setPosition(x:Number, y:Number, z:Number):void;

        /**
         * Set the current velocity of the listener in meters per second squared.
         */
        public static native function setVelocity(x:Number, y:Number, z:Number):void;

        /**
         * Set the orientation of the listener by providing two vectors, at and up.
         */
        public static native function setOrientation(atX:Number, atY:Number, atZ:Number, upX:Number, upY:Number, upZ:Number):void;
    }
}