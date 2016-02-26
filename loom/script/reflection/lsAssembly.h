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

#ifndef _lsassembly_h
#define _lsassembly_h

extern "C" {
#include "lua.h"
}

#include "loom/common/core/assert.h"
#include "loom/common/utils/utString.h"
#include "loom/common/utils/utStreams.h"
#include "loom/common/utils/utByteArray.h"

#include "loom/script/reflection/lsReflection.h"

namespace LS {
class LSLuaState;

class Assembly {
    friend class AssemblyWriter;
    friend class AssemblyReader;
    friend class BinReader;
    friend class LSLuaState;

private:
    utString name;
    utString uid;
    utString loomConfig;

    LSLuaState *vm;

    utHashTable<utHashedString, Module *> modules;
    utHashTable<utHashedString, Type *>   types;

    // loaded assemblies by LSLuaState (utPointerHashKey)
    static utHashTable<utPointerHashKey, utHashTable<utHashedString, Assembly *> *> assemblies;

    // cached type -> assembly lookup
    static utHashTable<utPointerHashKey, Assembly *> typeAssemblyLookup;

    // for a loaded assembly, this will be the (mapped) path to the file
    utString filePath;
    utString sha512;

    unsigned int ordinal;

    bool debugBuild;

    // the assemblies we reference
    utArray<Assembly *> referencedAssemblies;

    utArray<Type*> *ordinalTypes;

public:

    bool loaded;

    Assembly() :
        vm(NULL), types(), ordinal(1), debugBuild(true), ordinalTypes(NULL), loaded(false)
    {
    }

    /*
    * Closes the assembly, cleaning up associated hashes and Types
    */
    ~Assembly();

    static int loadBytes(lua_State *L);
    static int load(lua_State *L);

    inline LSLuaState *getLuaState()
    {
        return vm;
    }

    Object *createInstance(const char *typeName);

    unsigned int uniqueOrdinal()
    {
        unsigned int o = ordinal;

        ordinal++;
        return o;
    }

    Module *getModule(const utString& name);
    void getModules(utList<Module *>& modules);

    // get Type by full qualified typename
    Type *getType(const utString& typeName);

    /*
     * Fasssst type getter by ordinal
     */
    inline Type *getTypeByOrdinal(LSTYPEID typeID)
    {
        lmAssert(typeID > 0 && typeID <= (LSTYPEID)types.size(), "Assembly::getTypeByOrdinal - Assembly %s typeID out of range %i (%i)", name.c_str(), typeID, (int)types.size());
        return ordinalTypes->at(typeID);
    }

    void getTypes(utArray<Type *>& types);

    int getTypeCount();
    Type *getTypeAtIndex(int index);

    void freeByteCode()
    {
        utArray<Type*> types;
        getTypes(types);
        for(unsigned int i=0; i<types.size(); i++)
            types[i]->freeByteCode();
    }

    void getPackageTypes(const utString& packageName, utArray<Type *>& types);

    // types visible outside of assembly
    void getExportedTypes(utList<Type *>& types);

    // register module as owned by assembly
    void registerModule(Module *module);

    const utString& getName()
    {
        return name;
    }

    const utString& getUniqueId()
    {
        return uid;
    }

    void execute();
    int run(lua_State* L);

    void connectToDebugger(const char *host, int port);

    static void getLoadedAssemblies(LSLuaState *vm, utList<Assembly *>& oassemblies);

    // get the assembly that the specified class was define in
    static Assembly *getAssembly(Type *type);

    // get the assembly that was first executed
    static Assembly *getEntryAssembly();

    // get the assembly that is currently executing code
    static Assembly *getExecutingAssembly();

    // get the assembly of the method that invoked the currently executing method
    static Assembly *getCallingAssembly();

    static Assembly *getLoaded(LSLuaState *vm, const utString& name, const utString& uid);

    static Assembly *create(LSLuaState *vm, const utString& name, const utString& uid);
	
    static Assembly *loadBinary(LSLuaState *vm, utByteArray *bytes);

    static void loadBinaryHeader(LSLuaState *vm, utByteArray *bytes);
    static Assembly *loadBinaryBody();

	/*
     * Loads a JSON assembly which is used during compilation
     */
    static Assembly *loadFromString(LSLuaState *vm, const utString& source);

    MethodInfo *getStaticMethodInfo(const char *name);

    void bootstrap();

    const utString& getSHA512()
    {
        return sha512;
    }

    void setDebugBuild(bool isDebug)
    {
        debugBuild = isDebug;
    }

    bool getDebugBuild()
    {
        return debugBuild;
    }

    void addReference(Assembly *assembly)
    {
        if (referencedAssemblies.find(assembly) == UT_NPOS)
        {
            referencedAssemblies.push_back(assembly);
        }
    }

    int getReferenceCount()
    {
        return (int)referencedAssemblies.size();
    }

    const utString& getReferenceName(int index)
    {
        return referencedAssemblies.at(index)->getName();
    }

    Assembly* getReference(int index)
    {
        return referencedAssemblies.at(index);
    }

    void setLoomConfig(const utString& config)
    {
        loomConfig = config;
    }

    const utString& getLoomConfig()
    {
        return loomConfig;
    }
};
}
#endif
