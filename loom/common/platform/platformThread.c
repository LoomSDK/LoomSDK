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

#include "loom/common/platform/platformThread.h"
#include "loom/common/platform/platform.h"
#include "loom/common/core/assert.h"
#include "loom/common/core/allocator.h"

#if LOOM_PLATFORM == LOOM_PLATFORM_WIN32

#define WIN32_LEAN_AND_MEAN
#include <assert.h>
#include <windows.h>
#include <limits.h>
#include <stdlib.h>
#include <process.h>
#include "loom/common/core/performance.h"

// Global reference to
HANDLE gMutexHandle = NULL;

int platform_getLogicalThreadCount()
{
    SYSTEM_INFO sysinfo;

    GetSystemInfo(&sysinfo);
    return sysinfo.dwNumberOfProcessors;
}


int platform_getCurrentThreadId()
{
    return GetCurrentThreadId();
}


int loom_process_ensureOnlyOneInstance()
{
    char moduleFile[2048];

    strcpy(moduleFile, "loomProcessLock_");
    GetModuleFileNameA(NULL, moduleFile + 16, 2047);
    gMutexHandle = CreateMutexA(NULL, 1, moduleFile);

    if (!gMutexHandle)
    {
        return 0;
    }

    if (GetLastError() == ERROR_ALREADY_EXISTS)
    {
        CloseHandle(gMutexHandle);
        gMutexHandle = NULL;
        return 0;
    }

    return 1;
}


MutexHandle loom_mutex_create_real(const char *file, int line)
{
    CRITICAL_SECTION *cs;

    assert(sizeof(MutexHandle) >= sizeof(CRITICAL_SECTION *));
    cs = (CRITICAL_SECTION *)lmAlloc(NULL, sizeof(CRITICAL_SECTION));
    InitializeCriticalSectionAndSpinCount(cs, 800); // TODO: Tune wait time.
    return cs;
}


void loom_mutex_lock_real(const char *file, int line, MutexHandle m)
{
#ifndef NTELEMETRY
    TmU64 matchId;
#endif

    lmAssert(m != 0, "loom_mutex_lock_real - tried to lock NULL");

    tmTryLockEx(gTelemetryContext, &matchId, 1000, file, line, m, "mutex_lock");

    EnterCriticalSection((CRITICAL_SECTION *)m);

    tmEndTryLockEx(gTelemetryContext, matchId, file, line, m, TMLR_SUCCESS);

    tmSetLockState(gTelemetryContext, m, TMLS_LOCKED, "mutex_lock");
}


int loom_mutex_trylock_real(const char *file, int line, MutexHandle m)
{
#ifndef NTELEMETRY
    TmU64 matchId;
#endif

    lmAssert(m != 0, "loom_mutex_lock_real - tried to lock NULL");

    tmTryLockEx(gTelemetryContext, &matchId, 1000, file, line, m, "mutex_trylock");

    if (TryEnterCriticalSection((CRITICAL_SECTION *)m))
    {
        tmEndTryLockEx(gTelemetryContext, matchId, file, line, m, TMLR_SUCCESS);
        tmSetLockState(gTelemetryContext, m, TMLS_LOCKED, "mutex_trylock");
        return 1;
    }
    else
    {
        tmEndTryLockEx(gTelemetryContext, matchId, file, line, m, TMLR_FAILED);
        return 0;
    }
}


void loom_mutex_unlock_real(const char *file, int line, MutexHandle m)
{
    lmAssert(m != 0, "loom_mutex_lock_real - tried to unlock NULL");
    LeaveCriticalSection((CRITICAL_SECTION *)m);
    tmSetLockStateEx(gTelemetryContext, file, line, m, TMLS_RELEASED, "mutex_unlock");
}


void loom_mutex_destroy_real(const char *file, int line, MutexHandle m)
{
    assert(m);

    DeleteCriticalSection((CRITICAL_SECTION *)m);
    tmSetLockStateEx(gTelemetryContext, file, line, m, TMLS_DESTROYED, "mutex_destroy");
    lmFree(NULL, m);
}


ThreadHandle loom_thread_start(ThreadFunction func, void *param)
{
    // _beginthreadex is reported to properly initialize the CRT, while
    // CreateThread does not, so we use it.
    assert(sizeof(uintptr_t) == sizeof(ThreadHandle));
    return (ThreadHandle)_beginthreadex(NULL, 0, func, param, 0, NULL);
}


int loom_thread_getIdFromHandle(ThreadHandle th)
{
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    return GetThreadId((HANDLE)th);

#else
    assert(0); // Needs to be implemented.
    return 0;
#endif
}


void loom_thread_join(ThreadHandle th)
{
    tmEnter(gTelemetryContext, TMZF_NONE, "thread_join");

    tmTryLock(gTelemetryContext, th, "thread_join");
    WaitForSingleObject(th, INFINITE);
    tmEndTryLock(gTelemetryContext, th, TMLR_SUCCESS);

    CloseHandle(th);

    tmLeave(gTelemetryContext);
}


SemaphoreHandle loom_semaphore_create_real(const char *file, int line)
{
    SemaphoreHandle *s = CreateSemaphore(NULL, 0, LONG_MAX, NULL);

    assert(s);
    return s;
}


void loom_semaphore_post_real(const char *file, int line, SemaphoreHandle s)
{
    assert(s);
    ReleaseSemaphore((HANDLE)s, 1, NULL);

    tmSignalLockCount(gTelemetryContext, s, 1, "semaphore_post");
}


void loom_semaphore_wait_real(const char *file, int line, SemaphoreHandle s)
{
#ifndef NTELEMETRY
    TmU64 matchId;
#endif

    assert(s);

    tmTryLockEx(gTelemetryContext, &matchId, 1000, file, line, s, "semaphore_wait");

    WaitForSingleObject((HANDLE)s, INFINITE);

    tmEndTryLockEx(gTelemetryContext, matchId, file, line, s, TMLR_SUCCESS);
}


void loom_semaphore_destroy_real(const char *file, int line, SemaphoreHandle s)
{
    assert(s);
    CloseHandle((HANDLE)s);
    tmSetLockState(gTelemetryContext, s, TMLS_DESTROYED, "semaphore_destroy");
}


int atomic_compareAndExchange(volatile int *value, int expected, int newVal)
{
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    return _InterlockedCompareExchange(value, newVal, expected);

#else
    return __sync_val_compare_and_swap(value, expected, newVal);
#endif
}


int atomic_increment(volatile int *value)
{
    assert(value);
    assert((int)value % 4 == 0); // Only 32 bit aligned values work.
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    return _InterlockedIncrement(value);

#else
    return __sync_sub_and_fetch(value, 1);
#endif
}


int atomic_decrement(volatile int *value)
{
    assert(value);
    assert((int)value % 4 == 0); // Only 32 bit aligned values work.
#if LOOM_COMPILER == LOOM_COMPILER_MSVC
    return _InterlockedDecrement(value);

#else
    return __sync_sub_and_fetch(value, 1);
#endif
}


void loom_thread_sleep(long ms)
{
    tmEnter(gTelemetryContext, TMZF_IDLE, "thread_sleep");
    Sleep(ms);
    tmLeave(gTelemetryContext);
}


void loom_thread_yield()
{
    tmEnter(gTelemetryContext, TMZF_IDLE, "thread_yield");
    SwitchToThread();
    tmLeave(gTelemetryContext);
}


#if LOOM_COMPILER == LOOM_COMPILER_MSVC
#define MEMORY_RW_BARRIER    _ReadWriteBarrier
#else
#define MEMORY_RW_BARRIER    __sync_synchronize
#endif

int atomic_load32(volatile int *variable)
{
    // TODO: This can certainly be backed off.
    MEMORY_RW_BARRIER();

    return *variable;
}


void atomic_store32(volatile int *variable, int newValue)
{
    // TODO: This can certainly be backed off.
    MEMORY_RW_BARRIER();

    *variable = newValue;

    MEMORY_RW_BARRIER();
}


//
// Usage: SetThreadName (-1, "MainThread");
// From: http://msdn.microsoft.com/en-us/library/xcb2z8hs%28v=VS.71%29.aspx
typedef struct tagTHREADNAME_INFO
{
    DWORD  dwType;     // must be 0x1000
    LPCSTR szName;     // pointer to name (in user addr space)
    DWORD  dwThreadID; // thread ID (-1=caller thread)
    DWORD  dwFlags;    // reserved for future use, must be zero
} THREADNAME_INFO;

void SetThreadName(DWORD dwThreadID, LPCSTR szThreadName)
{
    THREADNAME_INFO info;

    info.dwType     = 0x1000;
    info.szName     = szThreadName;
    info.dwThreadID = dwThreadID;
    info.dwFlags    = 0;

    __try
    {
        RaiseException(0x406D1388, 0, sizeof(info) / sizeof(DWORD), (void *)&info);
    }
    __except (EXCEPTION_CONTINUE_EXECUTION)
    {
    }
}


void loom_thread_setDebugName(const char *name)
{
    SetThreadName(GetCurrentThreadId(), name);
}


#elif LOOM_PLATFORM_IS_APPLE

#include <assert.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>

#include "loom/common/platform/platformDisplay.h"
#include "loom/common/core/performance.h"

#include <mach/mach_init.h>
#include <mach/task.h>
#include <mach/mach_traps.h>
#include <mach/semaphore.h>
#include <libkern/OSAtomic.h>

#include <sys/sysctl.h>
#include <sys/sem.h>
#include <sys/file.h>
#include <pthread.h>
#include <errno.h>

#include <sched.h>
#include <time.h>

int loom_process_ensureOnlyOneInstance()
{
    char     path[1024];
    uint32_t size = sizeof(path);

    lmAssert(_NSGetExecutablePath(path, &size) == 0, "Failed to get executable path.");

    int fd = open(path, O_RDONLY | O_EXLOCK | O_NONBLOCK);
    if (fd == -1)
    {
        return 1;
    }
    return 0;
}


int platform_getLogicalThreadCount()
{
    int    mib[4], numCPU;
    size_t len = sizeof(numCPU);

    // set the mib for hw.ncpu
    mib[0] = CTL_HW;
    mib[1] = HW_AVAILCPU; // alternatively, try HW_NCPU;

    // get the number of CPUs from the system
    sysctl(mib, 2, &numCPU, &len, NULL, 0);

    if (numCPU < 1)
    {
        mib[1] = HW_NCPU;
        sysctl(mib, 2, &numCPU, &len, NULL, 0);

        if (numCPU < 1)
        {
            numCPU = 1;
        }
    }

    return numCPU;
}


int platform_getCurrentThreadId()
{
    return (size_t)pthread_self();
}


MutexHandle loom_mutex_create_real(const char *file, int line)
{
    pthread_mutexattr_t mta;
    pthread_mutex_t     *m = malloc(sizeof(pthread_mutex_t));

    assert(m);

    // TODO: We can cache this.
    pthread_mutexattr_init(&mta);
    pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);

    int err = pthread_mutex_init(m, &mta);
    assert(!err);


    return m;
}


void loom_mutex_lock_real(const char *file, int line, MutexHandle m)
{
    assert(m);
    pthread_mutex_lock((pthread_mutex_t *)m);
}


int loom_mutex_trylock_real(const char *file, int line, MutexHandle m)
{
    int err;

    lmAssert(m, "Mutex is not valid");

    err = pthread_mutex_trylock((pthread_mutex_t *)m);

    if (err == EBUSY)
    {
        return 0;
    }

    lmAssert(!err, "Could not lock mutex");

    return 1;
}


void loom_mutex_unlock_real(const char *file, int line, MutexHandle m)
{
    assert(m);
    pthread_mutex_unlock((pthread_mutex_t *)m);
}


void loom_mutex_destroy_real(const char *file, int line, MutexHandle m)
{
    assert(m);
    pthread_mutex_destroy((pthread_mutex_t *)m);
    lmFree(NULL, m);
}


typedef void *(*pthread_thread_func)(void *);

ThreadHandle loom_thread_start(ThreadFunction func, void *param)
{
    assert(sizeof(ThreadHandle) >= sizeof(pthread_t *));
    pthread_t *t = (pthread_t *)lmAlloc(NULL, sizeof(pthread_t));
    pthread_create(t, NULL, (pthread_thread_func)func, param);
    return t;
}


int loom_thread_getIdFromHandle(ThreadHandle th)
{
    assert(sizeof(int) >= sizeof(ThreadHandle));
    return (size_t)th;
}


void loom_thread_join(ThreadHandle th)
{
    pthread_join(*(pthread_t *)th, NULL);
}


SemaphoreHandle loom_semaphore_create_real(const char *file, int line)
{
    semaphore_t   *sem = malloc(sizeof(semaphore_t));
    kern_return_t err;

    lmAssert(sem, "Failed to allocate memory for semaphore.");
    lmAssert(sizeof(SemaphoreHandle) >= sizeof(semaphore_t), "Size of native semaphore type too large for our semaphore handle on this platform.");
    err = semaphore_create(mach_task_self(), sem, SYNC_POLICY_FIFO, 0);
    lmAssert(err == KERN_SUCCESS, "Semaphore did not create properly. Expected %d, got %d", KERN_SUCCESS, err);
    return (SemaphoreHandle)sem;
}


void loom_semaphore_post_real(const char *file, int line, SemaphoreHandle s)
{
    kern_return_t err;
    semaphore_t   *sem = (semaphore_t *)s;

    lmAssert(s, "Semaphore must be valid.");
    err = semaphore_signal(*sem);
    lmAssert(err == KERN_SUCCESS, "Failed to properly signal semaphore. Expected %d, got %d", KERN_SUCCESS, err);
}


void loom_semaphore_wait_real(const char *file, int line, SemaphoreHandle s)
{
    kern_return_t err;
    semaphore_t   *sem = (semaphore_t *)s;

    lmAssert(s, "Semaphore must be valid.");
    err = semaphore_wait(*sem);
    lmAssert(err == KERN_SUCCESS, "Failed to properly wait on semaphore. Expected %d, got %d", KERN_SUCCESS, err);
}


void loom_semaphore_destroy_real(const char *file, int line, SemaphoreHandle s)
{
    kern_return_t err;
    semaphore_t   *sem = (semaphore_t *)s;

    lmAssert(s, "Semaphore must be valid.");
    err = semaphore_destroy(mach_task_self(), *sem);
    lmAssert(err == KERN_SUCCESS, "Semaphore did not destruct properly. Expected %d, got %d", KERN_SUCCESS, err);
}


int atomic_compareAndExchange(volatile int *value, int expected, int newVal)
{
    return __sync_val_compare_and_swap(value, expected, newVal);
}


int atomic_increment(volatile int *value)
{
    return OSAtomicAdd32(1, value);
}


int atomic_decrement(volatile int *value)
{
    return OSAtomicAdd32(-1, value);
}


void loom_thread_sleep(long ms)
{
    struct timespec sleepTime;

    sleepTime.tv_sec = ms / 1000;
    ms = ms % 1000;
    sleepTime.tv_nsec = ms * 1000 * 1000;
    nanosleep(&sleepTime, NULL);
}


void loom_thread_yield()
{
    sched_yield();
}


int atomic_load32(volatile int *variable)
{
    __sync_synchronize();
    return *variable;
}


void atomic_store32(volatile int *variable, int newValue)
{
    __sync_synchronize();
    *variable = newValue;
    __sync_synchronize();
}


void loom_thread_setDebugName(const char *name)
{
    pthread_setname_np(name);
}


#elif LOOM_PLATFORM == LOOM_PLATFORM_ANDROID || LOOM_PLATFORM == LOOM_PLATFORM_LINUX

#include <assert.h>
#include <stdlib.h>
#include <pthread.h>
#include <sched.h>
#include <time.h>
#include <unistd.h>
#include <semaphore.h>
#include <errno.h>

#include "loom/common/platform/platformDisplay.h"
#include "loom/common/core/performance.h"
#include <stdio.h>

#if LOOM_PLATFORM == LOOM_PLATFORM_ANDROID
#include <sys/atomics.h>
#endif

#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX

#include "sys/file.h"

int loom_process_ensureOnlyOneInstance()
{
    // Unlike pidfiles, these flocks are always automatically released when your process dies
    // for any reason, have no race conditions exist relating to file deletion
    // (as the file doesn't need to be deleted to release the lock), and there's no chance
    // of a different process inheriting the PID and thus appearing to validate a stale lock.

    // note that multiple loom processes will require passing an identifier for the lock
    int fd = open("/var/run/loom_process_lock", O_WRONLY);

    if (fd == -1)
    {
        return 0;
    }

    if (flock(fd, LOCK_EX | LOCK_UN))
    {
        return 0;
    }

    return 1;
}
#endif

int platform_getLogicalThreadCount()
{
    // FIXME:  On my Droid2, get a value of 1 on the sysconf call below
    // Loom currently refuses to run on 1 thread it appears (at least under Android)
    return 2;

    // Cribbed from: http://stackoverflow.com/questions/7962155
    //return sysconf(_SC_NPROCESSORS_CONF);
}


int platform_getCurrentThreadId()
{
    int id = (int)pthread_self();

    return(id);
}


MutexHandle loom_mutex_create_real(const char *file, int line)
{
    pthread_mutexattr_t mta;
    pthread_mutex_t     *m = malloc(sizeof(pthread_mutex_t));

    assert(m);

    // TODO: We can cache this.
    pthread_mutexattr_init(&mta);
    pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);

    int err = pthread_mutex_init(m, &mta);
    assert(!err);


    return m;
}


void loom_mutex_lock_real(const char *file, int line, MutexHandle m)
{
    int err;

    lmAssert(m, "Mutex is not valid");
    err = pthread_mutex_lock((pthread_mutex_t *)m);
    lmAssert(!err, "Could not lock mutex");
}


int loom_mutex_trylock_real(const char *file, int line, MutexHandle m)
{
    int err;

    lmAssert(m, "Mutex is not valid");

    err = pthread_mutex_trylock((pthread_mutex_t *)m);

    if (err == EBUSY)
    {
        return 0;
    }

    lmAssert(!err, "Could not lock mutex");

    return 1;
}


void loom_mutex_unlock_real(const char *file, int line, MutexHandle m)
{
    int err;

    lmAssert(m, "Mutex is not valid");
    err = pthread_mutex_unlock((pthread_mutex_t *)m);
    lmAssert(!err, "Could not lock mutex");
}


void loom_mutex_destroy_real(const char *file, int line, MutexHandle m)
{
    int err;

    lmAssert(m, "Mutex is not valid");
    err = pthread_mutex_destroy((pthread_mutex_t *)m);
    lmAssert(!err, "Could not destroy mutex");
    lmFree(NULL, m);
}


typedef void *(*pthread_thread_func)(void *);

ThreadHandle loom_thread_start(ThreadFunction func, void *param)
{
    assert(sizeof(ThreadHandle) >= sizeof(pthread_t *));
    pthread_t *t = malloc(sizeof(pthread_t));
    pthread_create(t, NULL, (pthread_thread_func)func, param);
    return t;
}


int loom_thread_getIdFromHandle(ThreadHandle th)
{
    assert(sizeof(int) >= sizeof(ThreadHandle));
    return (size_t)th;
}


void loom_thread_join(ThreadHandle th)
{
    pthread_join(*(pthread_t *)th, NULL);
}


SemaphoreHandle loom_semaphore_create_real(const char *file, int line)
{
    sem_t *sem = malloc(sizeof(sem_t));
    int   err;

    lmAssert(sem, "Failed to allocate memory for semaphore.");

    // Note, on Linux a sem_t is 16 bytes.  This is ok as we don't ever store
    // the semaphore data itself only a pointer
    lmAssert(sizeof(SemaphoreHandle) >= sizeof(sem_t *), "Size of native semaphore type too large for our semaphore handle on this platform. (%i/%i)", sizeof(SemaphoreHandle), sizeof(sem_t));
    err = sem_init(sem, 0, 0);
    lmAssert(err != -1, "Semaphore did not create properly.");
    return (SemaphoreHandle)sem;
}


void loom_semaphore_post_real(const char *file, int line, SemaphoreHandle s)
{
    int   err;
    sem_t *sem = (sem_t *)s;

    lmAssert(s, "Semaphore must be valid.");
    err = sem_post(sem);
    lmAssert(err == 0, "Failed to properly post to semaphore.");
}


void loom_semaphore_wait_real(const char *file, int line, SemaphoreHandle s)
{
    int   err;
    sem_t *sem = (sem_t *)s;

    lmAssert(s, "Semaphore must be valid.");
    err = sem_wait(sem);
    lmAssert(err == 0, "Failed to properly wait for semaphore.");
}


void loom_semaphore_destroy_real(const char *file, int line, SemaphoreHandle s)
{
    int   err;
    sem_t *sem = (sem_t *)s;

    lmAssert(s, "Semaphore must be valid.");
    err = sem_destroy(sem);
    lmAssert(err == 0, "Failed to properly destroy semaphore.");
}


void loom_thread_sleep(long ms)
{
    int err = usleep(ms * 1000);

    lmAssert(err == 0, "Failed to sleep for %d ms.", ms);
}


void loom_thread_yield()
{
    int err = sched_yield();

    lmAssert(err == 0, "Failed to yield thread.");
}


int atomic_compareAndExchange(volatile int *value, int expected, int newVal)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    return __sync_val_compare_and_swap(value, expected, newVal);

#else
    // NOTE: Bionic returns a 0 on a successful exchange.
    // c.f. libc/arch-arm/bionic/atomics_arm.S
    // We return the expected value on success.
    // TODO: What should the value returned on a failure be?
    if (__atomic_cmpxchg(expected, newVal, value) == 0)
    {
        return expected;
    }
    else
    {
        return newVal;
    }
#endif
}


int atomic_increment(volatile int *value)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    return __sync_fetch_and_add(value, 1);

#else
    // NOTE: Android's implementation of these functions is atypical in that it returns the
    //  value of the parameter PRIOR to the operation, rather than the value after modification.
    // c.f. http://groups.google.com/group/android-ndk/browse_thread/thread/db9c6e602804540b/1a4e8912a93272fa?pli=1
    // c.f. libc/arch-arm/bionic/atomics_arm.S
    return __atomic_inc(value) + 1;
#endif
}


int atomic_decrement(volatile int *value)
{
#if LOOM_PLATFORM == LOOM_PLATFORM_LINUX
    return __sync_fetch_and_sub(value, 1);

#else
    // NOTE: Android's implementation of these functions is atypical in that it returns the
    //  value of the parameter PRIOR to the operation, rather than the value after modification.
    // c.f. http://groups.google.com/group/android-ndk/browse_thread/thread/db9c6e602804540b/1a4e8912a93272fa?pli=1
    // c.f. libc/arch-arm/bionic/atomics_arm.S
    return __atomic_dec(value) - 1;
#endif
}


int atomic_load32(volatile int *variable)
{
    __sync_synchronize();
    return *variable;
}


void atomic_store32(volatile int *variable, int newValue)
{
    __sync_synchronize();
    *variable = newValue;
    __sync_synchronize();
}


void loom_thread_setDebugName(const char *name)
{
    pthread_setname_np(pthread_self(), name);
}


#else

// Dummy implementation to keep unsupported platforms semi-happy.
//#error "No implementation of threading primitives for this platform."

#include <assert.h>
#include <limits.h>
#include <stdlib.h>
#include "loom/common/core/performance.h"


int platform_getLogicalThreadCount()
{
    return 1;
}


int platform_getCurrentThreadId()
{
    return 1;
}


MutexHandle loom_mutex_create_real(const char *file, int line)
{
    return (void *)1;
}


void loom_mutex_lock_real(const char *file, int line, MutexHandle m)
{
}


void loom_mutex_unlock_real(const char *file, int line, MutexHandle m)
{
}


void loom_mutex_destroy_real(const char *file, int line, MutexHandle m)
{
}


ThreadHandle loom_thread_start(ThreadFunction func, void *param)
{
    assert(0);
    return (void *)1;
}


int loom_thread_getIdFromHandle(ThreadHandle th)
{
    return 1;
}


void loom_thread_join(ThreadHandle th)
{
}


SemaphoreHandle loom_semaphore_create_real(const char *file, int line)
{
    return (void *)1;
}


void loom_semaphore_post_real(const char *file, int line, SemaphoreHandle s)
{
}


void loom_semaphore_wait_real(const char *file, int line, SemaphoreHandle s)
{
}


void loom_semaphore_destroy_real(const char *file, int line, SemaphoreHandle s)
{
}


int atomic_compareAndExchange(volatile int *value, int expected, int newVal)
{
    *value = newVal;
    return expected;
}


int atomic_increment(volatile int *value)
{
    return *value = *value + 1;
}


int atomic_decrement(volatile int *value)
{
    return *value = *value - 1;
}


void loom_thread_sleep(long ms)
{
    printf("WARNING: Skipping sleep for %ld\n", ms);
}


void loom_thread_yield()
{
}


int atomic_load32(volatile int *variable)
{
    return *variable;
}


void atomic_store32(volatile int *variable, int newValue)
{
    *variable = newValue;
}


void loom_thread_setDebugName(ThreadHandle th, const char *name)
{
}


int loom_mutex_trylock_real(const char *file, int line, MutexHandle m)
{
}
#endif
