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

#include "loom/script/compiler/builders/lsAssemblyBuilder.h"

namespace LS {
// build out assembly
void AssemblyBuilder::build()
{
    writer.setName(name);
    writer.setVersion(version);

    // setup assembly path
    for (UTsize i = 0; i < buildInfo->getNumAssemblyPaths(); i++)
    {
        writer.addAssemblyPath(buildInfo->getAssemblyPath(i));
    }

    // setup references
    for (UTsize i = 0; i < buildInfo->getNumReferences(); i++)
    {
        writer.addReference(buildInfo->getReference(i));
    }

    for (UTsize i = 0; i < moduleBuilders.size(); i++)
    {
        moduleBuilders[i]->build();
    }
}


void AssemblyBuilder::setAssembly(Assembly *assembly)
{
    lmAssert(!this->assembly, "AssemblyBuilder::setAssembly - assembly already set");
    this->assembly = assembly;
    writer.setAssembly(assembly);
}


void AssemblyBuilder::writeToString(utString& out)
{
    writer.writeToString(out);
}


void AssemblyBuilder::writeToFile(const utString& filename)
{
    writer.writeToFile(filename);
}


void AssemblyBuilder::initialize(BuildInfo *buildInfo)
{
    this->buildInfo = buildInfo;

    name    = buildInfo->getAssemblyName();
    version = buildInfo->getAssemblyVersion();

    // initialize modules
    for (UTsize i = 0; i < buildInfo->getNumModules(); i++)
    {
        ModuleBuildInfo *mbi = buildInfo->getModule(i);

        ModuleBuilder *mbuilder = new ModuleBuilder();
        mbuilder->initialize(this, mbi);

        writer.addModuleWriter(&mbuilder->writer);

        moduleBuilders.push_back(mbuilder);
    }
}


AssemblyBuilder *AssemblyBuilder::create(BuildInfo *buildInfo)
{
    AssemblyBuilder *ab = new AssemblyBuilder();

    ab->initialize(buildInfo);
    ab->build();
    return ab;
}


void AssemblyBuilder::injectTypes(Assembly *assembly)
{
    for (UTsize i = 0; i < moduleBuilders.size(); i++)
    {
        moduleBuilders.at(i)->injectTypes(assembly);
    }
}


void AssemblyBuilder::injectByteCode(Assembly *assembly)
{
    for (UTsize i = 0; i < moduleBuilders.size(); i++)
    {
        moduleBuilders.at(i)->injectByteCode(assembly);
    }
}
}
