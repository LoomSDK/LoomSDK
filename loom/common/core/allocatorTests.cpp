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


#include "loom/common/core/allocator.h"
#include "loom/common/core/allocatorJEMalloc.h"
#include "seatest.h"

SEATEST_FIXTURE(allocatorSystem)
{
    SEATEST_FIXTURE_ENTRY(allocator_basic);
    SEATEST_FIXTURE_ENTRY(allocator_basicRealloc)
    SEATEST_FIXTURE_ENTRY(allocator_freeList);
    SEATEST_FIXTURE_ENTRY(allocator_cppNewDeleteBasic);
    SEATEST_FIXTURE_ENTRY(allocator_cppNewDeleteComplex);
    SEATEST_FIXTURE_ENTRY(allocator_jemalloc);
    SEATEST_FIXTURE_ENTRY(allocator_arena);
}

SEATEST_TEST(allocator_basic)
{
    int              i          = 0;
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    void *data = lmAlloc(heapAlloc, 1024);

    for (i = 0; i < 1024; i++)
    {
        ((unsigned char *)data)[i] = i & 0xFF;
    }
    lmFree(heapAlloc, data);
}

SEATEST_TEST(allocator_basicRealloc)
{
    int              i          = 0;
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    // Make it.
    void *data = lmAlloc(heapAlloc, 1024);

    assert_true(data != NULL);
    for (i = 0; i < 1024; i++)
    {
        ((unsigned char *)data)[i] = i & 0xFF;
    }

    // Grow it.
    data = lmRealloc(heapAlloc, data, 2048);
    assert_true(data != NULL);
    for (i = 0; i < 2048; i++)
    {
        ((unsigned char *)data)[i] = (i + 64) & 0xFF;
    }

    // Shrink it.
    data = lmRealloc(heapAlloc, data, 1024);
    assert_true(data != NULL);
    for (i = 0; i < 1024; i++)
    {
        ((unsigned char *)data)[i] = (i + 75) & 0xFF;
    }

    // Free it.
    lmFree(heapAlloc, data);
}

SEATEST_TEST(allocator_freeList)
{
    loom_allocator_t *freeListAlloc = loom_allocator_initializeFixedPoolAllocator(loom_allocator_getGlobalHeap(), 128, 1024);
    void             *a, *b, *c, *d;

    for (int i = 0; i < 1024 / 4; i++)
    {
        assert_true((a = lmAlloc(freeListAlloc, 128)) != NULL);
        assert_true((b = lmAlloc(freeListAlloc, 128)) != NULL);
        assert_true((c = lmAlloc(freeListAlloc, 128)) != NULL);
        assert_true((d = lmAlloc(freeListAlloc, 128)) != NULL);
    }

    // Can't alloc any more.
    assert_true(lmAlloc(freeListAlloc, 128) == NULL);
    assert_true(lmAlloc(freeListAlloc, 128) == NULL);
    assert_true(lmAlloc(freeListAlloc, 128) == NULL);
    assert_true(lmAlloc(freeListAlloc, 128) == NULL);

    // Free four items, we should be able to alloc 4 more.
    lmFree(freeListAlloc, a);
    lmFree(freeListAlloc, b);
    lmFree(freeListAlloc, c);
    lmFree(freeListAlloc, d);

    assert_true((a = lmAlloc(freeListAlloc, 128)) != NULL);
    assert_true((b = lmAlloc(freeListAlloc, 128)) != NULL);
    assert_true((c = lmAlloc(freeListAlloc, 128)) != NULL);
    assert_true((d = lmAlloc(freeListAlloc, 128)) != NULL);

    // Awesome!
    loom_allocator_destroy(freeListAlloc);
}

SEATEST_TEST(allocator_cppNewDeleteBasic)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    int *foo = lmNew(heapAlloc) int();

    *foo = 1234;
    lmDelete(heapAlloc, foo);
}

class AllocTestClass
{
public:
    static int allocCount;
    static int destructCount;

    AllocTestClass()
    {
        allocCount++;
    }

    ~AllocTestClass()
    {
        destructCount++;
    }

    static void resetCounters()
    {
        allocCount = destructCount = 0;
    }
};

int AllocTestClass::allocCount    = 0;
int AllocTestClass::destructCount = 0;

SEATEST_TEST(allocator_cppNewDeleteComplex)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    AllocTestClass::resetCounters();

    assert_int_equal(AllocTestClass::allocCount, 0);
    assert_int_equal(AllocTestClass::destructCount, 0);

    AllocTestClass *foo = lmNew(heapAlloc) AllocTestClass();
    assert_int_equal(AllocTestClass::allocCount, 1);
    assert_int_equal(AllocTestClass::destructCount, 0);

    lmDelete(heapAlloc, foo);
    assert_int_equal(AllocTestClass::allocCount, 1);
    assert_int_equal(AllocTestClass::destructCount, 1);
}

SEATEST_TEST(allocator_jemalloc)
{
    void *allocs[100];

    loom_allocator_t *tracker = loom_allocator_initializeJemallocAllocator(loom_allocator_getGlobalHeap());
    size_t           count, bytes;

    loom_allocator_t *je = loom_allocator_initializeTrackerProxyAllocator(tracker);

    for (int i = 0; i < 100; i++)
    {
        allocs[i] = lmAlloc(je, 128);
    }

    loom_allocator_getTrackerProxyStats(je, &bytes, &count);
    assert_true(count >= 100);
    assert_true(bytes >= 128 * 100);

    for (int i = 0; i < 100; i++)
    {
        for (int j = 0; j < 128; j++)
        {
            ((unsigned char *)allocs[i])[j] = j;
        }
    }

    for (int i = 0; i < 100; i++)
    {
        lmFree(je, allocs[i]);
    }

    loom_allocator_getTrackerProxyStats(je, &bytes, &count);
    assert_int_equal((int)count, 0);
    assert_int_equal((int)bytes, 0);

    loom_allocator_destroy(je);
    loom_allocator_destroy(tracker);
}

SEATEST_TEST(allocator_arena)
{
    void *allocs[100];

    loom_allocator_t *tracker = loom_allocator_initializeTrackerProxyAllocator(loom_allocator_getGlobalHeap());
    size_t           count, bytes;

    loom_allocator_getTrackerProxyStats(tracker, &bytes, &count);
    assert_int_equal((int)count, 0);
    assert_int_equal((int)bytes, 0);

    loom_allocator_t *arena = loom_allocator_initializeArenaProxyAllocator(tracker);

    for (int i = 0; i < 100; i++)
    {
        allocs[i] = lmAlloc(arena, 128);
    }

    loom_allocator_getTrackerProxyStats(tracker, &bytes, &count);
    assert_true(count >= 100);
    assert_true(bytes >= 128 * 100);

    for (int i = 0; i < 100; i++)
    {
        for (int j = 0; j < 128; j++)
        {
            ((unsigned char *)allocs[i])[j] = j;
        }
    }

    // This should free everything.
    loom_allocator_destroy(arena);

    loom_allocator_getTrackerProxyStats(tracker, &bytes, &count);
    assert_int_equal((int)count, 0);
    assert_int_equal((int)bytes, 0);

    loom_allocator_destroy(tracker);
}
