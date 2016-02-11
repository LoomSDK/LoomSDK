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

#include "loom/script/compiler/lsCompiler.h"
#include "loom/common/core/assert.h"
#include "loom/common/utils/utStreams.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/runtime/lsProfiler.h"
#include "loom/script/serialize/lsAssemblyWriter.h"
#include "loom/script/common/lsError.h"
#include "loom/common/utils/utBase64.h"

namespace LS {
void AssemblyWriter::writeToString(utString& out)
{
    json_t *json = json_object();

    json_object_set(json, "type", json_string("ASSEMBLY"));
    json_object_set(json, "name", json_string(name.c_str()));
    json_object_set(json, "version", json_string(version.c_str()));
    json_object_set(json, "uid", json_string(uid.c_str()));
    json_object_set(json, "loomconfig", json_string(loomConfig.c_str()));

#ifdef LOOM_ENABLE_JIT
    json_object_set(json, "jit", json_true());
#else
    json_object_set(json, "jit", json_false());
#endif

    json_object_set(json, "debugbuild", LSCompiler::isDebugBuild() ? json_true() : json_false());

    // references

    json_t *refArray = json_array();

    json_object_set(json, "references", refArray);

    for (UTsize i = 0; i < references.size(); i++)
    {
        utString assemblyName = references.at(i);

        json_t *ro = json_object();

        json_object_set(ro, "name", json_string(assemblyName.c_str()));

        json_array_append(refArray, ro);
    }

    // modules

    json_t *moduleArray = json_array();

    json_object_set(json, "modules", moduleArray);

    for (UTsize i = 0; i < modules.size(); i++)
    {
        json_t *mjson = modules[i]->write();
        json_array_append(moduleArray, mjson);
    }

    out = json_dumps(json, JSON_INDENT(3) | JSON_SORT_KEYS | JSON_PRESERVE_ORDER | JSON_COMPACT);
}


void AssemblyWriter::writeToFile(const utString& filename)
{
    utString out;

    writeToString(out);

    // ... and write it
    utFileStream fs;

    fs.open(filename.c_str(), utStream::SM_WRITE);

    if (fs.isOpen())
    {
        fs.write(out.c_str(), (int)out.size());

        fs.close();
    }
    else
    {
        LSError("Could not write to %s", filename.c_str());
    }
}
}
