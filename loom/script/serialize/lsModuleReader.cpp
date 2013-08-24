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

#include "loom/script/serialize/lsTypeReader.h"
#include "loom/script/serialize/lsModuleReader.h"

namespace LS {
Type *ModuleReader::declareType(Module *module, json_t *json)
{
    Type *type = TypeReader::declareType(module, json);

    module->addType(type);
    return type;
}


void ModuleReader::declareTypes(Assembly *assembly, json_t *json)
{
    utString type    = json_string_value(json_object_get(json, "type"));
    utString name    = json_string_value(json_object_get(json, "name"));
    utString version = json_string_value(json_object_get(json, "version"));

    if (type != "MODULE")
    {
        abort();
    }

    Module *module = Module::create(assembly, name);

    // declare types
    json_t *typeArray = json_object_get(json, "types");

    for (UTsize i = 0; i < json_array_size(typeArray); i++)
    {
        declareType(module, json_array_get(typeArray, i));
    }
}


Type *ModuleReader::deserializeType(Module *module, json_t *json)
{
    Type *type = TypeReader::deserialize(module, json);

    return type;
}


Module *ModuleReader::deserialize(Assembly *assembly, json_t *json)
{
    utString name = json_string_value(json_object_get(json, "name"));

    Module *module = assembly->getModule(name);

    assert(module);

    // types
    json_t *typeArray = json_object_get(json, "types");

    for (UTsize i = 0; i < json_array_size(typeArray); i++)
    {
        deserializeType(module, json_array_get(typeArray, i));
    }

    return module;
}
}
