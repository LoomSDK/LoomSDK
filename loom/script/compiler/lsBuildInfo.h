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

#ifndef _lsbuildinfo_h
#define _lsbuildinfo_h

#include "jansson.h"

#include "loom/common/utils/utString.h"
#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utStreams.h"

#include "loom/script/compiler/lsParser.h"

namespace LS {
class BuildInfo;
class ModuleBuildInfo {
    friend class BuildInfo;

    utString moduleName;
    utString version;

    utArray<utString> sourcePath;
    utArray<utString> sourceFiles;
    utHashTable<utHashedString, utString>          sourceCode;
    utHashTable<utHashedString, CompilationUnit *> astCode;

    utHashTable<utHashedString, ClassDeclaration *> classes;

    BuildInfo *buildInfo;

    void parseSourceFile(const utString& filename, utString& code);
    void loadSourceFile(const utString& filename, utString& code);

    void parse(json_t *json);

public:

    ModuleBuildInfo(BuildInfo *buildInfo) { this->buildInfo = buildInfo; }

    UTsize getNumSourceFiles()
    {
        return sourceFiles.size();
    }

    const utString& getSourceFilename(UTsize idx)
    {
        return sourceFiles.at(idx);
    }

    const utString& getSourceCode(const utString& filename)
    {
        if (sourceCode.find(utHashedString(filename)) != UT_NPOS)
        {
            return *sourceCode[utHashedString(filename)];
        }
        else
        {
            //FIXME: error!
            static utString error;
            return error;
        }
    }

    CompilationUnit *getCompilationUnit(const utString& filename)
    {
        if (astCode.find(utHashedString(filename)) != UT_NPOS)
        {
            return *astCode[utHashedString(filename)];
        }

        //FIXME: error!
        return NULL;
    }

    const utString& getModuleName()
    {
        return moduleName;
    }

    const utString& getModuleVersion()
    {
        return version;
    }
};

class BuildInfo {
    utArray<utString> assemblyPath;
    utArray<utString> references;

    utString assemblyName;
    utString assemblyVersion;

    utHashTable<utHashedString, ModuleBuildInfo *> modules;

    utString outputDir;

    utString buildFilePath;

    void _parseBuildFile(const char *buildFile);

    bool debugBuild;

    // whether we are building an executable (or library)
    bool executable;

public:

    utString buildFileDirectory;

    bool parseErrors;

    BuildInfo() : debugBuild(true), executable(false), parseErrors(false) {}

    const utString& getAssemblyName()
    {
        return assemblyName;
    }

    const utString& getAssemblyVersion()
    {
        return assemblyVersion;
    }

    bool isExecutable()
    {
        return executable;
    }

    bool isLibrary()
    {
        return !executable;
    }

    UTsize getNumReferences()
    {
        return references.size();
    }

    const utString& getReference(UTsize idx)
    {
        return references[idx];
    }

    UTsize getNumAssemblyPaths()
    {
        return assemblyPath.size();
    }

    const utString& getAssemblyPath(UTsize idx)
    {
        return assemblyPath[idx];
    }

    UTsize getNumModules()
    {
        return modules.size();
    }

    ModuleBuildInfo *getModule(UTsize idx)
    {
        return modules[idx];
    }

    ModuleBuildInfo *getModule(const utString& name)
    {
        if (modules.find(utHashedString(name)) != UT_NPOS)
        {
            return *modules[utHashedString(name)];
        }

        //FIXME: error!
        return NULL;
    }

    const utString& getOutputDir()
    {
        return outputDir;
    }

    const utString& getBuildFilePath()
    {
        return buildFilePath;
    }

    // get class declaration from fully qualified name
    ClassDeclaration *getClassDeclaration(const utString& className);

    void setDebugBuild(bool isDebug)
    {
        debugBuild = isDebug;
    }

    bool isDebugBuild()
    {
        return debugBuild;
    }

    static BuildInfo *createDefaultBuildFile();
    static BuildInfo *parseBuildFile(const char *buildFile);
};
}
#endif
