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
#include "loom/script/serialize/lsTypeWriter.h"

namespace LS {
json_t *TypeWriter::write()
{
    json_t *json = json_object();

    json_object_set(json, "typeid", json_integer(typeID));

    if (attr.isClass)
    {
        json_object_set(json, "type", json_string("CLASS"));
    }
    else if (attr.isInterface)
    {
        json_object_set(json, "type", json_string("INTERFACE"));
    }
    else if (attr.isStruct)
    {
        json_object_set(json, "type", json_string("STRUCT"));
    }
    else if (attr.isDelegate)
    {
        json_object_set(json, "type", json_string("DELEGATE"));
    }
    else if (attr.isEnum)
    {
        json_object_set(json, "type", json_string("ENUM"));
    }
    else
    {
        lmAssert(0, "Type isn't a class, interface, struct, or enum %s", typeName.c_str());
    }

    json_t *cattr = json_array();

    json_object_set(json, "classattributes", cattr);

    if (attr.isNative)
    {
        json_array_append(cattr, json_string("native"));
    }

    if (attr.isPublic)
    {
        json_array_append(cattr, json_string("public"));
    }
    else
    {
        json_array_append(cattr, json_string("private"));
    }

    if (attr.isStatic)
    {
        json_array_append(cattr, json_string("static"));
    }

    if (attr.isFinal)
    {
        json_array_append(cattr, json_string("final"));
    }

    json_object_set(json, "name", json_string(typeName.c_str()));
    json_object_set(json, "package", json_string(packageName.c_str()));

    json_object_set(json, "baseType", json_string(baseTypeFullPath.c_str()));

    json_t *jinterfaces = json_array();
    json_object_set(json, "interfaces", jinterfaces);

    for (UTsize i = 0; i < interfaces.size(); i++)
    {
        json_array_append(jinterfaces, json_string(interfaces[i].c_str()));
    }

    json_t *jdelegateTypes = json_array();
    json_object_set(json, "delegateTypes", jdelegateTypes);

    for (UTsize i = 0; i < delegateTypes.size(); i++)
    {
        json_array_append(jdelegateTypes, json_string(delegateTypes[i].c_str()));
    }

    json_object_set(json, "delegateReturnType", json_string(delegateReturnType.c_str()));

    json_object_set(json, "source", json_string(source.c_str()));
    json_object_set(json, "docString", json_string(docString.c_str()));
    json_object_set(json, "line", json_integer(lineNumber));

    json_object_set(json, "metainfo", MemberInfoWriter::writeMetaInfo(&metaInfo));

    // imports

    json_t *importArray = json_array();

    json_object_set(json, "imports", importArray);

    for (UTsize i = 0; i < imports.size(); i++)
    {
        json_t *ijson = json_string(imports.at(i).c_str());
        json_array_append(importArray, ijson);
    }

    // constructor
    if (constructor)
    {
        json_t *cjson = constructor->write();
        json_object_set(json, "constructor", cjson);
    }

    // methods

    json_t *methodArray = json_array();

    json_object_set(json, "methods", methodArray);

    for (UTsize i = 0; i < methods.size(); i++)
    {
        json_t *mjson = methods[i]->write();
        json_array_append(methodArray, mjson);
    }

    // fields

    json_t *fieldArray = json_array();

    json_object_set(json, "fields", fieldArray);

    for (UTsize i = 0; i < fields.size(); i++)
    {
        json_t *fjson = fields[i]->write();
        json_array_append(fieldArray, fjson);
    }

    // properties

    json_t *propArray = json_array();

    json_object_set(json, "properties", propArray);

    for (UTsize i = 0; i < properties.size(); i++)
    {
        json_t *pjson = properties[i]->write();
        json_array_append(propArray, pjson);
    }

    json_object_set(json, "bytecode_staticinitializer",
                    json_string(bcStaticInitializer.getBase64().c_str()));
    json_object_set(json, "bytecode_instanceinitializer",
                    json_string(bcInstanceInitializer.getBase64().c_str()));

#if LOOM_ENABLE_JIT
    json_object_set(json, "bytecode_staticinitializer_fr2",
        json_string(bcStaticInitializer.getBase64FR2().c_str()));
    json_object_set(json, "bytecode_instanceinitializer_fr2",
        json_string(bcInstanceInitializer.getBase64FR2().c_str()));
#endif

    return json;
}
}
