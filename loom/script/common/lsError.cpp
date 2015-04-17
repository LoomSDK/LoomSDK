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

#include "lsError.h"
#include "lsLog.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <assert.h>


namespace LS {
void LSError(const char *format, ...)
{
    /*
    char    buff[2048];
    va_list args;

    va_start(args, format);
#ifdef _MSC_VER
    vsprintf_s(buff, 2046, format, args);
#else
    vsnprintf(buff, 2046, format, args);
#endif
    va_end(args);
    */

    char* buff;
    va_list args;
    lmLogArgs(args, buff, format);
    LSLog(LSLogError, "%s", buff);
    free(buff);

    exit(EXIT_FAILURE);
}


void LSWarning(const char *format, ...)
{
    /*
    char    buff[2048];
    va_list args;

    va_start(args, format);
#ifdef _MSC_VER
    vsprintf_s(buff, 2046, format, args);
#else
    vsnprintf(buff, 2046, format, args);
#endif
    va_end(args);
    */

    char* buff;
    va_list args;
    lmLogArgs(args, buff, format);

    LSLog(LSLogWarn, "%s", buff);

    free(buff);
}
}
