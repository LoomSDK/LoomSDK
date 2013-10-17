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

#import <Foundation/Foundation.h>
#import <Foundation/NSSet.h>

#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformVideo.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/vendor/jansson/jansson.h"

lmDefineLogGroup(gAppleVideoLogGroup, "loom.video.apple", 1, 0);

static VideoEventCallback gEventCallback = NULL;

int platform_videoSupported()
{
    ///TODO: make true once we support video on iOS
    return false;
}

void platform_videoInitialize(VideoEventCallback eventCallback)
{
    gEventCallback = eventCallback;

    ////TODO: video playback support on iOS
}

void platform_videoPlayFullscreen(const char *video, int scaleMode, int controlMode, int bgColor)
{
    ////TODO: video playback support on iOS
    lmLogError(gAppleVideoLogGroup, "Fullscreen Video Playback not currently implemented on iOS!!");
}
