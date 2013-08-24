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

#ifndef _TASKS_TASKSINTERNAL_H_
#define _TASKS_TASKSINTERNAL_H_

#include <string.h>
#include <assert.h>

#ifdef __cplusplus
extern "C" {
#endif

// This file contains private definitions for tasks. It should only be used
// if you are testing internals of the system or trying to debug stuff.

struct task
{
    // When refcount goes to zero, we are deleted.
    atomic_int_t  refCount;

    // Work to perform & payload.
    task_callback callback;
    void          *payload;

    // Indicate priority.
    int           priority;

    // State, used for sanity checking. See task_state_t for values.
    task_state_t  state;

    // How many tasks before we start?
    atomic_int_t  startCount;

    // How many tasks before we are finished?
    atomic_int_t  finishCount;

    // Task to trigger when we start and/or finish.
    struct task   *toStart;
    struct task   *toFinish;

    // Thread to run in (+1 so 0 == no affinity, 1 == thread 0, and so on)
    unsigned int  threadAffinity;
};

#define TASKS_RINGBUFFER_GUARDS    1
#define TASKS_MAX_QUEUE_LENGTH     128

// TODO: http://www.1024cores.net/home/lock-free-algorithms/queues/bounded-mpmc-queue ?
typedef struct task_ringbuffer_t
{
    // We maintain ring buffers for queues so we never shift stuff around.
    // TODO: We can probably make this lockless,
    // see: http://www.informit.com/articles/article.aspx?p=1626980&seqNum=3
    int    readIndex, writeIndex;

#if TASKS_RINGBUFFER_GUARDS == 1
    int    preGuard;
#endif

    task_t *buffer[TASKS_MAX_QUEUE_LENGTH];

#if TASKS_RINGBUFFER_GUARDS == 1
    int    postGuard;
#endif
} task_ringbuffer_t;

void task_ringbuffer_init(task_ringbuffer_t *ring);
int task_ringbuffer_isfull(task_ringbuffer_t *ring);
int task_ringbuffer_isempty(task_ringbuffer_t *ring);
int task_ringbuffer_put(task_ringbuffer_t *ring, task_t *item);
task_t *task_ringbuffer_get(task_ringbuffer_t *ring);

typedef struct task_queue_t
{
    MutexHandle       mutex;
    task_ringbuffer_t queue[TASKS_MAX_PRIORITY];
} task_queue_t;

void task_queue_init(task_queue_t *q);
void task_queue_destroy(task_queue_t *q);
int task_queue_enqueue(task_queue_t *q, task_t *t);
task_t *task_queue_dequeue(task_queue_t *q);

typedef struct task_thread_t
{
    // Which thread are we? This is an ID as in platform_getCurrentThreadId(),
    // ie, an opaque non-consecutive number.
    int             threadId;

    // Handle if available, ie, a thread we control
    ThreadHandle    threadHandle;

    // Semaphore indicating available work.
    SemaphoreHandle workSemaphore;

    // Flag indicating we should return/exit.
    int             interruptFlag;

    // Which thread to try to steal work from next?
    int             nextVictim;

    // Inc'ed every time we don't find work, used to throttle sleep period.
    int             misses;

    // What groups to grab work from?
    unsigned int    groupMask;

    // Only we can take work from the affinity queue. Anyone posts, we take.
    task_queue_t    affinityQueue;

    // Anyone can grab work out of the general queue. We post, anyone takes.
    task_queue_t    generalQueue;
} task_thread_t;

// Find the task_thread_t structure for a given threadId.
task_thread_t *tasks_threadById(int threadId);

#ifdef __cplusplus
};
#endif
#endif
