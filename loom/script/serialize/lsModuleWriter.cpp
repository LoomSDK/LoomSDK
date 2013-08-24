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

#include "loom/script/serialize/lsModuleWriter.h"

namespace LS {
json_t *ModuleWriter::write()
{
    json_t *json = json_object();

    json_object_set(json, "type", json_string("MODULE"));
    json_object_set(json, "name", json_string(name.c_str()));
    json_object_set(json, "version", json_string(version.c_str()));

    // types
    json_t *typeArray = json_array();
    json_object_set(json, "types", typeArray);

    for (UTsize i = 0; i < types.size(); i++)
    {
        json_t *tjson = types[i]->write();
        json_array_append(typeArray, tjson);
    }

    // dependencies
    json_t *depArray = json_array();
    json_object_set(json, "dependencies", depArray);

    for (UTsize i = 0; i < dependencies.size(); i++)
    {
        json_array_append(depArray, json_string(dependencies[i].c_str()));
    }

    return json;
}
}
