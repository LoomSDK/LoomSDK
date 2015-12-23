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

#ifndef _lsassemblybuilder_h
#define _lsassemblybuilder_h

#include "loom/script/compiler/lsBuildInfo.h"
#include "loom/script/serialize/lsAssemblyWriter.h"
#include "loom/script/compiler/builders/lsModuleBuilder.h"

namespace LS {
class AssemblyBuilder {
    Assembly *assembly;

    // access to the current BuildInfo
    BuildInfo *buildInfo;

    // as we must assign type id's BEFORE the assembly exists
    // the AssemblyBuilder does this using a simple increment scheme
    LSTYPEID typeID;

    // the name of the assembly we are building
    utString name;

    // the version number of said assembly
    utString version;

    // the unique id (GUID) of the assembly
    utString uid;

    // the assembly writer, this is split out from the builder
    // as to limit dependencies for serialization
    AssemblyWriter writer;

    void initialize(BuildInfo *buildInfo);

    utArray<ModuleBuilder *> moduleBuilders;

    // build out assembly (without bytecode)
    void build();

public:

    AssemblyBuilder() :
        assembly(NULL), buildInfo(NULL), typeID(0)
    {
    }

    static AssemblyBuilder *create(BuildInfo *buildInfo);

    void setAssembly(Assembly *assembly);

    void setLoomConfig(const char *configJSON)
    {
        writer.setLoomConfig(configJSON);
    }

    // inject bytecode
    void injectByteCode(Assembly *assembly);

    void injectTypes(Assembly *assembly);

    void writeToString(utString& out);

    void writeToFile(const utString& filename);

    LSTYPEID allocateTypeID()
    {
        typeID++;
        return typeID;
    }
};
}
#endif
