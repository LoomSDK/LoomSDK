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


    ///Types of the control widget to display over the video
    public enum VideoControlMode
    {
        ///show the full system video control widget
        Show,

        ///don't show any video control widget
        Hide,

        ///don't show any video control widget AND stop the video playblack on user touch
        StopOnTouch
    };


    ///Method of scaling the video to the screen
    public enum VideoScaleMode
    {
        ///don't scale at all and keep the video the same resolution as its source
        None,

        ///scale the video up to fill the entire screen, ignoring its aspect ratio
        Fill,

        ///scale the video until either its width or height touches the edges of the screen, thereby preserving the aspect ratio
        FitAspect,
    };


    ///Video playback class
    public class Video 
    {
///TODO: document        
        public static native function playFullscreen(video:String, scaleMode:VideoScaleMode, controlMode:VideoControlMode, bgColor:uint):void;

        public static native var supported:Boolean;
        public static native var onComplete:NativeDelegate;
        public static native var onFail:NativeDelegate;
    }
}