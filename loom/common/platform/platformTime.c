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

#include <assert.h>
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platform.h"
#include "loom/common/core/allocator.h"

#if LOOM_PLATFORM_IS_APPLE

#include <mach/mach_time.h>
#include <sys/time.h>

// TODO: Can we reuse this indefinitely? Or will it vary?
static mach_timebase_info_data_t gTimebaseInfo;
static uint64_t gEpochStart;

void platform_timeInitialize()
{
    /* Get the timebase info */
    mach_timebase_info(&gTimebaseInfo);

    // Track time relative to app start so we don't run out of range too quickly.
    gEpochStart = mach_absolute_time();
}


int platform_getMilliseconds()
{
    uint64_t t = mach_absolute_time() - gEpochStart;
    uint64_t r = (t * gTimebaseInfo.numer) / gTimebaseInfo.denom;

    r /= 1000 * 1000; // Convert from ns to ms.
    return r;
}


typedef struct loom_mach_precisionTimer_t
{
    mach_timebase_info_data_t info;
    uint64_t                  start;
} loom_mach_precisionTimer_t;

loom_precision_timer_t loom_startTimer()
{
    loom_mach_precisionTimer_t *t = lmAlloc(NULL, sizeof(loom_mach_precisionTimer_t));

    mach_timebase_info(&t->info);
    t->start = mach_absolute_time();
    return t;
}


int loom_readTimer(loom_precision_timer_t timer)
{
    loom_mach_precisionTimer_t *t = timer;
    uint64_t a = mach_absolute_time() - t->start;
    uint64_t b = (a * t->info.numer) / t->info.denom;

    b /= 1000 * 1000; // Convert from ns to ms.
    return b;
}


void loom_destroyTimer(loom_precision_timer_t timer)
{
    loom_mach_precisionTimer_t *t = (loom_mach_precisionTimer_t *)timer;

    lmFree(NULL, t);
}


#elif LOOM_PLATFORM == LOOM_PLATFORM_WIN32

#include <windows.h>

void platform_timeInitialize()
{
    int r = timeBeginPeriod(1);

    assert(r == TIMERR_NOERROR);
}


int platform_getMilliseconds()
{
    // TODO: Do better than this.
    return timeGetTime();
}


typedef struct loom_win32_precisionTimer_t
{
    LARGE_INTEGER mPerfCountCurrent;
    LARGE_INTEGER mFrequency;
} loom_win32_precisionTimer_t;

loom_precision_timer_t loom_startTimer()
{
    loom_win32_precisionTimer_t *t = lmAlloc(NULL, sizeof(loom_win32_precisionTimer_t));

    QueryPerformanceFrequency(&t->mFrequency);
    QueryPerformanceCounter(&t->mPerfCountCurrent);
    return t;
}


int loom_readTimer(loom_precision_timer_t timer)
{
    double elapsed = 0.f;
    loom_win32_precisionTimer_t *t = (void *)timer;
    LARGE_INTEGER               endCount;

    QueryPerformanceCounter(&endCount);
    elapsed = 1000.0 * ((double)(endCount.QuadPart - t->mPerfCountCurrent.QuadPart) / (double)t->mFrequency.QuadPart);
    return (int)elapsed;
}


void loom_destroyTimer(loom_precision_timer_t timer)
{
    loom_win32_precisionTimer_t *t = (loom_win32_precisionTimer_t *)timer;

    lmFree(NULL, t);
}


#else  // Assume *nix?

#include <time.h>
int timespecDelta(struct timespec *then, struct timespec *now);

struct timespec dawn;

typedef struct timespec   loom_linux_precisionTimer_t; // Don't bother creating our own timer struct -- for now, just use timespec

// Select a platform appropriate clock. CLOCK_MONOTONIC is reported
// to give best results on Android, 
// see http://gamasutra.com/view/feature/171774/getting_high_precision_timing_on_.php?print=1
// for a full discussion.
#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#define WHICH_CLOCK CLOCK_MONOTONIC
#else
#define WHICH_CLOCK CLOCK_REALTIME 
#endif

void platform_timeInitialize()
{
    // Store the current time as our dawn moment.
    clock_gettime(WHICH_CLOCK, &dawn);
}


int platform_getMilliseconds()
{
    struct timespec now;

    clock_gettime(WHICH_CLOCK, &now);

    return timespecDelta(&dawn, &now);
}


loom_precision_timer_t loom_startTimer()
{
    loom_linux_precisionTimer_t *t = lmAlloc(NULL, sizeof(loom_linux_precisionTimer_t));

    clock_gettime(WHICH_CLOCK, t);
    return t;
}


int loom_readTimer(loom_precision_timer_t timer)
{
    struct timespec             now;
    loom_linux_precisionTimer_t *t = (loom_linux_precisionTimer_t *)timer;

    clock_gettime(WHICH_CLOCK, &now);

    return timespecDelta(t, &now);
}


int timespecDelta(struct timespec *then, struct timespec *now)
{
    long deltaSec  = now->tv_sec - then->tv_sec;
    long deltaNSec = now->tv_nsec - then->tv_nsec;

    long deltaMSec = deltaSec * 1000 + deltaNSec / (1000 * 1000);

    return (int)deltaMSec;
}


void loom_destroyTimer(loom_precision_timer_t timer)
{
    loom_linux_precisionTimer_t *t = (loom_linux_precisionTimer_t *)timer;

    lmFree(NULL, t);
}
#endif
