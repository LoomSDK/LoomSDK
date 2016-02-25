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

#include "lsLog.h"
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>

#include "loom/script/loomscript.h"

namespace LS {
static FunctionLog externLog = 0;

static void *externExtra = 0;

// mappings to external logging
static int externLogDebug = -1;
static int externLogInfo  = -1;
static int externLogWarn  = -1;
static int externLogError = -1;

static LSLogLevel logLevel = LSLogInfo;

void LSLogInitialize(FunctionLog log, void *extra,
    int logDebug, int logInfo, int logWarn, int logError)
{
    externExtra    = extra;
    externLog      = log;
    externLogDebug = logDebug;
    externLogInfo  = logInfo;
    externLogWarn  = logWarn;
    externLogError = logError;
}


void LSLogSetLevel(LSLogLevel level)
{
    logLevel = level;
}

void LSLog(LSLogLevel level, const char *format, ...)
{
    char* buff;
    va_list args;

    if (level < logLevel)
    {
        return;
    }

    lmLogArgs(args, buff, format);

    if (externLog)
    {
        int elevel;

        switch (level)
        {
        case LSLogDebug:
            elevel = externLogDebug;
            break;

        case LSLogInfo:
            elevel = externLogInfo;
            break;

        case LSLogWarn:
            elevel = externLogWarn;
            break;

        case LSLogError:
            elevel = externLogError;
            break;
        }

        externLog(externExtra, elevel, "%s", buff);
    } else {
        printf("%s\n", buff);
    }

    lmFree(NULL, buff);

}
}
