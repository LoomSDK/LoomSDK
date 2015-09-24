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

#include "loom/common/core/assert.h"
#include "loom/common/core/log.h"
#include "loom/common/platform/platformFile.h"
#include "loom/common/utils/utBase64.h"
#include "loom/script/compiler/builders/lsAssemblyBuilder.h"
#include "loom/script/compiler/lsCompiler.h"
#include "loom/script/compiler/lsTypeQualifyVisitor.h"
#include "loom/script/compiler/lsMemberVisitor.h"
#include "loom/script/compiler/lsTypeVisitor.h"
#include "loom/script/compiler/lsTypeCompiler.h"
#include "loom/script/compiler/lsJitTypeCompiler.h"
#include "loom/script/compiler/lsCompilerLog.h"
#include "loom/script/serialize/lsAssemblyReader.h"
#include "loom/script/serialize/lsBinWriter.h"
#include "loom/script/serialize/lsBinReader.h"
#include "loom/script/compiler/lsTypeValidator.h"


namespace LS {
bool LSCompiler::debugBuild = true;

utString LSCompiler::sdkPath = ".";

// for build files + source
utArray<utString> LSCompiler::sourcePath;

// for binary assemblies you may be building against
utArray<utString> LSCompiler::assemblyPath;

utArray<Type *>     LSCompiler::importedTypes;
utArray<Assembly *> LSCompiler::importedAssemblies;

bool LSCompiler::dumpSymbols = false;

// the root build file, for linker and generating dependencies
utString  LSCompiler::rootBuildFile;
BuildInfo *LSCompiler::rootBuildInfo = NULL;

utArray<utString> LSCompiler::rootDependencies;
utArray<utString> LSCompiler::rootLibDependencies;

utArray<BuildInfo *> LSCompiler::rootBuildDependencies;

json_t            *LSCompiler::loomConfigJSON = NULL;
utArray<utString> LSCompiler::loomConfigClassPath;

const char* LSCompiler::embeddedSystemAssembly = NULL;

lmDefineLogGroup(LSCompiler::compilerLogGroup, "loom.compiler", 1, LoomLogInfo);
lmDefineLogGroup(LSCompiler::compilerVerboseLogGroup, "loom.compiler.verbose", 0, LoomLogInfo);

void LSCompiler::openCompilerVM()
{
    // create dedicated lua state

    vm = new LSLuaState();
    vm->open();
}


void LSCompiler::closeCompilerVM()
{
    vm->close();
    delete vm;
    vm = NULL;
}


void LSCompiler::compileTypes(CompilationUnit *cunit)
{
    for (UTsize i = 0; i < cunit->classDecls.size(); i++)
    {
        ClassDeclaration *cls = cunit->classDecls.at(i);
        assert(cls->type);

#ifndef LOOM_ENABLE_JIT
        TypeCompiler::compile(cls);
#else
        JitTypeCompiler::compile(cls);
#endif
    }
}


void LSCompiler::processTypes(ModuleBuildInfo *mbi)
{
    // process the fully qualified type information
    for (UTsize j = 0; j < mbi->getNumSourceFiles(); j++)
    {
        utString filename = mbi->getSourceFilename(j);

        CompilationUnit *cunit = mbi->getCompilationUnit(filename);

        logVerbose("Type Qualifying Visitor %s", cunit->filename.c_str());

        TypeQualifyVisitor tqv(vm);
        tqv.visit(cunit);
    }

    // process the member types, so everything is available once
    // we get to the method code
    for (UTsize j = 0; j < mbi->getNumSourceFiles(); j++)
    {
        utString        filename = mbi->getSourceFilename(j);
        CompilationUnit *cunit   = mbi->getCompilationUnit(filename);

        logVerbose("Type Member Visitor %s", cunit->filename.c_str());

        MemberTypeVisitor mtv(vm, cunit);
        mtv.processMemberTypes();
    }

    // generate type info for method code
    for (UTsize j = 0; j < mbi->getNumSourceFiles(); j++)
    {
        utString        filename = mbi->getSourceFilename(j);
        CompilationUnit *cunit   = mbi->getCompilationUnit(filename);

        logVerbose("Type Visitor %s", cunit->filename.c_str());

        TypeVisitor tv(vm);
        tv.visit(cunit);
    }

    // if we have any compiler errors, dump them and exit
    if (LSCompilerLog::getNumErrors())
    {
        LSCompilerLog::dump();
        exit(EXIT_FAILURE);
    }

    // validate types
    for (UTsize j = 0; j < mbi->getNumSourceFiles(); j++)
    {
        utString filename = mbi->getSourceFilename(j);

        CompilationUnit *cunit = mbi->getCompilationUnit(filename);

        logVerbose("Type Validating %s", cunit->filename.c_str());

        for (UTsize k = 0; k < cunit->classDecls.size(); k++)
        {
            TypeValidator tv(vm, cunit, cunit->classDecls.at(k));
            tv.validate();
        }
    }

    // if we have any compiler errors, dump them and exit
    if (LSCompilerLog::getNumErrors())
    {
        LSCompilerLog::dump();
        exit(EXIT_FAILURE);
    }
}


void LSCompiler::compileModules()
{
    for (UTsize i = 0; i < buildInfo->getNumModules(); i++)
    {
        ModuleBuildInfo *mbi = buildInfo->getModule(i);

        processTypes(mbi);

        for (UTsize j = 0; j < mbi->getNumSourceFiles(); j++)
        {
            utString        filename = mbi->getSourceFilename(j);
            CompilationUnit *cunit   = mbi->getCompilationUnit(filename);
            compileTypes(cunit);
        }
    }
}


void LSCompiler::processLoomConfig()
{
    utArray<unsigned char> configBytes;
    json_t                 *json = NULL;

    if (utFileStream::tryReadToArray("./loom.config", configBytes, true))
    {
        if (configBytes.size())
        {
            json_error_t error;
            json = json_loads((const char *)configBytes.ptr(), JSON_DISABLE_EOF_CHECK, &error);


            lmAssert(json, "JSON Error: Line %i Column %i Position %i, %s (Source: %s)", error.line, error.column, error.position, error.text, "./loom.config");
        }
    }

    // if we don't have a loom.config or it is empty, initial empty json config
    if (!json)
    {
        json = json_object();
    }

    // add default
    addSourcePath("./src");

    json_t *classpath = json_object_get(json, "classpath");

    if (classpath)
    {
        lmAssert(json_is_array(classpath), "malformed classpath array in loom.config JSON");

        // if we have a classpath array, no default
        sourcePath.clear();

        for (size_t i = 0; i < json_array_size(classpath); i++)
        {
            json_t *path = json_array_get(classpath, i);

            lmAssert(json_is_string(path), "non-string in classpath array in loom.config JSON");

            const char *spath = json_string_value(path);

            if (loomConfigClassPath.find(spath) != UT_NPOS)
            {
                lmAssert(0, "duplicate path in classpath array in loom.config JSON");
            }

            loomConfigClassPath.push_back(spath);

            addSourcePath(spath);
        }
    }

    // and store to static var
    loomConfigJSON = json;
}


void LSCompiler::processExecutableConfig(AssemblyBuilder *ab)
{
    lmAssert(loomConfigJSON, "loomConfigJSON not initialized");

    utHashTable<utHashedString, utString> defs;

    for (UTsize i = 0; i < LSLuaState::getNumCommandlineArgs(); i++)
    {
        const char *arg = LSLuaState::getCommandlineArg(i).c_str();

        if ((strlen(arg) >= 3) && (arg[0] == '-') && (arg[1] == 'D'))
        {
            char key[1024];
            char value[1024];

            lmAssert(strlen(arg) < 1023, "argument buffer overflow");

            key[0] = value[0] = 0;

            strcpy(key, &arg[2]);

            if (strstr(arg, "="))
            {
                key[strstr(arg, "=") - arg - 2] = 0;
                strcpy(value, strstr(arg, "=") + 1);
            }

            // value defaults to true
            if (!value[0])
            {
                sprintf(value, "true");
            }

            defs.insert(key, value);
        }
    }

    // Add command line defines to config

    json_t *json = json_deep_copy(loomConfigJSON);

    utHashTable<utHashedString, utString>::Iterator itr = defs.iterator();

    while (itr.hasMoreElements())
    {
        const char *key   = itr.peekNextKey().str().c_str();
        const char *value = itr.peekNextValue().c_str();

        json_object_set_new(json, key, json_string(value));

        itr.next();
    }

    const char *out = json_dumps(json, JSON_INDENT(3) | JSON_COMPACT);

    ab->setLoomConfig(out);
}


void LSCompiler::compileAssembly(BuildInfo *buildInfo)
{
    clearImports();

    log("Compiling: %s", buildInfo->getAssemblyName().c_str());

    LSCompiler *compiler = new LSCompiler();

    // open a new (isolated) compiler VM
    compiler->openCompilerVM();

    compiler->vm->setCompiling(true);

    // parses the build file, parses source files, generates AST, etc
    compiler->buildInfo = buildInfo;

    // let the buildInfo know we are debug
    compiler->buildInfo->setDebugBuild(debugBuild);

    // build 1st pass assembly which contains type signatures but no code
    AssemblyBuilder *ab = AssemblyBuilder::create(compiler->buildInfo);

    utString typesAssembly;

    // write out temporary assembly
    ab->writeToString(typesAssembly);

    //load the type signature assembly into our VM (also loads any references)
    Assembly *assembly = compiler->vm->loadTypeAssembly(typesAssembly);

    // compile all modules (types)
    compiler->compileModules();

    // dump any errors/warnings
    LSCompilerLog::dump();

    // if we have any compiler errors, exit
    if (LSCompilerLog::getNumErrors())
    {
        exit(EXIT_FAILURE);
    }

    LSCompilerLog::clear();

    ab->setAssembly(assembly);

    // inject type information
    ab->injectTypes(assembly);

    // inject byte code into assembly builder
    ab->injectByteCode(assembly);

    // write out final assembly
    utString outputDir = compiler->buildInfo->getOutputDir();

    utString ext = ".loom";

    if (compiler->buildInfo->isExecutable())
    {
        processExecutableConfig(ab);
        utString json;
        ab->writeToString(json);

        // output a loom lib for IDE's to consume

        if (dumpSymbols)
        {
            utString jsonFileName;

            if (outputDir.length())
            {
                jsonFileName = outputDir + platform_getFolderDelimiter() + compiler->buildInfo->getAssemblyName() + ".symbols";
            }
            else
            {
                jsonFileName = compiler->buildInfo->getAssemblyName() + ".symbols";
            }

            ab->writeToFile(jsonFileName);

            log("Symbols Generated: %s", jsonFileName.c_str());
        }

        // finally link the root assembly
        linkRootAssembly(json);
    }
    else
    {
        utString jsonFileName;

        ext = ".loomlib";

        if (outputDir.length())
        {
            jsonFileName = outputDir + platform_getFolderDelimiter() + compiler->buildInfo->getAssemblyName() + ext;
        }
        else
        {
            jsonFileName = compiler->buildInfo->getAssemblyName() + ext;
        }

        ab->writeToFile(jsonFileName);
    }


    compiler->vm->setCompiling(false);

    // shut 'er down!
    compiler->closeCompilerVM();

    delete compiler;
}


BuildInfo *LSCompiler::loadBuildFile(const utString& cref)
{
    for (UTsize i = 0; i < sourcePath.size(); i++)
    {
        utString path = sourcePath.at(i);
        path += platform_getFolderDelimiter();
        path += cref;
        if (!strstr(cref.c_str(), ".build"))
        {
            path += ".build";
        }

        utFileStream stream;
        stream.open(path.c_str(), utStream::SM_READ);
        if (stream.isOpen())
        {
            stream.close();

            BuildInfo *buildInfo = BuildInfo::parseBuildFile(path.c_str());
            return buildInfo;
        }
    }

    return NULL;
}


void LSCompiler::compileRootBuildDependencies()
{
    for (UTsize i = 0; i < rootBuildDependencies.size(); i++)
    {
        BuildInfo *buildInfo = rootBuildDependencies.at(i);
        compileAssembly(buildInfo);
    }
}


void LSCompiler::generateRootDependenciesRecursive(const utString& ref)
{
    // We're either going to be compiling against an existing loom assembly
    // or compiling from a build file

    char cref[2048];

    snprintf(cref, 2048, "%s", ref.c_str());
    if (strstr(cref, ".loomlib"))
    {
        *(strstr(cref, ".loomlib")) = 0;
    }

    for (UTsize i = 0; i < rootBuildDependencies.size(); i++)
    {
        BuildInfo *buildInfo = rootBuildDependencies.at(i);
        if (buildInfo->getAssemblyName() == cref)
        {
            return;
        }
    }

    // first look in the src folders for an existing build file
    BuildInfo *buildInfo = loadBuildFile(cref);

    if (buildInfo)
    {
        for (UTsize i = 0; i < buildInfo->getNumReferences(); i++)
        {
            utString rref = buildInfo->getReference(i);
            generateRootDependenciesRecursive(rref);
        }

        rootBuildDependencies.push_back(buildInfo);
    }

    if (rootDependencies.find(ref) == UT_NPOS)
    {
        if (!buildInfo)
        {
            // we're compiling against a .loomlib and won't be rebuilding it
            rootLibDependencies.push_back(ref);
        }

        rootDependencies.push_back(ref);
    }
}


void LSCompiler::generateRootDependencies()
{
    lmAssert(rootBuildInfo, "Root build info is null");

    for (UTsize i = 0; i < rootBuildInfo->getNumReferences(); i++)
    {
        utString ref = rootBuildInfo->getReference(i);
        generateRootDependenciesRecursive(ref);
    }
}


void LSCompiler::linkRootAssembly(const utString& sjson)
{
    json_error_t jerror;
    json_t       *json = json_loadb((const char *)sjson.c_str(), sjson.length(), 0, &jerror);

    lmAssert(json, "Error linking assembly");

    json_t *ref_array = json_object_get(json, "references");
    lmAssert(json, "Error linking assembly, can't get executable references");

    for (UTsize i = 0; i < rootBuildDependencies.size(); i++)
    {
        BuildInfo *buildInfo     = rootBuildDependencies.at(i);
        utString  assemblySource = buildInfo->getOutputDir() + platform_getFolderDelimiter() + buildInfo->getAssemblyName() + ".loomlib";

        utArray<unsigned char> rarray;
        lmAssert(utFileStream::tryReadToArray(assemblySource, rarray), "Unable to load library assembly %s", assemblySource.c_str());

        utBase64 base64 = utBase64::encode64(rarray);

        for (size_t j = 0; j < json_array_size(ref_array); j++)
        {
            json_t   *jref = json_array_get(ref_array, j);
            utString jname = json_string_value(json_object_get(jref, "name"));
            if (buildInfo->getAssemblyName() == jname)
            {
                logVerbose("Linking: %s", jname.c_str());

                json_object_set(jref, "binary", json_string(base64.getBase64().c_str()));
                break;
            }
        }
    }

    // filter the reference array by the import assemblies
    utStack<int> filter;
    for (size_t j = 0; j < json_array_size(ref_array); j++)
    {
        json_t   *jref = json_array_get(ref_array, j);
        utString jname = json_string_value(json_object_get(jref, "name"));

        bool found = false;

        // always find the System assembly, so we don't have to explicitly import from it
        if (jname == "System")
        {
            found = true;
        }

        for (UTsize k = 0; k < importedAssemblies.size() && !found; k++)
        {
            if (importedAssemblies.at(k)->getName() == jname)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            filter.push((int)j);
        }
    }

    while (filter.size())
    {
        json_array_remove(ref_array, filter.pop());
    }

    for (UTsize i = 0; i < rootLibDependencies.size(); i++)
    {
        utString libName = rootLibDependencies.at(i);

        for (size_t j = 0; j < json_array_size(ref_array); j++)
        {
            json_t   *jref = json_array_get(ref_array, j);
            utString jname = json_string_value(json_object_get(jref, "name"));

            if (libName != jname)
            {
                continue;
            }

            logVerbose("Linking: %s", libName.c_str());

            utString delim   = platform_getFolderDelimiter();
            utString libPath = sdkPath + delim + "libs" + delim + libName + ".loomlib";

            utArray<unsigned char> rarray;

            if (libName == "System" && embeddedSystemAssembly)
            {
                size_t embeddedSystemAssemblyLength = strlen(embeddedSystemAssembly);
                rarray.resize((int)(embeddedSystemAssemblyLength + 1));
                memcpy(&rarray[0], embeddedSystemAssembly, embeddedSystemAssemblyLength + 1);
            }
            else
            {
                lmAssert(utFileStream::tryReadToArray(libPath, rarray), "Unable to load library assembly %s", libName.c_str());    
            }

            utBase64 base64 = utBase64::encode64(rarray);
            json_object_set(jref, "binary", json_string(base64.getBase64().c_str()));

            break;
        }
    }

    json_object_set(json, "executable", json_true());

    utString execSource = rootBuildInfo->getOutputDir() + utString(platform_getFolderDelimiter()) + rootBuildInfo->getAssemblyName() + ".loom";

    // generate binary assembly for executable
    BinWriter::writeExecutable(execSource.c_str(), json);

    log("Compile Successful: %s\n", execSource.c_str());
}


void LSCompiler::setSDKBuild(const utString& lscPath)
{
    char lsc[2048];

    snprintf(lsc, 2048, "%s", lscPath.c_str());

    // Slurp off the filename...
    unsigned int len = (unsigned int)(strlen(lsc) - 1);
    while (len-- > 0)
    {
        if ((lsc[len] == '\\') || (lsc[len] == '/'))
        {
            lsc[len] = '\0';
            break;
        }
    }

    // And the tools folder...
    while (len-- > 0)
    {
        if ((lsc[len] == '\\') || (lsc[len] == '/'))
        {
            lsc[len + 1] = '\0'; // This won't cause a buffer overrun because
                                 // we already ate backwards in the previous loop.
                                 // But we do need to preserve the trailing slash.
            break;
        }
    }

    // Then note the path.
    sdkPath = lsc;
    log("SDK Path: %s", sdkPath.c_str());

    AssemblyReader::addLibraryAssemblyPath(sdkPath + "libs");
}


void LSCompiler::log(const char *format, ...)
{
    char* buff;
    va_list args;
    lmLogArgs(args, buff, format);
    lmLog(compilerLogGroup, "%s", buff);
    lmFree(NULL, buff);
}


void LSCompiler::logVerbose(const char *format, ...)
{
    char* buff;
    va_list args;
    lmLogArgs(args, buff, format);
    lmLog(compilerVerboseLogGroup, "%s", buff);
    lmFree(NULL, buff);
}


void LSCompiler::initialize()
{
    AssemblyReader::addLibraryAssemblyPath("./libs");

    if (rootBuildFile.length() != 0)
    {
        rootBuildInfo = loadBuildFile(rootBuildFile);
    }
    else
    {
        rootBuildInfo = BuildInfo::createDefaultBuildFile();
    }

    if (!rootBuildInfo)
    {
        lmLog(compilerLogGroup, "Unable to open build info file '%s'", rootBuildFile.c_str());
        exit(EXIT_FAILURE);
    }

    if (rootBuildInfo->parseErrors)
    {
        lmLog(compilerLogGroup, "Please fix the following parser errors and recompile");
        LSCompilerLog::dump();
        exit(EXIT_FAILURE);
    }

    generateRootDependencies();

    compileRootBuildDependencies();
    compileAssembly(rootBuildInfo);
}
}
