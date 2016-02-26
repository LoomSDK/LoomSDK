package loom.sound
{
    [Native(managed)]
    /**
     * A sound, which may potentially play.
     *
     * Loom supports positional audio. Sounds may have their volume, position,
     * pitch, and looping status modified to suit the needs of your
     * application.
     *
     * Source files can be in MP3, OGG and WAV (8 & 16 bit PCM) formats with a 
     * 44.1Khz sample rate. Note that MP3 supports requires that you have a 
     * valid license to perform MP3 playback.
     *
     * Note that sounds are stored uncompressed in memory. One minute of CD 
     * quality stereo audio takes about 10MB of storage. Be aware when 
     * running on mobile devices!
     *
     * Sound asset data is only loaded once, so you can safely call Sound.load()
     * as much as you like without consuming lots of memory.
     *
     * Make sure to call deleteNative() on Sounds when you are done with them.
     * This frees up critical audio resources. Behind the scenes, Loom attempts
     * to reuse audio playback resources. It does this by stealing inactive 
     * Sound's resources after about 64 are active. New Sound instances will 
     * steal from old Sounds which are not playing. This will keep things running
     * smoothly, but can lead to absent/silent sounds.
     *
     * See the PositionalAudioExample for a great example of using the Sound and
     * Listener classes.
     *
     * @see Listener
     */
    public native class Sound
    {
        /**
         * Create a new Sound instance by loading an asset.
         *
         * Source files can be in MP3, OGG and WAV (8 & 16 bit PCM) format. Note
         * that MP3 supports requires that you have a valid license to perform
         * MP3 playback.
         */
        public static native function load(assetPath:String):Sound;

        /**
         * Load and decompress a sound into memory for on-demand playback.
         */
        public static native function preload(assetPath:String):void;

        /**
         * Set the position in meters relative to world origin for sound 
         * playback.
         */
        public native function setPosition(x:Number, y:Number, z:Number):void;

        /**
         * Set the velocity of the sound.
         */
        public native function setVelocity(x:Number, y:Number, z:Number):void;

        /**
         * If a sound is listener relative, then its position is relative to
         * the position of the listener instead of the origin of the world. It
         * is also positioned independently of rotation.
         */
        public native function setListenerRelative(isRelative:Boolean):void;

        /**
         * Adjust how distance affects this sound. See Section 3.4 of the OpenAL 1.1 specification
         * for full details; the parameters will get you most of the way there though!
         *
         * @param innerRadius When closer than this distance, the sound is played at full volume.
         * @param outerRadius When further than this distance, the sound is no longer audible.
         * @param rollOff     Adjust the curve used for gain falloff.
         */
        public native function setFalloffRadius(innerRadius:Number, outerRadius:Number, rollOff:Number = 1.0):void;

        /**
         * Adjust sound volume. Gain of 1 preserves sound volume, 0 mutes it.
         * Dividing by a factor of 2 reduces volume by 6dB and multiplying by
         * 2 increases volume by 6dB.
         */
        public native function setGain(gainFactor:Number):void;

        /**
         * Return the current sound volume.
         */
        public native function getGain():Number;
        
        /**
         * When true, the sound loops indefinitely.
         */
        public native function setLooping(loop:Boolean):void;

        /** 
         * Controls speed of sound playback. Pitch may be adjusted from 0.5 
         * to 2.0.
         */
        public native function setPitch(pitchFactor:Number):void;
        
        /**
         * Plays the sound.
         */
        public native function play():void;

        /**
         * Pauses playback; resume with play().
         */
        public native function pause():void;

        /**
         * Stop playback.
         */
        public native function stop():void;

        /**
         * Rewind playhead to start of sound but doesn't stop playback.
         */
        public native function rewind():void;

        /**
         * True if we are currently playing the sound.
         */
        public native function isPlaying():Boolean;

        /**
         * True if the sound asset failed to load correctly.
         */
        public native function isNull():Boolean;

        /**
         * True if we have ever played the sound.
         */
        public native function hasEverPlayed():Boolean;
    }
}
