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
#include "loom/common/core/log.h"
#include "loom/script/native/lsLuaBridge.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/native/lsNativeDelegate.h"


lmDefineLogGroup(gNativeDelegateGroup, "script.native", 1, LoomLogInfo);


namespace LS {
utHashTable<utPointerHashKey, utArray<NativeDelegate *> *> NativeDelegate::sActiveNativeDelegates;
static const int scmBadThreadID = 0xBAADF00D;
int              NativeDelegate::smMainThreadID = scmBadThreadID;

// todo
//   - handles to active nativedelegates (rw from main thread, ro from secondary)
//      - store pointer and counter
//      - each instance gets unique count
//      - check instance in the sActiveNativeDelegates list before calling
//   - locked queue of pending calls and args
//      - write out preamble + delegate id 
//      - write out arg type + value into buffer
//      - write out postamble
//      - realloc as needed
//      - keep vector of pending calls
//   - delayed call executor routine
//      - loop queue
//      - check and call each delegate, warn-skip if no good
//      - clear queue

struct NativeDelegateCallNote
{
    const NativeDelegate *delegate;
    int delegateKey;
    unsigned char *data;
    int ndata;
    int offset;

    NativeDelegateCallNote(const NativeDelegate *target)
    {
        delegate = target;
        delegateKey = target->_key;
        ndata = 1024;
        data = (unsigned char*)malloc(ndata);
        offset = 0;
    }

    ~NativeDelegateCallNote()
    {
        delegate = NULL;
        delegateKey = -1;
        if(data)
        {        
            free(data);
            data = NULL;
        }
        ndata = -1;
        offset = -1;
    }

    void ensureBuffer(int freeBytes)
    {
        // Nop if enough free space.
        if(offset+freeBytes<ndata)
            return;

        ndata *= 2; // Pow 2 growth factor - dumb but effective.
        data = (unsigned char*)lmRealloc(NULL, data, ndata);
    }

    void writeByte(unsigned char value)
    {
        ensureBuffer(1);
        data[offset] = value;
        offset++;
    }

    void writeInt(unsigned int value)
    {
        ensureBuffer(4);
        memcpy(&data[offset], &value, sizeof(unsigned int));
        offset += 4;
    }

    void writeFloat(float value)
    {
        ensureBuffer(4);
        memcpy(&data[offset], &value, sizeof(float));
        offset += 4;
    }

    void writeDouble(double value)
    {
        ensureBuffer(8);
        memcpy(&data[offset], &value, sizeof(double));
        offset += 8;
    }

    void writeString(const char *value)
    {
        writeInt(strlen(value));
        for(int i=0; i<strlen(value); i++)
            writeByte(value[i]);
    }

    void writeBool(bool value)
    {
        if(value)
            writeByte(1);
        else
            writeByte(0);
    }

    void rewind()
    {
        offset = 0;
    }

    unsigned char readByte()
    {
        //assert(offset + 1 < ndata);
        unsigned char v = data[offset];
        offset ++;
        return v;
    }

    unsigned int readInt()
    {
        //assert(offset + 4 < ndata);
        int v = 0;
        memcpy(&v, &data[offset], sizeof(unsigned int));
        offset += 4;
        return v;
    }

    float readFloat()
    {
        //assert(offset + 4 < ndata);
        float v = 0.f;
        memcpy(&v, &data[offset], sizeof(float));
        offset += 4;
        return v;
    }

    double readDouble()
    {
        //assert(offset + 8 < ndata);
        double v = 0.0;
        memcpy(&v, &data[offset], sizeof(double));
        offset += 8;
        return v;
    }

    // Don't forget to free()
    char *readString()
    {
        int strLen = readInt();
        char *str = (char*)malloc(strLen+1);
        memset(str, 0, strLen+1);
        for(int i=0; i<strLen; i++)
            str[i] = readByte();
        return str;
    }

    bool readBool()
    {
        return readByte() == 0 ? false : true;
    }
};

enum
{
    MSG_Nop = 0,
    MSG_PushInt,
    MSG_PushFloat,
    MSG_PushDouble,
    MSG_PushString,
    MSG_PushBool,
    MSG_Invoke,
};

static MutexHandle gCallNoteMutex = NULL;
static utArray<NativeDelegateCallNote*> gNDCallNoteQueue;

static void ensureQueueInit()
{
    if(gCallNoteMutex)
        return;

    gCallNoteMutex = loom_mutex_create();
}

void NativeDelegate::postNativeDelegateCallNote(NativeDelegateCallNote *ndcn)
{
    ensureQueueInit();

    loom_mutex_lock(gCallNoteMutex);

    // Prep for reading.
    ndcn->rewind();

    // Store for later access.
    gNDCallNoteQueue.push_back(ndcn);

    loom_mutex_unlock(gCallNoteMutex);
}

void NativeDelegate::executeDeferredCalls(lua_State *L)
{
    ensureQueueInit();

    loom_mutex_lock(gCallNoteMutex);

    for(int i=0; i<gNDCallNoteQueue.size(); i++)
    {
        NativeDelegateCallNote *ndcn = gNDCallNoteQueue[i];

        // Try to resolve the delegate pointer.
        utArray<NativeDelegate *> *delegates = NULL;
        if (sActiveNativeDelegates.find(L) != UT_NPOS)
        {
            delegates = *(sActiveNativeDelegates.get(L));
        }
        else
        {
            // No delegate list, can't do it.
            loom_mutex_unlock(gCallNoteMutex);
            return;
        }
        
        bool found = false;
        for(int i=0; i<delegates->size(); i++)
        {
            // Look for our delegate.
            if((*delegates)[i] != ndcn->delegate)
                continue;

            // If key mismatches, warn and bail.
            if((*delegates)[i]->_key != ndcn->delegateKey)
            {
                LSError("Found delegate call note with key mismatch (delegate=%x actualKey=%x expectedKey=%x), ignoring...", (*delegates)[i], (*delegates)[i]->_key, ndcn->delegateKey);
                break;
            }

            // Match!
            found = true;
            break;
        }

        // Bail if no match.
        if(!found)
            continue;

        // Otherwise, let's call it.
        const NativeDelegate *theDelegate = ndcn->delegate;
        for(;;)
        {
            unsigned char actionType = ndcn->readByte();
            bool done = false;
            char *str = NULL;
            switch(actionType)
            {
                case MSG_Nop:
                    LSError("Got a nop in delegate data stream.");
                break;

                case MSG_PushString:
                    str = ndcn->readString();
                    theDelegate->pushArgument(str);
                    free(str);
                break;

                case MSG_PushDouble:
                    theDelegate->pushArgument(ndcn->readDouble());
                    break;

                case MSG_PushFloat:
                    theDelegate->pushArgument(ndcn->readFloat());
                    break;
                
                case MSG_PushInt:
                    theDelegate->pushArgument((int)ndcn->readInt());
                    break;
                
                case MSG_PushBool:
                    theDelegate->pushArgument(ndcn->readBool());
                    break;

                case MSG_Invoke:
                    theDelegate->invoke();
                    done = true;
                    break;
            }

            if(done)
                break;
        }

    }

    // Purge queue.
    gNDCallNoteQueue.clear();

    loom_mutex_unlock(gCallNoteMutex);
}

// To disambiguate NativeDelegates at the address of old NDs, we have a key.
// in order to collide you have to allocate and free 4 billion NDs and get the same address
// on the 4 billionth ND as you did on the first. If you get a crash due to this coincidence,
// I'll buy you something nice.
static int gNativeDelegateKeyGenerator = 1000;

NativeDelegate::NativeDelegate()
    : L(NULL), _callbackCount(0), _isAsync(false), _argumentCount(0), _activeNote(NULL), _key(gNativeDelegateKeyGenerator++)
{
}

void NativeDelegate::allowAsync()
{
    lmLogError(gNativeDelegateGroup, "SETTING ASYNC ON %x", this);
    _isAsync = true;
}

void NativeDelegate::createCallbacks()
{
    //lmAssert(gNativeDelegateMainThread == platform_getCurrentThreadId(), "Working with a NativeDelegate outside of the main thread!");

    if (!L)
    {
        LSError("NativeDelegate attempting to create callbacks table without valid VM");
    }

    // we must create a lua table to hold our script callbacks
    // these cannot be held in the context of the script binding
    // as they may change/be stripped via mechanisms of pure native
    // handling
    int top = lua_gettop(L);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);
    lua_pushlightuserdata(L, this);
    lua_newtable(L);
    lua_newtable(L);
    lua_rawseti(L, -2, LSINDEXNATIVEDELEGATECALLBACKS);
    lua_settable(L, -3);
    lua_settop(L, top);
}


void NativeDelegate::registerDelegate(lua_State *L, NativeDelegate *delegate)
{
    assertMainThread();

    utArray<NativeDelegate *> *delegates = NULL;

    if (sActiveNativeDelegates.find(L) != UT_NPOS)
    {
        delegates = *(sActiveNativeDelegates.get(L));
    }

    if (!delegates)
    {
        delegates = new utArray<NativeDelegate *>;
        sActiveNativeDelegates.insert(L, delegates);
    }

    delegates->push_back(delegate);
}


void NativeDelegate::setVM(lua_State *vm, bool newCallbacks)
{
    if (L)
    {
        if (newCallbacks)
        {
            createCallbacks();
        }
        return;
    }

    L = vm;

    registerDelegate(vm, this);

    // first time we're setting VM, so make sure callbacks table exists
    createCallbacks();
}


void NativeDelegate::getCallbacks(lua_State *L) const
{
    lua_pushnil(L);
    int top = lua_gettop(L);

    lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);
    lua_pushlightuserdata(L, (void *)this);
    lua_gettable(L, -2);
    lua_rawgeti(L, -1, LSINDEXNATIVEDELEGATECALLBACKS);
    lua_replace(L, top);
    lua_settop(L, top);
}


NativeDelegateCallNote *NativeDelegate::prepCallbackNote() const
{
    lmLogError(gNativeDelegateGroup, "Considering async callback %x", this);
    
    // Are noting currently? Just work with that.
    if(_activeNote)
    {
        lmLogError(gNativeDelegateGroup, " OUT 1");
        return _activeNote;
    }

    // See if we should try to go async.
    if(_isAsync == false)
    {
        lmLogError(gNativeDelegateGroup, " OUT 2");
        return NULL;
    }

    if(smMainThreadID == platform_getCurrentThreadId())
        return NULL;

    // Only do this for async delegates off main thread.
    lmLogError(gNativeDelegateGroup, "Queueing async callback");
    _activeNote = lmNew(NULL) NativeDelegateCallNote(this);
    return _activeNote;
}

void NativeDelegate::pushArgument(const char *value) const
{
    if(NativeDelegateCallNote *ndcn = prepCallbackNote())
    {
        ndcn->writeByte(MSG_PushString);
        ndcn->writeString(value);
        return;
    }

    if (!L)
        return;

    lua_pushstring(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(int value) const
{
    if(NativeDelegateCallNote *ndcn = prepCallbackNote())
    {
        ndcn->writeByte(MSG_PushInt);
        ndcn->writeInt(value);
        return;
    }

    if (!L)
        return;

    lua_pushinteger(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(float value) const
{
    if(NativeDelegateCallNote *ndcn = prepCallbackNote())
    {
        ndcn->writeByte(MSG_PushFloat);
        ndcn->writeFloat(value);
        return;
    }

    if (!L)
        return;

    lua_pushnumber(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(double value) const
{
    if(NativeDelegateCallNote *ndcn = prepCallbackNote())
    {
        ndcn->writeByte(MSG_PushDouble);
        ndcn->writeDouble(value);
        return;
    }

    if (!L)
        return;

    lua_pushnumber(L, value);
    _argumentCount++;
}


void NativeDelegate::pushArgument(bool value) const
{
    if(NativeDelegateCallNote *ndcn = prepCallbackNote())
    {
        ndcn->writeByte(MSG_PushBool);
        ndcn->writeBool(value);
        return;
    }

    if (!L)
        return;

    lua_pushboolean(L, value);
    _argumentCount++;
}


int NativeDelegate::getCount() const
{
    return _callbackCount;
}


// We don't currently support return values as this makes it the responsibility
// of the caller to clean up the stack, this can be changed if we automate
void NativeDelegate::invoke () const
{
    if(NativeDelegateCallNote *ndcn = prepCallbackNote())
    {
        ndcn->writeByte(MSG_Invoke);

        // Submit it and clear state.
        postNativeDelegateCallNote(ndcn);
        _activeNote = NULL;
        return;
    }

    // Don't do this from non-main thread.
    assertMainThread();

    // if we have no callbacks defined, the VM state will be NULL
    if (!L)
    {
        // Even if we don't do anything, need to reset arg count.
        _argumentCount = 0;
        return;
    }

    int top = lua_gettop(L);

    int numArgs = _argumentCount;

    // Reset argument count, so recursion is properly handled
    _argumentCount = 0;

    getCallbacks(L);

    int tidx = lua_gettop(L);

    if (!lua_istable(L, tidx))
    {
        LSError("Error getting native delegate callback table");
    }

    for (int i = 0; i < _callbackCount; i++)
    {
        lua_pushnumber(L, (double)i);
        lua_gettable(L, tidx);

        int t = lua_gettop(L);

        for (int i = top - numArgs; i < top; i++)
        {
            lua_pushvalue(L, i + 1);
        }

        lua_call(L, numArgs, 1);

        lua_settop(L, t);

        /* removes last lua_function called */
        lua_pop(L, 1);
    }

    lua_settop(L, top);

    // clean up arguments off stack
    lua_pop(L, numArgs);
}


int NativeDelegate::__op_assignment(lua_State *L)
{
    NativeDelegate *delegate = (NativeDelegate *)lualoom_getnativepointer(L, 1,
                                                                          true, "system.NativeDelegate");

    if (!delegate)
    {
        LSError("Unable to get native delegate on += operator");
    }

    // set the VM, and recreate callbacks table
    delegate->setVM(L, true);

    delegate->getCallbacks(L);

    if (!lua_istable(L, -1))
    {
        LSError("Bad native delegates table");
    }

    // clear current callbacks
    for (int i = 0; i < delegate->_callbackCount; i++)
    {
        lua_pushnumber(L, (double)i);
        lua_pushnil(L);
        lua_settable(L, -3);
    }

    // reset
    delegate->_callbackCount = 0;

    if (lua_isnil(L, 2))
    {
        return 0;
    }

    if (!lua_isfunction(L, 2) && !lua_iscfunction(L, 2))
    {
        LSError("Unknown type on NativeDelegate assignment operator");
    }

    // add the lua function or cfunction to our delegate's callback table
    lua_pushnumber(L, (double)0);
    lua_pushvalue(L, 2);
    lua_settable(L, -3);
    lua_pop(L, 1);
    // pop __lscallbacks

    delegate->_callbackCount++;

    return 0;
}


int NativeDelegate::__op_minusassignment(lua_State *L)
{
    NativeDelegate *delegate = (NativeDelegate *)lualoom_getnativepointer(L, 1,
                                                                          "system.NativeDelegate");

    if (!delegate)
    {
        LSError("Unable to get native delegate on += operator");
    }

    if (!delegate->_callbackCount)
    {
        return 0;
    }

    delegate->setVM(L);

    delegate->getCallbacks(L);

    int tidx = lua_gettop(L);

    if (!lua_istable(L, tidx))
    {
        LSError("Bad native delegates table");
    }

    if (lua_isfunction(L, 2) || lua_iscfunction(L, 2))
    {
        int idx = -1;
        for (int i = 0; i < delegate->_callbackCount; i++)
        {
            lua_rawgeti(L, tidx, i);
            if (lua_equal(L, 2, -1))
            {
                idx = i;
                lua_pop(L, 1);
                break;
            }
            lua_pop(L, 1);
        }


        // this function was never added in the first place
        if (idx == -1)
        {
            return 0;
        }

        // shift the other delegates down
        lua_pushnumber(L, (double)idx);
        lua_pushnil(L);
        lua_settable(L, tidx);

        int ntable = 0;
        if (delegate->_callbackCount > 1)
        {
            // temp table
            lua_newtable(L);
            ntable = lua_gettop(L);

            int c = 0;
            for (int nidx = 0; nidx < delegate->_callbackCount; nidx++)
            {
                lua_pushnumber(L, (double)nidx);
                lua_gettable(L, tidx);
                if (lua_isnil(L, -1))
                {
                    lua_pop(L, 1);
                    continue;
                }

                lua_pushnumber(L, (double)c);
                lua_pushvalue(L, -2);
                lua_settable(L, ntable);
                // pop lua_function
                lua_pop(L, 1);
                c++;
            }
        }

        // clear it
        delegate->_callbackCount--;

        // and copy from new temp table
        for (int nidx = 0; nidx < delegate->_callbackCount; nidx++)
        {
            lua_pushnumber(L, (double)nidx);
            lua_pushnumber(L, (double)nidx);
            lua_gettable(L, ntable);
            lua_settable(L, tidx);
        }
    }
    else
    {
        LSError("Unknown type on NativeDelegate -= operator");
    }

    return 0;
}


int NativeDelegate::__op_plusassignment(lua_State *L)
{
    NativeDelegate *delegate = (NativeDelegate *)lualoom_getnativepointer(L, 1,
                                                                          "system.NativeDelegate");

    if (!delegate)
    {
        LSError("Unable to get native delegate on += operator");
    }

    delegate->setVM(L);

    delegate->getCallbacks(L);

    int tidx = lua_gettop(L);

    if (!lua_istable(L, -1))
    {
        LSError("Bad native delegates table");
    }

    if (lua_isfunction(L, 2) || lua_iscfunction(L, 2))
    {
        // check if we already added this callback
        for (int i = 0; i < delegate->_callbackCount; i++)
        {
            lua_rawgeti(L, tidx, i);
            if (lua_equal(L, 2, -1))
            {
                lua_pop(L, 1);
                return 0; // already added
            }
            lua_pop(L, 1);
        }

        // add the lua function or cfunction to our delegate's callback table
        lua_pushnumber(L, (double)delegate->_callbackCount++);
        lua_pushvalue(L, 2);
        lua_settable(L, -3);
        lua_pop(L, 1);
        // pop __lscallbacks
    }
    else
    {
        LSError("Unknown type on NativeDelegate += operator");
    }

    return 0;
}


void NativeDelegate::invalidate()
{
    _callbackCount = 0;

    if (L)
    {
        lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXNATIVEDELEGATES);
        lua_pushlightuserdata(L, this);
        lua_pushnil(L);
        lua_settable(L, -3);
        lua_pop(L, 1);
    }

    L = NULL;
}


void NativeDelegate::invalidateLuaStateDelegates(lua_State *L)
{
    utArray<NativeDelegate *> *delegates = NULL;

    if (sActiveNativeDelegates.find(L) != UT_NPOS)
    {
        delegates = *(sActiveNativeDelegates.get(L));
    }

    if (delegates)
    {
        for (UTsize i = 0; i < delegates->size(); i++)
        {
            NativeDelegate *delegate = delegates->at(i);
            delegate->invalidate();
        }

        sActiveNativeDelegates.erase(L);
        delete delegates;
    }
}


NativeDelegate::~NativeDelegate()
{
    // If we are in the native delegate list, remove ourselves.
    utArray<NativeDelegate *> *delegates = NULL;
    if (sActiveNativeDelegates.find(L) != UT_NPOS)
    {
        delegates = *(sActiveNativeDelegates.get(L));
    }

    if (delegates)
    {
        UTsize idx = delegates->find(this);
        if(idx != UT_NPOS)
            delegates->erase(idx);
    }

    // And clean up our Lua VM state.
    invalidate();
}


void NativeDelegate::markMainThread()
{
    smMainThreadID = platform_getCurrentThreadId();
}


void NativeDelegate::assertMainThread()
{
    if(smMainThreadID == scmBadThreadID)
    {
        lmLogWarn(gNativeDelegateGroup,
                 "Tried to touch a NativeDelegate before the main thread was marked. "
                 "Probably need to add a markMainThread call?");
    }

    if( smMainThreadID != platform_getCurrentThreadId())
    {
        lmLogWarn(gNativeDelegateGroup,
                 "Trying to fire a NativeDelegate from thread %x that is not the main "
                 "thread %x. This will result in memory corruption and race conditions!",
                platform_getCurrentThreadId(), smMainThreadID);
    }
}
}
