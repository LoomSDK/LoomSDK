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

#include "loom/script/common/lsError.h"
#include "loom/script/common/lsFile.h"
#include "loom/script/serialize/lsAssemblyReader.h"
#include "loom/script/serialize/lsBinReader.h"
#include "loom/script/reflection/lsAssembly.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/common/core/assert.h"
#include "loom/script/native/lsNativeInterface.h"

namespace LS {
// loaded assemblies by lua_State (utPointerHashKey)
utHashTable<utPointerHashKey, utHashTable<utHashedString, Assembly *> *> Assembly::assemblies;

// cached type -> assembly lookup
utHashTable<utPointerHashKey, Assembly *> Assembly::typeAssemblyLookup;

void Assembly::registerModule(Module *module)
{
    module->setAssembly(this);
    modules.insert(utHashedString(module->getName()), module);
}


Module *Assembly::getModule(const utString& name)
{
    UTsize idx = modules.find(utHashedString(name));

    if (idx == UT_NPOS)
    {
        return NULL;
    }

    return modules.at(idx);
}


Assembly *Assembly::getAssembly(Type *type)
{
    // look in assemblies loaded for type's lua_State
    const Module *m = type->getModule();
    Assembly     *a = m->getAssembly();

    return a;
}


Assembly *Assembly::create(LSLuaState *vm, const utString& name)
{
    Assembly *a = new Assembly();

    a->vm   = vm;
    a->name = name;

    utHashTable<utHashedString, Assembly *> *lookup = NULL;

    UTsize idx = assemblies.find(vm);

    if (idx != UT_NPOS)
    {
        lookup = assemblies.at(idx);
    }
    else
    {
        lookup = new utHashTable<utHashedString, Assembly *>();
        assemblies.insert(vm, lookup);
    }

    utHashedString key = a->name;
    lookup->insert(key, a);

    vm->assemblies.insert(utHashedString(a->getName()), a);

    return a;
}


void Assembly::bootstrap()
{
    utArray<Type *> types;
    getTypes(types);

    Type *btype = vm->getType("system.Bootstrap");

    for (UTsize i = 0; i < types.size(); i++)
    {
        Type *type = types[i];

        if (type->getFullName() == "system.Null")
        {
            continue;
        }

        if (type->castToType(btype))
        {
            MemberInfo *mi = type->findMember("initialize");
            assert(mi);
            assert(mi->isMethod());

            MethodInfo *method = (MethodInfo *)mi;

            method->invoke(NULL, 0);
        }
    }
}


Assembly *Assembly::loadFromString(LSLuaState *vm, const utString& source)
{
    Assembly *assembly = AssemblyReader::deserialize(vm, source);

    return assembly;
}

int Assembly::loadBytes(lua_State *L) {

    utByteArray *bytes = static_cast<utByteArray*>(lualoom_getnativepointer(L, 1, false, "system.ByteArray"));
    
    Assembly *assembly = LSLuaState::getExecutingVM(L)->loadExecutableAssemblyBinary(static_cast<const char*>(bytes->getDataPtr()), bytes->getSize());

    lmAssert(assembly, "Error loading assembly bytes");

    return 1;
}

Assembly *Assembly::loadBinary(LSLuaState *vm, utByteArray *bytes)
{
    Assembly *assembly = BinReader::loadExecutable(vm, bytes);

    //lualoom_pushnative

    return assembly;
}


Type *Assembly::getType(const utString& typeName)
{
    Type *type = NULL;

    UTsize idx = types.find(typeName);

    if (idx != UT_NPOS)
    {
        return types.at(idx);
    }

    for (UTsize i = 0; i < modules.size(); i++)
    {
        Module *module = modules.at(i);
        type = module->getType(typeName);
        if (type)
        {
            types.insert(typeName, type);
            return type;
        }
    }

    types.insert(typeName, NULL);
    return type;
}


void Assembly::getPackageTypes(const utString&  packageName,
                               utArray<Type *>& types)
{
    for (UTsize i = 0; i < modules.size(); i++)
    {
        Module *module = modules.at(i);
        module->getPackageTypes(packageName, types);
    }
}


void Assembly::getTypes(utArray<Type *>& types)
{
    for (UTsize i = 0; i < modules.size(); i++)
    {
        modules.at(i)->getTypes(types);
    }
}


int Assembly::getTypeCount()
{
    utArray<Type *> types;
    getTypes(types);
    return (int)types.size();
}


Type *Assembly::getTypeAtIndex(int index)
{
    utArray<Type *> types;
    getTypes(types);
    if ((index < 0) || (index >= (int)types.size()))
    {
        LSError("Type out of range");
    }
    return types[index];
}


MethodInfo *Assembly::getStaticMethodInfo(const char *name)
{
    utArray<Type *> types;

    for (UTsize i = 0; i < modules.size(); i++)
    {
        modules.at(i)->getTypes(types);

        for (UTsize j = 0; j < types.size(); j++)
        {
            Type *type = types.at(j);

            MemberTypes types;
            types.method = true;
            utArray<MemberInfo *> members;
            type->findMembers(types, members);
            for (UTsize k = 0; k < members.size(); k++)
            {
                //TODO: this get's the first static main method, at compiler time
                // we need to verify only one entry per assembly

                MethodInfo *methodInfo = (MethodInfo *)members.at(k);
                if (methodInfo->isStatic() && !strcmp(methodInfo->getName(), name))
                {
                    return methodInfo;
                }
            }
        }

        types.clear();
    }

    return NULL;
}


void Assembly::execute()
{
    MethodInfo *method = getStaticMethodInfo("main");

    if (!method)
    {
        LSError("Unable to find main method in Assembly %s", getName().c_str());
    }

    method->invoke(NULL, 0);
}


void Assembly::connectToDebugger(const char *host, int port)
{
    if (!vm)
    {
        LSError("Assembly::connectToDebugger called on uninitialized assembly");
    }

    Type *debuggerClient = vm->getType("system.debugger.DebuggerClient");

    if (!debuggerClient)
    {
        LSError("Unable to get system.debugger.DebuggerClient");
    }

    MethodInfo *method = debuggerClient->findMethodInfoByName("connect");

    if (!method)
    {
        LSError("Unable to get system.debugger.DebuggerClient.connect method");
    }

    lua_pushstring(vm->VM(), host);
    lua_pushnumber(vm->VM(), port);

    method->invoke(NULL, 2);
}


void Assembly::getLoadedAssemblies(LSLuaState *vm, utList<Assembly *>& oassemblies)
{
    utHashTable<utHashedString, Assembly *> *lookup = NULL;

    UTsize idx = assemblies.find(vm);

    if (idx != UT_NPOS)
    {
        lookup = assemblies.at(idx);
    }
    else
    {
        return;
    }

    for (UTsize i = 0; i < lookup->size(); i++)
    {
        oassemblies.push_back(lookup->at(i));
    }
}


void Assembly::close()
{
    utArray<Type *> types;
    getTypes(types);

    for (UTsize i = 0; i < types.size(); i++)
    {
        typeAssemblyLookup.remove(types.at(i));
        lmFree(NULL,  types.at(i));
    }

    assemblies.remove(vm);
}
}
