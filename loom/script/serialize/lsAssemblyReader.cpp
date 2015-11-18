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

#include "loom/common/utils/utSHA2.h"
#include "loom/common/utils/guid.h"
#include "loom/script/serialize/lsModuleReader.h"
#include "loom/script/serialize/lsAssemblyReader.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/common/lsError.h"
#include "loom/common/utils/utBase64.h"
#include "loom/common/core/assert.h"

#if LOOM_PLATFORM != LOOM_PLATFORM_IOS && LOOM_PLATFORM != LOOM_PLATFORM_ANDROID 
#include "loom/script/compiler/lsCompiler.h"
#endif

namespace LS 
{

utHashTable<utHashedString, utString> AssemblyReader::linkedAssemblies;
utArray<utString> AssemblyReader::libraryAssemblyPath;

bool AssemblyReader::loadLibraryAssemblyJSON(const utString& assemblyName, utString& json)
{

#if LOOM_PLATFORM != LOOM_PLATFORM_IOS && LOOM_PLATFORM != LOOM_PLATFORM_ANDROID 
    if (assemblyName == "System" && LSCompiler::getEmbeddedSystemAssembly())
    {
        json = LSCompiler::getEmbeddedSystemAssembly();
        return true;
    }
#endif    

    for (UTsize i = 0; i < libraryAssemblyPath.size(); i++)
    {
        utString path = libraryAssemblyPath.at(i);
        path += "/";
        path += assemblyName;
        path += ".loomlib";


        utArray<unsigned char> buffer;
        if (utFileStream::tryReadToArray(path.c_str(), buffer))
        {
            json = (const char *)buffer.ptr();
            return true;
        }
    }

    return false;
}


void AssemblyReader::parseLinkedAssemblies(json_t *executableJSON)
{
    json_t *ref_array = json_object_get(executableJSON, "references");

    lmAssert(ref_array, "Error with executable assembly, missing references section");

    for (size_t j = 0; j < json_array_size(ref_array); j++)
    {
        json_t   *jref    = json_array_get(ref_array, j);
        utString name     = json_string_value(json_object_get(jref, "name"));
        json_t   *jbinary = json_object_get(jref, "binary");
        lmAssert(jbinary, "Error with linked assembly %s, missing binary section", name.c_str());
        utString binary = (const char *)utBase64::decode64(json_string_value(jbinary)).getData().ptr();
        linkedAssemblies.insert(utHashedString(name), binary);
    }
}


Assembly *AssemblyReader::deserialize(LSLuaState *vm, const utString& sjson)
{
    json_error_t jerror;
    json_t       *json = json_loadb(sjson.c_str(), sjson.size(), 0, &jerror);

    lmAssert(json, "Error loading Assembly json: %s\n %s %i\n", jerror.source, jerror.text, jerror.line);

    utString type       = json_string_value(json_object_get(json, "type"));
    utString name       = json_string_value(json_object_get(json, "name"));
    utString version    = json_string_value(json_object_get(json, "version"));
    utString uid        = json_string_value(json_object_get(json, "uid"));
    utString loomconfig = json_string_value(json_object_get(json, "loomconfig"));

    bool executable = false;
    if (json_object_get(json, "executable") && json_is_true(json_object_get(json, "executable")))
    {
        executable = true;
        parseLinkedAssemblies(json);
        printf("Loading executable assembly: %s.loom\n", name.c_str());
    }

    if (type != "ASSEMBLY")
    {
        LSError("Assembly %s type string not found", name.c_str());
    }

#ifdef LOOM_ENABLE_JIT
    if (!json_is_true(json_object_get(json, "jit")))
    {
        LSError("Assembly %s.loom has interpreted bytecode, JIT required", name.c_str());
    }
#else
    if (json_is_true(json_object_get(json, "jit")))
    {
        LSError("Assembly %s.loom has JIT bytecode, interpreted required", name.c_str());
    }
#endif

    if (uid.length() == 0)
    {
        loom_guid_t guid;
        loom_generate_guid(guid);
        uid = guid;
    }

    Assembly *assembly = Assembly::getLoaded(vm, name, uid);
    if (assembly != NULL)
    {
        return assembly;
    }

    assembly = Assembly::create(vm, name, uid);

    assembly->setLoomConfig(loomconfig);

    if (json_is_false(json_object_get(json, "debugbuild")))
    {
        assembly->setDebugBuild(false);
    }
    else
    {
        assembly->setDebugBuild(true);
    }

    // load references
    json_t *refArray = json_object_get(json, "references");

    for (UTsize i = 0; i < json_array_size(refArray); i++)
    {
        Assembly *rasm = NULL;

        json_t *ref = json_array_get(refArray, i);

        utString refname = json_string_value(json_object_get(ref, "name"));

        assembly->addReference(refname);

        // if we've already loaded this assembly continue
        if (vm->getAssembly(refname))
        {
            continue;
        }

        utString *sjson = linkedAssemblies.get(utHashedString(refname));

        if (sjson)
        {
            rasm = vm->loadAssemblyJSON(*sjson);
        }
        else
        {
            utString fileJSON;
            if (loadLibraryAssemblyJSON(refname, fileJSON))
            {
                rasm = vm->loadAssemblyJSON(fileJSON);
            }
            else
            {
                lmAssert(0, "Unable to load assembly '%s' as either a library or an executable!'", refname.c_str());
            }
        }
    }

    // modules
    json_t *moduleArray = json_object_get(json, "modules");

    // first pass is to declare module types
    for (UTsize i = 0; i < json_array_size(moduleArray); i++)
    {
        json_t *jmodule = json_array_get(moduleArray, i);

        ModuleReader::declareTypes(assembly, jmodule);
    }

    // next pass is to deserialize fully
    for (UTsize i = 0; i < json_array_size(moduleArray); i++)
    {
        json_t *jmodule = json_array_get(moduleArray, i);

        ModuleReader::deserialize(assembly, jmodule);
    }

    if (executable)
    {
        linkedAssemblies.clear();
    }

    return assembly;
}
}
