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
#include "loom/common/core/log.h"
#include "loom/common/core/performance.h"
#include "loom/common/platform/platformThread.h"
#include "loom/common/utils/fourcc.h"

#include "jemalloc/jemalloc.h"

lmDefineLogGroup(gAllocatorLogGroup, "alloc", 1, LoomLogInfo);

// This is our alignment size for general allocations. When we need to 
// pre-post pad data on an allocation, we'll use this many bytes to move
// fore/back.
#define LOOM_ALLOCATOR_ALIGNMENT    16

#define USE_JEMALLOC 1
 

/**************************************************************************
* Loom Debug Allocation Proxy
*
* The `LOOM_ALLOCATOR_DEBUG` mode inserts a debugging memory allocator proxy
* supporting with metainfo and padding injection and verification.
* It is useful for discovering all sorts of memory misuse and corruption issues.
*
* If you enable this check, all `lmAlloc`, `lmCalloc`, `lmFree` and `lmRealloc` calls
* get augmented with metainfo at allocation time and verified at free time.
* `lmNew`, `lmDelete` and related also use the above calls under the hood,
* so they are covered as well.
* The outside API remains the same as the pointers get shifted accordingly.
*
* `LOOM_ALLOCATOR_DEBUG_LIST` enables tracking of allocation blocks in a list.
* Disabling the tracking disables periodic verification and `lmAllocVerifyAll`.
*
* If `LOOM_ALLOCATOR_DEBUG_PERIOD` is > 0, periodic checking of all of the allocated
* blocks is enabled. A counter is incremented every allocation and free and so each
* allocation gets verified every `LOOM_ALLOCATOR_DEBUG_PERIOD` counts.
* Set to `1` to check all the blocks every allocation and free (can be very slow).
*
* Every allocation has bytes initialized to `LOOM_ALLOCATOR_DEBUG_UNINITIALIZED`
* after allocation and erased to `LOOM_ALLOCATOR_DEBUG_FREED` after a free.
*
* Each allocation gains a hidden header containing the source file path and line number
* of the allocation. The maximum length of the path is set by `LOOM_ALLOCATOR_DEBUG_MAXPATH`.
*
* `LOOM_ALLOCATOR_DEBUG_SIG` defines the signature value saved in the header and footer
* padding.
*
* `LOOM_ALLOCATOR_DEBUG_SIG_HEADER_PADDING` and `LOOM_ALLOCATOR_DEBUG_SIG_FOOTER_PADDING`
* define the number of 32-bit (4 byte) signatures to use in the header and footer respectively.
*
* DEBUGGING TIPS
* You can get an insight into an augmented pointer by offsetting it by and casting it to
* `loom_debugAllocatorHeader_t*` e.g. `((loom_debugAllocatorHeader_t*) pointer - 1)`.
* This is especially useful as an expression in the watch window of an IDE.
* If you see garbage in the `file` field, it was most likely not allocated by the
* mentioned allocation functions.
*
* Otherwise you should be able to see the file and line it was allocated on as well as
* the signature, which is checked and should equal `LOOM_ALLOCATOR_DEBUG_SIG`.
* If the path is cut off, you can increase `LOOM_ALLOCATOR_DEBUG_MAXPATH`.
*
*/
#define LOOM_ALLOCATOR_DEBUG 1
#define LOOM_ALLOCATOR_DEBUG_LIST 1
#define LOOM_ALLOCATOR_DEBUG_PERIOD 0
#define LOOM_ALLOCATOR_DEBUG_MAXPATH 128-2-4 // Subtracting by 2 makes it 4-byte aligned due to the 16-bit line number
#define LOOM_ALLOCATOR_DEBUG_SIG 0xCACACACA
#define LOOM_ALLOCATOR_DEBUG_SIG_HEADER_PADDING 64
#define LOOM_ALLOCATOR_DEBUG_SIG_FOOTER_PADDING 64
#define LOOM_ALLOCATOR_DEBUG_UNINITIALIZED 0xAD
#define LOOM_ALLOCATOR_DEBUG_FREED 0xDA




static loom_allocator_t gSystemAllocator;
static loom_allocator_t* gGlobalHeap;
static int              heap_allocated = 0;
static unsigned int gMemoryAllocated = 0;

loom_allocator_t* loom_allocator_initializeDebugAllocator(loom_allocator_t*);

void loom_allocator_startup()
{
    assert(heap_allocated == 0);
    heap_allocated = 1;
    loom_allocator_initializeHeapAllocator(&gSystemAllocator);
    gSystemAllocator.name = "Global System";
    gGlobalHeap = &gSystemAllocator;
#if LOOM_ALLOCATOR_DEBUG
    gGlobalHeap = loom_allocator_initializeDebugAllocator(&gSystemAllocator);
#endif
}

unsigned int loom_allocator_getAllocatedMemory() {
    return gMemoryAllocated;
}

loom_allocator_t *loom_allocator_getGlobalHeap()
{
    // TODO: Go back to explicit startup, this hides static variable startup costs.
    // TODO: At least make this threadsafe.
    if (!heap_allocated)
    {
        loom_allocator_startup();
    }

    return gGlobalHeap;
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

void * lmCalloc_inner( loom_allocator_t *allocator, size_t count, size_t size, const char *file, int line )
{
   void *obj = NULL;
   if(!allocator) allocator = loom_allocator_getGlobalHeap();

   size *= count;

   obj = allocator->allocCall(allocator, size, file, line);
   memset(obj, 0, size);
   tmAllocEx(gTelemetryContext, file, line, obj, size, "lmCalloc");
   
   return obj;
}

void lmFree_inner( loom_allocator_t *allocator, void *ptr, const char *file, int line )
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
   if(!allocator) allocator = loom_allocator_getGlobalHeap();

   if (ptr == NULL)
   {
       obj = allocator->allocCall(allocator, size, file, line);
   }
   else
   {
       obj = allocator->reallocCall(allocator, ptr, size, file, line);
   }

   tmAllocEx(gTelemetryContext, file, line, obj, size, "lmRealloc");
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
#if USE_JEMALLOC == 1
   return je_malloc(size);
#else
   return malloc(size);
#endif
}

static void loom_heapAlloc_free(loom_allocator_t *thiz, void *ptr, const char *file, int line)
{
#if USE_JEMALLOC == 1
   je_free(ptr);
#else
   free(ptr);
#endif
}

static void *loom_heapAlloc_realloc(loom_allocator_t *thiz, void *ptr, size_t size, const char *file, int line)
{
#if USE_JEMALLOC == 1
   return je_realloc(ptr, size);
#else
   return realloc(ptr, size);
#endif
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



// ----------- DEBUG ALLOCATOR ---------------------------------------------


typedef struct loom_debugAllocatorHeader loom_debugAllocatorHeader_t;

// Header padding
typedef struct loom_debugAllocatorHeader
{
    // Source file of allocation
    char file[LOOM_ALLOCATOR_DEBUG_MAXPATH];
    // Source line of allocation
    uint16_t line;
    // Inner size of allocation excluding padding
    uint32_t size;
#if LOOM_ALLOCATOR_DEBUG_LIST
    loom_debugAllocatorHeader_t* prev;
    loom_debugAllocatorHeader_t* next;
#endif
    uint32_t sig[LOOM_ALLOCATOR_DEBUG_SIG_HEADER_PADDING];
} loom_debugAllocatorHeader_t;

// Footer padding
typedef struct loom_debugAllocatorFooter
{
    uint32_t sig[LOOM_ALLOCATOR_DEBUG_SIG_FOOTER_PADDING];
} loom_debugAllocatorFooter_t;


typedef struct loom_debugAllocator loom_debugAllocator_t;

static MutexHandle            gDebugAllocatorLock;
static loom_debugAllocator_t* gDebugAllocatorList;

// Allocator state
typedef struct loom_debugAllocator
{
    loom_debugAllocator_t*       next;

    MutexHandle                  lock;
#if LOOM_ALLOCATOR_DEBUG_LIST
    loom_debugAllocatorHeader_t* list;
#endif
    unsigned int counter;

    // Number of allocated memory blocks in the list
    unsigned int blocks;
    bool guard;
    bool verifyAll;
} loom_debugAllocator_t;


// Return the header of the provided allocated outer (padding included) memory pointer
static loom_debugAllocatorHeader_t* loom_debugAllocator_getHeader(void* outer)
{
    return (loom_debugAllocatorHeader_t*)outer;
}

// Return the footer of the provided allocated outer (padding included) memory pointer
// Note: the allocated memory needs a header with a valid size already
static loom_debugAllocatorFooter_t* loom_debugAllocator_getFooter(void* outer)
{
    return (loom_debugAllocatorFooter_t*)((char*)outer + sizeof(loom_debugAllocatorHeader_t) + loom_debugAllocator_getHeader(outer)->size);
}

// Convert from the outer (header and footer padding included) pointer
// to the inner (padding excluded, usable region) pointer
static void* loom_debugAllocator_outerToInner(void* outer)
{
    return (void*)(((loom_debugAllocatorHeader_t*)outer) + 1);
}

// Convert from the inner (header and footer padding excluded, usable region) pointer
// to the outer (header and footer padding included) pointer
static void* loom_debugAllocator_innerToOuter(void* inner)
{
    return (void*)(((loom_debugAllocatorHeader_t*)inner) - 1);
}

// Verify the outer pointer signatures and assert on a mismatch
static void loom_debugAllocator_verify(void* outer, const char *file, int line)
{
    loom_debugAllocatorHeader_t *header = loom_debugAllocator_getHeader(outer);
    for (int i = 0; i < LOOM_ALLOCATOR_DEBUG_SIG_HEADER_PADDING; i++) lmCheck(header->sig[i] == LOOM_ALLOCATOR_DEBUG_SIG, "Allocator header verification internal check failed at 0x%X, expected 0x%08lX got 0x%08lX\n    Deallocation was at %s@%d\n    Allocation was at %s@%d", header, LOOM_ALLOCATOR_DEBUG_SIG, header->sig[i], file, line, header->file, header->line);
    loom_debugAllocatorFooter_t *footer = loom_debugAllocator_getFooter(outer);
    for (int i = 0; i < LOOM_ALLOCATOR_DEBUG_SIG_FOOTER_PADDING; i++) lmCheck(footer->sig[i] == LOOM_ALLOCATOR_DEBUG_SIG, "Allocator footer verification internal check failed at 0x%X, expected 0x%08lX got 0x%08lX\n    Deallocation was at %s@%d\n    Allocation was at %s@%d", footer, LOOM_ALLOCATOR_DEBUG_SIG, footer->sig[i], file, line, header->file, header->line);
}

// Add the provided header to the list of all debug allocated blocks
static void loom_debugAllocator_listAdd(loom_debugAllocator_t *debugAlloc, loom_debugAllocatorHeader_t *header)
{
#if LOOM_ALLOCATOR_DEBUG_LIST
    header->next = header->prev = NULL;
    loom_mutex_lock(debugAlloc->lock);
    if (debugAlloc->list != NULL) { debugAlloc->list->prev = header; }
    header->next = debugAlloc->list;
    debugAlloc->list = header;
    debugAlloc->blocks++;
    loom_mutex_unlock(debugAlloc->lock);
#endif
}

// Remove the provided header from the list of all debug allocated blocks
static void loom_debugAllocator_listRemove(loom_debugAllocator_t *debugAlloc, loom_debugAllocatorHeader_t *header)
{
#if LOOM_ALLOCATOR_DEBUG_LIST
    loom_debugAllocatorHeader_t *prev = header->prev;
    loom_debugAllocatorHeader_t *next = header->next;
    loom_mutex_lock(debugAlloc->lock);
    if (prev) {
        if (next) {
            prev->next = next;
            next->prev = prev;
        } else {
            prev->next = NULL;
        }
    } else {
      if (next) {
          next->prev = NULL;
          debugAlloc->list = next;
      } else {
          debugAlloc->list = NULL;
      }
    }
    debugAlloc->blocks--;
    loom_mutex_unlock(debugAlloc->lock);
#endif
}

// Verify all of the allocated blocks
// Only verifies if enabled by `verifyAll`
// If enabled, verifies every `LOOM_ALLOCATOR_DEBUG_PERIOD`,
// unless `force` equals `true`
static void loom_debugAllocator_listVerify(loom_debugAllocator_t *debugAlloc, bool force, const char *file, int line)
{
#if LOOM_ALLOCATOR_DEBUG_LIST
    loom_mutex_lock(debugAlloc->lock);
    if (!( // Don't return for the right conditions
        debugAlloc->verifyAll && // if enabled and
        !debugAlloc->guard && // if not reentrant and
        (
            force || // if forcing or
            (
                LOOM_ALLOCATOR_DEBUG_PERIOD > 0 && // if periodic checking enabled and
                (debugAlloc->counter++ % LOOM_ALLOCATOR_DEBUG_PERIOD) == 0 // counter is at the start of the period
            )
        )
    )) {
        loom_mutex_unlock(debugAlloc->lock);
        return;
    }

    loom_debugAllocatorHeader_t *current = debugAlloc->list;
    // Guard from reentrance on error-related alloc
    debugAlloc->guard = true;
    unsigned int blocks = 0;
    while (current != NULL) {
        loom_debugAllocator_verify((void*)current, file, line);
        current = current->next;
        blocks++;
    }
    lmCheck(blocks == debugAlloc->blocks, "Allocator block number mismatch, expected %d got %d", debugAlloc->blocks, blocks);
    debugAlloc->guard = false;

    loom_mutex_unlock(debugAlloc->lock);
#endif
}

// Returns the size padded by the header and footer
static size_t loom_debugAllocator_getPaddedSize(size_t size)
{
    return size + sizeof(loom_debugAllocatorHeader_t) + sizeof(loom_debugAllocatorFooter_t);
}

// Setup all the required header and footer state on
// the provided previously allocated outer pointer
static void loom_debugAllocator_set(loom_debugAllocator_t *debugAlloc, void* outer, size_t size, size_t paddedSize, const char *file, int line)
{
    loom_debugAllocatorHeader_t *header;
    loom_debugAllocatorFooter_t *footer;

    header = loom_debugAllocator_getHeader(outer);

    // Set various information
    const size_t maxLen = sizeof(header->file) - 1;
    const size_t fileLen = strlen(file);
    const size_t actualLen = fileLen < maxLen ? fileLen : maxLen;
    strncpy(header->file, file, actualLen);
    header->file[actualLen] = 0;
    header->line = line;
    header->size = size;

    // Write header signature
    for (int i = 0; i < LOOM_ALLOCATOR_DEBUG_SIG_HEADER_PADDING; i++) header->sig[i] = LOOM_ALLOCATOR_DEBUG_SIG;

    // Write footer signature
    footer = loom_debugAllocator_getFooter(outer);
    for (int i = 0; i < LOOM_ALLOCATOR_DEBUG_SIG_FOOTER_PADDING; i++) footer->sig[i] = LOOM_ALLOCATOR_DEBUG_SIG;

    gMemoryAllocated += paddedSize;

    loom_mutex_lock(debugAlloc->lock);

    // Add the new block to the list
    loom_debugAllocator_listAdd(debugAlloc, header);

    // Check the list if applicable
    loom_debugAllocator_listVerify(debugAlloc, false, file, line);

    loom_mutex_unlock(debugAlloc->lock);

}

// Returns newly allocated `size` bytes with hidden header and footer padding
// Note: the bytes are initialized with a value of 0xAD
// (defined by `LOOM_ALLOCATOR_DEBUG_UNINITIALIZED`),
// so if a string of bytes that looks like 0xADADADAD appears in a value,
// it means that it was not properly initialized
static void* loom_debugAllocator_alloc(loom_allocator_t *thiz, size_t size, const char *file, int line)
{
    loom_debugAllocator_t *debugAlloc;
    size_t paddedSize;
    void *outer;

    // Allocate requested size + header and footer
    debugAlloc = (loom_debugAllocator_t*)thiz->userdata;
    paddedSize = loom_debugAllocator_getPaddedSize(size);
    outer = lmAlloc(thiz->parent, paddedSize);
    memset(outer, LOOM_ALLOCATOR_DEBUG_UNINITIALIZED, paddedSize);

    // Setup hidden state
    loom_debugAllocator_set(debugAlloc, outer, size, paddedSize, file, line);

    // Pass back the usable (inner) region
    return loom_debugAllocator_outerToInner(outer);
}

// Unset/remove the provided outer pointer from the list and stop tracking it
static void loom_debugAllocator_unset(loom_debugAllocator_t *debugAlloc, void *outer, const char *file, int line)
{
    loom_debugAllocatorHeader_t *header;
    size_t paddedSize;

    // Verify before unsetting
    loom_mutex_lock(debugAlloc->lock);
    // Guard from reentrance on error-related alloc
    if (!debugAlloc->guard) {
        debugAlloc->guard = true;
        loom_debugAllocator_verify(outer, file, line);
        debugAlloc->guard = false;
    }
    
    header = loom_debugAllocator_getHeader(outer);

    paddedSize = loom_debugAllocator_getPaddedSize(header->size);

    loom_debugAllocator_listVerify(debugAlloc, false, file, line);
    loom_debugAllocator_listRemove(debugAlloc, header);
    loom_mutex_unlock(debugAlloc->lock);

    gMemoryAllocated -= paddedSize;
}

static void loom_debugAllocator_checkFreed(void *inner, const char *file, int line)
{
    if ((((unsigned int)((uintptr_t)inner)) & 0xFFFFFFFF) == LOOM_FOURCC(LOOM_ALLOCATOR_DEBUG_FREED, LOOM_ALLOCATOR_DEBUG_FREED, LOOM_ALLOCATOR_DEBUG_FREED, LOOM_ALLOCATOR_DEBUG_FREED)) {
        lmLogWarn(gAllocatorLogGroup, "Possible double free detected at %s@%d", file, line);
    }
}

// Unset and free the provided inner pointer including the surrounding padding
// The freed inner data is filled with 0xDA bytes, so sequences of 0xDADADADADA are
// more easily recognizable as freed data
static void loom_debugAllocator_free(loom_allocator_t *thiz, void *inner, const char *file, int line)
{
    loom_debugAllocator_t       *debugAlloc;
    loom_debugAllocatorHeader_t *header;
    void *outer;

    if (inner == NULL) return;

    loom_debugAllocator_checkFreed(inner, file, line);

    outer = loom_debugAllocator_innerToOuter(inner);
    header = loom_debugAllocator_getHeader(outer);

    debugAlloc = (loom_debugAllocator_t*)thiz->userdata;
    loom_debugAllocator_unset(debugAlloc, outer, file, line);

    memset(inner, LOOM_ALLOCATOR_DEBUG_FREED, header->size);

    lmFree(thiz->parent, outer);
}

// Reallocate the provided inner pointer into the new size,
// the padding data is adjusted accordingly
static void* loom_debugAllocator_realloc(loom_allocator_t *thiz, void *inner, size_t newSize, const char *file, int line)
{
    loom_debugAllocator_t       *debugAlloc;
    void *outer, *newOuter;
    size_t newPaddedSize;

    debugAlloc = (loom_debugAllocator_t*)thiz->userdata;
    outer = loom_debugAllocator_innerToOuter(inner);

    // Remove old padding
    loom_mutex_lock(debugAlloc->lock);
    loom_debugAllocator_unset(debugAlloc, outer, file, line);

    // Reallocate with new size
    newPaddedSize = loom_debugAllocator_getPaddedSize(newSize);
    newOuter = lmRealloc(thiz->parent, outer, newPaddedSize);

    // Re-setup the padding
    loom_debugAllocator_set(debugAlloc, newOuter, newSize, newPaddedSize, file, line);
    loom_mutex_unlock(debugAlloc->lock);

    return loom_debugAllocator_outerToInner(newOuter);
}

void loom_debugAllocator_verifyAll(const char* file, int line)
{
    if (gDebugAllocatorLock == NULL) return;
    loom_mutex_lock(gDebugAllocatorLock);
    loom_debugAllocator_t *alloc = gDebugAllocatorList;
    while (alloc) {
        loom_mutex_lock(alloc->lock);
        bool verifyAll = alloc->verifyAll;
        alloc->verifyAll = true;
        loom_debugAllocator_listVerify(alloc, true, file, line);
        alloc->verifyAll = verifyAll;
        loom_mutex_unlock(alloc->lock);
        alloc = alloc->next;
    }
    loom_mutex_unlock(gDebugAllocatorLock);
}

static void loom_debugAllocator_destroy(loom_allocator_t *thiz)
{
    loom_debugAllocator_t *debugAlloc;
    loom_debugAllocator_t *alloc;
    bool found;

    debugAlloc = (loom_debugAllocator_t *)thiz->userdata;


    // Remove from the master list.
    loom_mutex_lock(gDebugAllocatorLock);

    alloc = gDebugAllocatorList;
    if (alloc == debugAlloc) {
        gDebugAllocatorList = debugAlloc->next;
    }
    else
    {
        while (alloc) {
            if (alloc->next == debugAlloc) {
                alloc->next = debugAlloc->next;
                found = true;
                break;
            }
            alloc = alloc->next;
        }
        lmAssert(found, "Debug allocator not found in global list!");
    }
    debugAlloc->next = NULL;

    loom_mutex_unlock(gDebugAllocatorLock);

    loom_mutex_destroy(debugAlloc->lock);
#if LOOM_ALLOCATOR_DEBUG_LIST
    while (debugAlloc->list) loom_debugAllocator_listRemove(debugAlloc, debugAlloc->list);
#endif
    lmFree(thiz->parent, debugAlloc);
}


loom_allocator_t *loom_allocator_initializeDebugAllocator(loom_allocator_t *parent)
{
    loom_allocator_t *a;

    // Set up the state structure.
    loom_debugAllocator_t *debugAlloc = lmAlloc(parent, sizeof(loom_debugAllocator_t));

    // Add to list of allocators
    if (gDebugAllocatorLock == NULL) gDebugAllocatorLock = loom_mutex_create();
    loom_mutex_lock(gDebugAllocatorLock);
    debugAlloc->next = gDebugAllocatorList;
    gDebugAllocatorList = debugAlloc;
    loom_mutex_unlock(gDebugAllocatorLock);

    memset(debugAlloc, 0, sizeof(loom_debugAllocator_t));
    debugAlloc->lock = loom_mutex_create();
    debugAlloc->verifyAll = true;

    // Sanity check the header size.
    lmAssert(sizeof(loom_debugAllocatorHeader_t) % 4 == 0, "Debug allocator header size not aligned to 4 bytes: %d", sizeof(loom_debugAllocatorHeader_t));
    lmAssert(sizeof(loom_debugAllocatorFooter_t) % 4 == 0, "Debug allocator footer size not aligned to 4 bytes: %d", sizeof(loom_debugAllocatorFooter_t));

    // Set up the allocator structure.
    a = lmAlloc(parent, sizeof(loom_allocator_t));
    memset(a, 0, sizeof(loom_allocator_t));
    a->name = "Debug";
    a->parent = parent;
    a->userdata = debugAlloc;
    a->allocCall = loom_debugAllocator_alloc;
    a->freeCall = loom_debugAllocator_free;
    a->reallocCall = loom_debugAllocator_realloc;
    a->destroyCall = loom_debugAllocator_destroy;
    return a;
}
