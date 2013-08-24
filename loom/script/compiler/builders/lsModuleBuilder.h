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

#ifndef _lsmodulebuilder_h
#define _lsmodulebuilder_h

#include "loom/script/serialize/lsModuleWriter.h"
#include "loom/script/compiler/lsAST.h"
#include "loom/script/compiler/lsBuildInfo.h"
#include "loom/script/compiler/builders/lsTypeBuilder.h"

namespace LS {
class ModuleBuilder {
    friend class AssemblyBuilder;

    utString name;
    utString version;

    utArray<TypeBuilder *> typeBuilders;

    utArray<utString> dependencies;

    void addDependency(const utString& dep);

    ModuleWriter    writer;
    AssemblyBuilder *assemblyBuilder;

    void initialize(AssemblyBuilder *assemblyBuilder, ModuleBuildInfo *binfo);

    void build();

    void injectByteCode(Assembly *assembly);

    void injectTypes(Assembly *assembly);
};
}
#endif
