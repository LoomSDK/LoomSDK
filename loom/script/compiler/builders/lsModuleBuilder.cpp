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

#include "loom/script/compiler/builders/lsModuleBuilder.h"

namespace LS {
void ModuleBuilder::build()
{
    writer.setName(name);
    writer.setVersion(version);
    writer.setDependencies(dependencies);

    for (UTsize i = 0; i < typeBuilders.size(); i++)
    {
        typeBuilders[i]->build();
    }
}


void ModuleBuilder::addDependency(const utString& dep)
{
    if (dependencies.find(dep) != UT_NPOS)
    {
        dependencies.push_back(dep);
    }
}


void ModuleBuilder::initialize(AssemblyBuilder *assemblyBuilder, ModuleBuildInfo *binfo)
{
    name    = binfo->getModuleName();
    version = binfo->getModuleVersion();
    this->assemblyBuilder = assemblyBuilder;

    for (UTsize i = 0; i < binfo->getNumSourceFiles(); i++)
    {
        // Look up the compilation unit.
        const utString  filename = binfo->getSourceFilename(i);
        CompilationUnit *cunit   = binfo->getCompilationUnit(filename);

        lmAssert(cunit, "Internal compiler error: failed to find compilation unit for '%s'!", filename.c_str());

        //add dependencies
        //TODO: filter these to actually used
        for (UTsize j = 0; j < cunit->dependencies.size(); j++)
        {
            addDependency(cunit->dependencies[j]);
        }

        //look at types
        for (UTsize j = 0; j < cunit->classDecls.size(); j++)
        {
            ClassDeclaration *cls = cunit->classDecls.at(j);

            TypeBuilder *typeBuilder = lmNew(NULL) TypeBuilder(assemblyBuilder);
            typeBuilder->initialize(cls);
            typeBuilders.push_back(typeBuilder);

            writer.addTypeWriter(&typeBuilder->writer);
        }
    }
}


void ModuleBuilder::injectByteCode(Assembly *assembly)
{
    for (UTsize i = 0; i < typeBuilders.size(); i++)
    {
        typeBuilders.at(i)->injectByteCode(assembly);
    }
}


void ModuleBuilder::injectTypes(Assembly *assembly)
{
    for (UTsize i = 0; i < typeBuilders.size(); i++)
    {
        typeBuilders.at(i)->injectTypes(assembly);
    }
}


void injectTypes(Assembly *assembly);
}
