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
#include <string.h>
#include <assert.h>
#include "loom/common/core/allocator.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/performance.h"
#include "loom/common/platform/platformThread.h"

// This is our alignment size for general allocations. When we need to
// pre-post pad data on an allocation, we'll use this many bytes to move
// fore/back.
#define LOOM_ALLOCATOR_ALIGNMENT    16

static loom_allocator_t gGlobalHeap;
static int              heap_allocated = 0;

void loom_allocator_startup()
{
    assert(heap_allocated == 0);
    heap_allocated = 1;
    loom_allocator_initializeHeapAllocator(&gGlobalHeap);
    gGlobalHeap.name = "Global";
}


loom_allocator_t *loom_allocator_getGlobalHeap()
{
    // TODO: Go back to explicit startup, this hides static variable startup costs.
    // TODO: At least make this threadsafe.
    if (!heap_allocated)
    {
        loom_allocator_startup();
    }

    return &gGlobalHeap;
}


void *lmAlloc_inner(loom_allocator_t *allocator, size_t size, const char *file, int line)
{
    void *obj = NULL;

    if (!allocator)
    {
        allocator = loom_allocator_getGlobalHeap();
    }

    obj = allocator->allocCall(allocator, size, file, line);
    tmAllocEx(gTelemetryContext, file, line, obj, size, "lmAlloc");
    return obj;
}


void lmFree_inner(loom_allocator_t *allocator, void *ptr, const char *file, int line)
{
    if (!allocator)
    {
        allocator = loom_allocator_getGlobalHeap();
    }

    tmFree(gTelemetryContext, ptr);

    allocator->freeCall(allocator, ptr, file, line);
}


void *lmRealloc_inner(loom_allocator_t *allocator, void *ptr, size_t size, const char *file, int line)
{
    void *obj = NULL;

    if (!allocator)
    {
        allocator = loom_allocator_getGlobalHeap();
    }
    obj = allocator->reallocCall(allocator, ptr, size, file, line);
    tmAllocEx(gTelemetryContext, file, line, ptr, size, "lmRealloc");
    return obj;
}


void loom_allocator_destroy(loom_allocator_t *allocator)
{
    // Let the dtor run.
    if (allocator->destroyCall)
    {
        allocator->destroyCall(allocator);
    }

    // Let the parent lmFree it if appropriate.
    if (allocator->parent)
    {
        lmFree(allocator->parent, allocator);
    }
}


// ----------- DEFAULT CRT HEAP ALLOCATOR ---------------------------------------------

static void *loom_heapAlloc_alloc(loom_allocator_t *thiz, size_t size, const char *file, int line)
{
    return malloc(size);
}


static void loom_heapAlloc_free(loom_allocator_t *thiz, void *ptr, const char *file, int line)
{
    free(ptr);
}


static void *loom_heapAlloc_realloc(loom_allocator_t *thiz, void *ptr, size_t size, const char *file, int line)
{
    return realloc(ptr, size);
}


void loom_allocator_initializeHeapAllocator(loom_allocator_t *a)
{
    memset(a, 0, sizeof(loom_allocator_t));
    a->allocCall   = loom_heapAlloc_alloc;
    a->reallocCall = loom_heapAlloc_realloc;
    a->freeCall    = loom_heapAlloc_free;
}


// ----------- POOL ALLOCATOR ---------------------------------------------

typedef struct loom_poolallocator_t
{
    MutexHandle lock;
    size_t      itemSize, itemCount;
    void        *memory;
    void        *freeListHead;
} loom_poolallocator_t;

static void *loom_poolAlloc_alloc(loom_allocator_t *thiz, size_t size, const char *file, int line)
{
    loom_poolallocator_t *poolState = (loom_poolallocator_t *)thiz->userdata;
    void                 *tmp;

    assert(poolState->itemSize == size);

    // Unlink something from the lmFree list if we can.
    tmp = poolState->freeListHead;
    if (tmp == NULL)
    {
        return NULL;
    }
    poolState->freeListHead = *(void **)tmp;
    return tmp;
}


static void loom_poolAlloc_free(loom_allocator_t *thiz, void *ptr, const char *file, int line)
{
    loom_poolallocator_t *poolState = (loom_poolallocator_t *)thiz->userdata;

    // Make sure it's in our pool and on an item boundary.
    assert(ptr >= poolState->memory);                                                                                // After/at beginning.
    assert((unsigned char *)ptr <= (unsigned char *)poolState->memory + poolState->itemSize * poolState->itemCount); // Before end.
    assert(((unsigned char *)ptr - (unsigned char *)poolState->memory) % poolState->itemSize == 0);                  // On item boundary.

    // Re-attach to lmFree list.
    *(void **)ptr           = poolState->freeListHead;
    poolState->freeListHead = ptr;
}


static void *loom_poolAlloc_realloc(loom_allocator_t *thiz, void *ptr, size_t size, const char *file, int line)
{
    loom_poolallocator_t *poolState = (loom_poolallocator_t *)thiz->userdata;

    lmAssert((size_t)size <= poolState->itemSize, "Fixed pool allocator can only realloc up to the fixed item size.");
    return ptr;
}


static void loom_poolAlloc_destroy(loom_allocator_t *thiz)
{
    loom_poolallocator_t *poolState = (loom_poolallocator_t *)thiz->userdata;

    loom_mutex_destroy(poolState->lock);
    lmFree(thiz->parent, poolState->memory);
    lmFree(thiz->parent, poolState);
}


loom_allocator_t *loom_allocator_initializeFixedPoolAllocator(loom_allocator_t *parent, size_t itemSize, size_t itemCount)
{
    loom_allocator_t *a;
    size_t           i;

    // Set up the pool state.
    loom_poolallocator_t *poolState = lmAlloc(parent, sizeof(loom_poolallocator_t));

    poolState->lock      = loom_mutex_create();
    poolState->itemSize  = itemSize;
    poolState->itemCount = itemCount;
    poolState->memory    = lmAlloc(parent, itemSize * itemCount);
    memset(poolState->memory, 0, itemSize * itemCount);

    // Thread the lmFree list.
    poolState->freeListHead = poolState->memory;
    for (i = 0; i < itemCount - 1; i++)
    {
        *(unsigned char **)((unsigned char *)poolState->memory + i * itemSize) = ((unsigned char *)poolState->memory + ((i + 1) * itemSize));
    }

    // Set up the allocator structure.
    a = lmAlloc(parent, sizeof(loom_allocator_t));
    memset(a, 0, sizeof(loom_allocator_t));
    a->parent      = parent;
    a->userdata    = poolState;
    a->allocCall   = loom_poolAlloc_alloc;
    a->reallocCall = loom_poolAlloc_realloc;
    a->freeCall    = loom_poolAlloc_free;
    a->destroyCall = loom_poolAlloc_destroy;
    return a;
}


// ----------- ARENA PROXY ALLOCATOR ---------------------------------------------

typedef struct loom_arenaProxyAllocHeader
{
    struct loom_arenaProxyAllocHeader *prev, *next;
} loom_arenaProxyAllocHeader_t;

typedef struct loom_arenaProxyAllocator
{
    MutexHandle                  lock;
    loom_arenaProxyAllocHeader_t *first;
} loom_arenaProxyAllocator_t;

static void *loom_arenaProxyAlloc_userPointerToArenaPointer(void *ptr)
{
    return ((unsigned char *)ptr) - LOOM_ALLOCATOR_ALIGNMENT;
}


static void *loom_arenaProxyAlloc_arenaPointerToUserPointer(void *ptr)
{
    return ((unsigned char *)ptr) + LOOM_ALLOCATOR_ALIGNMENT;
}


static void *loom_arenaProxyAlloc_alloc(loom_allocator_t *thiz, size_t size, const char *file, int line)
{
    loom_arenaProxyAllocator_t   *poolState = (loom_arenaProxyAllocator_t *)thiz->userdata;
    loom_arenaProxyAllocHeader_t *apah      = NULL;

    void *tmp = lmAlloc(thiz->parent, size + LOOM_ALLOCATOR_ALIGNMENT);

    loom_mutex_lock(poolState->lock);

    // Link it into the doubly linked list of arena allocations.
    apah             = (loom_arenaProxyAllocHeader_t *)tmp;
    apah->next       = poolState->first;
    apah->prev       = NULL;
    poolState->first = apah;

    loom_mutex_unlock(poolState->lock);

    // And pass back the usable region.
    return loom_arenaProxyAlloc_arenaPointerToUserPointer(tmp);
}


static void loom_arenaProxyAlloc_free(loom_allocator_t *thiz, void *ptr, const char *file, int line)
{
    loom_arenaProxyAllocator_t   *poolState = (loom_arenaProxyAllocator_t *)thiz->userdata;
    loom_arenaProxyAllocHeader_t *apah      = NULL;

    loom_mutex_lock(poolState->lock);

    // Get the header.
    apah = (loom_arenaProxyAllocHeader_t *)loom_arenaProxyAlloc_userPointerToArenaPointer(ptr);

    // Deal with links to preceding item.
    if (apah->prev == NULL) // Then we're linked to the head, so unlink.
    {
        poolState->first = apah->next;
    }
    else
    {
        apah->prev->next = apah->next;
    }

    // Deal with links to following item.
    if (apah->next)
    {
        apah->next->prev = apah->prev;
    }

    // Do the actual free.
    lmFree(thiz->parent, apah);

    loom_mutex_unlock(poolState->lock);
}


static void loom_arenaProxyAlloc_destroy(loom_allocator_t *thiz)
{
    loom_arenaProxyAllocator_t   *poolState = (loom_arenaProxyAllocator_t *)thiz->userdata;
    loom_arenaProxyAllocHeader_t *walk      = NULL, *walkTmp = NULL;

    loom_mutex_lock(poolState->lock);

    // Walk the allocation list and free everything up.
    walk = poolState->first;
    while (walk)
    {
        walkTmp = walk;
        walk    = walk->next;
        lmFree(thiz->parent, walkTmp);
    }

    poolState->first = NULL;

    loom_mutex_unlock(poolState->lock);

    loom_mutex_destroy(poolState->lock);
    lmFree(thiz->parent, poolState);
}


loom_allocator_t *loom_allocator_initializeArenaProxyAllocator(loom_allocator_t *parent)
{
    loom_allocator_t *a;

    // Set up the state structure.
    loom_arenaProxyAllocator_t *state = lmAlloc(parent, sizeof(loom_arenaProxyAllocator_t));

    memset(state, 0, sizeof(loom_arenaProxyAllocator_t));
    state->first = NULL;
    state->lock  = loom_mutex_create();

    // Sanity check the header size.
    lmAssert(sizeof(loom_arenaProxyAllocHeader_t) <= LOOM_ALLOCATOR_ALIGNMENT, "Arena allocator header is too big, update LOOM_ALLOCATOR_ALIGNMENT?");

    // Set up the allocator structure.
    a = lmAlloc(parent, sizeof(loom_allocator_t));
    memset(a, 0, sizeof(loom_allocator_t));
    a->parent      = parent;
    a->userdata    = state;
    a->allocCall   = loom_arenaProxyAlloc_alloc;
    a->freeCall    = loom_arenaProxyAlloc_free;
    a->destroyCall = loom_arenaProxyAlloc_destroy;
    return a;
}


// ----------- TRACKING PROXY ALLOCATOR ---------------------------------------------

typedef struct loom_trackingProxyAllocator
{
    MutexHandle                        lock;
    size_t                             allocatedBytes, allocatedCount;
    struct loom_trackingProxyAllocator *next;
} loom_trackingProxyAllocator_t;

typedef struct loom_trackingProxyAllocatorHeader
{
    size_t size;
} loom_trackingProxyAllocatorHeader_t;

static MutexHandle gTrackingProxyListLock = NULL;
static loom_trackingProxyAllocator_t *gTrackingProxyListHead;

static void *loom_trackingProxyAlloc_alloc(loom_allocator_t *thiz, size_t size, const char *file, int line)
{
    loom_trackingProxyAllocator_t       *poolState = (loom_trackingProxyAllocator_t *)thiz->userdata;
    loom_trackingProxyAllocatorHeader_t *tpah      = NULL;

    void *tmp = lmAlloc(thiz->parent, size + LOOM_ALLOCATOR_ALIGNMENT);

    loom_mutex_lock(poolState->lock);

    // Note size on the allocation.
    tpah       = (loom_trackingProxyAllocatorHeader_t *)tmp;
    tpah->size = size;

    // Increment counts.
    poolState->allocatedCount++;
    poolState->allocatedBytes += size;

    loom_mutex_unlock(poolState->lock);

    // And pass back the usable region.
    return loom_arenaProxyAlloc_arenaPointerToUserPointer(tmp);
}


static void loom_trackingProxyAlloc_free(loom_allocator_t *thiz, void *ptr, const char *file, int line)
{
    loom_trackingProxyAllocator_t       *poolState = (loom_trackingProxyAllocator_t *)thiz->userdata;
    loom_trackingProxyAllocatorHeader_t *tpah      = NULL;

    loom_mutex_lock(poolState->lock);

    // Get the header.
    tpah = (loom_trackingProxyAllocatorHeader_t *)loom_arenaProxyAlloc_userPointerToArenaPointer(ptr);

    // Decrement counts.
    poolState->allocatedBytes -= tpah->size;

    lmAssert(poolState->allocatedCount > 0, "loom_trackingProxyAlloc_free - trying to free more allocations than we allocated! Allocator mismatch?");

    poolState->allocatedCount--;

    // Do the actual free.
    lmFree(thiz->parent, tpah);

    loom_mutex_unlock(poolState->lock);
}


static void loom_trackingProxyAlloc_destroy(loom_allocator_t *thiz)
{
    loom_trackingProxyAllocator_t *poolState = (loom_trackingProxyAllocator_t *)thiz->userdata;
    loom_trackingProxyAllocator_t **walk     = NULL;
    int foundInList = 0;

    // Remove from the master list.
    loom_mutex_lock(gTrackingProxyListLock);

    walk = &gTrackingProxyListHead;
    do
    {
        if (*walk != poolState)
        {
            continue;
        }

        *walk       = poolState->next;
        foundInList = 1;
        break;
    } while (*walk);

    lmAssert(foundInList, "Tracking proxy allocator not found in global list!");

    loom_mutex_unlock(gTrackingProxyListLock);

    loom_mutex_destroy(poolState->lock);
    lmFree(thiz->parent, poolState);
}


void loom_allocator_getTrackerProxyStats(loom_allocator_t *thiz, size_t *allocatedBytes, size_t *allocatedCount)
{
    loom_trackingProxyAllocator_t *poolState = (loom_trackingProxyAllocator_t *)thiz->userdata;

    loom_mutex_lock(poolState->lock);
    if (allocatedBytes)
    {
        *allocatedBytes = poolState->allocatedBytes;
    }
    if (allocatedCount)
    {
        *allocatedCount = poolState->allocatedCount;
    }
    loom_mutex_unlock(poolState->lock);
}


loom_allocator_t *loom_allocator_initializeTrackerProxyAllocator(loom_allocator_t *parent)
{
    loom_allocator_t *a;

    // Set up the state structure.
    loom_trackingProxyAllocator_t *state = lmAlloc(parent, sizeof(loom_trackingProxyAllocator_t));

    memset(state, 0, sizeof(loom_trackingProxyAllocator_t));
    state->lock = loom_mutex_create();

    // TODO: Clean this up.
    if (gTrackingProxyListLock == NULL)
    {
        gTrackingProxyListLock = loom_mutex_create();
    }

    // Add it to the list.
    loom_mutex_lock(gTrackingProxyListLock);
    state->next            = gTrackingProxyListHead;
    gTrackingProxyListHead = state;
    loom_mutex_unlock(gTrackingProxyListLock);

    // Sanity check the header size.
    lmAssert(sizeof(loom_trackingProxyAllocatorHeader_t) <= LOOM_ALLOCATOR_ALIGNMENT, "Tracking allocator header is too big, update LOOM_ALLOCATOR_ALIGNMENT?");

    // Set up the allocator structure.
    a = lmAlloc(parent, sizeof(loom_allocator_t));
    memset(a, 0, sizeof(loom_allocator_t));
    a->parent      = parent;
    a->userdata    = state;
    a->allocCall   = loom_trackingProxyAlloc_alloc;
    a->freeCall    = loom_trackingProxyAlloc_free;
    a->destroyCall = loom_trackingProxyAlloc_destroy;
    return a;
}
