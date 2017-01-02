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
#include "loom/common/core/string.h"
#include "loom/common/platform/platformIO.h"
#include "loom/common/config/applicationConfig.h"

lmDefineLogGroup(gLoomApplicationConfigLogGroup, "config", 1, LoomLogInfo);


const int LoomApplicationConfig::POSITION_INVALID   = 0x1FFF0000;
const int LoomApplicationConfig::POSITION_UNDEFINED = 0x1FFF0000 + 1;
const int LoomApplicationConfig::POSITION_CENTERED  = 0x1FFF0000 + 2;

utString LoomApplicationConfig::configJSON;
int      LoomApplicationConfig::_waitForAssetAgent = false;
utString LoomApplicationConfig::assetHost;
int      LoomApplicationConfig::assetPort;
bool     LoomApplicationConfig::_wants51Audio   = false;
utString LoomApplicationConfig::_version       = "0.0.0";
utString LoomApplicationConfig::_applicationId = "unknown_app_id";
utString LoomApplicationConfig::_applicationType = "";

int      LoomApplicationConfig::_waitForDebugger = false;
utString LoomApplicationConfig::_debuggerHost;
int      LoomApplicationConfig::_debuggerPort;
utString LoomApplicationConfig::_displayTitle = "Loom";
int      LoomApplicationConfig::_displayX = LoomApplicationConfig::POSITION_UNDEFINED;
int      LoomApplicationConfig::_displayY = LoomApplicationConfig::POSITION_UNDEFINED;
int      LoomApplicationConfig::_displayWidth = 640;
int      LoomApplicationConfig::_displayHeight = 480;
utString LoomApplicationConfig::_displayOrientation = "auto";
bool     LoomApplicationConfig::_displayMaximized = false;
bool     LoomApplicationConfig::_displayMinimized = false;
bool     LoomApplicationConfig::_displayResizable = true;
bool     LoomApplicationConfig::_displayBorderless = false;
utString LoomApplicationConfig::_displayMode = "windowed";


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
        return !stricmp(json_string_value(value), "true") ? true : false;
    }

    lmLogWarn(gLoomApplicationConfigLogGroup, "Unknown json bool conversion in config for key %s", key);

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

    lmLogWarn(gLoomApplicationConfigLogGroup, "Unknown json int conversion in config for key %s", key);

    return 0;
}

static void _jsonReadInt(json_t *json, const char *key, int &value)
{
    if (json_t *jint = json_object_get(json, key))
    {
        value = _jsonParseInt(key, jint);
    }
}

static void _jsonReadStr(json_t *json, const char *key, utString &value)
{
    if (json_t *jstring = json_object_get(json, key))
    {
        value = json_string_value(jstring);
    }
}

static void _jsonReadBool(json_t *json, const char *key, bool &value)
{
    if (json_t *jbool = json_object_get(json, key))
    {
        value = _jsonParseBool(key, jbool);
    }
}

static void _jsonReadPos(json_t *json, const char *key, int &value)
{
    if (json_t *jpos = json_object_get(json, key))
    {
        if (json_is_string(jpos))
        {
            utString pos = json_string_value(jpos);

            int v =
                pos == "center" ? LoomApplicationConfig::POSITION_CENTERED :
                LoomApplicationConfig::POSITION_INVALID;

            if (v == LoomApplicationConfig::POSITION_INVALID)
            {
                lmLogWarn(gLoomApplicationConfigLogGroup, "Unknown value for '%s' position: %s", key, pos.c_str());
            }
            else
            {
                value = v;
            }
        }
        else if (json_is_integer(jpos))
        {
            value = json_integer_value(jpos);
        }
        else
        {
            lmLogWarn(gLoomApplicationConfigLogGroup, "Unknown value for '%s' position", key);
        }
    }
}

const utString& LoomApplicationConfig::displayOrientation()
{
    return _displayOrientation;
}

static void parseLogBlock(json_t *logBlock, utString name)
{
    json_t *enabled = json_object_get(logBlock, "enabled");
    json_t *level = json_object_get(logBlock, "level");

    if (enabled || level)
    {
        int enabledRule = -1;
        loom_logLevel_t filterRule = LoomLogInvalid;

        if (enabled) enabledRule = _jsonParseBool((name + " enabled").c_str(), enabled);
        if (level)
        {
            loom_logLevel_t levelEnum = LoomLogInvalid;
            if (json_is_integer(level)) {
                levelEnum = (loom_logLevel_t)json_integer_value(level);
            }
            else if (json_is_string(level))
            {
                const char *levelName = json_string_value(level);
                levelEnum = loom_log_parseLevel(levelName);
                lmAssert(levelEnum != LoomLogInvalid, "Invalid configured log level for %s: %s", name.c_str(), levelName);
            }

            lmAssert(levelEnum != LoomLogInvalid, "Invalid configured log level for %s: %s", name.c_str(), json_dumps(level, JSON_COMPACT));
            
            filterRule = levelEnum;
        }

        if (name == "")
        {
            if (enabledRule == 0) filterRule = LoomLogNone;
            loom_log_setGlobalLevel(filterRule);
        }
        else
        {
            loom_log_addRule(name.c_str(), enabledRule, filterRule);
        }
        
    }

    // Walk the children.
    const char *key;
    json_t     *value;

    json_object_foreach(logBlock, key, value)
    {
        if (strcmp(key, "enabled") == 0 || strcmp(key, "level") == 0) continue;

        parseLogBlock(value, name == "" ? key : name + "." + key);
    }
}

// this will always be in assets/loom.config (unless we decide to move it)
void LoomApplicationConfig::parseApplicationConfig(const utString& jsonString)
{
    configJSON = jsonString;

    // verify config is valid JSON

    json_error_t jerror;
    json_t       *json = json_loadb(jsonString.c_str(), jsonString.length(), 0, &jerror);

    lmAssert(json, "LoomApplicationConfig::parseApplicationConfig() error parsing application config %s\n %s %i\n", jerror.source, jerror.text, jerror.line);

    _jsonReadInt(json, "waitForAssetAgent", _waitForAssetAgent);

    _jsonReadStr(json, "assetAgentHost", assetHost);
    _jsonReadInt(json, "assetAgentPort", assetPort);

    _jsonReadStr(json, "version", _version);
    _jsonReadStr(json, "app_id", _applicationId);
    _jsonReadStr(json, "app_type", _applicationType);

    // Parse log block.
    if (json_t *logBlock = json_object_get(json, "log"))
    {
        parseLogBlock(logBlock, "");
    }

    _jsonReadBool(json, "_wants51Audio", _wants51Audio);
    _jsonReadInt(json, "waitForDebugger", _waitForDebugger);

    _jsonReadStr(json, "debuggerHost", _debuggerHost);
    _jsonReadInt(json, "debuggerPort", _debuggerPort);

    if (json_t *displayBlock = json_object_get(json, "display"))
    {
        _jsonReadStr(displayBlock, "title", _displayTitle);

        _jsonReadPos(displayBlock, "x", _displayX);
        _jsonReadPos(displayBlock, "y", _displayY);
        
        _jsonReadInt(displayBlock, "width", _displayWidth);
        _jsonReadInt(displayBlock, "height", _displayHeight);
        _jsonReadStr(displayBlock, "orientation", _displayOrientation);
        _jsonReadBool(displayBlock, "maximized", _displayMaximized);
        _jsonReadBool(displayBlock, "minimized", _displayMinimized);
        _jsonReadBool(displayBlock, "resizable", _displayResizable);
        _jsonReadBool(displayBlock, "borderless", _displayBorderless);
        _jsonReadStr(displayBlock, "mode", _displayMode);
    }

    json_delete(json);
}
