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

#include <stdlib.h>
#include "seatest.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/core/assert.h"

SEATEST_FIXTURE(platformThread)
{
    SEATEST_FIXTURE_ENTRY(platformThread_locklessCountTest);
    SEATEST_FIXTURE_ENTRY(platformThread_mutexCountTest);
    SEATEST_FIXTURE_ENTRY(platformThread_semaphoreChain);
    SEATEST_FIXTURE_ENTRY(platformThread_compareExchangeTest);
}

static MutexHandle  gTestCountMutex      = NULL;
static volatile int gCompareExchangeLock = 0;
static volatile int gTestCount           = 0;

static const int COUNT_UP_UNLOCKED = 0;
static const int COUNT_UP_LOCKED   = 1;

static const int COUNT_DOWN_UNLOCKED = 7;
static const int COUNT_DOWN_LOCKED   = 12;

static const int THREAD_COUNT    = 16;
static const int INCREMENT_LIMIT = 5000;

static int __stdcall threadCountUpLocklessFunc(void *param)
{
    for (int i = 0; i < INCREMENT_LIMIT; i++)
    {
        atomic_increment(&gTestCount);
    }

    return 0;
}


static int __stdcall threadCountDownLocklessFunc(void *param)
{
    for (int i = 0; i < INCREMENT_LIMIT; i++)
    {
        atomic_decrement(&gTestCount);
    }

    return 0;
}


SEATEST_TEST(platformThread_locklessCountTest)
{
    // Spawn threads that each increment many times.
    const int    threadCount = THREAD_COUNT;
    ThreadHandle thread[threadCount];

    // Start them up.
    for (int i = 0; i < threadCount; i++)
    {
        thread[i] = loom_thread_start(threadCountUpLocklessFunc, NULL);
    }

    // Wait for them all to end.
    for (int i = 0; i < threadCount; i++)
    {
        loom_thread_join(thread[i]);
    }

    // Check results.
    assert_int_equal(threadCount * INCREMENT_LIMIT, gTestCount);

    // Now, count back down.
    for (int i = 0; i < threadCount; i++)
    {
        thread[i] = loom_thread_start(threadCountDownLocklessFunc, NULL);
    }

    // Wait for them all to end.
    for (int i = 0; i < threadCount; i++)
    {
        loom_thread_join(thread[i]);
    }

    // Check results.
    assert_int_equal(0, gTestCount);
}

static int __stdcall threadCountUpMutexFunc(void *param)
{
    for (int i = 0; i < INCREMENT_LIMIT; i++)
    {
        loom_mutex_lock(gTestCountMutex);
        gTestCount++;
        loom_mutex_unlock(gTestCountMutex);
    }

    return 0;
}


static int __stdcall threadCountDownMutexFunc(void *param)
{
    for (int i = 0; i < INCREMENT_LIMIT; i++)
    {
        loom_mutex_lock(gTestCountMutex);
        gTestCount--;
        loom_mutex_unlock(gTestCountMutex);
    }

    return 0;
}


SEATEST_TEST(platformThread_mutexCountTest)
{
    // Set up mutex.
    gTestCountMutex = loom_mutex_create();

    // Spawn threads that each increment many times.
    const int    threadCount = THREAD_COUNT;
    ThreadHandle thread[threadCount];

    // Start them up.
    for (int i = 0; i < threadCount; i++)
    {
        thread[i] = loom_thread_start(threadCountUpMutexFunc, NULL);
    }

    // Wait for them all to end.
    for (int i = 0; i < threadCount; i++)
    {
        loom_thread_join(thread[i]);
    }

    // Check results.
    assert_int_equal(threadCount * INCREMENT_LIMIT, gTestCount);

    // Now, count back down.
    for (int i = 0; i < threadCount; i++)
    {
        thread[i] = loom_thread_start(threadCountDownMutexFunc, NULL);
    }

    // Wait for them all to end.
    for (int i = 0; i < threadCount; i++)
    {
        loom_thread_join(thread[i]);
    }

    // Check results.
    assert_int_equal(0, gTestCount);

    // Clean up mutex.
    loom_mutex_destroy(gTestCountMutex);
    gTestCountMutex = NULL;
}

static int __stdcall threadCountUpCompareExchangeFunc(void *param)
{
    int myCnt = 0;

    while (myCnt < INCREMENT_LIMIT)
    {
        if (atomic_compareAndExchange(&gCompareExchangeLock, COUNT_UP_UNLOCKED, COUNT_UP_LOCKED) == COUNT_UP_UNLOCKED)
        {
            gTestCount++;
            myCnt++;
            gCompareExchangeLock = COUNT_UP_UNLOCKED;
        }
    }

    return 0;
}


static int __stdcall threadCountDownCompareExchangeFunc(void *param)
{
    int myCnt = 0;

    while (myCnt < INCREMENT_LIMIT)
    {
        if (atomic_compareAndExchange(&gCompareExchangeLock, COUNT_DOWN_UNLOCKED, COUNT_DOWN_LOCKED) == COUNT_DOWN_UNLOCKED)
        {
            gTestCount--;
            myCnt++;
            gCompareExchangeLock = COUNT_DOWN_UNLOCKED;
        }
    }

    return 0;
}


SEATEST_TEST(platformThread_compareExchangeTest)
{
    // Set up the central compare-exchange mutex.
    gCompareExchangeLock = COUNT_UP_UNLOCKED;

    // Spawn threads that each increment many times.
    const int    threadCount = THREAD_COUNT;
    ThreadHandle thread[threadCount];

    // Start them up.
    for (int i = 0; i < threadCount; i++)
    {
        thread[i] = loom_thread_start(threadCountUpCompareExchangeFunc, NULL);
    }

    // Wait for them all to end.
    for (int i = 0; i < threadCount; i++)
    {
        loom_thread_join(thread[i]);
    }

    // Check results.
    assert_int_equal(threadCount * INCREMENT_LIMIT, gTestCount);

    gCompareExchangeLock = COUNT_DOWN_UNLOCKED;

    // Now, count back down.
    for (int i = 0; i < threadCount; i++)
    {
        thread[i] = loom_thread_start(threadCountDownCompareExchangeFunc, NULL);
    }

    // Wait for them all to end.
    for (int i = 0; i < threadCount; i++)
    {
        loom_thread_join(thread[i]);
    }

    // Check results.
    assert_int_equal(0, gTestCount);

    // Ensure our lock variable got set back the way it should.
    assert_int_equal(COUNT_DOWN_UNLOCKED, gCompareExchangeLock);
}


static const int       gSemChainLength = 512;
static SemaphoreHandle gSemChain[gSemChainLength];
// Scratch pad that will be used for each thread to keep track of whether
//  or not its previous / successor threads are taking their turns in the
//  proper time.  We don't have a central check in the main test function,
//  but if each thread checks its neighbor, and we ensure that the entire
//  scratch pad is scribbled on in the end, then we know that everyone
//  behaved like they should.
// The scratch pad starts with all zeroes:
//  000000000000000000000000000000
// And as threads begin to execute, they scribble on the pad:
//  111111000000000000000000000000
// And each thread can ensure that its predecessor has scribbled a 1, and
//  each successor has not yet written anything.
static volatile int gSemThreadScratch[gSemChainLength];

static int __stdcall threadSemChainFunc(void *arg)
{
    size_t realArg = (size_t)arg;

    loom_semaphore_wait(gSemChain[realArg]);

    // Ensure that the previous place has been scribbled on.
    if (realArg > 0)
    {
        assert_int_equal(1, gSemThreadScratch[realArg - 1]);
    }

    // Ensure that our scratch pad has NOT been scribbled on yet
    assert_int_equal(0, gSemThreadScratch[realArg]);

    // Scribble on the scratch pad to mark where we're at in the chain.
    gSemThreadScratch[realArg] = 1;

    // Ensure that the next place has NOT been scribbled on.
    if (realArg < gSemChainLength - 1)
    {
        assert_int_equal(0, gSemThreadScratch[realArg + 1]);
    }

    // And post for the next thread to continue (if there is a next thead)
    loom_semaphore_post(gSemChain[realArg + 1]);

    return 0;
}


SEATEST_TEST(platformThread_semaphoreChain)
{
    // Set up semaphores.
    for (int i = 0; i < gSemChainLength; i++)
    {
        gSemChain[i]         = loom_semaphore_create();
        gSemThreadScratch[i] = 0;
    }

    // Kick off threads. Each thread waits for its corresponding sem and
    // then posts to next sem, forming a chain.
    ThreadHandle chainThreads[gSemChainLength - 1];

    for (int i = 0; i < gSemChainLength - 1; i++)
    {
        chainThreads[i] = loom_thread_start(threadSemChainFunc, (void *)(size_t)i);
    }

    // Kick off first link in chain, then wait for last.
    loom_semaphore_post(gSemChain[0]);
    loom_semaphore_wait(gSemChain[gSemChainLength - 1]);

    // Close threads.
    for (int i = 0; i < gSemChainLength - 1; i++)
    {
        loom_thread_join(chainThreads[i]);
    }

    // Tear down semaphores.
    for (int i = 0; i < gSemChainLength; i++)
    {
        loom_semaphore_destroy(gSemChain[i]);
    }

    // Ensure that all scratch pad places have been scribbled on appropriately.
    for (int i = 0; i < gSemChainLength - 1; i++)
    {
        assert_int_equal(1, gSemThreadScratch[i]);
    }

    // Ensure that the last scratch pad place (ours) hasn't been scribbled on yet.
    assert_int_equal(0, gSemThreadScratch[gSemChainLength - 1]);

    // If it finishes we are golden.
    assert_true(true);
}
