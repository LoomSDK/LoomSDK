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

// LoomScript Compiler
#include "loom/common/core/log.h"
#include "loom/common/core/assert.h"
#include "loom/common/platform/platform.h"
#include "loom/common/platform/platformTime.h"
#include "loom/common/platform/platformFile.h"
#include "loom/script/compiler/lsCompiler.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/native/lsNativeDelegate.h"

using namespace LS;

void installPackageSystem();
void installPackageCompiler();

// we'll be able to do this from a unit test project post CLI sprint
// for now, old-sk001 beats!

extern "C" {
void stringtable_initialize();
}

#if LOOM_PLATFORM == LOOM_PLATFORM_OSX
#include <unistd.h>
#include <mach-o/dyld.h> /* _NSGetExecutablePath */

utString GetLSCPath()
{
    char         path[4096];
    unsigned int size = sizeof(path);

    if (_NSGetExecutablePath(path, &size) != 0)
    {
        lmAssert(0, "Error getting executable path");
    }

    return utString(path);
}


#elif LOOM_PLATFORM == LOOM_PLATFORM_WIN32

#include <windows.h>

utString GetLSCPath()
{
    char         path[4096];
    unsigned int size = sizeof(path);

    GetModuleFileName(NULL, path, size);

    return utString(path);
}


#else

#include <unistd.h>

utString GetLSCPath()
{
    char buffer[BUFSIZ];

    readlink("/proc/self/exe", buffer, BUFSIZ);
    return utString(buffer);
}
#endif

utString GetSDKPathFromLSCPath(utString const& lscPath)
{
    char lsc[2048];
    snprintf(lsc, 2048, "%s", lscPath.c_str());

    // Slurp off the filename...
    unsigned int len = strlen(lsc) - 1;
    while (len-- > 0)
    {
        if ((lsc[len] == '\\') || (lsc[len] == '/'))
        {
            lsc[len + 1] = '\0';
            break;
        }
    }

    // And go up the directories until we find one with "lib" in it...
    // But shouldn't be more than 3
    bool found = false;
    for (int i = 0; i <= 3; i++)
    {
        utString searchLib(lsc);
        searchLib += "libs";
        if (platform_dirExists(searchLib.c_str()) == 0)
        {
            found = true;
            break;
        }
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
    }

    if (!found)
    {
        printf("Unable to find SDK libraries somewhere inside %s\n", lsc);
        exit(EXIT_FAILURE);
    }

    return utString(lsc);
}

void RunUnitTests()
{
    LSCompiler::setRootBuildFile("Tests.build");
    LSCompiler::initialize();

    LSLuaState *testVM = new LSLuaState();

    // FIXME:  default paths
    testVM->open();

    Assembly *testAssembly = testVM->loadExecutableAssembly("Tests.loom");
    testAssembly->execute();

    testVM->close();
}


void RunBenchmarks()
{
    LSCompiler::setRootBuildFile("Benchmarks.build");
    LSCompiler::initialize();

    LSLuaState *benchVM = new LSLuaState();

    benchVM->open();

    Assembly *benchAssembly = benchVM->loadExecutableAssembly("Benchmarks.loom");
    benchAssembly->execute();

    benchVM->close();
}


int main(int argc, const char **argv)
{
    stringtable_initialize();
    loom_log_initialize();
    platform_timeInitialize();

    NativeDelegate::markMainThread();

    LSLuaState::initCommandLine(argc, argv);

#ifdef LOOM_ENABLE_JIT
    printf("LSC - JIT Compiler\n");
#else
    printf("LSC - Interpreted Compiler\n");
#endif

    bool runtests      = false;
    bool runbenchmarks = false;
    bool symbols       = false;

    const char *rootBuildFile = NULL;
    const char *sdkRoot = NULL;
    
    for (int i = 1; i < argc; i++)
    {
        if ((strlen(argv[i]) >= 2) && (argv[i][0] == '-') && (argv[i][1] == 'D'))
        {
            continue;
        }
        else if (!strcmp(argv[i], "--release"))
        {
            LSCompiler::setDebugBuild(false);
        }
        else if (!strcmp(argv[i], "--verbose"))
        {
            LSCompiler::setVerboseLog(true);
        }
        else if (!strcmp(argv[i], "--unittest"))
        {
            runtests = true;
        }
        else if (!strcmp(argv[i], "--benchmark"))
        {
            runbenchmarks = true;
        }
        else if (!strcmp(argv[i], "--symbols"))
        {
            symbols = true;
        }
        else if (!strcmp(argv[i], "--xmlfile"))
        {
            i++;      // skip the filename
            continue; // unit tests option
        }
        else if (!strcmp(argv[i], "--root"))
        {
            i++;
            if (i >= argc)
            {
                LSError("--root option requires folder to be specified");
            }
            
            printf("Root set to %s\n", argv[i]);
            sdkRoot = argv[i];
        }
        else if (!strcmp(argv[i], "--project"))
        {
            i++;
            if (i >= argc)
            {
                LSError("--root option requires folder to be specified");
            }

            printf("Project folder set to %s\n", argv[i]);

#if LOOM_PLATFORM == LOOM_PLATFORM_OSX || LOOM_PLATFORM == LOOM_PLATFORM_LINUX
            chdir(argv[i]);
#elif LOOM_PLATFORM == LOOM_PLATFORM_WIN32
            ::SetCurrentDirectory(argv[i]);
#endif
        }
        else if (!strcmp(argv[i], "--help"))
        {
            printf("--release : build in release mode\n");
            printf("--verbose : enable verbose compilation\n");
            printf("--unittest [--xmlfile filename.xml]: run unit tests with optional xml file output\n");
            printf("--root: set the SDK root\n");
            printf("--project: set the project folder\n");
            printf("--symbols : dump symbols for binary executable\n");
            printf("--help: display this help\n");
        }
        else if (strstr(argv[i], ".build"))
        {
            rootBuildFile = argv[i];
        }
        else
        {
            printf("unknown option: %s\n", argv[i]);
            printf("lsc --help for a list of options\n");
            return EXIT_FAILURE;
        }
    }

    installPackageSystem();
    installPackageCompiler();

    LSCompiler::processLoomConfig();

    if (runtests)
    {
        RunUnitTests();
        return EXIT_SUCCESS;
    }

    if (runbenchmarks)
    {
        RunBenchmarks();
        return EXIT_SUCCESS;
    }

    LSCompiler::setDumpSymbols(symbols);

    // todo, better sdk detection
    // TODO: LOOM-690 - find a better paradigm here.
    //Check we are trimming a valid path
    utString lscPath = GetLSCPath();

    if (sdkRoot != NULL)
    {
        LSCompiler::setSDKBuild(sdkRoot);
    }
    else if (strstr(lscPath.c_str(), "loom/sdks/") || strstr(lscPath.c_str(), "loom\\sdks\\"))
    {
        LSCompiler::setSDKBuild(GetSDKPathFromLSCPath(lscPath));
    }
    else
    {
        // In-SDK-repo build
        const char* found = NULL;
        if (!found) found = strstr(lscPath.c_str(), "build/loom-");
        if (!found) found = strstr(lscPath.c_str(), "build\\loom-");
        if (found)
        {
            utString artifacts = lscPath.substr(0, found - lscPath.c_str()) + "artifacts";
            artifacts += platform_getFolderDelimiter();
            if (platform_dirExists(artifacts.c_str()) == 0) LSCompiler::setSDKBuild(artifacts);
        }
    }

    if (!rootBuildFile)
    {
        printf("Building Main.loom with default settings\n");
        LSCompiler::defaultRootBuildFile();
    }
    else
    {
        printf("Building %s\n", rootBuildFile);
        LSCompiler::setRootBuildFile(rootBuildFile);
    }


    LSCompiler::initialize();

    return EXIT_SUCCESS;
}
