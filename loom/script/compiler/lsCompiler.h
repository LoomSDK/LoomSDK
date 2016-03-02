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

#ifndef _lscompiler2_h
#define _lscompiler2_h

#include "loom/common/core/log.h"
#include "loom/common/utils/utStreams.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/compiler/lsParser.h"
#include "loom/script/compiler/lsBuildInfo.h"

#include "loom/script/reflection/lsReflection.h"

namespace LS {
class AssemblyBuilder;

class LSCompiler 
{

private:

    // dedicated lua_State we build/tear down at compile time
    // ensuring no runtime dependencies
    LSLuaState *vm;

    BuildInfo *buildInfo;

    static bool debugBuild;

    void openCompilerVM();
    void closeCompilerVM();

    void compileTypes(CompilationUnit *cunit);

    void processTypes(ModuleBuildInfo *mbi);

    void compileModules();

    // path to the sdk we're building with
    static utString sdkPath;

    // for build files + source
    static utArray<utString> sourcePath;

    // for binary assemblies you may be building against
    static utArray<utString> assemblyPath;

    // Types which were imported by the current compilation
    // used for filtering which assemblies are linked for binary loom files
    static utArray<Type *> importedTypes;

    // Assemblies which were imported by the current compilation
    // includes referenced dependencies of those assemblies as well
    static utArray<Assembly *> importedAssemblies;

    // whether to dump symbols for binary executable
    static bool dumpSymbols;

    // the root build file, for linker and generating dependencies
    static utString  rootBuildFile;
    static BuildInfo *rootBuildInfo;

    // root dependencies in full (dependencies of dependencies of dependencies included)
    static utArray<utString> rootDependencies;

    // root loomlib dependencies in full (dependencies of dependencies...)
    static utArray<utString> rootLibDependencies;

    // root dependencies in full, where we have a .build file and so will be compiling the
    // linked assembly from source
    static utArray<BuildInfo *> rootBuildDependencies;

    // if we have a loom config, this will be valid json, otherwise NULL
    static json_t *loomConfigJSON;

    static utString loomConfigOverride;
    static utArray<utString> loomConfigClassPath;

    static void linkRootAssembly(const utString& sjson);
    static void compileRootBuildDependencies();
    static void generateRootDependenciesRecursive(const utString& ref);
    static void generateRootDependencies();
    static BuildInfo *loadBuildFile(const utString& cref);
    static const char *readAssemblyUID(const utArray<unsigned char>& rawjson);

    static const char* embeddedSystemAssembly;

public:

    static loom_logGroup_t compilerLogGroup;

    LSCompiler() : vm(NULL), buildInfo(NULL)
    {
    }

    static void compileAssembly(BuildInfo *buildInfo);

    static bool isDebugBuild()
    {
        return debugBuild;
    }

    static void setDebugBuild(bool _debugBuild)
    {
        debugBuild = _debugBuild;
    }

    static void setSDKBuild(const utString& lscPath);

    static void setConfigOverride(const char *config);

    static void setDumpSymbols(bool dump)
    {
        dumpSymbols = dump;
    }

    static void setRootBuildFile(const utString& buildFile)
    {
        rootBuildFile = buildFile;
    }

    static void defaultRootBuildFile()
    {
        rootBuildFile = "";
    }

    static const utString& getRootBuildFile()
    {
        return rootBuildFile;
    }

    static void addSourcePath(const utString& _sourcePath)
    {
        sourcePath.push_back(_sourcePath);
    }

    static int getSourcePathCount()
    {
        return (int)sourcePath.size();
    }

    static const utString& getSourcePath(int idx)
    {
        return sourcePath.at(idx);
    }

    static void addAssemblyPath(const utString& _assemblyPath)
    {
        assemblyPath.push_back(_assemblyPath);
    }

    static int getAssemblyPathCount()
    {
        return (int)assemblyPath.size();
    }

    static const utString& getAssemblyPath(int idx)
    {
        return assemblyPath.at(idx);
    }

    // load the loom.config to json, if any
    static void processLoomConfig();

    static void processExecutableConfig(AssemblyBuilder *ab);

    // must be called after all source paths, assembly paths, and root build file have been set
    static void initialize();

    static void log(const char *format, ...);
    static void logVerbose(const char *format, ...);

    static void clearImports()
    {
        importedTypes.clear();
        importedAssemblies.clear();
    }

    // recursively mark imported assemblies and that assemblies references
    static void markImportAssembly(Assembly *assembly)
    {
        if (importedAssemblies.find(assembly) == UT_NPOS)
        {
            importedAssemblies.push_back(assembly);

            LSLuaState *state = assembly->getLuaState();

            lmAssert(state, "null state");

            for (int i = 0; i < assembly->getReferenceCount(); i++)
            {
                Assembly *ref = assembly->getReference(i);

                lmAssert(ref, "null assembly");

                markImportAssembly(ref);
            }
        }
    }

    // marks a type as being imported by the sources being compiled
    static void markImportType(Type *type)
    {
        if (importedTypes.find(type) == UT_NPOS)
        {
            importedTypes.push_back(type);

            Assembly *assembly = type->getAssembly();

            markImportAssembly(assembly);
        }
    }

    static void setEmbeddedSystemAssembly(const char* data)
    {
        embeddedSystemAssembly = data;    
    }

    static const char* getEmbeddedSystemAssembly()
    {
        return embeddedSystemAssembly;
    }
};
}
#endif
