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

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include "loom/common/platform/platform.h"
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/stringTable.h"


/***
 * Logging Design Goals
 *
 * 1. Log levels.
 * 2. Log groups.
 * 3. Filter rules.
 * 4. Multiple listeners.
 * 5. Absolute simplest API and good performance.
 * 6. No global registration steps.
 ***/

lmDefineLogGroup(gLogLogGroup, "logger", 0, LoomLogInfo);

// A log listener callback description contained in a linked list.
typedef struct loom_log_listenerEntry
{
    void                          *payload;
    loom_logListener_t            callback;
    struct loom_log_listenerEntry *next;
} loom_log_listenerEntry_t;

// A log rule description contained in a linked list.
typedef struct loom_log_rule
{
    const char           *groupPrefix;
    int                  enabledRule;
    int                  filterRule;
    struct loom_log_rule *next;
} loom_log_rule_t;

static loom_log_listenerEntry_t *listenerHead     = NULL;
static loom_log_rule_t          *ruleHead         = NULL;
static int              gLoomLogInvalidationToken = 1;
static loom_allocator_t *gLoggerAllocator         = NULL;

static void platformDebugListener(void *payload, loom_logGroup_t *group, loom_logLevel_t level, const char *msg)
{
    // TODO: Don't need to reprint the msg. platform_debugOut has printf semantics
    // so we are doing extra work here. We can skip it since msg is always baked out.
    // NOTE: Don't replace "%s" with msg, this will make any %'s in msg result in
    // inappropriate argument substitution.
    platform_debugOut("%s", msg);
}


void loom_log_initialize()
{
    // Turn off buffering to behave properly for loom CLI.
    setbuf(stdout, NULL);

    // Get our allocator.
    gLoggerAllocator = loom_allocator_getGlobalHeap();

    // And make sure we'll log SOMETHING.
    if (listenerHead == NULL)
    {
        loom_log_addListener(platformDebugListener, NULL);
    }
}


void loom_log_addListener(loom_logListener_t listener, void *payload)
{
    loom_log_listenerEntry_t *entry = lmAlloc(gLoggerAllocator, sizeof(loom_log_listenerEntry_t));

    memset(entry, 0, sizeof(loom_log_listenerEntry_t));

    // Fill in the listener entry.
    entry->callback = listener;
    entry->payload  = payload;

    // Link it on the list.
    entry->next  = listenerHead;
    listenerHead = entry;
}


void loom_log_removeListener(loom_logListener_t listener, void *payload)
{
    // Walk list and remove listener.
    loom_log_listenerEntry_t **entry = &listenerHead;
    loom_log_listenerEntry_t *cur    = NULL;

    do
    {
        cur = *entry;
        lmAssert(cur != 0, "Could not find listener to remove.");

        if (cur->payload != payload)
        {
            continue;
        }

        if (cur->callback != listener)
        {
            continue;
        }

        // Got it! Unlink and free.
        *entry = cur->next;
        lmFree(NULL, cur);
        return;
    } while ((entry = &((*entry)->next)));

    lmAssert(0, "Could not find listener to remove.");
}

#ifndef _MSC_VER
int _vscprintf(const char *format, va_list pargs)
{
    int retval;
    va_list argcopy;
    va_copy(argcopy, pargs);
    retval = vsnprintf(NULL, 0, format, argcopy);
    va_end(argcopy);
    return retval;
}
#endif

char* loom_log_getArgs(va_list args, const char **format) {
    int count = _vscprintf(*format, args);
    char* buff = (char*)malloc(count + 2);
    #if LOOM_COMPILER == LOOM_COMPILER_MSVC
        vsprintf_s(buff, count + 1, *format, args);
    #else
        vsnprintf(buff, count + 1, *format, args);
    #endif
    return buff;
}

void loom_log(loom_logGroup_t *group, loom_logLevel_t level, const char *format, ...)
{
    loom_log_listenerEntry_t *listener = listenerHead;

    // sometimes we're not using the lmLog macros, so enforce good behavior.
    if (!group->enabled)
    {
        return;
    }

    if (level < group->filterLevel)
    {
        return;
    }

    /*
    va_list args;
    char    buff[3000];
    va_start(args, format);
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    vsprintf_s(buff, 2998, format, args);
#else
    vsnprintf(buff, 2998, format, args);
#endif
    va_end(args);
    //*/
    
    //char* buff = loom_log_getArgs(&format);

    /*
    va_list args;
    va_start(args, format);
    int count = 3000;
    char* buff = (char*)malloc(count + 2);
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    vsprintf_s(buff, count + 1, format, args);
#else
    vsnprintf(buff, count, format, args);
#endif
    va_end(args);
    //*/

    char* buff;
    lmLogArgs(buff, format);

    // Walk the listeners and output.
    while (listener)
    {
        listener->callback(listener->payload, group, level, buff);
        listener = listener->next;
    }

    free(buff);

}


static void invalidateLogRuleToken()
{
    // Make sure we'll reapply all the rules. Note there is a 1 in 4
    // billion chance we might wrap around and miss updaeting group.
    // However, it's unlikely we'll encounter 4 billion rules between
    // calls to a group. In order to avoid the common case there, we'll
    // also skip 0.
    gLoomLogInvalidationToken++;
    if (gLoomLogInvalidationToken == 0)
    {
        gLoomLogInvalidationToken = 1;
    }
}


void loom_log_addRule(const char *prefix, int enabled, int filterLevel)
{
    // Allocate and store the rule.
    loom_log_rule_t *entry = lmAlloc(gLoggerAllocator, sizeof(loom_log_rule_t));

    memset(entry, 0, sizeof(loom_log_rule_t));

    // Fill in the listener entry.
    entry->groupPrefix = stringtable_insert(prefix);
    entry->enabledRule = enabled;
    entry->filterRule  = filterLevel;

    // Link it on the list.
    entry->next = ruleHead;
    ruleHead    = entry;

    // TODO: Make sure we keep rules sorted by group prefix length so most
    // specific rule is applied last?

    invalidateLogRuleToken();

    lmLogInfo(gLogLogGroup, "Adding rule '%s' enabled=%d level=%d", prefix, enabled, filterLevel);
    if ((enabled == -1) && (filterLevel == -1))
    {
        lmLogError(gLogLogGroup, "Rule '%s' has neither enabled nor filter level set.", prefix);
    }
}


void loom_log_resetRules()
{
    // Walk and free the list.
    loom_log_rule_t *tmp, *walk = ruleHead;

    while (walk)
    {
        tmp = walk->next;
        lmFree(gLoggerAllocator, tmp);
        walk = tmp;
    }

    ruleHead = NULL;

    invalidateLogRuleToken();
}


int loom_log_willGroupLog(loom_logGroup_t *group)
{
    loom_log_rule_t *walk = ruleHead;

    if (group->ruleCacheToken != gLoomLogInvalidationToken)
    {
        // Mark it as being up to date right away; this allow us to
        // emit log output on the following line.
        group->ruleCacheToken = gLoomLogInvalidationToken;

        lmLogInfo(gLogLogGroup, "Applying rules to group %s", group->name);

        // Apply rules to this group.
        while (walk)
        {
            lmLogInfo(gLogLogGroup, "  - Considering rule '%s'", walk->groupPrefix);

            // Is it a prefix match?
            if (strstr(group->name, walk->groupPrefix) == group->name)
            {
                lmLogInfo(gLogLogGroup, "  o Applying rule '%s'", walk->groupPrefix);

                // If so, set enabled/filter.
                if (walk->enabledRule != -1)
                {
                    group->enabled = walk->enabledRule;
                }
                if (walk->filterRule != -1)
                {
                    group->filterLevel = walk->filterRule;
                }
            }

            walk = walk->next;
        }
    }

    // Great, we know rules are fully applied to this group at this time.
    return group->enabled;
}
