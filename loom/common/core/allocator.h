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

#ifndef _CORE_ALLOCATOR_H_
#define _CORE_ALLOCATOR_H_

#include "loom/common/core/assert.h"
#include "jemalloc/jemalloc.h"
#include <stdint.h>
#include <stdbool.h>

/**************************************************************************
 * Loom Memory Allocation API
 *
 * USAGE
 *
 * (Note that you can pass NULL instead of an allocator
 * to use the global heap.)
 *
 * loom_allocator_t *someAllocator = ...;
 * MyClass *mc = lmNew(someAllocator) MyClass(someArg);
 * lmDelete(someAllocator) mc;
 *
 * MyStruct *ms = lmAlloc(someAllocator, sizeof(ms));
 * lmFree(someAllocator, ms);
 *
 * RATIONALE
 *
 * It is useful to have global control of memory allocation. The Loom
 * Memory API enables reporting, debugging, various allocation strategies,
 * run time configuration of memory manager operation, and so on. We also
 * want to be able to compose allocators, ie, add allocation tracking
 * backed by an allocation strategy of our choice.
 *
 * OVERVIEW
 *
 * Rather than hooking the global new/delete/malloc/free calls, which can
 * be brittle and hard to work with, we provide lmAlloc, lmFree, lmNew,
 * lmDelete calls which take a loom_allocator_t.
 *
 * The core allocator code is written in C, with lmNew/lmDelete implemented
 * and only available under C++.
 *
 * The array new/delete operators are not provided due to limitations in
 * C++'s support for overloading those operators with parameters. We
 * recommend using a vector/array class instead of using new[]/delete[].
 *
 * ALLOCATORS
 *
 * Using the right kind of allocation strategy can dramatically improve
 * performance and memory efficiency. In addition, it can be convenient to
 * consider each subsystem's memory allocation independently. A
 * loom_allocator_t is used to represent an allocator, and factory
 * functions are provided for common use cases (like a fixed pool allocator,
 * one backed by the CRT heap, jemalloc, or other cases).
 *
 * Proxy allocators are also available, ie, to keep track of the memory used
 * by an allocator.
 *
 * FURTHER USAGE EXAMPLES
 *
 * The unit tests for the allocator system should be helpful in understanding
 * usage.
 *
 */

// This defines the alignment mask (alignment size minus one) used in manual
// allocation with variably offset custom data fields
#define LOOM_ALLOCATOR_ALIGN_MASK (8-1)

#ifdef __cplusplus
extern "C" {
#endif

/************************************************************************
 * C ALLOCATION MACROS
 * 
 * Implement malloc/free/realloc type functionality using Loom allocators.
 ************************************************************************/
#define lmAlloc(allocator, size) lmAlloc_inner(allocator, size, __FILE__, __LINE__)
#define lmCalloc(allocator, count, size) lmCalloc_inner(allocator, count, size, __FILE__, __LINE__)
#define lmFree(allocator, ptr) lmFree_inner(allocator, ptr, __FILE__, __LINE__)
#define lmRealloc(allocator, ptr, newSize) lmRealloc_inner(allocator, ptr, newSize, __FILE__, __LINE__)

#define lmAllocVerifyAll() loom_debugAllocator_verifyAll(__FILE__, __LINE__)

typedef struct loom_allocator loom_allocator_t;

void *lmAlloc_inner(loom_allocator_t *allocator, size_t size, const char *file, int line);
void *lmCalloc_inner(loom_allocator_t *allocator, size_t count, size_t size, const char *file, int line);
void lmFree_inner(loom_allocator_t *allocator, void *ptr, const char *file, int line);
void *lmRealloc_inner(loom_allocator_t *allocator, void *ptr, size_t size, const char *file, int line);

void loom_debugAllocator_verifyAll(const char* file, int line);

// Call this before you do any allocations to start the allocation system!
//
// Note: Loom calls this for you in most scenarios.
void loom_allocator_startup();

// Returns the current amount of memory allocated through lmAlloc in bytes
// NOTE: Returns 0 unless LOOM_ALLOCATOR_CHECK is enabled
unsigned int loom_allocator_getAllocatedMemory();

// Allocate a new heap allocator using the provided allocator as backing
// store.
void loom_allocator_initializeHeapAllocator(loom_allocator_t *a);

// Return a pointer to the global OS heap.
loom_allocator_t *loom_allocator_getGlobalHeap();

// Allocate a new fixed pool allocator, one that can allocate up to
// itemCount items of itemSize size.
loom_allocator_t *loom_allocator_initializeFixedPoolAllocator(loom_allocator_t *parent, size_t itemSize, size_t itemCount);

// Allocate a new arena proxy allocator. This allocator keeps track of all
// the allocations that pass through it, and they are all freed automatically
// when the allocator is destroy'ed. It does this by adding 2*sizeof(void*)
// bytes to each allocation for a doubly linked list, so be aware of this
// if using it with a fixed size allocator.
loom_allocator_t *loom_allocator_initializeArenaProxyAllocator(loom_allocator_t *parent);

// The tracker proxy allows reporting of total allocations and total
// allocated footprint in bytes. It passes allocations through to its
// parent allocator, and imposes sizeof(size_t) overhead on each allocation.
loom_allocator_t *loom_allocator_initializeTrackerProxyAllocator(loom_allocator_t *parent);
void loom_allocator_getTrackerProxyStats(loom_allocator_t *thiz, size_t *allocatedBytes, size_t *allocatedCount);

// Destroy an allocator. Depending on the allocator's implementation this
// may also free all of its allocations (like in the arena proxy).
void loom_allocator_destroy(loom_allocator_t *a);

/************************************************************************
* Custom Allocator API.
*
* You can provide your own allocator modules. They need to have an
* initialization function that fills out and returns a loom_allocator
* instance allocated from the parent allocator.
*
* loom_allocator_alloc_t should allocate new memory. loom_allocator_free_t
* should free that memory given a pointer. loom_allocator_realloc_t should
* obey realloc() semantics. loom_allocator_destructor_t should clean up
* the allocator.
************************************************************************/
typedef void *(*loom_allocator_alloc_t)(loom_allocator_t *thiz, size_t size, const char *file, int line);
typedef void (*loom_allocator_free_t)(loom_allocator_t *thiz, void *ptr, const char *file, int line);
typedef void *(*loom_allocator_realloc_t)(loom_allocator_t *thiz, void *ptr, size_t newSize, const char *file, int line);
typedef void (*loom_allocator_destructor_t)(loom_allocator_t *thiz);

struct loom_allocator
{
    const char                  *name;
    void                        *userdata;

    loom_allocator_alloc_t      allocCall;
    loom_allocator_free_t       freeCall;
    loom_allocator_realloc_t    reallocCall;
    loom_allocator_destructor_t destroyCall;

    loom_allocator_t            *parent;
};


#ifdef __cplusplus
}; // close extern "C"
#endif

// Define C++ memory API
#ifdef __cplusplus

/************************************************************************
* C++ ALLOCATION API
*
* It is problematic to override new/delete globally, so we require developers
* to use lmNew and lmFree instead. new Foo() becomes
* lmNew(someAllocator) Foo(), and delete myFoo becomes
* lmDelete(someAllocator, myfoo). We do not support the delete[] or new[]
* operators, if you want an array use the templated vector class.
*
************************************************************************/
#define lmNew(allocator)                new(allocator, __FILE__, __LINE__, 1, 2, 3)
#define lmDelete(allocator, obj)        { loom_destructInPlace(obj); lmFree(allocator, obj); }
#define lmSafeDelete(allocator, obj)    if (obj) { loom_destructInPlace(obj); lmFree(allocator, obj); obj = NULL; }
#define lmSafeFree(allocator, obj)      if (obj) { lmFree(allocator, obj); obj = NULL; }

#include <new>

inline void *operator new(size_t size, loom_allocator_t *a, const char *file, int line, int dummya, int dummyb, int dummyc)
{
    return lmAlloc(a, size);
}


inline void operator delete(void *p, loom_allocator_t *a, const char *file, int line, int dummya, int dummyb, int dummyc)
{
    lmFree(a, p);
}


inline void operator delete(void *p, loom_allocator_t *a)
{
    lmFree(a, p);
}

// Construct the type with preallocated memory (construct with no allocation)
// Usage: loom_constructInPlace<CustomType>(preallocatedMemoryOfSufficientSize);
#pragma warning( disable: 4345 )
template<typename T>
T* loom_constructInPlace(void* memory)
{
    return new (memory)T();
}

// Destruct the type without freeing memory (calls the destructor)
template<typename T>
void loom_destructInPlace(T *t)
{
    if (t == NULL) return;
    t->~T();
}

// Constructs a new array of types of length nr using the provided allocator (or NULL for default allocator)
// Use this or utArray instead of lmNew for constructing arrays
// The types are constructed in order using loom_constructInPlace
//
// Note that this function may allocate slightly more memory than expected
// as it has to remember the array length
template<typename T>
T* loom_newArray(loom_allocator_t *allocator, unsigned int nr)
{
    T* arr = (T*) lmAlloc(allocator, sizeof(unsigned int) + nr * sizeof(T));
    lmSafeAssert(arr, "Unable to allocate additional memory in loom_newArray");
    *((unsigned int*)arr) = nr;
    arr = (T*)(((unsigned int*)arr) + 1);
    for (unsigned int i = 0; i < nr; i++)
    {
        loom_constructInPlace<T>((void*) &arr[i]);
    }
    return (T*) arr;
}

// Deconstructs an array allocated with loom_newArray and frees the allocated memory
// The types are destructed in reverse order using loom_destructInPlace
//
// This function only works with arrays allocated with loom_newArray
// as it has to access the array length in order to destruct the types
template<typename T>
void loom_deleteArray(loom_allocator_t *allocator, T *arr)
{
    if (arr == NULL) return;
    void* fullArray = (void*) (((unsigned int*)arr) - 1);
    unsigned int nr = *((unsigned int*)fullArray);
    while (nr > 0)
    {
        nr--;
        loom_destructInPlace<T>(&arr[nr]);
    }
    lmFree(allocator, fullArray);
}

#endif
#endif
