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

#include "loom/script/serialize/lsMemberInfoReader.h"
#include "loom/script/serialize/lsMethodReader.h"
#include "loom/script/runtime/lsLuaState.h"
#include "loom/script/runtime/lsRuntime.h"
#include "loom/script/common/lsError.h"

namespace LS {
void MethodReader::deserializeMethodBase(MethodBase *base, json_t *json)
{
    MemberInfoReader::deserialize(base, json);

    // handle modifiers
    json_t *marray = json_object_get(json, "methodattributes");

    for (size_t i = 0; i < json_array_size(marray); i++)
    {
        utString modifier = json_string_value(json_array_get(marray, i));

        if (modifier == "static")
        {
            base->attr.isStatic = true;
        }
        else if (modifier == "public")
        {
            base->attr.isPublic = true;
        }
        else if (modifier == "private")
        {
            base->attr.isPrivate = true;
        }
        else if (modifier == "protected")
        {
            base->attr.isProtected = true;
        }
        else if (modifier == "native")
        {
            base->attr.isNative = true;
        }
        else if (modifier == "virtual")
        {
            base->attr.isVirtual = true;
        }
        else if (modifier == "supercall")
        {
            base->attr.hasSuperCall = true;
        }
        else if (modifier == "operator")
        {
            base->attr.isOperator = true;
        }
    }

    // template types on return
    json_t *ttypes = json_object_get(json, "templatetypes");
    if (ttypes && json_is_object(ttypes))
    {
        TemplateInfo *info = MemberInfoReader::readTemplateTypeInfo(ttypes);
        assert(info);
        info->resolveTypes(Assembly::getAssembly(base->getDeclaringType())->getLuaState());
        base->setTemplateInfo(info);
    }

    // parameters
    json_t *parray = json_object_get(json, "parameters");
    for (size_t i = 0; i < json_array_size(parray); i++)
    {
        json_t *p = json_array_get(parray, i);

        ParameterInfo *param = lmNew(NULL) ParameterInfo();

        param->position = (int)i;

        param->name = json_string_value(json_object_get(p, "name"));

        base->parameters.push_back(param);

        utString stype = json_string_value(json_object_get(p, "type"));
        if (stype.size() > 0)
        {
            // a shortcut?
            param->member        = base;
            param->parameterType =
                base->declaringType->getModule()->getAssembly()->getLuaState()->getType(
                    stype.c_str());
            assert(param->parameterType);
        }

        if (json_is_true(json_object_get(p, "hasdefault")))
        {
            param->attributes.hasDefault = true;
        }

        if (param->attributes.hasDefault)
        {
            param->defaultArg = json_string_value(json_object_get(p, "defaultvalue"));
        }

        if (json_is_true(json_object_get(p, "isvarargs")))
        {
            param->attributes.isVarArgs = true;
        }

        // handle template types
        json_t *ttypes = json_object_get(p, "templatetypes");
        {
            for (size_t i = 0; i < json_array_size(ttypes); i++)
            {
                utString ttype = json_string_value(json_array_get(ttypes, i));
                Type     *type =
                    Assembly::getAssembly(base->declaringType)->getLuaState()->getType(
                        ttype.c_str());
                assert(type);
                param->addTemplateType(type);
            }
        }
    }

    // find first default argument
    for (UTsize i = 0; i < base->parameters.size(); i++)
    {
        if (base->parameters.at(i)->attributes.hasDefault)
        {
            base->firstDefaultArg = i;
            break;
        }
    }

    LSLuaState *VM = base->getType()->getAssembly()->getLuaState();

    if (base->isNative() && !VM->isCompiling())
    {
        lua_CFunction function = NULL;

        lua_State *L = VM->VM();

        int top = lua_gettop(L);

        lua_settop(L, top);

        lsr_pushmethodbase(L, base);

        if (!lua_isnil(L, -1))
        {
            function = lua_tocfunction(L, -1);
        }

        lua_pop(L, 1);

        if (!function)
        {
            if (base->declaringType->isPrimitive() && base->isStatic())
            {
                LSError("Missing primitive native function %s:%s",
                        base->declaringType->getFullName().c_str(),
                        base->name.c_str());
            }
            else if (!base->declaringType->isPrimitive())
            {
                LSError("Missing native function %s:%s",
                        base->declaringType->getFullName().c_str(),
                        base->name.c_str());
            }
        }
        else
        {
            if (base->declaringType->isPrimitive() && !base->isStatic())
            {
                LSError("Unnecessary primitive native instance function %s:%s",
                        base->declaringType->getFullName().c_str(),
                        base->name.c_str());
            }
        }
    }
    else
    {
        base->setByteCode(ByteCode::decode64(json_string_value(json_object_get(json, "bytecode"))));
    }
}


MethodInfo *MethodReader::deserializeMethodInfo(Type   *declaringType,
                                                json_t *json)
{
    MethodInfo *mi = lmNew(NULL) MethodInfo();

    mi->memberType.method = true;

    mi->declaringType = declaringType;

    // a shortcut?
    mi->type = declaringType->getModule()->getAssembly()->getLuaState()->getType("system.Function");
    assert(mi->type);

    utString returnType = json_string_value(
        json_object_get(json, "returntype"));
    if (returnType.size() > 0)
    {
        mi->setReturnType(
            declaringType->getModule()->getAssembly()->getLuaState()->getType(
                returnType.c_str()));
        assert(mi->getReturnType());
    }

    deserializeMethodBase(mi, json);

    return mi;
}


ConstructorInfo *MethodReader::deserializeConstructorInfo(Type   *declaringType,
                                                          json_t *json)
{
    ConstructorInfo *mi = lmNew(NULL) ConstructorInfo();

    mi->memberType.constructor = true;

    mi->declaringType = declaringType;

    // a shortcut?
    mi->type = Assembly::getAssembly(declaringType)->getLuaState()->getType(
        "system.Function");
    assert(mi->type);     // If this fires you almost certainly haven't loaded the
    // standard loomlibs yet, likely they aren't being found.

    if (json_is_true(json_object_get(json, "defaultconstructor")))
    {
        mi->defaultConstructor = true;
    }
    else
    {
        mi->defaultConstructor = false;
    }

    deserializeMethodBase(mi, json);

    return mi;
}
}
