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

#include "loom/common/core/performance.h"
#include "loom/common/core/log.h"
#include "loom/common/core/allocator.h"
#include "loom/graphics/gfxMath.h"

#include "loom/common/core/telemetry.h"

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

loom_allocator_t *gProfilerAllocator = NULL;

// Enable the profiler from the start of execution. Enable this if you
// want to profile application startup or are tracking down profiler stack
// mismatch issues - when the profiler is enabled LOOM_PROFILE_START and
// LOOM_PROFILE_END are checked to make sure an END is called for every
// START.
//#define LOOM_PROFILE_AT_ENGINE_START 1

#ifndef NPERFORMANCE

#include <stdio.h>
#include "telemetry.h"

// Telemetry state.
static char const *EXAMPLE_NAME     = "engineco";
static char const *kpHost           = "localhost";
HTELEMETRY        gTelemetryContext = NULL;
static TmU8       context_buffer[2 * 1024 * 1024]; // Static context buffer

static void debug_printer(const char *out)
{
    platform_debugOut("TM > %s", out);
}


void performance_initialize()
{
    // Load DLLs.
    if (!tmLoadTelemetry(1))
    {
        platform_debugOut("Could not load telemetry.");
        return;
    }
    else
    {
        tmStartup();

        // We have our memory for a context, but Telemetry needs to initialize it
        tmInitializeContext(&gTelemetryContext, context_buffer, sizeof(context_buffer));
        tmEnable(gTelemetryContext, TMO_OUTPUT_DEBUG_INFO, 1);
        tmSetParameter(gTelemetryContext, TMP_DEBUG_PRINTER, ( void * )debug_printer);

        // Connect to Server at the default port.  We also tell tmOpen to initialize any
        // OS networking services.  We specify an indefinite timeout.
        platform_debugOut("Telemetry connecting to %s", kpHost);
        int error = 1234;
        if ((error = tmOpen(gTelemetryContext, EXAMPLE_NAME, __DATE__ __TIME__, kpHost, TMCT_TCP,
                            TELEMETRY_DEFAULT_PORT, TMOF_MODERATE_CONTEXT_SWITCHES | TMOF_INIT_NETWORKING, -1)) != TM_OK)
        {
            platform_debugOut("... Telemetry connect failed (%d), exiting.", error);
            return;
        }
    }
}


void performance_tick()
{
    tmCheckDebugZoneLevel(gTelemetryContext, 1);
    tmTick(gTelemetryContext);
    tmSetDebugZoneLevel(gTelemetryContext, 1);
}


void performance_shutdown()
{
    tmClose(gTelemetryContext);
    tmShutdownContext(gTelemetryContext);
    tmShutdown();
}
#endif

lmDefineLogGroup(gProfilerLogGroup, "profiler", 1, LoomLogInfo);

void finishProfilerBlock(profilerBlock_t *block)
{
    int curTime = platform_getMilliseconds();

    if (curTime - block->startTime > block->thresholdMs)
    {
        lmLogDebug(gProfilerLogGroup, "%s exceeded threshold (%dms > %dms)", block->name, curTime - block->startTime, block->thresholdMs);
    }
}


//-----------------------------------------------------------------------------

#include <stdlib.h>
#include <string.h>
#include "loom/common/core/assert.h"
#include "loom/common/core/stringTable.h"
#include "loom/common/utils/utTypes.h"

typedef utHashTable<utHashedString, LoomProfilerRoot*> LookupType;

LoomProfilerRoot    *LoomProfilerRoot::sRootList = NULL;
void*                LoomProfilerRoot::sRootLookup = (void*) (lmNew(NULL) LookupType());
LoomProfiler        *gLoomProfiler = NULL;
static LoomProfiler aProfiler; // allocate the global profiler

#if (defined(LOOM_PROFILE_AT_ENGINE_START) && LOOM_PROFILE_AT_ENGINE_START) || defined(LOOM_DEBUG)
#define LOOM_PROFILE_AT_ENGINE_START_INTERNAL true
#else
#define LOOM_PROFILE_AT_ENGINE_START_INTERNAL false
#endif

extern "C" {
    LUA_GC_PROFILE(fullgc)
    LUA_GC_PROFILE(step)
}

LoomProfiler::LoomProfiler()
{
   mMaxStackDepth = MaxStackDepth;
   mCurrentHash = 0;

   mCurrentLoomProfilerEntry = lmNew(gProfilerAllocator) LoomProfilerEntry();
   mCurrentLoomProfilerEntry->mRoot = NULL;
   mCurrentLoomProfilerEntry->mNextForRoot = NULL;
   mCurrentLoomProfilerEntry->mNextLoomProfilerEntry = NULL;
   mCurrentLoomProfilerEntry->mNextHash = NULL;
   mCurrentLoomProfilerEntry->mParent = NULL;
   mCurrentLoomProfilerEntry->mNextSibling = NULL;
   mCurrentLoomProfilerEntry->mFirstChild = NULL;
   mCurrentLoomProfilerEntry->mLastSeenProfiler = NULL;
   mCurrentLoomProfilerEntry->mHash = 0;
   mCurrentLoomProfilerEntry->mSubDepth = 0;
   mCurrentLoomProfilerEntry->mInvokeCount = 0;
   mCurrentLoomProfilerEntry->mTotalTime = 0;
   mCurrentLoomProfilerEntry->mSubTime = 0;
   mCurrentLoomProfilerEntry->mMaxTime = 0;
   mCurrentLoomProfilerEntry->mMinTime = INFINITY;
   mCurrentLoomProfilerEntry->mStartTime = 0.0;
   mRootLoomProfilerEntry = mCurrentLoomProfilerEntry;

   for(U32 i = 0; i < LoomProfilerEntry::HashTableSize; i++)
      mCurrentLoomProfilerEntry->mChildHash[i] = 0;

   mProfileList = NULL;

   mEnabled = LOOM_PROFILE_AT_ENGINE_START_INTERNAL;   

   mNextEnable = LOOM_PROFILE_AT_ENGINE_START_INTERNAL;

   mStackDepth = 0;
   gLoomProfiler = this;
   mDumpToConsole   = false;

   mTimer = loom_startTimer();
}


LoomProfiler::~LoomProfiler()
{
   reset();
   lmSafeDelete(gProfilerAllocator, mRootLoomProfilerEntry);
   gLoomProfiler = NULL;

   loom_destroyTimer(mTimer);
}


void LoomProfiler::dumpToConsole()
{
    mDumpToConsole = true;
}


void LoomProfiler::reset()
{
   mEnabled = false; // in case we're in a profiler call.

   if (mDumpToConsole)
   {
      dump();
   }

   while(mProfileList)
   {
      lmSafeDelete(gProfilerAllocator, mProfileList);
      mProfileList = NULL;
   }
   for(LoomProfilerRoot *walk = LoomProfilerRoot::sRootList; walk; walk = walk->mNextRoot)
   {
      walk->mFirstLoomProfilerEntry = 0;
      walk->mTotalTime = 0;
      walk->mSubTime = 0;
      walk->mMaxTime = 0;
      walk->mMinTime = INFINITY;
      walk->mTotalInvokeCount = 0;
   }
   mCurrentLoomProfilerEntry = mRootLoomProfilerEntry;
   mCurrentLoomProfilerEntry->mNextForRoot = 0;
   mCurrentLoomProfilerEntry->mFirstChild = 0;
   for(U32 i = 0; i < LoomProfilerEntry::HashTableSize; i++)
      mCurrentLoomProfilerEntry->mChildHash[i] = 0;
   mCurrentLoomProfilerEntry->mInvokeCount = 0;
   mCurrentLoomProfilerEntry->mTotalTime = 0;
   mCurrentLoomProfilerEntry->mSubTime = 0;
   mCurrentLoomProfilerEntry->mMaxTime = 0;
   mCurrentLoomProfilerEntry->mMinTime = INFINITY;
   mCurrentLoomProfilerEntry->mSubDepth = 0;
   mCurrentLoomProfilerEntry->mLastSeenProfiler = 0;

   loom_resetTimer(mTimer);
}


LoomProfilerRoot::LoomProfilerRoot(const char *name)
{
    LookupType* lookup = static_cast<LookupType*>(sRootLookup);
    utHashedString key(name);
    bool inserted = lookup->insert(key, this);
    lmAssert(inserted, "Duplicate profile name: %s", name);

    mName                   = name;
    mNameHash               = (int)(long long)stringtable_insert(name); // Poor man's hash
    mNextRoot               = sRootList;
    sRootList               = this;
    mTotalTime              = 0;
    mSubTime                = 0;
    mMaxTime                = 0;
    mMinTime                = INFINITY;
    mTotalInvokeCount       = 0;
    mFirstLoomProfilerEntry = NULL;
    mEnabled                = true;
    mTelemetryVisited       = false;
}

LoomProfilerRoot* LoomProfilerRoot::fromName(const char *name)
{
    LookupType* lookup = static_cast<LookupType*>(sRootLookup);
    utHashedString key(name);
    LoomProfilerRoot* root;
    LoomProfilerRoot** rootp = lookup->get(key);
    if (rootp == NULL)
    {
        root = lmNew(NULL) LoomProfilerRoot(name);
    }
    else
    {
        root = *rootp;
    }
    return root;
}

void LoomProfiler::validate()
{
    for (LoomProfilerRoot *walk = LoomProfilerRoot::sRootList; walk; walk = walk->mNextRoot)
    {
        for (LoomProfilerEntry *dp = walk->mFirstLoomProfilerEntry; dp; dp = dp->mNextForRoot)
        {
            lmAssert(dp->mRoot == walk, "Mismatch");

            // check if it's in the parent's list...
            LoomProfilerEntry *wk;
            for (wk = dp->mParent->mFirstChild; wk; wk = wk->mNextSibling)
            {
                if (wk == dp)
                {
                    break;
                }
            }

            lmAssert(wk, "Validation failed - couldn't find child in its parent's list.");

            for (wk = dp->mParent->mChildHash[walk->mNameHash & (LoomProfilerEntry::HashTableSize - 1)];
                 wk; wk = wk->mNextHash)
            {
                if (wk == dp)
                {
                    break;
                }
            }

            lmAssert(wk, "Validation failed - couldn't find child in its parent's hash.");
        }
    }
}


void LoomProfiler::hashPush(LoomProfilerRoot *root)
{
   Telemetry::beginTickTimer(root);

   mStackDepth++;
   lmAssert(mStackDepth <= (S32) mMaxStackDepth,
                  "Stack overflow in profiler.  You may have mismatched PROFILE_START and PROFILE_ENDs");
   if(!mEnabled)
      return;

   LoomProfilerEntry *nextProfiler = NULL;
   if(!root->mEnabled || mCurrentLoomProfilerEntry->mRoot == root)
   {
      mCurrentLoomProfilerEntry->mSubDepth++;
      return;
   }

   if(mCurrentLoomProfilerEntry->mLastSeenProfiler &&
            mCurrentLoomProfilerEntry->mLastSeenProfiler->mRoot == root)
      nextProfiler = mCurrentLoomProfilerEntry->mLastSeenProfiler;

   if(!nextProfiler)
   {
      // first see if it's in the hash table...
      U32 index = root->mNameHash & (LoomProfilerEntry::HashTableSize - 1);
      
      nextProfiler = mCurrentLoomProfilerEntry->mChildHash[index];
      while(nextProfiler)
      {
         if(nextProfiler->mRoot == root)
            break;
         nextProfiler = nextProfiler->mNextHash;
      }

      if(!nextProfiler)
      {
         nextProfiler = lmNew(gProfilerAllocator) LoomProfilerEntry();
         for(U32 i = 0; i < LoomProfilerEntry::HashTableSize; i++)
            nextProfiler->mChildHash[i] = 0;

         nextProfiler->mRoot = root;
         nextProfiler->mNextForRoot = root->mFirstLoomProfilerEntry;
         root->mFirstLoomProfilerEntry = nextProfiler;

         nextProfiler->mNextLoomProfilerEntry = mProfileList;
         mProfileList = nextProfiler;

         nextProfiler->mNextHash = mCurrentLoomProfilerEntry->mChildHash[index];
         mCurrentLoomProfilerEntry->mChildHash[index] = nextProfiler;

         nextProfiler->mParent = mCurrentLoomProfilerEntry;
         nextProfiler->mNextSibling = mCurrentLoomProfilerEntry->mFirstChild;
         mCurrentLoomProfilerEntry->mFirstChild = nextProfiler;
         nextProfiler->mFirstChild = NULL;
         nextProfiler->mLastSeenProfiler = NULL;
         nextProfiler->mHash = root->mNameHash;
         nextProfiler->mInvokeCount = 0;
         nextProfiler->mTotalTime = 0;
         nextProfiler->mSubTime = 0;
         nextProfiler->mMaxTime = 0;
         nextProfiler->mMinTime = INFINITY;
         nextProfiler->mSubDepth = 0;
      }
   }

   root->mTotalInvokeCount++;
   nextProfiler->mInvokeCount++;
   
   nextProfiler->mStartTime = loom_readTimerNano(mTimer);

   mCurrentLoomProfilerEntry->mLastSeenProfiler = nextProfiler;
   mCurrentLoomProfilerEntry = nextProfiler;
}


void LoomProfiler::enable(bool enabled)
{
    mNextEnable = enabled;
}


void LoomProfiler::hashPop(LoomProfilerRoot *expected)
{
    Telemetry::endTickTimer(expected);

    mStackDepth--;

    lmAssert(mStackDepth >= 0, "Stack underflow in profiler.  You may have mismatched PROFILE_START and PROFILE_ENDs");
    if (mEnabled)
    {
        if (mCurrentLoomProfilerEntry->mSubDepth)
        {
            mCurrentLoomProfilerEntry->mSubDepth--;
            return;
        }

        if (expected)
        {
            lmAssert(expected == mCurrentLoomProfilerEntry->mRoot, "LoomProfiler::hashPop - didn't get expected ProfilerRoot!");
        }

        F64 fElapsed = loom_readTimerNano(mTimer) - mCurrentLoomProfilerEntry->mStartTime;

        lmAssert(fElapsed >= 0, "Elapsed time should be positive - is %f", fElapsed);

        mCurrentLoomProfilerEntry->mTotalTime        += fElapsed;
        mCurrentLoomProfilerEntry->mParent->mSubTime += fElapsed; // mark it in the parent as well...
        mCurrentLoomProfilerEntry->mRoot->mTotalTime += fElapsed;
        mCurrentLoomProfilerEntry->mMaxTime = fElapsed > mCurrentLoomProfilerEntry->mMaxTime ? fElapsed : mCurrentLoomProfilerEntry->mMaxTime;
        mCurrentLoomProfilerEntry->mMinTime = fElapsed < mCurrentLoomProfilerEntry->mMinTime ? fElapsed : mCurrentLoomProfilerEntry->mMinTime;
        mCurrentLoomProfilerEntry->mRoot->mMaxTime = fElapsed > mCurrentLoomProfilerEntry->mRoot->mMaxTime ? fElapsed : mCurrentLoomProfilerEntry->mRoot->mMaxTime;
        mCurrentLoomProfilerEntry->mRoot->mMinTime = fElapsed < mCurrentLoomProfilerEntry->mRoot->mMinTime ? fElapsed : mCurrentLoomProfilerEntry->mRoot->mMinTime;
        if (mCurrentLoomProfilerEntry->mParent->mRoot)
        {
            mCurrentLoomProfilerEntry->mParent->mRoot->mSubTime += fElapsed; // mark it in the parent as well...
        }
        mCurrentLoomProfilerEntry = mCurrentLoomProfilerEntry->mParent;
    }

    if (mStackDepth == 0)
    {
        // apply the next enable...
        if (mDumpToConsole)
        {
            dump();
            mCurrentLoomProfilerEntry->mStartTime = loom_readTimerNano(mTimer);
        }
        if (!mEnabled && mNextEnable)
        {
            mCurrentLoomProfilerEntry->mStartTime = loom_readTimerNano(mTimer);
        }

        mEnabled = mNextEnable;
    }
}

void LoomProfiler::hashZeroCheck()
{
    if (mStackDepth != 0)
    {
        // If you get this assert, it means you probably have mismatched LOOM_PROFILE_START
        // and LOOM_PROFILE_END blocks. Enable LOOM_PROFILE_AT_ENGINE_START (see #define at top
        // of file) to get a breakpoint on the exact mismatching LOOM_PROFILE_END.
        lmAssert(false, "Profiler zero stack check failed: %s",
            mCurrentLoomProfilerEntry == NULL ? "[entry NULL]" :
            mCurrentLoomProfilerEntry->mRoot == NULL ? "[entry root NULL] (try compiling as a debug build or with LOOM_PROFILE_AT_ENGINE_START enabled for more info)" :
            mCurrentLoomProfilerEntry->mRoot->mName
        );
    }
    
}

static S32 rootDataCompare(const void *s1, const void *s2)
{
    const LoomProfilerRoot *r1 = *((LoomProfilerRoot **)s1);
    const LoomProfilerRoot *r2 = *((LoomProfilerRoot **)s2);

    if ((r2->mTotalTime - r2->mSubTime) > (r1->mTotalTime - r1->mSubTime))
    {
        return 1;
    }
    return -1;
}


static int suppressedEntries;

static void LoomProfilerEntryDumpRecurse(LoomProfilerEntry *data, char *buffer, U32 bufferLen, F64 totalTime, float threshold)
{
    float tm = (float)(data->mRoot == NULL ? 100.0 : 100.0 * data->mTotalTime / totalTime);

    if (tm < threshold)
    {
        suppressedEntries++;
    }
    else
    {
        // dump out this one:
        lmLogInfo(gProfilerLogGroup, "%8.3f %8.3f %8.3f %8.3f %8.3f %8d %s%s",
                   data->mRoot == NULL ? 100.0 : 100.0 * data->mTotalTime / totalTime,
                   data->mRoot == NULL ? 100.0 : 100.0 * (data->mTotalTime - data->mSubTime) / totalTime,
                   data->mTotalTime / (1000.0 * 1000.0 * (data->mInvokeCount > 0 ? data->mInvokeCount : 1)),
                   data->mMaxTime / (1000.0 * 1000.0),
                   data->mMinTime / (1000.0 * 1000.0),
                   data->mInvokeCount,
                   buffer,
                   data->mRoot ? data->mRoot->mName : "ROOT");
    }

    data->mTotalTime = 0;
    data->mSubTime = 0;
    data->mMaxTime = 0;
    data->mMinTime = INFINITY;
    data->mInvokeCount = 0;

    buffer[bufferLen]     = ' ';
    buffer[bufferLen + 1] = ' ';
    buffer[bufferLen + 2] = 0;

    // sort data's children...
    LoomProfilerEntry *list = NULL;

    while (data->mFirstChild)
    {
        LoomProfilerEntry *ins = data->mFirstChild;
        data->mFirstChild = ins->mNextSibling;
        LoomProfilerEntry **walk = &list;
        while (*walk && (*walk)->mTotalTime > ins->mTotalTime)
        {
            walk = &(*walk)->mNextSibling;
        }
        ins->mNextSibling = *walk;
        *walk             = ins;
    }

    data->mFirstChild = list;

    while (list)
    {
        if (list->mInvokeCount)
        {
            LoomProfilerEntryDumpRecurse(list, buffer, bufferLen + 2, totalTime, threshold);
        }
        list = list->mNextSibling;
    }
    buffer[bufferLen] = 0;
}


void LoomProfiler::dump()
{
    LOOM_PROFILE_ZERO_CHECK()

    bool enableSave = mEnabled;

    mEnabled = false;
    mStackDepth++;

    // may have some profiled calls... gotta turn em off.

    utArray<LoomProfilerRoot *> rootVector;
    F64 totalTime = 0.0;
    for (LoomProfilerRoot *walk = LoomProfilerRoot::sRootList; walk; walk = walk->mNextRoot)
    {
        if (walk->mTotalInvokeCount == 0)
        {
            continue;
        }

        totalTime += walk->mTotalTime - walk->mSubTime;
        lmAssert(totalTime == totalTime, "Got a bad LoomProfilerRoot!"); // NaN is always inequal to itself.
        rootVector.push_back(walk);
    }

    qsort((void *)&rootVector[0], rootVector.size(), sizeof(LoomProfilerRoot *), rootDataCompare);

    lmLogInfo(gProfilerLogGroup, "");
    lmLogInfo(gProfilerLogGroup, "Profiler Data Dump:");
    lmLogInfo(gProfilerLogGroup, "Ordered by non-sub total time -");
    lmLogInfo(gProfilerLogGroup, "%%NSTime  %% Time  AvgTime  MaxTime  MinTime Invoke # Name");
                                   

    suppressedEntries = 0;

    float threshold = 0.1f;

    for (U32 i = 0; i < rootVector.size(); i++)
    {
        LoomProfilerRoot *root = rootVector[i];
        float tm = (float)(100.0 * (root->mTotalTime - root->mSubTime) / totalTime);
        if (tm >= threshold)
        {
            lmLogInfo(gProfilerLogGroup, "%7.3f %7.3f %8.3f %8.3f %8.3f %8d %s",
                       100.0 * (root->mTotalTime - root->mSubTime) / totalTime,
                       100.0 * root->mTotalTime / totalTime,
                       root->mTotalTime / (1000.0 * 1000.0 * (root->mTotalInvokeCount > 0 ? root->mTotalInvokeCount : 1)),
                       root->mMaxTime / (1000.0 * 1000.0),
                       root->mMinTime / (1000.0 * 1000.0),
                       root->mTotalInvokeCount,
                       root->mName);
        }
        else
        {
            suppressedEntries++;
        }

        root->mTotalInvokeCount = 0;
        root->mTotalTime = 0;
        root->mSubTime = 0;
        root->mMaxTime = 0;
        root->mMinTime = INFINITY;
    }
    lmLogInfo(gProfilerLogGroup, "Suppressed %i items with < %.1f%% of measured time.", suppressedEntries, threshold);
    lmLogInfo(gProfilerLogGroup, "");
    lmLogInfo(gProfilerLogGroup, "Ordered by stack trace total time -");
    lmLogInfo(gProfilerLogGroup, "  %% Time %% NSTime  AvgTime  MaxTime  MinTime Invoke # Name");

    mCurrentLoomProfilerEntry->mTotalTime = loom_readTimerNano(mTimer);

    char depthBuffer[MaxStackDepth * 2 + 1];
    depthBuffer[0]    = 0;
    suppressedEntries = 0;
    LoomProfilerEntryDumpRecurse(mCurrentLoomProfilerEntry, depthBuffer, 0, totalTime, threshold);
    lmLogInfo(gProfilerLogGroup, "Suppressed %i items with < %.1f%% of measured time.", suppressedEntries, threshold);

    mEnabled = enableSave;
    mStackDepth--;

    mDumpToConsole = false;
}
