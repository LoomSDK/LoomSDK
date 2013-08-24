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

#include "seatest.h"
#include "loom/engine/tasks/tasks.h"
#include "loom/common/platform/platform.h"

SEATEST_FIXTURE(tasks)
{
    SEATEST_FIXTURE_ENTRY(tasks_simple);
    SEATEST_FIXTURE_ENTRY(tasks_complex);
    SEATEST_FIXTURE_ENTRY(tasks_ringBuffer);
    SEATEST_FIXTURE_ENTRY(tasks_queueSimple);
    SEATEST_FIXTURE_ENTRY(tasks_queueComplex);
}

// Public API test.
static volatile int gWorkDone = 0;
static task_t *doWork(void *payload, task_t *t)
{
    gWorkDone = 1;
    tasks_interruptMainThread();
    return NULL;
}


SEATEST_TEST(tasks_simple)
{
    tasks_startup(0);

    task_t *simplestTask = task_initialize(doWork, NULL);
    tasks_schedule(simplestTask);

    tasks_run();
    tasks_shutdown();

    assert_int_equal(gWorkDone, 1);
}

static int gChildWorkCount = 0, gParentWorkCount = 0;

task_t *dummyChildTask(void *payload, task_t *task)
{
    atomic_increment(&gChildWorkCount);
    loom_thread_sleep(2);
    return NULL;
}


task_t *dummyParentTask(void *payload, task_t *task)
{
    task_t *newTask = task_initialize(dummyChildTask, NULL);

    atomic_increment(&gParentWorkCount);
    task_setFinishes(newTask, task);
    tasks_schedule(newTask);
    return NULL;
}


SEATEST_TEST(tasks_complex)
{
    tasks_startup(0);

    task_t *prevTask  = NULL;
    task_t *firstTask = NULL;

    // Set up a chain of 100 tasks.
    const int tasksToRun = 100;
    task_t    *taskList[tasksToRun];
    for (int i = 0; i < tasksToRun; i++)
    {
        task_t *simplestTask = task_initialize(dummyParentTask, NULL);
        task_acquire(simplestTask);

        taskList[i] = simplestTask;

        if (!firstTask)
        {
            firstTask = simplestTask;
        }

        if (prevTask)
        {
            task_setStarts(prevTask, simplestTask);
        }

        prevTask = simplestTask;
    }

    // And a terminal task, to shut down the system.
    task_t *finalTask = task_initialize(doWork, NULL);
    task_setStarts(prevTask, finalTask);

    // Kick it off.
    tasks_schedule(firstTask);

    // Run 'er out.
    tasks_run();
    tasks_shutdown();

    // Confirm that we hit all the tasks.
    for (int i = 0; i < tasksToRun; i++)
    {
        assert_int_equal(TS_Done, task_getTaskState(taskList[i]));
        task_release(taskList[i]);
    }

    assert_int_equal(tasksToRun, gChildWorkCount);
    assert_int_equal(tasksToRun, gParentWorkCount);

    assert_int_equal(gWorkDone, 1);
}

// Internals tests.
#include "loom/engine/tasks/tasksInternal.h"

static task_ringbuffer_t testRing;

SEATEST_TEST(tasks_ringBuffer)
{
    task_ringbuffer_init(&testRing);

    // Confirm it is empty.
    assert_true(task_ringbuffer_isfull(&testRing) == 0);
    assert_true(task_ringbuffer_isempty(&testRing) == 1);

    assert_true(task_ringbuffer_get(&testRing) == NULL);

    // Put something in and out.
    assert_true(task_ringbuffer_put(&testRing, (task_t *)0xDEADBEEF) == 1);
    assert_true(task_ringbuffer_isfull(&testRing) == 0);
    assert_true(task_ringbuffer_isempty(&testRing) == 0);

    size_t res = (size_t)task_ringbuffer_get(&testRing);
    assert_true(task_ringbuffer_isfull(&testRing) == 0);
    assert_true(task_ringbuffer_isempty(&testRing) == 1);
    assert_int_equal(0xDEADBEEF, (int)res);

    // Fill the buffer from an empty state.
    assert_true(task_ringbuffer_isempty(&testRing) == 1);

    int i = 1;
    while (task_ringbuffer_put(&testRing, (task_t *)i) == 1)
    {
        i++;
    }

    assert_int_equal(i, 128 - 1 + 1);
    assert_true(task_ringbuffer_isfull(&testRing) == 1);
    assert_true(task_ringbuffer_isempty(&testRing) == 0);

    // Pull out and see if we got values we expected.
    int j = 1;
    while (!task_ringbuffer_isempty(&testRing))
    {
        size_t val = (size_t)task_ringbuffer_get(&testRing);
        assert_int_equal(j, (int)val);

        j++;
        i--;
    }

    // And correct total # made it through.
    assert_int_equal(1, i);
}

SEATEST_TEST(tasks_queueSimple)
{
    // Make a test queue.
    gWorkDone = 0;
    task_queue_t testQ;
    task_queue_init(&testQ);

    task_t *a = task_initialize(doWork, NULL);
    task_t *b = task_initialize(doWork, NULL);
    task_setPriority(b, 1);
    task_t *c = task_initialize(doWork, NULL);
    task_setPriority(c, 2);
    task_t *d = task_initialize(doWork, NULL);

    task_queue_enqueue(&testQ, a);
    task_queue_enqueue(&testQ, b);
    task_queue_enqueue(&testQ, c);
    task_queue_enqueue(&testQ, d);

    // Expect oldest highest priority first.
    assert_true(task_queue_dequeue(&testQ) == c);
    assert_true(task_queue_dequeue(&testQ) == b);
    assert_true(task_queue_dequeue(&testQ) == a);
    assert_true(task_queue_dequeue(&testQ) == d);
    assert_true(task_queue_dequeue(&testQ) == NULL);

    task_queue_destroy(&testQ);
}

const static int    csmQueueCount = 16;
const static int    csmTaskCount  = 100;
static task_queue_t gQueues[csmQueueCount];
static task_t       *gTasks[csmQueueCount * csmTaskCount * TASKS_MAX_PRIORITY];

static task_t *doAtomicInc(void *payload, task_t *t)
{
    atomic_increment(&gWorkDone);
    return NULL;
}


static int __stdcall workerThreadFunc(void *payload)
{
    size_t startId = ((size_t)payload) * (csmQueueCount / TASKS_MAX_PRIORITY);

    tmThreadName(gTelemetryContext, 0, "worker %d", int(payload));
    tmEnter(gTelemetryContext, TMZF_NONE, "worker");

    // Walk the queues and pull data out.
    size_t curQueue = startId;
    for ( ; ; )
    {
        int ttl = csmQueueCount * 2;
        while (ttl--)
        {
            task_t *taskToRun = task_queue_dequeue(&gQueues[curQueue++ % csmQueueCount]);
            if (!taskToRun)
            {
                continue;
            }

            taskToRun->callback(taskToRun->payload, taskToRun);
            taskToRun->state = TS_Done;
            break;
        }

        if (ttl == -1)
        {
            break;
        }
    }

    tmLeave(gTelemetryContext);

    return 0;
}


SEATEST_TEST(tasks_queueComplex)
{
#if LOOM_COMPILER != LOOM_COMPILER_MSVC
    return;
#endif

    // Make sure workdone is zero.
    atomic_store32(&gWorkDone, 0);

    // Create some queues. Pre-seed with work.
    task_t **curTaskSlot = gTasks;
    for (int i = 0; i < csmQueueCount; i++)
    {
        task_queue_init(&gQueues[i]);

        for (int j = 0; j < csmTaskCount; j++)
        {
            for (int k = 0; k < TASKS_MAX_PRIORITY; k++)
            {
                task_t *newTask = task_initialize(doAtomicInc, (void *)j);
                task_setPriority(newTask, k);
                assert_true(task_queue_enqueue(&gQueues[i], newTask) == 1);
                *(curTaskSlot++) = newTask;
            }
        }
    }

    // Spawn some threads to pull work. Pass them an ID to offset the queues
    // they pull from.
    ThreadHandle workers[8];
    for (int i = 0; i < 8; i++)
    {
        workers[i] = loom_thread_start(workerThreadFunc, (void *)i);
    }

    // Wait for them to be done.
    for (int i = 0; i < 8; i++)
    {
        loom_thread_join(workers[i]);
    }

    // Every queue should be empty.
    for (int i = 0; i < csmQueueCount; i++)
    {
        for (int j = 0; j < TASKS_MAX_PRIORITY; j++)
        {
            assert_true(task_ringbuffer_isempty(&gQueues[i].queue[j]) == 1);
        }
    }

    // Every task should be done.
    for (int i = 0; i < csmQueueCount * csmTaskCount * TASKS_MAX_PRIORITY; i++)
    {
        assert_int_equal(TS_Done, gTasks[i]->state);
        if (gTasks[i]->state != TS_Done)
        {
            printf("Saw task #%d with state %d priority %d payload %zu\n", i, gTasks[i]->state, gTasks[i]->priority, (size_t)gTasks[i]->payload);
        }
    }

    // Check final results.
    assert_int_equal(csmQueueCount * csmTaskCount * TASKS_MAX_PRIORITY, atomic_load32(&gWorkDone));

    // Shut down.
    for (int i = 0; i < csmQueueCount; i++)
    {
        task_queue_destroy(&gQueues[i]);
    }
}
