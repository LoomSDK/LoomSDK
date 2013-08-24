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

#ifndef _PLATFORM_PLATFORMTHREAD_H_
#define _PLATFORM_PLATFORMTHREAD_H_

#include <stddef.h>
#include "loom/common/platform/platform.h"

#ifdef __cplusplus
extern "C" {
#endif

#if LOOM_COMPILER != LOOM_COMPILER_MSVC

#define __cdecl
#define __stdcall
#endif

/**************************************************************************
 * Loom Threading Primitives
 *
 * Wrappers for various common multithreading primitives (mutex, semaphore,
 * thread, atomic ops, memory barriers).
 *************************************************************************/

// Some utility code:
int platform_getLogicalThreadCount();
int platform_getCurrentThreadId();

// Our own simple mutex abstraction:
typedef void * MutexHandle;

MutexHandle loom_mutex_create_real(const char *file, int line);
void loom_mutex_lock_real(const char *file, int line, MutexHandle m);
int loom_mutex_trylock_real(const char *file, int line, MutexHandle m);
void loom_mutex_unlock_real(const char *file, int line, MutexHandle m);
void loom_mutex_destroy_real(const char *file, int line, MutexHandle m);

#define loom_mutex_create()      loom_mutex_create_real(__FILE__, __LINE__)
#define loom_mutex_lock(m)       loom_mutex_lock_real(__FILE__, __LINE__, m)
#define loom_mutex_trylock(m)    loom_mutex_trylock_real(__FILE__, __LINE__, m)
#define loom_mutex_unlock(m)     loom_mutex_unlock_real(__FILE__, __LINE__, m)
#define loom_mutex_destroy(m)    loom_mutex_destroy_real(__FILE__, __LINE__, m)

// Our own simple thread abstraction:
typedef void * ThreadHandle;
typedef int (__stdcall * ThreadFunction)(void *param); // TODO: Sort out __stdcall, is this portable?

ThreadHandle loom_thread_start(ThreadFunction func, void *param);

// Set the name of the thread as it will be seen in the debugger.
void loom_thread_setDebugName(const char *name);
int loom_thread_getIdFromHandle(ThreadHandle th);
void loom_thread_join(ThreadHandle th);

// Our own simple semaphore abstraction:
#if LOOM_PLATFORM_IS_APPLE
typedef size_t   SemaphoreHandle;
#else
typedef void *   SemaphoreHandle;
#endif

SemaphoreHandle loom_semaphore_create_real(const char *file, int line);
void loom_semaphore_post_real(const char *file, int line, SemaphoreHandle s);
void loom_semaphore_wait_real(const char *file, int line, SemaphoreHandle s);
void loom_semaphore_destroy_real(const char *file, int line, SemaphoreHandle s);

#define loom_semaphore_create()      loom_semaphore_create_real(__FILE__, __LINE__)
#define loom_semaphore_post(s)       loom_semaphore_post_real(__FILE__, __LINE__, s)
#define loom_semaphore_wait(s)       loom_semaphore_wait_real(__FILE__, __LINE__, s)
#define loom_semaphore_destroy(s)    loom_semaphore_destroy_real(__FILE__, __LINE__, s)

// Some atomic primitives:
typedef int   atomic_int_t;
int atomic_compareAndExchange(volatile atomic_int_t *value, int expected, int newVal);
int atomic_increment(volatile atomic_int_t *value);
int atomic_decrement(volatile atomic_int_t *value);
int atomic_load32(volatile atomic_int_t *variable);
void atomic_store32(volatile atomic_int_t *variable, int newValue);

// Sleeping and yielding.
void loom_thread_sleep(long ms);
void loom_thread_yield();

/**
 * Ensure we aren't already running the process. Returns 1 if we are
 * already running.
 */
int loom_process_ensureOnlyOneInstance();

#ifdef __cplusplus
};
#endif
#endif
