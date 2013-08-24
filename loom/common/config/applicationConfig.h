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

class LoomApplicationConfig {
    static utString configJSON;
    static int      _waitForAssetAgent;
    static utString assetHost;
    static int      assetPort;
    static utString _version;

    static utString _applicationId;

    static int      _waitForDebugger;
    static utString _debuggerHost;
    static int      _debuggerPort;

public:

    static void parseApplicationConfig(const utString& jsonString);

    static const utString& getApplicationConfigJSON()
    {
        return configJSON;
    }

    // 0 if no wait, else # of milliseconds to wait.
    static const int waitForAssetAgent()
    {
        return _waitForAssetAgent;
    }

    static const utString& assetAgentHost()
    {
        return assetHost;
    }

    static const int assetAgentPort()
    {
        return assetPort;
    }

    static const utString& version()
    {
        return _version;
    }

    // 0 if no wait, else # of milliseconds to wait.
    static const int waitForDebugger()
    {
        return _waitForDebugger;
    }

    static const utString& debuggerHost()
    {
        return _debuggerHost;
    }

    static const int debuggerPort()
    {
        return _debuggerPort;
    }

    static const utString& applicationId()
    {
        return _applicationId;
    }
};
#endif
