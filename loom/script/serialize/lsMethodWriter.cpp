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

#include "loom/script/serialize/lsMethodWriter.h"

namespace LS {
json_t *ParameterInfoWriter::write()
{
    json_t *p = json_object();

    json_object_set(p, "name", json_string(name.c_str()));

    json_object_set(p, "type", json_string(fullTypeName.c_str()));

    json_object_set(p, "hasdefault",
                    attr.hasDefault ? json_true() : json_false());

    if (attr.hasDefault)
    {
        json_object_set(p, "defaultvalue", json_string(defaultArg.c_str()));
    }

    json_object_set(p, "isvarargs",
                    attr.isVarArgs ? json_true() : json_false());

    if (templateInfo)
    {
        json_object_set(p, "templatetypes", MemberInfoWriter::writeTemplateTypeInfo(templateInfo));
    }
    else
    {
        json_object_set(p, "templatetypes", json_null());
    }

    return p;
}


void MethodBaseWriter::write(json_t *json)
{
    MemberInfoWriter::write(json);

    json_t *mattr = json_array();

    json_object_set(json, "methodattributes", mattr);

    if (attr.isNative)
    {
        json_array_append(mattr, json_string("native"));
    }
    if (attr.isPublic)
    {
        json_array_append(mattr, json_string("public"));
    }
    if (attr.isPrivate)
    {
        json_array_append(mattr, json_string("private"));
    }
    if (attr.isProtected)
    {
        json_array_append(mattr, json_string("protected"));
    }
    if (attr.isOperator)
    {
        json_array_append(mattr, json_string("operator"));
    }
    if (attr.isStatic)
    {
        json_array_append(mattr, json_string("static"));
    }
    if (attr.hasSuperCall)
    {
        json_array_append(mattr, json_string("supercall"));
    }

    json_t *params = json_array();

    json_object_set(json, "parameters", params);

    for (UTsize i = 0; i < paramWriters.size(); i++)
    {
        json_t *p = paramWriters.at(i)->write();
        json_array_append(params, p);
    }

    if (templateInfo)
    {
        json_object_set(json, "templatetypes", MemberInfoWriter::writeTemplateTypeInfo(templateInfo));
    }
    else
    {
        json_object_set(json, "templatetypes", json_null());
    }

    if (!attr.isNative)
    {
        json_object_set(json, "bytecode", json_string(byteCode.getBase64().c_str()));
#if LOOM_ENABLE_JIT
        json_object_set(json, "bytecode_fr2", json_string(byteCode.getBase64FR2().c_str()));
#endif
    }
    else
    {
        json_object_set(json, "bytecode", json_string(""));
#if LOOM_ENABLE_JIT
        json_object_set(json, "bytecode_fr2", json_string(""));
#endif
    }
}


json_t *MethodInfoWriter::write()
{
    json_t *json = json_object();

    json_object_set(json, "type", json_string("METHOD"));

    MethodBaseWriter::write(json);

    json_object_set(json, "returntype", json_string(returnType.c_str()));

    return json;
}


json_t *ConstructorInfoWriter::write()
{
    json_t *json = json_object();

    json_object_set(json, "type", json_string("CONSTRUCTOR"));
    json_object_set(json, "defaultconstructor", defaultConstructor ? json_true() : json_false());

    MethodBaseWriter::write(json);

    return json;
}
}
