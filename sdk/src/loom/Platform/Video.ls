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
     * Loom Video API.
     *
     * Loom abstracts the native video playback functionality on your platform 
     * (if present) and provides a streamlined interface to play videos.
     *
     *
     * MP4 encoding can sometimes be tricky and some encodes will not work on all devices. A good
     * base method that we have found is to use 'ffmpeg' (ffmpeg.org) with the following settings:
     *
     * ffmpeg -i inputVideoName.mp4 -c:v libx264 -strict -2 -preset slower -profile:v baseline -level 3.0 -s 640x360 ouputVideoName.mp4
     *
     * The '-s 640x360' is optional, but some Android devices cannot handle larger resolution video 
     * playback.  If your video is not 16:9, adjust that value to match your aspect ratio, or remove 
     * it completely.
     *
     *
     *  IMPORTANT NOTE: Android is especially particular as to filenames used for video files. They must be
     *  all lowercase and contain no spaces for maximum compatibiity.
     *
     *  IMPORTANT NOTE #2: Android playback requires video files to be located in "assets/videos/" in order for
     *  them to be packaged into the APK correctly.  We suggest that you keep all of your video files in that
     *  folder no matter what platform you are developing for in order to avoid confusion in the future, and 
     *  as such have provided a const called 'Video.RootFolder' to use.
     *
     */


    /**
     * Delegate used when Video playback has completed, ie. "complete" or "fail"
     *
     *  @param type String indicating the state of completion
     *  @param payload Additional supporting information regarding the return type
     */
    public delegate VideoCompleteDelegate(type:String, payload:String):void;


    /**
     * Type of control widget to display over the video
     */
    public enum VideoControlMode
    {
        /**
         * Show the full system video control widget
         */
        Show,

        /**
         * Don't show any video control widget
         */
        Hide,

        /**
         * Don't show any video control widget AND stop the video playblack on user touch
         */
        StopOnTouch
    };


    /**
     * Method of scaling the video to the screen
     */
    public enum VideoScaleMode
    {
        /**
         * Don't scale at all and keep the video the same resolution as its source
         * Known Issue: This method will sometimes cause the video to "slide in" towards the middle of the screen on Android. Loom-1809.
         */
        ///Note: Removed for now until it is working and testing on iOS as well as Android
        // None = 0,

        /**
         * Scale the video up to fill the entire screen, ignoring its aspect ratio
         */
        ///Note: Removed for now until it is working and testing on iOS as well as Android
        // Fill = 1,

        /**
         * Center the video and scale it until either its width or height touches the edges of the screen, thereby preserving the aspect ratio
         */
        FitAspect = 2
    };


    /**
     * Static control class for playing back videos
     */
    public native class Video 
    {
        /**
         * Constant string helper that denotes the folder where video files should be located for maximum platform compatibility
         */
        public static const RootFolder:String       = "assets/videos/";

        /**
         * Plays a video in Fullscreen mode
         *
         *  @param video Name of the video file to play, NOT including its extension. NOTE: This file must reside in "assets/videos/" in order to work across all platforms.
         *  @param scaleMode Method of scaling the video on screen
         *  @param controlMode Type of video controls to display over the video
         *  @param bgColor Hex formatted color (ie. 0xFF000000) to set the area of the screen not filled with the video, in cases where it does not fill the screen
         */
        public static native function playFullscreen(video:String, scaleMode:VideoScaleMode, controlMode:VideoControlMode, bgColor:uint):void;

        /**
         * Indicates whether or not Video is supported on the current platform
         */
        public static native var supported:Boolean;

        /**
         * Called when the video completes normally
         *
         *  @param type String indicating the state of completion
         *  @param payload Additional supporting information regarding the return type
         */
        public static native var onComplete:VideoCompleteDelegate;

        /**
         * Called when the video is unable to play or complete
         *
         *  @param type String indicating the state of completion
         *  @param payload Additional supporting information regarding the return type
         */
        public static native var onFail:VideoCompleteDelegate;
    }
}