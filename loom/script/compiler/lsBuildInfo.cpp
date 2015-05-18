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

#include <stdio.h>

#include "loom/common/utils/utTypes.h"
#include "loom/common/platform/platformFile.h"

#include "loom/script/common/lsError.h"
#include "loom/script/common/lsSimpleGlob.h"
#include "loom/script/common/lsLog.h"

#include "loom/script/compiler/lsCompiler.h"
#include "loom/script/compiler/lsCompilerLog.h"

#include "loom/script/compiler/lsBuildInfo.h"
#include "loom/script/compiler/lsDeclarationVisitor.h"
#include "loom/script/serialize/lsAssemblyReader.h"

namespace LS {
void ModuleBuildInfo::parseSourceFile(const utString& filename,
                                      utString&       code)
{
    LSCompiler::logVerbose("Parsing %s", filename.c_str());

    Parser parser(code, filename);

    int numErrors = LSCompilerLog::getNumErrors();

    CompilationUnit *cunit = parser.parseCompilationUnit(buildInfo);

    // if we have parse errors return
    if (numErrors < LSCompilerLog::getNumErrors())
    {
        buildInfo->parseErrors = true;
        return;
    }

    // and visit declarations
    DeclarationVisitor dv;
    dv.visit(cunit);

    for (UTsize i = 0; i < cunit->classDecls.size(); i++)
    {
        ClassDeclaration *cls     = cunit->classDecls.at(i);
        utString         fullpath = cls->pkgDecl->spath + ".";
        fullpath += cls->name->string;
        classes.insert(utHashedString(fullpath), cls);
    }

    astCode.insert(utHashedString(filename), cunit);
}


void ModuleBuildInfo::loadSourceFile(const utString& filename, utString& code)
{
    utFileStream fs;

    fs.open(filename.c_str(), utStream::SM_READ);

    if (!fs.isOpen())
    {
        LSError("Unable to read file %s", filename.c_str());
    }

    int sz = fs.size();

    if (sz)
    {
        char *buffer = new char[sz + 1];

        fs.read(buffer, sz);
        buffer[sz] = 0;

        code = buffer;

        delete[] buffer;

        fs.close();
    }
    else
    {
        code = "/* Empty Source File */";
    }
}


static void recursiveGlob(const char *path, const char *extension, utArray<utString>& files)
{
    utString _path;

    _path  = path;
    _path += utString("/*.") + utString(extension);
    CSimpleGlob globfiles(SG_GLOB_ONLYFILE);
    globfiles.Add(_path.c_str());

    for (int j = 0; j < globfiles.FileCount(); j++)
    {
        files.push_back(globfiles.File(j));
    }

    _path  = path;
    _path += "/*";
    CSimpleGlob globdirs(SG_GLOB_ONLYDIR | SG_GLOB_NODOT);
    globdirs.Add(_path.c_str());

    for (int j = 0; j < globdirs.FileCount(); j++)
    {
        recursiveGlob(globdirs.File(j), extension, files);
    }
}


void ModuleBuildInfo::parse(json_t *json)
{
    moduleName = json_string_value(json_object_get(json, "name"));
    version    = json_string_value(json_object_get(json, "version"));

    json_t *lsourcePath = json_object_get(json, "sourcePath");

    int numPaths = (int)json_array_size(lsourcePath);

    char buildPath[1024];
    strncpy(buildPath, buildInfo->getBuildFilePath().c_str(), 1024);

    for (int i = strlen(buildPath) - 1; i >= 0; i--)
    {
        if (buildPath[i] == '\\' || buildPath[i] == '/')
        {
            buildPath[i] = 0;
            break;
        }
    }

    for (int i = 0; i < numPaths; i++)
    {
        // relative to the build file
        utString path = buildPath;
        path += platform_getFolderDelimiter();
        path += json_string_value(json_array_get(lsourcePath, i));

        sourcePath.push_back(path);
    }

    for (UTsize i = 0; i < sourcePath.size(); i++)
    {
        utString path = sourcePath[i];

        if (path.size() && (path[path.size() - 1] != *platform_getFolderDelimiter()))
        {
            if (path.size() && path.size())
            {
                path += platform_getFolderDelimiter();
            }
        }

        recursiveGlob(path.c_str(), "ls", sourceFiles);
    }

    for (UTsize i = 0; i < sourceFiles.size(); i++)
    {
        utString code;
        utString sourceFile = sourceFiles[i];

        loadSourceFile(sourceFile, code);
        sourceCode.insert(utHashedString(sourceFile), code);

        // and parse
        parseSourceFile(sourceFile, code);
    }

    // if we have any compiler errors, dump them and exit
    if (LSCompilerLog::getNumErrors())
    {
        LSCompilerLog::dump(true);
        exit(EXIT_FAILURE);
    }
}


BuildInfo *BuildInfo::createDefaultBuildFile()
{
    BuildInfo *binfo = new BuildInfo();

    binfo->assemblyName    = "Main";
    binfo->assemblyVersion = "1.0";
    binfo->executable      = true;

    // If we're just throwing some defaults together, pull in all available
    // loomlibs; if the user wants to be lean they can make a Main.build!
    utArray<utString> defaultLibs;
    utArray<utString> libPath = AssemblyReader::getLibraryAssemblyPath();

    for (UTsize i = 0; i < libPath.size(); i++)
    {
        recursiveGlob(libPath[i].c_str(), "loomlib", defaultLibs);
    }

    // embedded System.loomlib is available
    if (LSCompiler::getEmbeddedSystemAssembly())
    {
        utString systemLoomLib = "libs";
        systemLoomLib += platform_getFolderDelimiter();
        systemLoomLib += "System.loomlib";
        defaultLibs.push_back(systemLoomLib);
    }

    for (UTsize i = 0; i < defaultLibs.size(); i++)
    {
        // Strip the name from the path...
        utString strippedLib = defaultLibs[i];

        // It's between last slash and last .
        int lastSlashIdx = -1;
        int lastDotIdx   = -1;
        for (UTsize j = 0; j < strippedLib.size(); j++)
        {
            if (strippedLib.at(j) == *platform_getFolderDelimiter())
            {
                lastSlashIdx = j;
            }

            if (strippedLib.at(j) == '.')
            {
                lastDotIdx = j;
            }
        }

        if ((lastSlashIdx == -1) || (lastDotIdx == -1))
        {
            LSLog(LSLogWarn, "Failed to recognize '%s' as a loomlib.", strippedLib.c_str());
            continue;
        }

        strippedLib = strippedLib.substr(lastSlashIdx + 1, (lastDotIdx - lastSlashIdx) - 1);

        if (strippedLib == "Compiler")
        {
            continue; // don't link to the compiler by default
        }
        binfo->references.push_back(strippedLib);
    }

    binfo->outputDir = "." + utString(platform_getFolderDelimiter()) + "bin";

    // Create the main module
    ModuleBuildInfo *mi = new ModuleBuildInfo(binfo);

    mi->moduleName = "Main";
    mi->version    = "1.0";

    // add source paths default src or from loom.config classpath
    for (int i = 0; i < LSCompiler::getSourcePathCount(); i++)
    {
        mi->sourcePath.push_back(LSCompiler::getSourcePath(i));
    }

    for (UTsize i = 0; i < mi->sourcePath.size(); i++)
    {
        utString path = mi->sourcePath[i];
        recursiveGlob(path.c_str(), "ls", mi->sourceFiles);
    }

    for (UTsize i = 0; i < mi->sourceFiles.size(); i++)
    {
        utString code;
        utString sourceFile = mi->sourceFiles[i];

        mi->loadSourceFile(sourceFile, code);
        mi->sourceCode.insert(utHashedString(sourceFile), code);

        // and parse
        mi->parseSourceFile(sourceFile, code);
    }

    binfo->modules.insert(utHashedString("Main"), mi);

    return binfo;
}


void BuildInfo::_parseBuildFile(const char *buildFile)
{
    utString _buildFile = buildFile;

    // the path to the actual buildfile
    buildFilePath = buildFile;

    buildFileDirectory = "src" + utString(platform_getFolderDelimiter());

    utFileStream fs;

    fs.open(_buildFile.c_str(), utStream::SM_READ);

    int sz = fs.size();

    if (sz <= 0)
    {
        LSError("Build file %s has 0 size", buildFile);
    }


    char *buffer = new char[sz + 1];
    fs.read(buffer, sz);

    json_error_t error;
    json_t       *obuild = json_loadb(buffer, sz, 0, &error);

    if (!obuild)
    {
        LSError("Error reading %s json", buildFile);
    }

    assemblyName    = json_string_value(json_object_get(obuild, "name"));
    assemblyVersion = json_string_value(json_object_get(obuild, "version"));
    executable      = false;
    if (json_object_get(obuild, "executable") && json_is_true(json_object_get(obuild, "executable")))
    {
        executable = true;
    }

    json_t *jreferences = json_object_get(obuild, "references");

    int numReferences = (int)json_array_size(jreferences);

    for (int i = 0; i < numReferences; i++)
    {
        json_t *jreference = json_array_get(jreferences, i);

        utString reference = json_string_value(jreference);

        references.push_back(reference);
    }

    if (json_object_get(obuild, "outputDir"))
    {
        outputDir = json_string_value(json_object_get(obuild, "outputDir"));
    }

    json_t *jmodules = json_object_get(obuild, "modules");

    int numModules = (int)json_array_size(jmodules);

    for (int i = 0; i < numModules; i++)
    {
        json_t *omodule = json_array_get(jmodules, i);

        ModuleBuildInfo *mi = new ModuleBuildInfo(this);
        mi->parse(omodule);

        modules.insert(utHashedString(mi->moduleName), mi);
    }
}


BuildInfo *BuildInfo::parseBuildFile(const char *buildFile)
{
    BuildInfo *binfo = new BuildInfo();

    binfo->_parseBuildFile(buildFile);

    return binfo;
}


ClassDeclaration *BuildInfo::getClassDeclaration(const utString& className)
{
    for (UTsize i = 0; i < modules.size(); i++)
    {
        ModuleBuildInfo *mbi = modules.at(i);

        ClassDeclaration **cls = mbi->classes.get(className);
        if (cls && *cls)
        {
            return *cls;
        }
    }

    return NULL;
}
}
