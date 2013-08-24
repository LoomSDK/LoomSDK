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

#include "stdlib.h"
#include "loom/script/serialize/lsMemberInfoReader.h"

namespace LS
{
void MemberInfoReader::deserializeMetaInfo(MemberInfo *memberInfo, json_t *root)
{
    void *iter = json_object_iter(root);

    while (iter)
    {
        utString name = json_object_iter_key(iter);

        json_t *metaArray = json_object_iter_value(iter);

        for (UTsize i = 0; i < json_array_size(metaArray); i++)
        {
            MetaInfo *metaInfo = memberInfo->addUniqueMetaInfo(name);

            json_t *keyArray = json_array_get(metaArray, i);

            for (UTsize j = 0; j < json_array_size(keyArray); j += 2)
            {
                json_t *key   = json_array_get(keyArray, j);
                json_t *value = json_array_get(keyArray, j + 1);
                metaInfo->keys.insert(json_string_value(key), json_string_value(value));
            }
        }

        iter = json_object_iter_next(root, iter);
    }
}


void MemberInfoReader::deserialize(MemberInfo *memberInfo, json_t *memberJSON)
{
    memberInfo->name = json_string_value(json_object_get(memberJSON, "name"));

    json_t *jsource = json_object_get(memberJSON, "source");

    if (jsource && json_is_string(jsource))
    {
        memberInfo->source     = json_string_value(jsource);
        memberInfo->lineNumber = (int)json_integer_value(json_object_get(memberJSON, "line"));
    }

    json_t *jdocstring = json_object_get(memberJSON, "docString");
    if (jdocstring && json_is_string(jdocstring))
    {
        if (strlen(json_string_value(jdocstring)))
        {
            memberInfo->setDocString(json_string_value(jdocstring));
        }
    }

    memberInfo->ordinal = (int)json_integer_value(json_object_get(memberJSON, "ordinal"));

    deserializeMetaInfo(memberInfo, json_object_get(memberJSON, "metainfo"));
}


TemplateInfo *MemberInfoReader::readTemplateTypeInfo(json_t *json)
{
    if (!json_is_object(json))
    {
        return NULL;
    }

    TemplateInfo *tinfo = new TemplateInfo;

    json_t *types = json_object_get(json, "types");

    json_t *type = json_object_get(json, "type");

    tinfo->fullTypeName = json_string_value(type);

    if (!types)
    {
        return NULL;
    }

    for (UTsize i = 0; i < json_array_size(types); i++)
    {
        json_t *element = json_array_get(types, i);

        if (json_is_string(element))
        {
            TemplateInfo *t = new TemplateInfo;
            t->fullTypeName = json_string_value(element);
            tinfo->types.push_back(t);
        }
        else if (json_is_object(element))
        {
            tinfo->types.push_back(readTemplateTypeInfo(element));
        }
        else
        {
            assert(0);
        }
    }

    return tinfo;
}
}
