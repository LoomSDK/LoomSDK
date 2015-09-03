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


#include "loom/common/utils/lmAutoPtr.h"
#include "seatest.h"

SEATEST_FIXTURE(lmAutoPtr)
{
    SEATEST_FIXTURE_ENTRY(allocator_basic);
}

SEATEST_TEST(lmAutoPtr_default_constructor)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    {
        lmAutoPtr<int> p;

        assert_true(p.get() == NULL);
    }
}

SEATEST_TEST(lmAutoPtr_constructor)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    {
        lmAutoPtr<int> p(lmNew(heapAlloc) int(1));

        assert_true(p.get() != NULL);
        assert_true(*p.get() == 1);
    }
}

SEATEST_TEST(lmAutoPtr_assign)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    {
        lmAutoPtr<int> p;
        p = lmNew(heapAlloc) int(2);

        assert_true(p.get() != NULL);
        assert_true(*p.get() == 2);

        p = lmNew(heapAlloc) int(3);

        assert_true(p.get() != NULL);
        assert_true(*p.get() == 3);
    }
}

SEATEST_TEST(allocator_get)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    {
        int* raw = lmNew(heapAlloc) int(4);
        lmAutoPtr<int> p(raw);

        assert_true(p.get() == raw);
        assert_true(*p.get() == 4);
    }
}

SEATEST_TEST(lmAutoPtr_release)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    {
        lmAutoPtr<int> p;

        int* raw = p.release();
        assert_true(raw == NULL);

        raw = lmNew(heapAlloc) int(5);
        p.reset(raw);
        int* raw2 = p.release();
        assert_true(raw == raw2);
    }
}

SEATEST_TEST(lmAutoPtr_reset)
{
    loom_allocator_t *heapAlloc = loom_allocator_getGlobalHeap();

    {
        lmAutoPtr<int> p(lmNew(heapAlloc) int(1));

        p.reset();
        assert_true(p.get() == NULL);

        int* raw = lmNew(heapAlloc) int(6);
        p.reset(raw);
        assert_true(p.get() == raw);

        p.reset();
        assert_true(p.get() == NULL);
    }
}