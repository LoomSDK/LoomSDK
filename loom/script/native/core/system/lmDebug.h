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
    static bool filterMethodBase(MethodBase *methodBase);
    
    static int getCallStackInfo(lua_State *L)
    {
        return getCallStack(L, ASSERT_EVENT);
    }

    // retrieve a Vector of callstack info, or nil in the case of an invalid stack
    static int getCallStack(lua_State *L, EventType eventType);

    // Main lua VM debug hook
    static void debugHook(lua_State *L, lua_Debug *ar);

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
    static int loomAssert(lua_State *L);

    // retrieve locals for a given stack frame
    static int getLocals(lua_State *L);

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
    static int getBreakpoints(lua_State *L);

    // tests whether the given breakpoint exists
    static bool hasBreakpoint(const char *source, int line);

    static void regenerateSourceBreakpoints();

    // add's a breakpoint at the given source and line, checks for duplicates
    // and avoids them
    static void addBreakpoint(const char *source, int line);

    // removes a breakpoint at the given source and line
    static void removeBreakpoint(const char *source, int line);

    // removes all breakpoints
    static void removeAllBreakpoints();

    // removes the breakpoint at the given index
    static void removeBreakpointAtIndex(int index);
};

