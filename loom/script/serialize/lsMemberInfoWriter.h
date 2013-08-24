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

#ifndef _lsmemberinfowriter_h
#define _lsmemberinfowriter_h

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/reflection/lsMemberInfo.h"

namespace LS {
class MemberInfoWriter
{
    utString name;

    MemberTypes memberType;

    // fully qualified path to the class object that declares this member info
    utString declaringType;

    // fully qualified path to the type this member is
    utString type;

    utHashTable<utHashedString, utList<MetaInfo *> *> metaInfo;

    utString docString;
    int      ordinal;

    utString source;
    int      lineNumber;

public:

    MemberInfoWriter() : ordinal(0), lineNumber(0)
    {
    }

    void setName(const utString& name)
    {
        this->name = name;
    }

    void setDeclaringType(const utString& declaringType)
    {
        this->declaringType = name;
    }

    void setType(const utString& type)
    {
        this->type = type;
    }

    // Adds a unique MetaInfo to thie MemberInfo, possibly in addtion to an existing MetaInfo with the same name
    MetaInfo *addUniqueMetaInfo(const utString& name, const utString& key = "", const utString& value = "")
    {
        UTsize idx = metaInfo.find(name);

        utList<MetaInfo *> *metaList;

        if (idx == UT_NPOS)
        {
            metaList = new utList<MetaInfo *>;
            metaInfo.insert(name, metaList);
        }
        else
        {
            metaList = metaInfo.at(idx);
        }

        MetaInfo *mi = new MetaInfo;

        mi->name = name;

        if (key != "")
        {
            mi->keys.insert(key, value);
        }

        metaList->push_back(mi);

        return mi;
    }

    void setDocString(const utString& _docString)
    {
        docString = _docString;
    }

    void setSourceInfo(const char *source, int lineNumber)
    {
        this->source     = source;
        this->lineNumber = lineNumber;
    }

    void setOrdinal(int _ordinal)
    {
        ordinal = _ordinal;
    }

    void write(json_t *json);

    static json_t *writeTemplateTypeInfo(TemplateInfo *templateInfo);

    static json_t *writeMetaInfo(utHashTable<utHashedString, utList<MetaInfo *> *> *metaInfo);
};
}
#endif
