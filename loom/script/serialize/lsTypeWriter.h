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

#ifndef _lstypewriter_h
#define _lstypewriter_h

#include "jansson.h"

#include "loom/common/utils/utTypes.h"
#include "loom/common/utils/utString.h"

#include "loom/script/serialize/lsFieldInfoWriter.h"
#include "loom/script/serialize/lsPropertyInfoWriter.h"
#include "loom/script/serialize/lsMethodWriter.h"

namespace LS {
class TypeWriter {
    friend class ModuleWriter;

    TypeAttributes attr;

    utString baseTypeFullPath;

    utString packageName;
    utString typeName;

    utString source;
    utString docString;
    int      lineNumber;

    LSTYPEID typeID;

    // byte code
    utString bcStaticInitializer;

    utString bcInstanceInitializer;

    utArray<utString>             imports;
    ConstructorInfoWriter         *constructor;
    utArray<MethodInfoWriter *>   methods;
    utArray<FieldInfoWriter *>    fields;
    utArray<PropertyInfoWriter *> properties;
    utArray<utString>             interfaces;

    utArray<utString> delegateTypes;
    utString          delegateReturnType;

    utHashTable<utHashedString, utList<MetaInfo *> *> metaInfo;

public:

    TypeWriter() :
        typeID(0), constructor(NULL)
    {
    }

    void setTypeName(const utString& typeName)
    {
        this->typeName = typeName;
    }

    void setPackageName(const utString& packageName)
    {
        this->packageName = packageName;
    }

    void setTypeID(LSTYPEID typeID)
    {
        this->typeID = typeID;
    }

    void addInteraceFullPath(const utString& fullPath)
    {
        interfaces.push_back(fullPath);
    }

    void addDelegateTypeFullPath(const utString& fullPath)
    {
        delegateTypes.push_back(fullPath);
    }

    void setDelegateReturnTypeFullPath(const utString& fullPath)
    {
        delegateReturnType = fullPath;
    }

    void setBaseTypeFullPath(const utString& fullPath)
    {
        this->baseTypeFullPath = fullPath;
    }

    void setInterface() { attr.isInterface = true; }

    void setClass() { attr.isClass = true; }

    void setStruct() { attr.isStruct = true; }

    void setDelegate() { attr.isDelegate = true; }

    void setEnum() { attr.isEnum = true; }

    void setStatic() { attr.isStatic = true; }

    void setPublic() { attr.isPublic = true; }

    void setFinal() { attr.isFinal = true; }

    void setBCInstanceInitializer(const utString& bc)
    {
        bcInstanceInitializer = bc;
    }

    void setBCStaticInitializer(const utString& bc)
    {
        bcStaticInitializer = bc;
    }

    void setImports(const utArray<utString>& imports)
    {
        this->imports = imports;
    }

    void addFieldInfoWriter(FieldInfoWriter *fwriter)
    {
        fields.push_back(fwriter);
    }

    void addPropertyInfoWriter(PropertyInfoWriter *pwriter)
    {
        properties.push_back(pwriter);
    }

    void setConstructorInfoWriter(ConstructorInfoWriter *cwriter)
    {
        constructor = cwriter;
    }

    void addMethodInfoWriter(MethodInfoWriter *mwriter)
    {
        methods.push_back(mwriter);
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

    void setSourceInfo(const char *source, int lineNumber)
    {
        this->source     = source;
        this->lineNumber = lineNumber;
    }

    void setDocString(const utString& _docString)
    {
        docString = _docString;
    }

    json_t *write();
};
}
#endif
