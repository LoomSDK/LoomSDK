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
#include "loom/script/reflection/lsFieldInfo.h"
#include "loom/script/reflection/lsMethodInfo.h"
#include "loom/script/serialize/lsMemberInfoReader.h"
#include "loom/script/serialize/lsMethodReader.h"
#include "loom/script/serialize/lsFieldInfoReader.h"
#include "loom/script/serialize/lsPropertyInfoReader.h"
#include "loom/script/serialize/lsTypeReader.h"

#include "loom/script/runtime/lsLuaState.h"

namespace LS {
void TypeReader::declareClass(Type *type, json_t *classJSON)
{
    type->type = type;

    MemberInfoReader::deserialize(type, classJSON);

    // handle class modifiers
    json_t *marray = json_object_get(classJSON, "classattributes");
    for (size_t i = 0; i < json_array_size(marray); i++)
    {
        utString modifier = json_string_value(json_array_get(marray, i));
        if (modifier == "public")
        {
            type->attr.isPublic = true;
        }
        if (modifier == "static")
        {
            type->attr.isStatic = true;
        }
        if (modifier == "final")
        {
            type->attr.isFinal = true;
        }
    }

    type->packageName = json_string_value(
        json_object_get(classJSON, "package"));
    type->fullName  = type->packageName + ".";
    type->fullName += type->name;

    MetaInfo *meta = type->getMetaInfo("Native");
    if (meta)
    {
        type->attr.isNative = true;

        if (meta->keys.find("managed") != UT_NPOS)
        {
            type->attr.isNativeManaged = true;
        }
    }
}


Type *TypeReader::declareType(Module *module, json_t *json)
{
    Type *type = new Type();

    const char *stype = json_string_value(json_object_get(json, "type"));

    if (!strcmp(stype, "CLASS"))
    {
        type->attr.isClass = true;
    }
    else if (!strcmp(stype, "INTERFACE"))
    {
        type->attr.isInterface = true;
    }
    else if (!strcmp(stype, "STRUCT"))
    {
        type->attr.isStruct = true;
    }
    else if (!strcmp(stype, "DELEGATE"))
    {
        type->attr.isDelegate = true;
    }
    else if (!strcmp(stype, "ENUM"))
    {
        type->attr.isEnum = true;
    }
    else
    {
        assert(0); //, "Unknown type: %s", stype);
    }
    declareClass(type, json);

    return type;
}


void TypeReader::deserializeClass(Type *type, json_t *classJSON)
{
    utString sbaseType = json_string_value(
        json_object_get(classJSON, "baseType"));

    if (sbaseType.size() > 0)
    {
        Type *baseType =
            type->getModule()->getAssembly()->getLuaState()->getType(
                sbaseType.c_str());
        lmAssert(baseType != NULL, "Unable to resolve type '%s' referenced as base of type '%s'",
                 sbaseType.c_str(), type->getFullName().c_str());
        type->setBaseType(baseType);
    }

    json_t *jinterfaces = json_object_get(classJSON, "interfaces");

    for (size_t i = 0; i < json_array_size(jinterfaces); i++)
    {
        json_t   *o     = json_array_get(jinterfaces, i);
        utString sface  = json_string_value(o);
        Type     *itype = type->getModule()->getAssembly()->getLuaState()->getType(
            sface.c_str());
        assert(itype);
        type->addInterface(itype);
    }

    json_t *jdelegateTypes = json_object_get(classJSON, "delegateTypes");

    for (size_t i = 0; i < json_array_size(jdelegateTypes); i++)
    {
        json_t   *o     = json_array_get(jdelegateTypes, i);
        utString stype  = json_string_value(o);
        Type     *itype = type->getModule()->getAssembly()->getLuaState()->getType(
            stype.c_str());
        assert(itype);
        type->addDelegateType(itype);
    }

    utString sdelegateReturnType = json_string_value(
        json_object_get(classJSON, "delegateReturnType"));

    if (sdelegateReturnType.size() > 0)
    {
        Type *delegateReturnType =
            type->getModule()->getAssembly()->getLuaState()->getType(
                sdelegateReturnType.c_str());
        assert(delegateReturnType);
        type->setDelegateReturnType(delegateReturnType);
    }

    // meta data

    MemberInfoReader::deserializeMetaInfo(type, json_object_get(classJSON, "metainfo"));

    // handle imports
    json_t *iarray = json_object_get(classJSON, "imports");
    for (size_t i = 0; i < json_array_size(iarray); i++)
    {
        json_t   *jimport = json_array_get(iarray, i);
        utString import   = json_string_value(jimport);

        Type *timport =
            type->getModule()->getAssembly()->getLuaState()->getType(
                import.c_str());
        type->addImport(timport);
    }

    json_t *jconstructor = json_object_get(classJSON, "constructor");
    if (jconstructor)
    {
        MethodBase *m = NULL;
        m = MethodReader::deserializeConstructorInfo(type, jconstructor);
        type->addMember(m);
    }

    // handle fields
    json_t *farray = json_object_get(classJSON, "fields");
    for (size_t i = 0; i < json_array_size(farray); i++)
    {
        json_t    *fo = json_array_get(farray, i);
        FieldInfo *f  = FieldInfoReader::deserializeFieldInfo(type, fo);
        type->addMember(f);
    }

    // handle properties

    json_t *parray = json_object_get(classJSON, "properties");
    for (size_t i = 0; i < json_array_size(parray); i++)
    {
        json_t       *po = json_array_get(parray, i);
        PropertyInfo *p  = PropertyInfoReader::deserializePropertyInfo(type, po);
        type->addMember(p);
    }

    // handle methods
    farray = json_object_get(classJSON, "methods");
    for (size_t i = 0; i < json_array_size(farray); i++)
    {
        json_t *fo = json_array_get(farray, i);

        MethodBase *m = NULL;
        m = MethodReader::deserializeMethodInfo(type, fo);
        type->addMember(m);
    }

    const char *bc = json_string_value(
        json_object_get(classJSON, "bytecode_staticinitializer"));

    type->setBCStaticInitializer(ByteCode::decode64(bc));

    bc = json_string_value(
        json_object_get(classJSON, "bytecode_instanceinitializer"));

    type->setBCInstanceInitializer(ByteCode::decode64(bc));
}


Type *TypeReader::deserialize(Module *module, json_t *json)
{
    Type *type = NULL;

    const char *stype = json_string_value(json_object_get(json, "type"));

    utString packageName = json_string_value(json_object_get(json, "package"));
    utString name        = json_string_value(json_object_get(json, "name"));
    utString fullName    = packageName + ".";

    fullName += name;

    type = module->getType(fullName);
    assert(type); //, "Cannot get type for %s", fullName.c_str());

    json_t *jtypeid = json_object_get(json, "typeid");
    assert(jtypeid && json_is_number(jtypeid));

    type->setTypeID((LSTYPEID)json_number_value(jtypeid));

    if (!strcmp(stype, "CLASS"))
    {
        type->attr.isClass = true;
    }
    else if (!strcmp(stype, "INTERFACE"))
    {
        type->attr.isInterface = true;
    }
    else if (!strcmp(stype, "STRUCT"))
    {
        type->attr.isStruct = true;
    }
    else if (!strcmp(stype, "DELEGATE"))
    {
        type->attr.isDelegate = true;
    }
    else if (!strcmp(stype, "ENUM"))
    {
        type->attr.isEnum = true;
    }
    else
    {
        assert(0); //, "Unknown type: %s", stype);
    }

    json_t *jsource = json_object_get(json, "source");
    if (jsource && json_is_string(jsource))
    {
        type->source     = json_string_value(jsource);
        type->lineNumber = (int)json_integer_value(json_object_get(json, "line"));
    }

    json_t *jdocstring = json_object_get(json, "docString");
    if (jdocstring && json_is_string(jdocstring))
    {
        if (strlen(json_string_value(jdocstring)))
        {
            type->setDocString(json_string_value(jdocstring));
        }
    }


    deserializeClass(type, json);

    assert(type);
    return type;
}
}
