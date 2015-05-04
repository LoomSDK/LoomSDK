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
#include <stdlib.h>
#include <string.h>
#include "loom/common/platform/platform.h"

// TODO: Handle include directories correctly for Android so that this isn't needed.
//  The problem is that our assert.h replaces the standard lib assert.h through a naming
//  conflict that is caused by us adding engine/src/core as an include directory.
//  Not hard to fix, but just something to do.
// But in the meantime, this was left in as a rather convenient accident on how to get
//  better tracelogs on all Android asserts, so left in for debugging in the meantime.
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#undef assert
#define assert(e)    lmSafeAssert(e, "Failed assertion: " # e)
#endif

// Allow user code to specify a callback in case of an assert. Note that this
// may be run in a very broken state, so be extremely careful what library code
// your use. It will be called after the assert is displayed.
#ifdef __cplusplus
extern "C" {
#endif
typedef void (*loom_assertcallback)();
void loom_setAssertCallback(loom_assertcallback);
void loom_fireAssertCallback();

#ifdef __cplusplus
};
#endif

#if !LOOM_DEBUG

#define lmSafeAssert(condition, errmsg)
#define lmAssert(condition, errmsg, ...)

#else

#define lmSafeAssert lmSafeCheck
#define lmAssert lmCheck

#endif

// Use lmSafeAssert when we are in modules that might not be able to handle malloc() and strcpy()
#define lmSafeCheck(condition, errmsg) \
    if (!(condition)) { platform_error("Assert failed [%s@%d] (" # condition "): %s", __FILE__, __LINE__, (errmsg)); abort(); }

// Use lmAssert when we can afford to use varargs
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
#define lmCheck(condition, errmsg, ...)                                                                                                          \
    if (!(condition)) {                                                                                                                           \
        char *lmAssertBuf = (char *)malloc(strlen(errmsg) + strlen(# condition) + 32); /* Allocate our buffer with 32 bytes of breathing room. */ \
        strcpy(lmAssertBuf, "Assert failed [%s@%d] (" # condition "): ");              /* Begin with our standard "assert failed" prefix. */      \
        strcpy(lmAssertBuf + strlen(lmAssertBuf), errmsg);                             /* Append our message to the end of our format string. */  \
        strcpy(lmAssertBuf + strlen(lmAssertBuf), "\n");                               /* Append a new line to the end for good measure. */       \
        platform_error(lmAssertBuf, __FILE__, __LINE__, __VA_ARGS__);                                                                             \
        __debugbreak();                                                                                                                           \
        loom_fireAssertCallback();                                                                                                                \
        abort();                                                                                                                                  \
    }
#else
#define lmCheck(condition, errmsg, args ...)                                                                                                     \
    if (!(condition)) {                                                                                                                           \
        char *lmAssertBuf = (char *)malloc(strlen(errmsg) + strlen(# condition) + 32); /* Allocate our buffer with 32 bytes of breathing room. */ \
        strcpy(lmAssertBuf, "Assert failed [%s@%d] (" # condition "): \n");            /* Begin with our standard "assert failed" prefix. */      \
        strcpy(lmAssertBuf + strlen(lmAssertBuf), errmsg);                             /* Append our message to the end of our format string. */  \
        strcpy(lmAssertBuf + strlen(lmAssertBuf), "\n");                               /* Append a new line to the end for good measure. */       \
        platform_error(lmAssertBuf, __FILE__, __LINE__, ## args);                                                                                 \
        loom_fireAssertCallback();                                                                                                                \
        abort();                                                                                                                                  \
    }
#endif

#endif