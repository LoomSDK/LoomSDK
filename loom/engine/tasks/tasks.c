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
#include <stdio.h>
#include <string.h>
#include "loom/common/core/assert.h"
#include "loom/common/core/performance.h"
#include "loom/common/core/allocator.h"
#include "loom/common/core/log.h"

#include "loom/engine/tasks/tasks.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformThread.h"

#include "loom/engine/tasks/tasksInternal.h"

#if LOOM_COMPILER == LOOM_COMPILER_MSVC
#define snprintf    _snprintf
#endif

// Information for our threads.
#define TASKS_MAX_THREAD_COUNT    32
static int           gThreadCount = 0;
static task_thread_t gWorkerThreads[TASKS_MAX_THREAD_COUNT];

// Miscellany
int gMainThreadId = -1;

static loom_logGroup_t taskLogGroup = { "tasks", 0 };

task_t *task_initialize(task_callback callback, void *payload)
{
    task_t *out = lmAlloc(NULL, sizeof(task_t));

    memset(out, 0, sizeof(task_t));
    task_acquire(out);
    out->callback = callback;
    out->payload  = payload;
    return out;
}


void tasks_finishTask(task_t *task)
{
    int    toStartCount = 0, toFinishCount = 0;
    task_t *nextTask    = NULL;

    do
    {
        // Clear nextTask.
        nextTask = NULL;

        // Mark it done. TODO: cmpxchg.
        atomic_store32((volatile int *)&task->state, TS_Done);

        // Notify the dependencies.
        if (task->toStart)
        {
            lmAssert(task->toStart != task, "Task cannot depend on itself to start.");
            lmAssert(atomic_load32(&task->toStart->startCount) >= 0, "Non-null toStart task cannot have zero startCount.");
            toStartCount = atomic_decrement(&task->toStart->startCount);
            if (toStartCount == 0)
            {
                tasks_schedule(task->toStart);
            }
        }

        if (task->toFinish)
        {
            lmAssert(task->toFinish != task, "Task cannot depend on itself to finish.");

            // Dec and see if we are finishing it.
            toFinishCount = atomic_decrement(&task->toFinish->finishCount);

            // On next loop, we can finish this task, too.
            if (toFinishCount == 0)
            {
                nextTask = task->toFinish;
            }
        }

        // Now we can nuke the task.
        task_release(task);

        // Update our task.
        task = nextTask;
    } while (task);
}


int __stdcall taskThreadFunc(void *payload)
{
    char threadNameBuff[16];

    task_thread_t *ourThread = (task_thread_t *)payload;

    tmThreadName(gTelemetryContext, 0, "Worker%d", ourThread - gWorkerThreads);

    // Assign our ID to the thread description. We have to do this here to
    // avoid race conditions.
    ourThread->threadId = platform_getCurrentThreadId();

    // Note our thread's name for the debugger.
    snprintf(threadNameBuff, 16, "Worker%d", ourThread - gWorkerThreads);
    loom_thread_setDebugName(threadNameBuff);

    for ( ; ; )
    {
        // Time... to die?
        if (atomic_load32(&ourThread->interruptFlag) != 0)
        {
            atomic_store32(&ourThread->interruptFlag, 0);
            return 0;
        }

        // Run a task.
        tasks_runAnyTask(1);
    }
}


void tasks_runAnyTaskForDuration(int millis)
{
    loom_precision_timer_t timer = loom_startTimer();

    while (loom_readTimer(timer) < millis)
    {
        tasks_runAnyTask(0);
    }
    loom_destroyTimer(timer);
}


void tasks_runAnyTask(int allowWaiting)
{
    task_t *work = NULL, *newWork = NULL;

    task_thread_t *ourThread = tasks_threadById(platform_getCurrentThreadId());

    if (!ourThread)
    {
        lmLogError(taskLogGroup, "Tried to run tasks on a thread %x we've never seen before; ignoring...", platform_getCurrentThreadId());
        return;
    }
    // lmAssert(ourThread, "Current thread is not valid.");

    if (!work)
    {
        // Look for work just for us.
        work = task_queue_dequeue(&ourThread->affinityQueue);
    }

    // TODO: Group queue checks.

    if (!work)
    {
        // Look for work in our general queue.
        work = task_queue_dequeue(&ourThread->generalQueue);
    }

    if (!work)
    {
        // Steal work. But never from ourselves.
        ourThread->nextVictim++;
        if (ourThread->nextVictim == ourThread->threadId)
        {
            ourThread->nextVictim++;
        }
        ourThread->nextVictim %= gThreadCount;

        work = task_queue_dequeue(&gWorkerThreads[ourThread->nextVictim].generalQueue);
    }

    // Did we get work? Run it!
    if (work)
    {
        if (work->threadAffinity > 0)
        {
            lmAssert(work->threadAffinity - 1 == tasks_threadById(platform_getCurrentThreadId()) - gWorkerThreads,
                     "Thread affinity is incorrect; task routed to wrong thread."); // TODO: What is this checking?
        }

        lmAssert(atomic_load32((volatile int *)&work->state) == TS_Scheduled, "Task cannot do work if not in scheduled state.");

        atomic_store32((volatile int *)&work->state, TS_Running);
        newWork = work->callback(work->payload, work);

        lmAssert(newWork == NULL, "Callback for new work may not be NULL."); // TODO: Don't handle this properly, need to try to exec/schedule it right away.

        if (atomic_load32((volatile int *)&work->finishCount) == 0)
        {
            tasks_finishTask(work);
        }

        // Don't process this again, get a new one. If we had a specific
        // unit of work to process next we could set it here.
        work = NULL;

        ourThread->misses = 0;
    }
    else
    {
        ourThread->misses++;
    }


    // Do some waiting logic if we need to.
    if (allowWaiting && (ourThread->misses > 10))
    {
        if (ourThread->misses > 100)
        {
            ourThread->misses = 100;
        }

        loom_thread_sleep(((ourThread->misses * ourThread->misses) / 200) + 1);
    }
}


void tasks_startup(int numThreads)
{
    int i;

    gMainThreadId = platform_getCurrentThreadId();

    // If no threads specified, run based on # of cores.
    if (numThreads < 1)
    {
        numThreads = platform_getLogicalThreadCount();
    }

    lmLog(taskLogGroup, "tasks_startup - using %d threads.", numThreads);

    // Set up thread data structures.
    lmAssert(numThreads > 0, "We cannot start without any threads.");
    lmAssert(numThreads < TASKS_MAX_THREAD_COUNT, "We cannot start with %d threads (max thread count is %d)", numThreads, TASKS_MAX_THREAD_COUNT);
    gThreadCount = numThreads;

    // Make sure max thread count is within the addressable bit count for
    // an integer.
    lmAssert(TASKS_MAX_THREAD_COUNT <= sizeof(int) * 8, "Max thread count must be within the addressable bit count for an integer.");

    for (i = 0; i < gThreadCount; i++)
    {
        memset(&gWorkerThreads[i], 0, sizeof(task_thread_t));
        gWorkerThreads[i].threadId      = -1;
        gWorkerThreads[i].workSemaphore = loom_semaphore_create();
        task_queue_init(&gWorkerThreads[i].affinityQueue);
        task_queue_init(&gWorkerThreads[i].generalQueue);
    }

    // Set up group data structures.

/*   assert(numGroups >= 0);
 * assert(numGroups < TASKS_MAX_GROUP_COUNT);
 * groupCount = numGroups;
 *
 * assert(TASKS_MAX_GROUP_COUNT <= sizeof(groupCount) * 8);
 * memset(groups, 0, sizeof(task_thread_t) * TASKS_MAX_GROUP_COUNT);
 *
 * for(i=0; i<groupCount; i++)
 * {
 *    task_queue_init(groups+i);
 * } */

    // Special setup for thread 0, main thread.
    gWorkerThreads[0].threadId = platform_getCurrentThreadId();

    // Now, kick off threads. Skip main thread (#0)
    for (i = 1; i < gThreadCount; i++)
    {
        gWorkerThreads[i].threadHandle = loom_thread_start(taskThreadFunc, &gWorkerThreads[i]);
    }
}


void tasks_run()
{
    // Make sure called from main thread.
    lmAssert(gMainThreadId == platform_getCurrentThreadId(), "tasks_run() must be called from the main thread.");

    // Process tasks.
    taskThreadFunc(&gWorkerThreads[0]);
}


void tasks_shutdown()
{
    int i;

    // Make sure called from main thread.
    lmAssert(gMainThreadId == platform_getCurrentThreadId(), "tasks_shutdown() must be called from the main thread.");

    // Flag shut down time.
    for (i = 0; i < gThreadCount; i++)
    {
        atomic_store32(&gWorkerThreads[i].interruptFlag, 1);
    }

    // Wait for all threads to finish.
    for (i = 1; i < gThreadCount; i++)
    {
        loom_thread_join(gWorkerThreads[i].threadHandle);
    }
}


task_thread_t *tasks_threadById(int threadId)
{
    int i;

    for (i = 0; i < gThreadCount; i++)
    {
        if (gWorkerThreads[i].threadId == threadId)
        {
            return gWorkerThreads + i;
        }
    }
    return NULL;
}


void tasks_schedule(task_t *task)
{
    int           cmpRes = -1;
    int           threadId;
    int           ourAffinityId;
    task_thread_t *taskThread;
    task_queue_t  *taskQueue;

    // If it has outstanding priors, ignore - the priors will enqueue it.
    if (task->startCount > 0)
    {
        return;
    }

    //printf("Enqueueing %x\n", task);

    if ((task->threadAffinity > 0) && (task->threadAffinity < (unsigned int)gThreadCount))
    {
        // It has an affinity and the thread exists, so add it.
        threadId   = -1;
        taskThread = &gWorkerThreads[task->threadAffinity - 1];
        taskQueue  = &taskThread->affinityQueue;
    }
    else
    {
        // Assign to our current thread.
        threadId   = platform_getCurrentThreadId();
        taskThread = tasks_threadById(threadId);

        ourAffinityId = (taskThread - gWorkerThreads) + 1;

        // Warn if we are correcting the thread affinity.
        if ((task->threadAffinity > 0) && (task->threadAffinity != ourAffinityId))
        {
            lmLog(taskLogGroup, "Correcting task from affinity %d to affinity %d.", task->threadAffinity - 1, ourAffinityId - 1);
            task->threadAffinity = ourAffinityId;
        }

        taskQueue = &taskThread->generalQueue;
    }

    lmAssert(taskThread, "Task thread must be valid.");
    lmAssert(taskQueue, "Task queue must be valid.");

    // Update thread status.
    cmpRes = atomic_compareAndExchange((volatile int *)&task->state, TS_Unscheduled, TS_Scheduled);
    lmAssert(cmpRes == TS_Unscheduled, "Failed to properly unschedule task");

    // Yield till work gets in.
    // TODO: Better backoff. Use poisson delay?
    while (task_queue_enqueue(taskQueue, task) == 0)
    {
        loom_thread_yield();
    }
}


void task_setPriority(task_t *task, int priority)
{
    lmAssert(task, "Cannot set the priority of an invalid task.");
    lmAssert(atomic_load32((volatile int *)&task->state) == TS_Unscheduled, "Can only set the priority of an unscheduled task.");
    lmAssert(priority < TASKS_MAX_PRIORITY, "Priority %d must be less than max priority of %d", priority, TASKS_MAX_PRIORITY);

    task->priority = priority;
}


void task_setStarts(task_t *task, task_t *taskToStart)
{
    lmAssert(task, "Cannot set the Starts of an invalid task.");
    lmAssert(taskToStart, "Starts task must be valid.");

    lmAssert(atomic_load32((volatile int *)&taskToStart->state) == TS_Unscheduled, "May only set the Starts of an unscheduled task.");
    atomic_increment(&taskToStart->startCount);

    lmAssert(task->toStart == NULL, "Failed to properly set the task Starts.");
    task->toStart = taskToStart;
}


void task_setFinishes(task_t *task, task_t *taskToFinish)
{
    lmAssert(task, "Cannot set the Finishes of an invalid task.");
    lmAssert(taskToFinish, "Finishes task must be valid.");

    lmAssert(atomic_load32((volatile int *)&taskToFinish->state) < TS_Done, "Finishes task may not be done.");
    atomic_increment(&taskToFinish->finishCount);

    lmAssert(task->toFinish == NULL, "Failed to properly set the task Finishes.");
    task->toFinish = taskToFinish;
}


void task_acquire(task_t *t)
{
    lmAssert(t, "Cannot acquire an invalid task.");
    atomic_increment(&t->refCount);
}


void task_release(task_t *t)
{
    lmAssert(t, "Cannot release an invalid task.");
    if (atomic_decrement(&t->refCount) == 0)
    {
        lmFree(NULL, t);
    }
}


task_state_t task_getTaskState(task_t *task)
{
    return atomic_load32((volatile int *)&task->state);
}


void task_setThreadAffinity(task_t *task, int threadId)
{
    lmAssert(task->state == TS_Unscheduled, "Can only set the affinity of an unscheduled task.");
    task->threadAffinity = threadId + 1;
}


void tasks_interruptMainThread()
{
    // Flag thread 0 to exit from tasks_run.
    atomic_store32(&gWorkerThreads[0].interruptFlag, 1);
}


// Ring buffer implementation.
#if TASKS_RINGBUFFER_GUARDS == 1
#define TASKS_RINGBUFFER_GUARDS_CHECK()    lmSafeAssert(ring->preGuard == 0xBAADF00D && ring->postGuard == 0xD00BFEED, "Ring buffer guards got corrupted.");
#else
#define TASKS_RINGBUFFER_GUARDS_CHECK    ()
#endif

void task_ringbuffer_init(task_ringbuffer_t *ring)
{
    ring->writeIndex = ring->readIndex = 0;

#if TASKS_RINGBUFFER_GUARDS == 1
    memset(ring->buffer, 0, sizeof(task_t *) * TASKS_MAX_QUEUE_LENGTH);
    ring->preGuard  = 0xBAADF00D;
    ring->postGuard = 0xD00BFEED;
#endif

    TASKS_RINGBUFFER_GUARDS_CHECK();
}


int task_ringbuffer_isfull(task_ringbuffer_t *ring)
{
    TASKS_RINGBUFFER_GUARDS_CHECK();
    return ((ring->writeIndex + 1) % TASKS_MAX_QUEUE_LENGTH) == ring->readIndex;
}


int task_ringbuffer_isempty(task_ringbuffer_t *ring)
{
    TASKS_RINGBUFFER_GUARDS_CHECK();
    return(ring->readIndex == ring->writeIndex);
}


int task_ringbuffer_put(task_ringbuffer_t *ring, task_t *item)
{
    if (task_ringbuffer_isfull(ring))
    {
        return 0;
    }

    TASKS_RINGBUFFER_GUARDS_CHECK();
    lmAssert(ring->buffer[ring->writeIndex] == NULL, "Ring buffer write location is not NULL as expected.");
    ring->buffer[ring->writeIndex] = item;
    TASKS_RINGBUFFER_GUARDS_CHECK();
    ring->writeIndex = (ring->writeIndex + 1) % TASKS_MAX_QUEUE_LENGTH;

    return 1;
}


task_t *task_ringbuffer_get(task_ringbuffer_t *ring)
{
    task_t *out = 0;

    if (task_ringbuffer_isempty(ring))
    {
        return 0;
    }

    TASKS_RINGBUFFER_GUARDS_CHECK();
    out = ring->buffer[ring->readIndex];
    TASKS_RINGBUFFER_GUARDS_CHECK();
    ring->buffer[ring->readIndex] = 0; // TODO: Needed?
    TASKS_RINGBUFFER_GUARDS_CHECK();
    ring->readIndex = (ring->readIndex + 1) % TASKS_MAX_QUEUE_LENGTH;

    return out;
}


// Queue implementation.
void task_queue_init(task_queue_t *q)
{
    int i;

    q->mutex = loom_mutex_create();
    for (i = 0; i < TASKS_MAX_PRIORITY; i++)
    {
        task_ringbuffer_init(q->queue + i);
    }
}


void task_queue_destroy(task_queue_t *q)
{
    loom_mutex_destroy(q->mutex);
    q->mutex = NULL;
}


int task_queue_enqueue(task_queue_t *q, task_t *t)
{
    int res;

    lmAssert(q, "Queue must be valid.");
    lmAssert(q->mutex, "Queue must have valid mutex.");

    lmAssert(t, "Task must be valid.");
    lmAssert(t->priority >= 0, "Task priority of %d must be greater than min priority of 0.", t->priority);
    lmAssert(t->priority < TASKS_MAX_PRIORITY, "Task priority of %d must be less than max priority of %d.", t->priority, TASKS_MAX_PRIORITY);

    loom_mutex_lock(q->mutex);
    res = task_ringbuffer_put(q->queue + t->priority, t);
    loom_mutex_unlock(q->mutex);

    return res;
}


task_t *task_queue_dequeue(task_queue_t *q)
{
    int    i;
    task_t *t = 0;

    lmAssert(q, "Queue must be valid.");
    lmAssert(q->mutex, "Queue must have valid mutex.");

    if (!loom_mutex_trylock(q->mutex))
    {
        return NULL;
    }

    for (i = TASKS_MAX_PRIORITY - 1; i >= 0; i--)
    {
        t = task_ringbuffer_get(&q->queue[i]);
        if (t)
        {
            break;
        }
    }

    loom_mutex_unlock(q->mutex);

    return t;
}
