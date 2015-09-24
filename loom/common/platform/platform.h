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

#ifndef _PLATFORM_PLATFORM_H_
#define _PLATFORM_PLATFORM_H_

#define LOOM_PLATFORM_WIN32      1
#define LOOM_PLATFORM_OSX        2
#define LOOM_PLATFORM_IOS        3
#define LOOM_PLATFORM_ANDROID    4
#define LOOM_PLATFORM_LINUX      5

// NOTE: LOOM_PLATFORM_IS_APPLE is defined below, but is noted up here.
//   This shortcut flag can be used to quickly test for the common case
//     of OSX or iOS (which share many libraries and routines).

#define LOOM_COMPILER_MSVC    1
#define LOOM_COMPILER_GNU     2
#define LOOM_COMPILER_CLANG   3

// Detect the current platform
#ifdef WIN32
    #define LOOM_PLATFORM    LOOM_PLATFORM_WIN32
#elif defined(__APPLE__)
    #include "TargetConditionals.h"
    #if TARGET_OS_IPHONE      // TARGET_OS_MAC is defined as 1 for iOS devices, so we need to check to make sure that TARGET_OS_IPHONE is NOT 1 before we can confirm that we're on OS/X.
        #define LOOM_PLATFORM    LOOM_PLATFORM_IOS
    #elif TARGET_OS_MAC
        #define LOOM_PLATFORM    LOOM_PLATFORM_OSX
    #endif
#elif defined(ANDROID_NDK)
    #define LOOM_PLATFORM    LOOM_PLATFORM_ANDROID
#elif defined(LOOM_LINUX_BUILD)
    #define LOOM_PLATFORM    LOOM_PLATFORM_LINUX
#endif

#ifndef LOOM_PLATFORM
    #error Unable to detect platform for Loom
#endif

// Detect the current compiler
#if defined(_MSC_VER)
    #define LOOM_COMPILER    LOOM_COMPILER_MSVC
#elif defined(__GNUC__)
    #define LOOM_COMPILER    LOOM_COMPILER_GNU
#elif defined(__clang__)
    #define LOOM_COMPILER    LOOM_COMPILER_CLANG
#else
    #error Unable to detect compiler for Loom
#endif

// Detect if the current platform is 64 bit
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    #ifdef _WIN64
        #define LOOM_PLATFORM_64BIT 1
    #else
        #define LOOM_PLATFORM_64BIT 0
    #endif
#elif LOOM_COMPILER == LOOM_COMPILER_CLANG || LOOM_COMPILER == LOOM_COMPILER_GNU
    #if defined(__x86_64__)
        #define LOOM_PLATFORM_64BIT 1
    #else
        #define LOOM_PLATFORM_64BIT 0
    #endif
#else
    #error "Unknown platform 64 bit support"
#endif

// Platform detection flag shortcuts
#if (LOOM_PLATFORM == LOOM_PLATFORM_IOS) || (LOOM_PLATFORM == LOOM_PLATFORM_OSX)
    #define LOOM_PLATFORM_IS_APPLE    1
#else
    #define LOOM_PLATFORM_IS_APPLE    0
#endif

#define LOOM_PLATFORM_TOUCH LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_IOS

#ifdef __cplusplus
extern "C" {
#endif

int platform_error(const char *out, ...);
int platform_debugOut(const char *out, ...);

#ifdef __cplusplus
}
#endif


int platform_error(const char *out, ...);
int platform_debugOut(const char *out, ...);
#endif // _PLATFORM_PLATFORM_H_
