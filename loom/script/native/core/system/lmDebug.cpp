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


#include "loom/script/loomscript.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/native/lsNativeDelegate.h"

using namespace LS;

/*
 * Provides low level debugger services which are implemented in native code for speed
 */
class Debug {
    // event types provided by the debug hook include
    // line, call, return, and assert events
    enum EventType
    {
        LINE_EVENT,
        CALL_EVENT,
        RETURN_EVENT,
        ASSERT_EVENT,
    };

    // breakpoint structure
    struct Breakpoint
    {
        // the path the source file as seen by the compiler
        // for instance src/MyGame.ls
        utString source;

        // the line number in the source file
        int      line;
    };

public:

    // scripts may listen to these natve delegates
    // to get notified of line, call, return, and assert events
    static NativeDelegate lineEventDelegate;
    static NativeDelegate callEventDelegate;
    static NativeDelegate returnEventDelegate;
    static NativeDelegate assertEventDelegate;

    // List of all breakpoints
    static utList<Breakpoint *> breakpoints;

    // Fast lookup of source file breakpoints
    static utHashTable<utFastStringHash, utArray<Breakpoint *> > sourceBreakpoints;

    // cached to avoid duplicate line events for same line
    static char lastSourceEvent[2048];
    static int  lastLineEvent;

    // if true, we are running under the debugger
    static bool debuggerRunning;

    // if true, an assertion event has happened
    // this is a fatal error that we can inspect the state
    // however, execution is frozen at this point
    static bool assertion;

    // if true, we're blocking this means that the debugger routine is controlling
    // execution of the main "thread"
    static bool blocking;

    // if true, we are stepping through the code line by line
    static bool stepping;

    // if true, step over calls, otherwise step into calls
    static bool stepOver;

    // true if we have caught a Debug.debug() call
    static bool debugBreak;

    // if we have exeuted a finish command or are steping over methods, this
    // the the method to finish before breaking back into debugger
    static MethodBase *finishMethod;

    // callstack info is captured using this structure
    struct _CallStackInfo
    {
        // the source file of the stack frame
        const char *source;
        // the line number of the stack frame
        int        line;
        // the LoomScript method of the stack frame
        MethodBase *method;
    };

    // up to 256 levels of stack
#define MAX_CALLSTACK    256

    // some method's are filtered as we do not want the debugger to trace into them
    // to avoid infinite recursion and other nastiness
    static bool filterMethodBase(MethodBase *methodBase)
    {
        const char *name = methodBase->getDeclaringType()->getName();

        if (!strcmp(name, "Vector"))
        {
            return true;
        }

        if (!strcmp(name, "Coroutine"))
        {
            return true;
        }

        if (!strcmp(name, "Debug"))
        {
            return true;
        }

        if (!strcmp(name, "DebuggerClient"))
        {
            return true;
        }

        if (!strcmp(name, "Breakpoint"))
        {
            return true;
        }

        return false;
    }
    
    static int getCallStackInfo(lua_State *L)
    {
        return getCallStack(L, ASSERT_EVENT);
    }

    // retrieve a Vector of callstack info, or nil in the case of an invalid stack
    static int getCallStack(lua_State *L, EventType eventType)
    {
        int top = lua_gettop(L);

        lua_Debug ar;

        int            nstack = 0;
        _CallStackInfo cstack[MAX_CALLSTACK];

        // look for method infos
        for (int i = 0; i < MAX_CALLSTACK; i++)
        {
            // if we get a null result here, we are out of stack
            if (!lua_getstack(L, i, &ar))
            {
                break;
            }

            // get function, source, and line
            if (!lua_getinfo(L, "fSl", &ar))
            {
                continue;
            }

            // if we're a cfunction we're not interested in debugging it
            // as we're a LoomScript debugger!
            if (lua_iscfunction(L, -1))
            {
                lua_pop(L, 1);

                // if we are at the top of the stack and we are not an assert event
                // return a null stack as this isn't an interesting stack to the
                // debugger
                if (!i && (eventType != ASSERT_EVENT))
                {
                    lua_pushnil(L);
                    return 1;
                }
                continue;
            }

            // lookup the stack frame's function in the global
            // function table
            lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
            lua_pushvalue(L, -2);
            lua_rawget(L, -2);

            // if we aren't found in the global functions
            if (lua_isnil(L, -1))
            {
                // we are at the top of the stack, so this is an invalid stack
                if (!i)
                {
                    break;
                }

                lua_pop(L, 2);
                continue;
            }

            // get the MethodBase
            MethodBase *methodBase = (MethodBase *)lua_topointer(L, -1);

            // if we're native and at the top of the stack, invalid stack
            if (!i && methodBase->isNative())
            {
                break;
            }

            // if we should filter, we need to stop here
            if (filterMethodBase(methodBase))
            {
                break;
            }

            // store out the stack info to our stack array
            _CallStackInfo *cs = &cstack[nstack++];

            cs->method = methodBase;

            if (!methodBase->isNative())
            {
                cs->source = ar.source;
                cs->line   = ar.currentline;
            }
            else
            {
                cs->source = "[Native]";
                cs->line   = 0;
            }

            // early our for line events when we have no breakpoints
            // and haven't hit a Debug.debug()
            if (eventType == LINE_EVENT)
            {
                // check breakpoints
                if (!i && !stepping)
                {
                    // we only stop on a breakpoint
                    if (!hasBreakpoint(cs->source, cs->line) && !debugBreak)
                    {
                        lastSourceEvent[0] = 0;
                        lua_pushnil(L);
                        return 1;
                    }
                }
            }

            lua_pop(L, 3);

            // pop the function, methodbase, and methodlookup
        }

        lua_settop(L, top); // reset stack

        // did we get anything, if not bail early
        if (!nstack)
        {
            lua_pushnil(L);
            return 1;
        }


        // check if the event is from the same line/source as last event
        _CallStackInfo *cs = &cstack[0];

        if (eventType == LINE_EVENT)
        {
            // we have a match, so bail
            if (!strcmp(lastSourceEvent, cs->source) && (lastLineEvent == cs->line))
            {
                lua_pushnil(L);
                return 1;
            }

            // cache for next line event
            lmAssert(strlen(cs->source) < 2000, "source file > 2000 charaters");
            strcpy(lastSourceEvent, cs->source);
            lastLineEvent = cs->line;
        }
        else
        {
            // clear cached event
            lastSourceEvent[0] = 0;
            lastLineEvent      = -1;
        }

        // We return a Vector.<CallStackInfo>

        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");
        Type *csiType    = LSLuaState::getLuaState(L)->getType(
            "system.CallStackInfo");

        int sourceOrdinal = csiType->getMemberOrdinal("source");
        int lineOrdinal   = csiType->getMemberOrdinal("line");
        int methodOrdinal = csiType->getMemberOrdinal("method");


        // create the vector instance
        lsr_createinstance(L, vectorType);
        lua_rawgeti(L, -1, LSINDEXVECTOR);

        // now we need to loop through and setup our CallStackInfos and get them into our return vector
        for (UTsize i = 0; i < (UTsize)nstack; i++)
        {
            cs = &cstack[i];

            lua_pushnumber(L, i);

            // note that system.CallStackInfo is not a native class, so we just fiddle
            // it with indexes
            lsr_createinstance(L, csiType);

            int csiIdx = lua_gettop(L);

            lua_pushnumber(L, sourceOrdinal);
            lua_pushstring(L, cs->source);
            lua_rawset(L, csiIdx);

            lua_pushnumber(L, lineOrdinal);
            lua_pushnumber(L, cs->line);
            lua_rawset(L, csiIdx);

            lua_pushnumber(L, methodOrdinal);

            if (cs->method->isMethod())
            {
                lualoom_pushnative<MethodInfo>(L, (MethodInfo *)cs->method);
            }
            else if (cs->method->isConstructor())
            {
                lualoom_pushnative<ConstructorInfo>(L, (ConstructorInfo *)cs->method);
            }
            else
            {
                lmAssert(0, "Attempting to debug non-method %s:%s",
                         cs->method->getDeclaringType()->getFullName().c_str(), cs->method->getName());
            }

            assert(lua_istable(L, -1));

            lua_rawset(L, csiIdx);

            lua_rawset(L, -3);
        }

        lua_pop(L, 1);
        // pop the vector table

        lsr_vector_set_length(L, -1, nstack);

        lmAssert(lua_gettop(L) - top == 1, "getCallStack - stack wasn't properly cleaned up");

        return 1;
    }

    // Main lua VM debug hook
    static void debugHook(lua_State *L, lua_Debug *ar)
    {
        int top = lua_gettop(L);

        // line event
        if ((ar->event == LUA_HOOKLINE) && lineEventDelegate.getCount() && !assertion)
        {
            // If we're finishing an method we are not interested
            // in line events until we have returned from the method
            if (finishMethod)
            {
                return;
            }

            // if we're not stepping, have no breakpoints, and haven't hit a Debug.debug()
            // we are not interested in the line event
            if (!stepping && !breakpoints.size() && !debugBreak)
            {
                return;
            }

            // get the call stack at this line
            getCallStack(L, LINE_EVENT);

            // if we don't have a valid stack, return
            if (lua_isnil(L, -1))
            {
                lua_pop(L, 1);
                return;
            }

            // call the native delegate
            lineEventDelegate.incArgCount();
            lineEventDelegate.invoke();
        }

        // return hook
        if ((ar->event == LUA_HOOKRET) && returnEventDelegate.getCount() && !assertion)
        {
            // if we don't have a method we're finishing, we
            // don't care
            if (!finishMethod)
            {
                return;
            }

            // get the call stack
            getCallStack(L, RETURN_EVENT);

            // invalid stack?  No problem, bail
            if (lua_isnil(L, -1))
            {
                lua_pop(L, 1);
                return;
            }

            // call the debugger's native delegate
            returnEventDelegate.incArgCount();
            returnEventDelegate.invoke();
        }

        // call hook
        if ((ar->event == LUA_HOOKCALL) && callEventDelegate.getCount() && !assertion)
        {
            // we on;y care about call events when stepping over
            if (!blocking || !stepping || !stepOver)
            {
                return;
            }

            // get the call stack for this event
            getCallStack(L, CALL_EVENT);

            // invalid? If so, bail
            if (lua_isnil(L, -1))
            {
                lua_pop(L, 1);
                return;
            }

            // call the debugger's event delegate
            callEventDelegate.incArgCount();
            callEventDelegate.invoke();
        }


        lua_settop(L, top);
    }

    // initializes the Lua VM debug hook at this point
    // we are now running under the debugger
    static int setDebugHook(lua_State *L)
    {
        lua_sethook(L, debugHook, LUA_MASKRET | LUA_MASKLINE | LUA_MASKCALL, 1);
        debuggerRunning    = true;
        lastSourceEvent[0] = 0;
        lastLineEvent      = -1;

        return 0;
    }

    // When running under the debugger, this will freeze the execution state
    // allowing us to inspect it.  Otherwise we get a fatal error and exit
    static int loomAssert(lua_State *L)
    {
        bool fail = false;

        if (lua_isnil(L, 1))
        {
            fail = true;
        }

        if (lua_isnumber(L, 1))
        {
            if (!lua_tonumber(L, 1))
            {
                fail = true;
            }
        }

        if (lua_isstring(L, 1))
        {
            if (!strlen(lua_tostring(L, 1)))
            {
                fail = true;
            }
        }

        if (lua_isboolean(L, 1))
        {
            if (!lua_toboolean(L, 1))
            {
                fail = true;
            }
        }

        if (fail)
        {
            if (!debuggerRunning)
            {
                lua_pushfstring(L, "Loom Assertion Failed: %s", lua_tostring(L, 2));
                lua_error(L);
            }
            else
            {
                // trip debugger

                assertion = true;

                getCallStack(L, ASSERT_EVENT);

                if (!lua_isnil(L, -1))
                {
                    assertEventDelegate.incArgCount();
                    assertEventDelegate.invoke();
                }
            }
        }

        return 0;
    }

    // retrieve locals for a given stack frame
    static int getLocals(lua_State *L)
    {
        // we are passed a Vector of CallStack infos
        // which are a snapshot, so query out the basic
        // info from the Vector
        int length = lsr_vector_get_length(L, 1);

        lua_rawgeti(L, 1, LSINDEXVECTOR);
        int vidx = lua_gettop(L);

        // this is the stack index we are interested in
        // as provided
        int stackIndex = (int)lua_tonumber(L, 2);

        // verify that the stackIndex is valid
        if ((stackIndex < 0) || (stackIndex >= length))
        {
            lua_pushnil(L);
            return 1;
        }

        Type *csiType      = LSLuaState::getLuaState(L)->getType("system.CallStackInfo");
        int  methodOrdinal = csiType->getMemberOrdinal("method");


        // build up an array of methods from the Vector
        utArray<MethodBase *> methods;
        MethodBase            *method;

        for (int i = 0; i < length; i++)
        {
            lua_rawgeti(L, vidx, i);
            lua_pushnumber(L, methodOrdinal);
            lua_rawget(L, -2);
            method = (MethodBase *)lualoom_getnativepointer(L, -1);
            lmAssert(method, "Debug.getLocals() - unable to retrieve method pointer");
            methods.push_back(method);
            lua_pop(L, 2);
        }

        lua_pop(L, 1); // pop vector table

        if (!methods.size())
        {
            lua_pushnil(L);
            return 1;
        }

        // Now, build up current stack information
        utArray<MethodBase *> curmethods;
        utArray<int>          curstack;

        for (int i = 0; i < MAX_CALLSTACK; i++)
        {
            lua_Debug ar;

            // if this is null, we're out of stack
            if (!lua_getstack(L, i, &ar))
            {
                break;
            }

            // get function, source, and line
            if (!lua_getinfo(L, "fSl", &ar))
            {
                continue;
            }

            // we are no interested in c functions
            if (lua_iscfunction(L, -1))
            {
                lua_pop(L, 1);
                continue;
            }

            // look up the function in the global function to MethodBase* table
            lua_rawgeti(L, LUA_GLOBALSINDEX, LSINDEXMETHODLOOKUP);
            lua_pushvalue(L, -2);
            lua_rawget(L, -2);

            // if it doesn't exist, continue
            if (lua_isnil(L, -1))
            {
                lua_pop(L, 2);
                continue;
            }

            method = (MethodBase *)lua_topointer(L, -1);

            // skip it if we should filter it
            if (filterMethodBase(method))
            {
                continue;
            }

            // we got one
            curstack.push_back(i);
            curmethods.push_back(method);
        }

        // if we ain't got no, we can exit
        if (!curmethods.size() || (curmethods.size() < methods.size()))
        {
            lua_pushnil(L);
            return 1;
        }

        // now we need to find our stack index by matching the stack snapshot
        // to a portion of the current stack
        int foundIdx = -1;
        for (UTsize i = 0; i < curmethods.size(); i++)
        {
            if (curmethods.size() - i < methods.size())
            {
                break;
            }

            MethodBase *a = curmethods.at(i);

            UTsize j;
            for (j = 0; j < methods.size(); j++)
            {
                if (a != methods.at(j))
                {
                    break;
                }

                a = curmethods.at(i + j + 1);
            }

            if (j == methods.size())
            {
                foundIdx = (int)i;
                break;
            }
        }

        if (foundIdx == -1)
        {
            lua_pushnil(L);
            return 1;
        }

        // found it, so offset
        foundIdx += stackIndex;

        if (foundIdx >= (int)curmethods.size())
        {
            lua_pushnil(L);
            return 1;
        }

        // get the lua offset, which is the absolute
        // stack index of the stack we're querying
        int luaStackIdx = curstack.at(foundIdx);


        // get the debug info
        lua_Debug ar;

        lua_getstack(L, (int)luaStackIdx, &ar);

        lua_getinfo(L, "fS", &ar);

        // We return a Dictionary.<String, Object> of results
        Type *dictType = LSLuaState::getLuaState(L)->getType("system.Dictionary");
        lsr_createinstance(L, dictType);

        int didx = lua_gettop(L);

        int idx = 1;

        // query all the locals for this method
        while (1)
        {
            const char *name = lua_getlocal(L, &ar, idx);

            if (!name)
            {
                break;
            }

            // if we're an internal variable don't add to local dump
            if ((name[0] != '(') && strncmp(name, "__ls_", 4))
            {
                if (lua_isnil(L, -1))
                {
                    lua_pushstring(L, "(null)");
                }
                else
                {
                    lua_pushvalue(L, -1);
                }
                lua_setfield(L, didx, name);
            }
            lua_pop(L, 1);

            idx++;
        }

        // and return Dictionary of locals
        return 1;
    }

    // accessor for line event delegate
    static NativeDelegate *getLineEventDelegate()
    {
        return &lineEventDelegate;
    }

    // accessor for return event delegate
    static NativeDelegate *getReturnEventDelegate()
    {
        return &returnEventDelegate;
    }

    // accessor for call event delegate
    static NativeDelegate *getCallEventDelegate()
    {
        return &callEventDelegate;
    }

    // accessor for assert event delegate
    static NativeDelegate *getAssertEventDelegate()
    {
        return &assertEventDelegate;
    }

    // retrieves a Vector of system.Breakpoints corresponding
    // to the current breakpoints
    static int getBreakpoints(lua_State *L)
    {
        Type *vectorType = LSLuaState::getLuaState(L)->getType("system.Vector");
        Type *bpType     = LSLuaState::getLuaState(L)->getType("system.Breakpoint");

        int sourceOrdinal = bpType->getMemberOrdinal("source");
        int lineOrdinal   = bpType->getMemberOrdinal("line");

        // create the vector instance
        lsr_createinstance(L, vectorType);

        // store the length
        lsr_vector_set_length(L, -1, breakpoints.size());

        lua_rawgeti(L, -1, LSINDEXVECTOR);

        int vidx = lua_gettop(L);

        // loop through the current breakpoints and setup
        // data
        for (UTsize i = 0; i < breakpoints.size(); i++)
        {
            Breakpoint *bp = breakpoints.at(i);

            lsr_createinstance(L, bpType);

            int bpIdx = lua_gettop(L);

            lua_pushnumber(L, sourceOrdinal);
            lua_pushstring(L, bp->source.c_str());
            lua_rawset(L, bpIdx);

            lua_pushnumber(L, lineOrdinal);
            lua_pushnumber(L, bp->line);
            lua_rawset(L, bpIdx);

            lua_rawseti(L, vidx, i);
        }

        lua_pop(L, 1); // pop vector table

        // return Vector
        return 1;
    }

    // tests whether the given breakpoint exists
    static bool hasBreakpoint(const char *source, int line)
    {
        utArray<Breakpoint *> *bps = sourceBreakpoints.get(utFastStringHash(source));

        if (!bps)
        {
            return false;
        }

        for (UTsize i = 0; i < bps->size(); i++)
        {
            if (bps->at(i)->line == line)
            {
                return true;
            }
        }

        return false;
    }

    static void regenerateSourceBreakpoints()
    {
        sourceBreakpoints.clear();

        for (UTsize i = 0; i < breakpoints.size(); i++)
        {
            Breakpoint *bp = breakpoints.at(i);

            utFastStringHash fhash(bp->source);

            if (sourceBreakpoints.find(fhash) == UT_NPOS)
            {
                utArray<Breakpoint *> bps;
                sourceBreakpoints.insert(fhash, bps);
            }

            sourceBreakpoints.get(fhash)->push_back(bp);
        }
    }

    // add's a breakpoint at the given source and line, checks for duplicates
    // and avoids them
    static void addBreakpoint(const char *source, int line)
    {
        Breakpoint *bp;

        for (UTsize i = 0; i < breakpoints.size(); i++)
        {
            bp = breakpoints.at(i);
            if ((bp->source == source) && (bp->line == line))
            {
                return;
            }
        }

        bp         = new Breakpoint;
        bp->source = source;
        bp->line   = line;

        breakpoints.push_back(bp);

        regenerateSourceBreakpoints();
    }

    // removes a breakpoint at the given source and line
    static void removeBreakpoint(const char *source, int line)
    {
        for (UTsize i = 0; i < breakpoints.size(); i++)
        {
            Breakpoint *bp = breakpoints.at(i);
            if ((bp->source == source) && (bp->line == line))
            {
                breakpoints.erase(bp);
                delete bp;
            }
        }

        regenerateSourceBreakpoints();
    }

    // removes all breakpoints
    static void removeAllBreakpoints()
    {
        for (UTsize i = 0; i < breakpoints.size(); i++)
        {
            delete breakpoints.at(i);
        }

        breakpoints.clear();

        regenerateSourceBreakpoints();
    }

    // removes the breakpoint at the given index
    static void removeBreakpointAtIndex(int index)
    {
        if ((index < 0) || (index >= (int)breakpoints.size()))
        {
            return;
        }

        Breakpoint *bp = breakpoints.at(index);
        breakpoints.erase(bp);
        delete bp;

        regenerateSourceBreakpoints();
    }
};

NativeDelegate Debug::lineEventDelegate;
NativeDelegate Debug::callEventDelegate;
NativeDelegate Debug::returnEventDelegate;
NativeDelegate Debug::assertEventDelegate;

char Debug::lastSourceEvent[2048];
int  Debug::lastLineEvent = -1;
utList<Debug::Breakpoint *> Debug::breakpoints;
utHashTable<utFastStringHash, utArray<Debug::Breakpoint *> > Debug::sourceBreakpoints;

bool Debug::assertion  = false;
bool Debug::blocking   = false;
bool Debug::stepping   = false;
bool Debug::stepOver   = false;
bool Debug::debugBreak = false;

MethodBase *Debug::finishMethod = NULL;

bool Debug::debuggerRunning = false;

int registerSystemDebug(lua_State *L)
{
    beginPackage(L, "system")

       .beginClass<Debug> ("Debug")

       .addStaticVar("assertion", &Debug::assertion)
       .addStaticVar("blocking", &Debug::blocking)
       .addStaticVar("stepping", &Debug::stepping)
       .addStaticVar("stepOver", &Debug::stepOver)
       .addStaticVar("debugBreak", &Debug::debugBreak)
       .addStaticVar("finishMethod", &Debug::finishMethod)

       .addStaticLuaFunction("assert", &Debug::loomAssert)
       .addStaticLuaFunction("setDebugHook", &Debug::setDebugHook)
       .addStaticLuaFunction("getLocals", &Debug::getLocals)
       .addStaticLuaFunction("getCallStack", &Debug::getCallStackInfo)

       .addStaticLuaFunction("getBreakpoints", &Debug::getBreakpoints)

       .addStaticMethod("hasBreakpoint", &Debug::hasBreakpoint)
       .addStaticMethod("addBreakpoint", &Debug::addBreakpoint)
       .addStaticMethod("removeBreakpoint", &Debug::removeBreakpoint)
       .addStaticMethod("removeBreakpointAtIndex", &Debug::removeBreakpointAtIndex)
       .addStaticMethod("removeAllBreakpoints", &Debug::removeAllBreakpoints)

       .addStaticProperty("lineEventDelegate", &Debug::getLineEventDelegate)
       .addStaticProperty("returnEventDelegate", &Debug::getReturnEventDelegate)
       .addStaticProperty("callEventDelegate", &Debug::getCallEventDelegate)
       .addStaticProperty("assertEventDelegate", &Debug::getAssertEventDelegate)

       .endClass()

       .endPackage();

    return 0;
}


void installSystemDebug()
{
    NativeInterface::registerNativeType<Debug>(registerSystemDebug);
}
