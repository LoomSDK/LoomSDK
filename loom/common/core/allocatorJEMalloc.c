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


#include <string.h>
#include "loom/common/core/allocatorJEMalloc.h"

#ifdef LOOM_DISABLE_JEMALLOC

loom_allocator_t *loom_allocator_initializeJemallocAllocator(loom_allocator_t *parent)
{
    // Just return a proxy to the parent heap.
    return loom_allocator_initializeTrackerProxyAllocator(parent);
}


#else

#include "loom/common/core/jemalloc/jemalloc.h"

static void *loom_jemalloc_alloc(loom_allocator_t *thiz, size_t size, const char *file, int line)
{
    return je_malloc(size);
}


static void *loom_jemalloc_realloc(loom_allocator_t *thiz, void *ptr, size_t size, const char *file, int line)
{
    return je_realloc(ptr, size);
}


static void loom_jemalloc_free(loom_allocator_t *thiz, void *ptr, const char *file, int line)
{
    je_free(ptr);
}


loom_allocator_t *loom_allocator_initializeJemallocAllocator(loom_allocator_t *parent)
{
    loom_allocator_t *newAlloc = lmAlloc(parent, sizeof(loom_allocator_t));

    memset(newAlloc, 0, sizeof(loom_allocator_t));
    newAlloc->parent      = parent;
    newAlloc->allocCall   = loom_jemalloc_alloc;
    newAlloc->reallocCall = loom_jemalloc_realloc;
    newAlloc->freeCall    = loom_jemalloc_free;
    return newAlloc;
}
#endif
