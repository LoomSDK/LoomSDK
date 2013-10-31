/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom.platform 
{
    /**
     * Loom Mobile API.
     *
     * Loom provides various platform specific mobile functionality.
     * Note that not all of the items found here will be available 
     * on every mobile platform.
     *
     */



    /**
     * Static control class for accessing various Mobile specific functionality.
     */
    public native class Mobile 
    {
        /* Placeholder for now... */
    }



    /**
     * Static control class for accessing Dolby Audio on complient Android devices
     */
    public native class DolbyAudio
    {
        /**
         * Constant representing the 'Music' Dolby Audio Profile
         */
        public static var MUSIC_PROFILE:String = "Music";

        /**
         * Constant representing the 'Movie' Dolby Audio Profile
         */
        public static var MOVIE_PROFILE:String = "Movie";

        /**
         * Constant representing the 'Game' Dolby Audio Profile
         */
        public static var GAME_PROFILE:String = "Game";

        /**
         * Constant representing the 'Void' Dolby Audio Profile
         */
        public static var VOICE_PROFILE:String = "Voice";

        /**
         * Indicates whether or not Dolby Audio is supported on the current platform
         */
        public static native var supported:Boolean;

        /**
         * Sets Dolby Audio processing status
         *
         *  @param enable Boolean indicating the status to set Dolby Audio processing to
         */
        public static native function setProcessingEnabled(enable:Boolean):void;

        /**
         * Queries whether or not Dolby Audio processing is enabled
         *
         *  @return Boolean Status of Dolby Audio processing
         */
        public static native function isProcessingEnabled():Boolean;

        /**
         * Sets Dolby Audio processing profile type
         *
         *  @param profileIndex Name of the processing profile to set as the active one for Dolby Audio.  Valid indices are obtaind through getNumProfile()
         *  @return Boolean Whether or not the profile is supported on this hardware
         */
        public static native function isProfileSupported(profile:String):Boolean;

        /**
         * Sets Dolby Audio processing profile type
         *
         *  @param profileIndex Name of the processing profile to set as the active one for Dolby Audio.  Valid indices are obtaind through getNumProfile()
         *  @return Boolean Whether or not the profile was set properly.  Possibly false if this profile isn't supported and the hardware.
         */
        public static native function setProfile(profile:String):Boolean;

        /**
         * Queries the currently selected Dolby Audio processing profile
         *
         *  @return String Name of the currently selected Dolby Audio processing profile
         */
        public static native function getSelectedProfile():String;
    }    
}