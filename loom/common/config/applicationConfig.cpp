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

#include "jansson.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/config/applicationConfig.h"

lmDefineLogGroup(gLoomApplicationConfigLogGroup, "script.LoomApplicationConfig", 1, LoomLogInfo);

utString LoomApplicationConfig::configJSON;
int      LoomApplicationConfig::_waitForAssetAgent = false;
utString LoomApplicationConfig::assetHost;
int      LoomApplicationConfig::assetPort;
utString LoomApplicationConfig::_version       = "0.0.0";
utString LoomApplicationConfig::_applicationId = "unknown_app_id";

int      LoomApplicationConfig::_waitForDebugger = false;
utString LoomApplicationConfig::_debuggerHost;
int      LoomApplicationConfig::_debuggerPort;

// little helpers that do conversion
static bool _jsonParseBool(const char *key, json_t *value)
{
    if (!value)
    {
        return false;
    }

    if (json_is_true(value))
    {
        return true;
    }

    if (json_is_false(value))
    {
        return false;
    }

    if (json_is_integer(value))
    {
        return json_integer_value(value) ? true : false;
    }

    if (json_is_real(value))
    {
        return json_real_value(value) ? true : false;
    }

    if (json_is_string(value))
    {
        return !strcasecmp(json_string_value(value), "true") ? true : false;
    }

    lmLog(gLoomApplicationConfigLogGroup, "WARNING: unknown json bool conversion in config for key %s", key);

    return false;
}


static int _jsonParseInt(const char *key, json_t *value)
{
    if (!value)
    {
        return 0;
    }

    if (json_is_true(value))
    {
        return 1;
    }

    if (json_is_false(value))
    {
        return 0;
    }

    if (json_is_integer(value))
    {
        return (int)json_integer_value(value);
    }

    if (json_is_real(value))
    {
        return (int)json_real_value(value);
    }

    if (json_is_string(value))
    {
        char *pEnd;
        return strtol(json_string_value(value), &pEnd, 10);
    }

    lmLog(gLoomApplicationConfigLogGroup, "WARNING: unknown json int conversion in config for key %s", key);

    return 0;
}


// this will always be in assets/loom.config (unless we decide to move it)
void LoomApplicationConfig::parseApplicationConfig(const utString& jsonString)
{
    configJSON = jsonString;

    // verify config is valid JSON

    json_error_t jerror;
    json_t       *json = json_loadb(jsonString.c_str(), jsonString.length(), 0, &jerror);

    lmAssert(json, "LoomApplicationConfig::parseApplicationConfig() error parsing application config %s\n %s %i\n", jerror.source, jerror.text, jerror.line);

    if (json_t *wfaa = json_object_get(json, "waitForAssetAgent"))
    {
        _waitForAssetAgent = _jsonParseInt("waitForAssetAgent", wfaa);
    }

    if (json_t *ah = json_object_get(json, "assetAgentHost"))
    {
        if (!json_is_string(ah))
        {
            lmLog(gLoomApplicationConfigLogGroup, "assetAgentHost was specified but is not a string!");
        }
        else
        {
            assetHost = json_string_value(ah);
        }
    }

    if (json_t *ap = json_object_get(json, "assetAgentPort"))
    {
        assetPort = _jsonParseInt("assetAgentPort", ap);
    }

    const char *v = json_string_value(json_object_get(json, "version"));
    if (v != NULL)
    {
        _version = v;
    }

    const char *app_id = json_string_value(json_object_get(json, "app_id"));
    if (app_id != NULL)
    {
        _applicationId = app_id;
    }

    // Parse log block.
    if (json_t *logBlock = json_object_get(json, "log"))
    {
        // Walk the children.
        const char *key;
        json_t     *value;

        json_object_foreach(logBlock, key, value)
        {
            // Key is the prefix for the rule.
            // Maybe we have level or enabled data?
            int enabledRule = -1;
            int filterRule  = -1;

            if (json_t *enabledBlock = json_object_get(value, "enabled"))
            {
                enabledRule = _jsonParseBool("log.enabled", value);
            }

            // TODO: Allow info, warn, error as parameters here.
            if (json_t *levelBlock = json_object_get(value, "level"))
            {
                filterRule = (int)json_integer_value(levelBlock);
            }

            loom_log_addRule(key, enabledRule, filterRule);
        }
    }

    if (json_t *wfd = json_object_get(json, "waitForDebugger"))
    {
        _waitForDebugger = _jsonParseInt("waitForDebugger", wfd);
    }

    if (json_t *dh = json_object_get(json, "debuggerHost"))
    {
        if (!json_is_string(dh))
        {
            lmLog(gLoomApplicationConfigLogGroup, "debuggerHost was specified but is not a string!");
        }
        else
        {
            _debuggerHost = json_string_value(dh);
        }
    }

    if (json_t *dp = json_object_get(json, "debuggerPort"))
    {
        _debuggerPort = _jsonParseInt("debuggerPort", dp);
    }

    json_delete(json);
}
