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

#ifndef _CORE_LOG_H
#define _CORE_LOG_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>

/**
 * Loom includes a lightweight logging framework.
 *
 * All log output is associated with a log group. Log groups provide a name,
 * an enabled, and a filter level (controlling what severity of log message
 * is displayed). Log groups are defined with the following macro in global
 * scope.
 *
 *    // Log group for Loom asset system. Logging is enabled by default (1),
 *    // and the minimim default threshold to show are warnings.
 *    lmDefineLogGroup(loom_asset, "loom.asset", 1, LoomLogWarn);
 *
 * Log groups may need to be shared across files. In this case you need one
 * instance of lmDefineLogGroup somewhere in your program, and the following
 * macro visible to the other files using the group:
 *
 *    lmDeclareLogGroup(loom_asset);
 *
 * Users may configure the logging system using prefix based rules. This is
 * implemented here via loom_log_addRule, but users will generally configure
 * it via loom.config.
 */

#define lmDeclareLogGroup(varName)                                    extern loom_logGroup_t varName;
#define lmDefineLogGroup(varName, groupName, enabled, filterLevel)    loom_logGroup_t varName = { groupName, enabled, filterLevel, 0 };

#define lmLogDebug(group, format, ...)                                if (loom_log_willGroupLog(&group)) { loom_log(&group, LoomLogDebug, "[%s] " format, group.name, ## __VA_ARGS__); }
#define lmLogInfo(group, format, ...)                                 if (loom_log_willGroupLog(&group)) { loom_log(&group, LoomLogInfo, "[%s] " format, group.name, ## __VA_ARGS__); }
#define lmLogError(group, format, ...)                                if (loom_log_willGroupLog(&group)) { loom_log(&group, LoomLogError, "[%s] " format, group.name, ## __VA_ARGS__); }
#define lmLogWarn(group, format, ...)                                 if (loom_log_willGroupLog(&group)) { loom_log(&group, LoomLogWarn, "[%s] " format, group.name, ## __VA_ARGS__); }
#define lmLog    lmLogInfo // Alias for completeness.

/**
Get the arguments of a log function as a char*,
make sure you free the char string when you are done with it!
format is a pointer to the format argument pointer (required for varargs functionality),
so you should use &format when calling this function
*/
char* loom_log_getArgs(va_list args, const char **format);

/**
 * Helper to pass and log arguments. Requires a va_list instanced
 * passed as first parameter.
 */
#define lmLogArgs(args, buff, format) \
    va_start(args, format); \
    buff = loom_log_getArgs(args, &format); \
    va_end(args); \


typedef struct loom_logGroup
{
    const char *name;
    int        enabled;
    int        filterLevel;
    int        ruleCacheToken;
} loom_logGroup_t;

typedef enum loom_logLevel
{
    LoomLogDebug = -1,   // Start below zero so that 0 defaults to something sane.
    LoomLogInfo,
    LoomLogWarn,
    LoomLogError,
    LoomLogMax   = LoomLogError
} loom_logLevel_t;

void loom_log_initialize();

typedef void (*loom_logListener_t)(void *payload, loom_logGroup_t *group, loom_logLevel_t level, const char *msg);
void loom_log_addListener(loom_logListener_t listener, void *payload);
void loom_log_removeListener(loom_logListener_t listener, void *payload);

void loom_log(loom_logGroup_t *group, loom_logLevel_t level, const char *format, ...);

// TODO: Make sure this inlines.
int loom_log_willGroupLog(loom_logGroup_t *group);
void loom_log_addRule(const char *prefix, int enabled, int filterLevel);
void loom_log_resetRules();

#ifdef __cplusplus
};
#endif
#endif
