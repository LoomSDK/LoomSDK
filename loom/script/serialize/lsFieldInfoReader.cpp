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
#include "loom/script/serialize/lsFieldInfoReader.h"

namespace LS {
FieldInfo *FieldInfoReader::deserializeFieldInfo(Type   *declaringType,
                                                 json_t *json)
{
    FieldInfo *fi = lmNew(NULL) FieldInfo();

    MemberInfoReader::deserialize(fi, json);

    fi->memberType.field = true;

    fi->declaringType = declaringType;

    // handle attr
    json_t *marray = json_object_get(json, "fieldattributes");
    for (size_t i = 0; i < json_array_size(marray); i++)
    {
        utString modifier = json_string_value(json_array_get(marray, i));

        if (modifier == "static")
        {
            fi->attr.isStatic = true;
        }
        else if (modifier == "public")
        {
            fi->attr.isPublic = true;
        }
        else if (modifier == "private")
        {
            fi->attr.isPrivate = true;
        }
        else if (modifier == "protected")
        {
            fi->attr.isProtected = true;
        }
        else if (modifier == "native")
        {
            fi->attr.isNative = true;
        }
        else if (modifier == "const")
        {
            fi->attr.isConst = true;
        }
    }

    utString stype = json_string_value(json_object_get(json, "type"));
    if (stype.size() > 0)
    {
        // a shortcut?
        fi->type =
            declaringType->getModule()->getAssembly()->getLuaState()->getType(
                stype.c_str());
        assert(fi->type);
    }

    // handle template types

    json_t *ttypes = json_object_get(json, "templatetypes");
    if (ttypes && json_is_object(ttypes))
    {
        TemplateInfo *info = MemberInfoReader::readTemplateTypeInfo(ttypes);
        assert(info);
        info->resolveTypes(Assembly::getAssembly(declaringType)->getLuaState());
        fi->setTemplateInfo(info);
    }

    return fi;
}
}
