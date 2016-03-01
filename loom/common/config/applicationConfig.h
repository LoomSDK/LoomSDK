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

#ifndef _lmapplicationconfig_h
#define _lmapplicationconfig_h

#include "loom/common/utils/utString.h"

/**
 * C++ access to assorted configuration parameters from the application assembly.
 *
 * These are available at startup time to drive app behavior. Currently this is a
 * snapshot of loom.config (with some content redacted by the compiler). lsc embeds
 * it in the LoomScript assembly.
 */
class LoomApplicationConfig 
{
    static utString configJSON;
    static int      _waitForAssetAgent;
    static utString assetHost;
    static int      assetPort;
    static utString _version;

    static utString _applicationId;

    static int      _waitForDebugger;
    static utString _debuggerHost;
    static int      _debuggerPort;

    static bool     _wants51Audio;

    static utString _displayTitle;
    static int      _displayWidth;
    static int      _displayHeight;
    static utString _displayOrientation;

    static utString  _logLevel;

public:

    static const utString OrientationLandscape;
    static const utString OrientationPortrait;

    static void parseApplicationConfig(const utString& jsonString);

    /// Access the raw loom.config JSON.
    static const utString& getApplicationConfigJSON()
    {
        return configJSON;
    }

    /// 0 if no wait, else # of milliseconds to wait for assetAgent connection before
    /// continuing execution.
    static const int waitForAssetAgent()
    {
        return _waitForAssetAgent;
    }

    /// Host for the asset agent.
    static const utString& assetAgentHost()
    {
        return assetHost;
    }

    /// Port for the asset agent.
    static const int assetAgentPort()
    {
        return assetPort;
    }

    /// Application version.
    static const utString& version()
    {
        return _version;
    }

    /// 0 if no wait, else # of milliseconds to wait for LS debugger.
    static const int waitForDebugger()
    {
        return _waitForDebugger;
    }

    /// Host for the LoomScript debugger.
    static const utString& debuggerHost()
    {
        return _debuggerHost;
    }

    /// Port for the LoomScript debugger.
    static const int debuggerPort()
    {
        return _debuggerPort;
    }

    /// The app's ID.
    static const utString& applicationId()
    {
        return _applicationId;
    }

    /// True if we should initialize 5.1 audio.
    static const bool wants51Audio()
    {
        return _wants51Audio;
    }

    static const utString& displayTitle()
    {
        return _displayTitle;
    }

    static const int displayWidth()
    {
        return _displayWidth;
    }

    static const int displayHeight()
    {
        return _displayHeight;
    }

    static const utString& displayOrientation();

    static const utString& logLevel();
};
#endif
