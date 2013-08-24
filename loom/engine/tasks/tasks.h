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

#ifndef _TASKS_TASKS_H_
#define _TASKS_TASKS_H_

#include "loom/common/platform/platformThread.h"

#ifdef __cplusplus
extern "C" {
#endif

/**************************************************************************
 * Loom Task System
 *
 * Loom is built around a task model. Tasks can depend on one another, be
 * locked to a specific thread, and have varying priorities. There is a
 * thread per core, consuming tasks as rapidly as possible using a work
 * stealing model.
 *************************************************************************/

// Opaque task type. This is refcounted by the tasks system, so it will
// be auto-freed when finished. You can hold a reference via task_acquire.
typedef struct task   task_t;

// Callback for task implementation. Returning a task will cause it to be
// run immediately if possible
typedef task_t * (*task_callback)(void *payload, task_t *task);

// Called from main thread to start task system. Pass zero for thread
// count to start a thread per core.
void tasks_startup(int numThreads);

// Called from main thread to run tasks. If tasks_interruptMainThread is
// called, then this returns. You can call it again to resume execution.
void tasks_run();

// Called from main thread, while task system is interrupted, to shut
// down and clean up.
void tasks_shutdown();

// This many priority levels are available. Higher levels are run first.
#define TASKS_MAX_PRIORITY    3

// Initialize a task with the provided callback and payload. You can call
// subsequent task_* methods to set properties on the task.
task_t *task_initialize(task_callback callback, void *payload);

// Set a task's priority, up to TASKS_MAX_PRIORITY-1. Must be set before
// the task is scheduled.
void task_setPriority(task_t *task, int priority);

// Tasks are refcounted. You can acquire/release references to them.
void task_acquire(task_t *t);
void task_release(task_t *t);

// Tasks can be locked to a specific thread, for instance, for GPU/UI/OS
// interactions.
void task_setThreadAffinity(task_t *task, int threadId);

// Indicate this task starts another when it starts. Task can only have
// task that they trigger, although a task can require many other tasks
// to be completed before it runs.
void task_setStarts(task_t *task, task_t *taskToStart);

// Indicates this task finishes another when it finishes. Task can only
// have one task that they finish, although a task can require many other
// tasks to complete before it is finished.
void task_setFinishes(task_t *task, task_t *taskToFinish);

// Indicate we're done setting up task, and put it in a work queue.
void tasks_schedule(task_t *task);

// The possible states of a task, used mostly for debugging or reporting.
typedef enum task_state_t
{
    TS_Unscheduled,
    TS_Scheduled,
    TS_Running,
    TS_Done,
    FORCE_INT = 0xFFFFFFFF
} task_state_t;

// Query the state of a task. Mostly used for debugging/reporting.
task_state_t task_getTaskState(task_t *task);

// Make every task thread terminate, this is non-reversible.
void tasks_interrupt();

// Make the main task thread return from tasks_run(). You can call
// tasks_run again to resume.
void tasks_interruptMainThread();

// Run any one task, call this if you're in a blocking task and need
// something to do.
void tasks_runAnyTask(int allowWaiting);

// Loop calling tasks_runAnyTask() for at least millis ms.
void tasks_runAnyTaskForDuration(int millis);

// Macros to declare a profiled task.
#define LOOM_DECLARE_TASK(name) \
    task_t * task_ ## name ## Task(void *payload, task_t * task);

#define LOOM_IMPLEMENT_TASK(name)                                   \
    task_t * task_ ## name ## _inner(void *payload, task_t * task); \
    task_t *task_ ## name ## Task(void *payload, task_t * task);    \
    task_t *task_ ## name ## Task(void *payload, task_t * task) {   \
        task_t *res = NULL;                                         \
        tmEnter(gTelemetryContext, TMZF_NONE, # name);              \
        res = task_ ## name ## _inner(payload, task);               \
        tmLeave(gTelemetryContext);                                 \
        return res; }                                               \
    task_t *task_ ## name ## _inner(void *payload, task_t * task)


#ifdef __cplusplus
};
#endif
#endif
