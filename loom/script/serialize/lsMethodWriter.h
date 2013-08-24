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

#ifndef _lsmethodwriter_h
#define _lsmethodwriter_h

#include "loom/script/serialize/lsMemberInfoWriter.h"

#include "loom/script/reflection/lsMethodInfo.h"

namespace LS {
class ParameterInfoWriter {
    utString fullTypeName;

    TemplateInfo *templateInfo;

public:

    ParameterInfoWriter() : templateInfo(NULL)
    {
    }

    utString name;
    utString defaultArg;

    ParameterAttributes attr;

    void setFullTypeName(const utString& name)
    {
        this->fullTypeName = name;
    }

    void setTemplateTypeInfo(TemplateInfo *_templateInfo)
    {
        this->templateInfo = _templateInfo;
    }

    json_t *write();
};

class MethodBaseWriter : public MemberInfoWriter {
protected:
    MethodAttributes attr;

    utArray<ParameterInfoWriter *> paramWriters;

    TemplateInfo *templateInfo;

    // bytecode
    utString byteCode;

public:

    MethodBaseWriter() : templateInfo(NULL)
    {
    }

    void write(json_t *json);

    void addParameterInfoWriter(ParameterInfoWriter *writer)
    {
        paramWriters.push_back(writer);
    }

    void setMethodAttributes(const MethodAttributes& attr)
    {
        this->attr = attr;
    }

    void setByteCode(const utString& bc)
    {
        byteCode = bc;
    }

    void setTemplateTypeInfo(TemplateInfo *_templateInfo)
    {
        this->templateInfo = _templateInfo;
    }
};

class MethodInfoWriter : public MethodBaseWriter {
    utString returnType;

public:
    json_t *write();

    void setReturnType(const utString& returnType)
    {
        this->returnType = returnType;
    }
};

class ConstructorInfoWriter : public MethodBaseWriter {
    bool defaultConstructor;

public:

    ConstructorInfoWriter() : defaultConstructor(false)
    {
    }

    json_t *write();

    // compiler default constructor
    void setDefaultConstructor(bool defaultConstructor)
    {
        this->defaultConstructor = defaultConstructor;
    }
};
}
#endif
