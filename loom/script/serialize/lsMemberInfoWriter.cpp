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
#include "loom/script/serialize/lsMemberInfoWriter.h"
#include "loom/script/compiler/lsAST.h"

namespace LS {
json_t *MemberInfoWriter::writeMetaInfo(utHashTable<utHashedString, utList<MetaInfo *> *> *metaInfo)
{
    json_t *root = json_object();

    for (UTsize i = 0; i < metaInfo->size(); i++)
    {
        utString key = metaInfo->keyAt(i).str();

        utList<MetaInfo *> *metaList = metaInfo->at(i);

        json_t *metaArray = json_array();

        json_object_set(root, key.c_str(), metaArray);

        for (UTsize j = 0; j < metaList->size(); j++)
        {
            MetaInfo *mi = metaList->at(j);

            json_t *keyArray = json_array();

            json_array_append(metaArray, keyArray);

            int count = 0;
            for (UTsize k = 0; k < mi->keys.size(); k++)
            {
                utString key    = mi->keys.keyAt(k).str();
                utString *value = mi->keys.get(key);

                json_array_append(keyArray, json_string(key.c_str()));
                json_array_append(keyArray, value ? json_string(value->c_str()) : json_string(""));
            }
        }
    }

    return root;
}


json_t *MemberInfoWriter::writeTemplateTypeInfo(TemplateInfo *templateInfo)
{
    lmAssert(templateInfo, "NULL templateInfo");
    json_t *tiobject = json_object();
    json_t *types    = json_array();

    json_object_set(tiobject, "types", types);

    lmAssert(templateInfo->type, "Untyped template info");

    json_object_set(tiobject, "type", json_string(templateInfo->type->getFullName().c_str()));

    for (UTsize i = 0; i < templateInfo->types.size(); i++)
    {
        TemplateInfo *t = templateInfo->types.at(i);
        if (t->types.size() > (UTsize)0)
        {
            json_array_append(types, writeTemplateTypeInfo(t));
        }
        else
        {
            lmAssert(t->type, "Untyped template info type");
            json_array_append(types, json_string(t->type->getFullName().c_str()));
        }
    }

    return tiobject;
}


void MemberInfoWriter::write(json_t *json)
{
    json_object_set(json, "name", json_string(name.c_str()));

    json_object_set(json, "docString", json_string(docString.c_str()));
    json_object_set(json, "source", json_string(source.c_str()));
    json_object_set(json, "line", json_integer(lineNumber));
    json_object_set(json, "ordinal", json_integer(ordinal));

    json_object_set(json, "metainfo", writeMetaInfo(&metaInfo));
}
}
