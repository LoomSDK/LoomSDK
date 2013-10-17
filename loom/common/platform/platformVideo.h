/*
 * ===========================================================================
 * Loom SDK
 * Copyright 2011, 2012, 2013
 * The Game Engine Company, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ===========================================================================
 */

#ifndef _LOOM_COMMON_PLATFORM_PLATFORMVIDEO_H_
#define _LOOM_COMMON_PLATFORM_PLATFORMVIDEO_H_

/**
 * Loom Video API
 *
 * For video playback support, Loom includes a cross-platform native video API. This
 * abstraction handles playing back fullscreen video on mobile devices.
 *
 */


///Types of the control widget to display over the video
enum LoomVideoControlMode
{
    ///show the full system video control widget
    Show,

    ///don't show any video control widget
    Hide,

    ///don't show any video control widget AND stop the video playblack on user touch
    StopOnTouch
};


///Method of scaling the video to the screen
enum LoomVideoScaleMode
{
    ///don't scale at all and keep the video the same resolution as its source
    None,

    ///scale the video up to fill the entire screen, ignoring its aspect ratio
    Fill,

    ///scale the video until either its width or height touches the edges of the screen, thereby preserving the aspect ratio
    FitAspect,
};





///Callback for video API events.
typedef void (*VideoEventCallback)(const char *type, const char *payload);

///Returns non-zero if the platform supports video playback
int platform_videoSupported();

///Initializes the video playback for the platform
void platform_videoInitialize(VideoEventCallback eventCallback);

///Plays the specified video file fullscreen
void platform_videoPlayFulscreen(const char *video, int scaleMode, int controlMode, int bgColor);

#endif
