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
#include "loom/common/core/allocator.h"
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <assert.h>

namespace LS {

static LSExitHandler exitHandler;

void LSSetExitHandler(LSExitHandler handler)
{
    exitHandler = handler;
}

void LSError(const char *format, ...)
{
    char* buff;
    va_list args;
    lmLogArgs(args, buff, format);
    LSLog(LSLogError, "%s", buff);
    lmFree(NULL, buff);

#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    __debugbreak();
#endif

    if (exitHandler) exitHandler();

    exit(EXIT_FAILURE);
}


void LSWarning(const char *format, ...)
{
    char* buff;
    va_list args;
    lmLogArgs(args, buff, format);
    LSLog(LSLogWarn, "%s", buff);
    lmFree(NULL, buff);
}
}
