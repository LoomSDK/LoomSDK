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

#ifndef _lspropertyinfowriter_h
#define _lspropertyinfowriter_h

#include "loom/common/core/assert.h"
#include "loom/script/reflection/lsPropertyInfo.h"
#include "loom/script/serialize/lsMemberInfoWriter.h"
#include "loom/script/serialize/lsMethodWriter.h"

namespace LS {
class PropertyInfoWriter : public MemberInfoWriter {
protected:
    PropertyAttributes attr;
    utString           fullTypeName;
    MethodInfoWriter   *getterWriter;
    MethodInfoWriter   *setterWriter;
    TemplateInfo       *templateInfo;

public:

    PropertyInfoWriter() :
        setterWriter(NULL), getterWriter(NULL), templateInfo(NULL)
    {
    }

    json_t *write();

    void setFullTypeName(const utString& name)
    {
        this->fullTypeName = name;
    }

    void setPropertyAttributes(const PropertyAttributes& attr)
    {
        this->attr = attr;
    }

    void setGetterMethodInfoWriter(MethodInfoWriter *writer)
    {
        getterWriter = writer;
    }

    void setSetterMethodInfoWriter(MethodInfoWriter *writer)
    {
        setterWriter = writer;
    }

    void setTemplateTypeInfo(TemplateInfo *_templateInfo)
    {
        if (!_templateInfo)
        {
            templateInfo = NULL;
            return;
        }

        lmAssert(_templateInfo->type, "Setting untyped TemplateInfo");

        templateInfo = _templateInfo;
    }
};
}
#endif
