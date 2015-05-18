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

#include "loom/script/reflection/lsModule.h"
#include "loom/script/runtime/lsLuaState.h"

#include "loom/script/serialize/lsMemberInfoReader.h"
#include "loom/script/serialize/lsMethodReader.h"
#include "loom/script/serialize/lsPropertyInfoReader.h"

namespace LS {
PropertyInfo *PropertyInfoReader::deserializePropertyInfo(Type   *declaringType,
                                                          json_t *json)
{
    PropertyInfo *pi = lmNew(NULL) PropertyInfo();

    MemberInfoReader::deserialize(pi, json);

    // handle attr
    json_t *marray = json_object_get(json, "propertyattributes");

    for (size_t i = 0; i < json_array_size(marray); i++)
    {
        utString modifier = json_string_value(json_array_get(marray, i));

        if (modifier == "static")
        {
            pi->attr.isStatic = true;
        }
        else if (modifier == "public")
        {
            pi->attr.isPublic = true;
        }
        else if (modifier == "private")
        {
            pi->attr.isPrivate = true;
        }
        else if (modifier == "protected")
        {
            pi->attr.isProtected = true;
        }
        else if (modifier == "native")
        {
            pi->attr.isNative = true;
        }
    }

    utString stype = json_string_value(json_object_get(json, "type"));
    if (stype.size() > 0)
    {
        // a shortcut?
        pi->type =
            declaringType->getModule()->getAssembly()->getLuaState()->getType(
                stype.c_str());
        assert(pi->type);
    }

    json_t *getter = json_object_get(json, "getter");
    json_t *setter = json_object_get(json, "setter");

    if (getter)
    {
        MethodBase *m = NULL;
        m = MethodReader::deserializeMethodInfo(declaringType, getter);
        assert(m->isMethod());
        pi->getter = (MethodInfo *)m;

        m->setPropertyInfo(pi);
    }

    if (setter)
    {
        MethodBase *m = NULL;
        m = MethodReader::deserializeMethodInfo(declaringType, setter);
        assert(m->isMethod());
        pi->setter = (MethodInfo *)m;

        m->setPropertyInfo(pi);
    }

    json_t *ttypes = json_object_get(json, "templatetypes");
    if (ttypes && json_is_object(ttypes))
    {
        TemplateInfo *info = MemberInfoReader::readTemplateTypeInfo(ttypes);
        assert(info);
        info->resolveTypes(Assembly::getAssembly(declaringType)->getLuaState());
        pi->setTemplateInfo(info);
    }


    return pi;
}
}
