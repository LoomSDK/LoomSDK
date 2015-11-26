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

#ifndef _lsluastate_h
#define _lsluastate_h

#include "loom/common/core/assert.h"
#include "loom/script/reflection/lsAssembly.h"
#include "loom/script/native/lsNativeDelegate.h"
#include "loom/script/runtime/lsRuntime.h"

namespace LS {
class LSLuaState {
    friend class Assembly;
    friend class BinReader;

    static lua_State  *lastState;
    static LSLuaState *lastLSState;

    // unique id across VM's
    static double uniqueKey;

    static double constructorKey;

    // when we're compiling we disable some
    // runtime checks
    bool compiling;

    // whether we are loading an assembly currently
    // this is incremented/decremented for possible
    // recursive loading
    int loadingAssembly;

    bool debuggingEnabled;

    lua_State *L;

    // loaded assemblies
    utHashTable<utHashedString, Assembly *> assemblies;
    utHashTable<utHashedString, Type *>     typeCache;

    utStack<utString> stackInfo;

    static utArray<utString> commandLine;

    static utArray<utString> buildCache;

    // lua_State* -> LSLuaState
    static utHashTable<utPointerHashKey, LSLuaState *> toLuaState;

    void declareLuaTypes(const utArray<Type *>& types);
    void initializeLuaTypes(const utArray<Type *>& types);

    void getClassTable(Type *type);
    void declareClass(Type *type);
    void initializeClass(Type *type);

    inline void beginAssemblyLoad()
    {
        loadingAssembly++;
    }

    inline void endAssemblyLoad()
    {
        loadingAssembly--;
        lmAssert(loadingAssembly >= 0, "Mismatched endAssemblyLoad called");
    }

    inline bool assemblyLoading()
    {
        return loadingAssembly != 0;
    }

    void finalizeAssemblyLoad(Assembly *assembly, utArray<Type *>& types);

    void cacheAssemblyTypes(Assembly *assembly, utArray<Type *>& types);

public:

    static size_t allocatedBytes;

    LSLuaState() :
        compiling(false), loadingAssembly(0), L(NULL)
    {

#ifdef LOOM_DEBUG
        debuggingEnabled = true;
#else
        debuggingEnabled = false;
#endif

        objectType   = NULL;
        nullType     = NULL;
        booleanType  = NULL;
        numberType   = NULL;
        stringType   = NULL;
        functionType = NULL;
        vectorType   = NULL;
        reflectionType = NULL;
    }

    inline lua_State *VM()
    {
        return L;
    }

    static inline LSLuaState *getLuaState(lua_State *L)
    {
        if (L == lastState)
        {
            return lastLSState;
        }

        // always look up by main thread, this handles coroutine states nicely

#ifdef LOOM_ENABLE_JIT
        LSLuaState **ls = toLuaState.get(mainthread(G(L)));
#else
        LSLuaState **ls = toLuaState.get(L->l_G->mainthread);
#endif

        lmAssert(ls, "Fatal Error: Unable to get LuaState");

        lastState   = L;
        lastLSState = *ls;

        return *ls;
    }

    void open();
    void close();

    void setCompiling(bool value)
    {
        compiling = value;
    }

    bool inline isCompiling()
    {
        return compiling;
    }

    void invokeStaticMethod(const utString& typePath, const char *methodName, int numParameters = 0);

    /*
     * Loads a Type assembly into the VM, Type assemblies are purely used during compilation
     */
    Assembly *loadTypeAssembly(const utString& assemblyString);

    /*
     * Loads a JSON assembly into the VM, JSON assemblies are used during compilation for loomlibs
     */
    Assembly *loadAssemblyJSON(const utString& json);

    /*
     * Loads an Binary assembly into the VM, at the moment Binary assemblies are exclusively used for executables
     * at runtime
     */
    Assembly *loadAssemblyBinary(utByteArray *bytes);

    /*
     * Loads an Executable Binary assembly into the VM, once loaded the assembly may be executed
     */
    Assembly *loadExecutableAssembly(const utString& assemblyName, bool absPath = false);
    Assembly *loadExecutableAssemblyBinary(const char *buffer, long bufferSize);

    // get all types loaded for a given package
    void getPackageTypes(const utString& packageName, utArray<Type *>& types);

    // fast access to key types
    Type *objectType;
    Type *nullType;
    Type *booleanType;
    Type *numberType;
    Type *stringType;
    Type *vectorType;
    Type *functionType;
    Type *reflectionType;

    // get all currently loaded types
    void getAllTypes(utArray<Type *>& types)
    {
        for (UTsize i = 0; i < assemblies.size(); i++)
        {
            Assembly *assembly = assemblies.at(i);
            assembly->getTypes(types);
        }
    }

    // get loaded type via fully qualified typename
    // for speed, use getTypeByID
    inline Type *getType(const char *typeName)
    {
        Type **v = typeCache.get(typeName);

        if (v)
        {
            return *v;
        }

        // if (and only if) we are currently loading an assembly, look up the type
        // in the current assemblies, all types will be resolved at assembly load
        // so this is the only time we need to do this.. saving many cycles
        if (assemblyLoading())
        {
            Type *type = NULL;

            for (UTsize i = 0; i < assemblies.size(); i++)
            {
                Assembly *assembly = assemblies.at(i);

                type = assembly->getType(typeName);
                if (type)
                {
                    typeCache.insert(type->getFullName(), type);
                    return type;
                }
            }
        }

        // otherwise, this type isn't loaded (or isn't being loaded)
        return NULL;
    }

    // get assembly by name
    Assembly *getAssembly(const utString& name);

    Assembly *getAssemblyByUID(const utString& uid);

    void tick();

    static LSLuaState *getExecutingVM(lua_State *L)
    {
        return getLuaState(L);
    }

    static double getUniqueKey()
    {
        double d = uniqueKey;

        uniqueKey++;
        return d;
    }

    static void initCommandLine(int argc, const char **argv);

    static UTsize getNumCommandlineArgs()
    {
        return commandLine.size();
    }

    static const utString& getCommandlineArg(UTsize idx)
    {
        assert(idx >= 0 && idx < commandLine.size());
        return commandLine[idx];
    }

    void dumpManagedNatives();
    void dumpLuaStack();

    int getStackSize();

    void triggerRuntimeError(const char *format, ...);

    static int traceback(lua_State *L);

    static bool isJIT()
    {
#ifdef LOOM_ENABLE_JIT
        return true;

#else
        return false;
#endif
    }

    LOOM_DELEGATE(OnReload);
};
}
#endif
