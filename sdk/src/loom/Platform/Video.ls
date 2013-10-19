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
     */


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
         */
        None,

        /**
         * Scale the video up to fill the entire screen, ignoring its aspect ratio
         */
        Fill,

        /**
         * Center the video and scale it until either its width or height touches the edges of the screen, thereby preserving the aspect ratio
         */
        FitAspect,
    };


    /**
     * Static control class for playing back videos
     */
    public class Video 
    {
        /**
         * Plays a video in Fullscreen mode
         *
         *  @param video Name of the video file to play, NOT including its extension
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
         * No parameters.
         */
        public static native var onComplete:NativeDelegate;

        /**
         * Called when the video is unable to play or complete
         *
         * No parameters.
         */
        public static native var onFail:NativeDelegate;
    }
}