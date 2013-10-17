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

#include "loom/common/core/log.h"
#include "loom/script/loomscript.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/common/platform/platformVideo.h"

using namespace LS;

lmDefineLogGroup(gNativeVideoLogGroup, "Loom.NativeVideo", 1, 0);

/// Script bindings to the native Video API.
///
/// See Video.ls for documentation on this API.
class Video
{
private:

    /// Event handler; this is called by the C video API when the Video registers an event
    static void eventCallback(const char *type, const char *payload)
    {
        json_error_t jerr;

        // Convert to delegate calls.
        lmLogDebug(gNativeVideoLogGroup, "Event type='%s' payload='%s'", type, payload);

        if (!strcmp(type, "complete"))
        {
            _OnVideoCompleteDelegate.pushArgument(type);
            _OnVideoCompleteDelegate.pushArgument(payload);
            _OnVideoCompleteDelegate.invoke();
        }
        else if (!strcmp(type, "fail"))
        {
            _OnVideoFailDelegate.pushArgument(type);
            _OnVideoFailDelegate.pushArgument(payload);
            _OnVideoFailDelegate.invoke();
        }
        else
        {
            lmLogWarn(gNativeVideoLogGroup, "Encountered an unknown event type '%s'", type);
        }
    }

public:

    LOOM_STATICDELEGATE(OnVideoComplete);
    LOOM_STATICDELEGATE(OnVideoFail);


    static bool initialize()
    {
        platform_videoInitialize(eventCallback);
    }
    static bool supported()
    {
        return (platform_videoSupported() != 0) ? true : false;
    }
    static void playFullscreen(const char *video, int scaleMode, int controlMode, int bgColor)
    {
        return platform_videoPlayFullscreen(video, scaleMode, controlMode, bgColor);
    }
};




NativeDelegate Video::_OnVideoCompleteDelegate;
NativeDelegate Video::_OnVideoFailDelegate;

static int registerLoomVideo(lua_State *L)
{
    beginPackage(L, "loom.video")

       .beginClass<Video>("Video")

       .addStaticProperty("supported", &Video::supported)
       .addStaticProperty("playFullscreen", &Video::playFullscreen)

       .addStaticProperty("onVideoComplete", &Video::getOnVideoCompleteDelegate)
       .addStaticProperty("onVideoFail", &Video::getOnVideoFailDelegate)
       .endClass()

       .endPackage();

    return 0;
}


void installLoomVideo()
{
    LOOM_DECLARE_NATIVETYPE(Video, registerLoomVideo);
    Video.initialize();
}
