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

#ifndef _CORE_ASSERT_H_
#define _CORE_ASSERT_H_

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

inline int platform_error(const char *out, ...)
{
    // TODO: Does this need to be smarter, or stripped in release builds?
    va_list args;

    va_start(args, out);
    vprintf(out, args);
    va_end(args);

    return 0;
}


#ifdef NDEBUG

#define lmSafeAssert(condition, errmsg)     { assert(condition); }
#define lmAssert(condition, errmsg, ...)    { assert(condition); }

#else

#define lmSafeAssert(condition, errmsg)     { assert(condition); }
#define lmAssert(condition, errmsg, ...)    { assert(condition); }
#endif
#endif
